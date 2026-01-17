/**
 * Service d'analyse de photos avec Claude Vision
 * Analyse la qualité du travail de déneigement via les photos avant/après
 */

const Anthropic = require('@anthropic-ai/sdk');
const Reservation = require('../models/Reservation');
const axios = require('axios');

// Client Anthropic (lazy init)
let anthropicClient = null;

function getAnthropicClient() {
  if (!anthropicClient && process.env.ANTHROPIC_API_KEY) {
    anthropicClient = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }
  return anthropicClient;
}

/**
 * Convertit une URL d'image en base64
 */
async function imageUrlToBase64(url) {
  try {
    const response = await axios.get(url, {
      responseType: 'arraybuffer',
      timeout: 10000,
    });
    const base64 = Buffer.from(response.data).toString('base64');
    const contentType = response.headers['content-type'] || 'image/jpeg';
    return { base64, contentType };
  } catch (error) {
    console.error('Erreur conversion image:', error.message);
    return null;
  }
}

/**
 * Construit le prompt d'analyse pour Claude Vision
 */
function buildAnalysisPrompt(photoType, hasBeforeAfter) {
  if (hasBeforeAfter) {
    return `Tu es un expert en contrôle qualité pour un service de déneigement de véhicules au Québec.

Analyse ces photos AVANT et APRÈS le déneigement d'un véhicule et évalue:

1. **Qualité du déneigement** (0-100):
   - La neige a-t-elle été correctement enlevée du véhicule?
   - Les vitres sont-elles bien dégagées?
   - Le toit, capot et coffre sont-ils dégagés?

2. **Complétude du travail** (0-100):
   - Toutes les zones visibles ont-elles été traitées?
   - Y a-t-il des zones oubliées?

3. **Problèmes détectés** (liste):
   - neige_residuelle
   - vitres_non_degagees
   - toit_non_degage
   - photo_floue
   - photo_sombre
   - vehicule_different
   - travail_incomplet

4. **Résumé** (2-3 phrases en français québécois)

Réponds en JSON avec ce format exact:
{
  "qualityScore": 85,
  "completenessScore": 90,
  "issues": ["neige_residuelle"],
  "summary": "Le déneigement est bien fait dans l'ensemble...",
  "beforePhotoQuality": "good",
  "afterPhotoQuality": "good"
}`;
  }

  return `Tu es un expert en contrôle qualité pour un service de déneigement de véhicules au Québec.

Analyse cette photo ${photoType === 'after' ? 'APRÈS' : 'AVANT'} déneigement et évalue:

1. **Qualité de la photo** (good/average/poor)
2. **Observations** sur l'état du véhicule
3. **Problèmes potentiels** détectés

Réponds en JSON:
{
  "photoQuality": "good",
  "observations": "Description de ce qu'on voit...",
  "issues": []
}`;
}

/**
 * Analyse les photos d'une réservation avec Claude Vision
 */
async function analyzeJobPhotos(reservationId) {
  const client = getAnthropicClient();
  if (!client) {
    throw new Error('Claude API non configurée');
  }

  if (process.env.AI_PHOTO_ANALYSIS_ENABLED !== 'true') {
    throw new Error('Analyse de photos désactivée');
  }

  // Récupérer la réservation avec ses photos
  const reservation = await Reservation.findById(reservationId);
  if (!reservation) {
    throw new Error('Réservation non trouvée');
  }

  const photos = reservation.photos || [];
  if (photos.length === 0) {
    throw new Error('Aucune photo à analyser');
  }

  // Séparer photos avant/après
  const beforePhotos = photos.filter((p) => p.type === 'before');
  const afterPhotos = photos.filter((p) => p.type === 'after');

  // Construire les messages avec images
  const content = [];
  const hasBeforeAfter = beforePhotos.length > 0 && afterPhotos.length > 0;

  // Ajouter les photos AVANT
  for (const photo of beforePhotos.slice(0, 2)) {
    const imageData = await imageUrlToBase64(photo.url);
    if (imageData) {
      content.push({
        type: 'text',
        text: '📷 Photo AVANT déneigement:',
      });
      content.push({
        type: 'image',
        source: {
          type: 'base64',
          media_type: imageData.contentType,
          data: imageData.base64,
        },
      });
    }
  }

  // Ajouter les photos APRÈS
  for (const photo of afterPhotos.slice(0, 2)) {
    const imageData = await imageUrlToBase64(photo.url);
    if (imageData) {
      content.push({
        type: 'text',
        text: '📷 Photo APRÈS déneigement:',
      });
      content.push({
        type: 'image',
        source: {
          type: 'base64',
          media_type: imageData.contentType,
          data: imageData.base64,
        },
      });
    }
  }

  // Ajouter le prompt d'analyse
  content.push({
    type: 'text',
    text: buildAnalysisPrompt(afterPhotos.length > 0 ? 'after' : 'before', hasBeforeAfter),
  });

  try {
    const response = await client.messages.create({
      model: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
      max_tokens: 1000,
      messages: [
        {
          role: 'user',
          content,
        },
      ],
    });

    const responseText = response.content[0].text;

    // Parser la réponse JSON
    let analysis;
    try {
      // Extraire le JSON de la réponse
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        analysis = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('Pas de JSON dans la réponse');
      }
    } catch (parseError) {
      console.error('Erreur parsing JSON:', parseError.message);
      analysis = {
        qualityScore: 70,
        completenessScore: 70,
        issues: [],
        summary: responseText.slice(0, 200),
      };
    }

    // Construire le résultat final
    const result = {
      qualityScore: analysis.qualityScore || 0,
      completenessScore: analysis.completenessScore || 0,
      issues: analysis.issues || [],
      summary: analysis.summary || '',
      beforePhotoQuality: analysis.beforePhotoQuality || null,
      afterPhotoQuality: analysis.afterPhotoQuality || null,
      photosAnalyzed: {
        before: beforePhotos.length,
        after: afterPhotos.length,
      },
      analyzedAt: new Date(),
      modelVersion: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
    };

    // Mettre à jour la réservation
    await Reservation.findByIdAndUpdate(reservationId, {
      $set: {
        aiPhotoAnalysis: result,
        'qualityVerification.aiQualityScore': result.qualityScore,
        'qualityVerification.photoIssues': result.issues,
      },
    });

    return result;
  } catch (error) {
    console.error('Erreur analyse Claude Vision:', error.message);
    throw error;
  }
}

/**
 * Analyse rapide d'une seule photo (pour validation en temps réel)
 */
async function analyzePhoto(photoUrl, photoType = 'after') {
  const client = getAnthropicClient();
  if (!client) {
    return { valid: true, issues: [] };
  }

  try {
    const imageData = await imageUrlToBase64(photoUrl);
    if (!imageData) {
      return { valid: false, issues: ['photo_inaccessible'] };
    }

    const response = await client.messages.create({
      model: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
      max_tokens: 300,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: imageData.contentType,
                data: imageData.base64,
              },
            },
            {
              type: 'text',
              text: `Analyse rapide de cette photo de véhicule (${photoType === 'after' ? 'après' : 'avant'} déneigement).

Réponds en JSON:
{
  "valid": true/false,
  "quality": "good/average/poor",
  "issues": ["liste des problèmes si présents"],
  "isVehicle": true/false
}`,
            },
          ],
        },
      ],
    });

    const responseText = response.content[0].text;
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);

    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }

    return { valid: true, issues: [] };
  } catch (error) {
    console.error('Erreur analyse photo:', error.message);
    return { valid: true, issues: [] };
  }
}

/**
 * Vérifie si les photos avant/après montrent le même véhicule
 */
async function verifyVehicleConsistency(beforePhotoUrl, afterPhotoUrl) {
  const client = getAnthropicClient();
  if (!client) {
    return { consistent: true, confidence: 0.5 };
  }

  try {
    const beforeData = await imageUrlToBase64(beforePhotoUrl);
    const afterData = await imageUrlToBase64(afterPhotoUrl);

    if (!beforeData || !afterData) {
      return { consistent: true, confidence: 0.5, error: 'Photos inaccessibles' };
    }

    const response = await client.messages.create({
      model: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
      max_tokens: 200,
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: 'Photo AVANT:' },
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: beforeData.contentType,
                data: beforeData.base64,
              },
            },
            { type: 'text', text: 'Photo APRÈS:' },
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: afterData.contentType,
                data: afterData.base64,
              },
            },
            {
              type: 'text',
              text: `Est-ce le MÊME véhicule sur les deux photos? Réponds en JSON:
{
  "sameVehicle": true/false,
  "confidence": 0.0-1.0,
  "reason": "explication courte"
}`,
            },
          ],
        },
      ],
    });

    const responseText = response.content[0].text;
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);

    if (jsonMatch) {
      const result = JSON.parse(jsonMatch[0]);
      return {
        consistent: result.sameVehicle,
        confidence: result.confidence,
        reason: result.reason,
      };
    }

    return { consistent: true, confidence: 0.5 };
  } catch (error) {
    console.error('Erreur vérification véhicule:', error.message);
    return { consistent: true, confidence: 0.5, error: error.message };
  }
}

module.exports = {
  analyzeJobPhotos,
  analyzePhoto,
  verifyVehicleConsistency,
};

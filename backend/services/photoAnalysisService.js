/**
 * Service d'analyse de photos avec Claude Vision.
 * Évalue la qualité du déneigement via les photos avant/après, détecte le type de véhicule,
 * estime la profondeur de neige et vérifie la cohérence entre les photos.
 */

const Anthropic = require('@anthropic-ai/sdk');
const Reservation = require('../models/Reservation');
const axios = require('axios');

// --- Initialisation du client Anthropic ---

let anthropicClient = null;

function getAnthropicClient() {
  if (!anthropicClient && process.env.ANTHROPIC_API_KEY) {
    anthropicClient = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }
  return anthropicClient;
}

// --- Fonctions utilitaires ---

/**
 * Convertit une URL d'image en base64 pour l'envoi à l'API Claude Vision.
 * @param {string} url - URL de l'image
 * @returns {Promise<Object|null>} { base64, contentType } ou null en cas d'erreur
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

// --- Constantes ---

/** Types de véhicules reconnus par l'analyse IA. */
const VEHICLE_TYPES = {
  SEDAN: 'sedan',
  SUV: 'suv',
  TRUCK: 'truck',
  COMPACT: 'compact',
  MINIVAN: 'minivan',
  UNKNOWN: 'unknown',
};

// --- Construction des prompts ---

/**
 * Construit le prompt d'analyse pour Claude Vision selon le type de photo.
 * @param {string} photoType - Type de photo ('before' ou 'after')
 * @param {boolean} hasBeforeAfter - true si les photos avant ET après sont disponibles
 * @returns {string} Le prompt formaté pour Claude
 */
function buildAnalysisPrompt(photoType, hasBeforeAfter) {
  if (hasBeforeAfter) {
    return `Tu es un expert en contrôle qualité pour un service de déneigement de véhicules au Québec.

Analyse ces photos AVANT et APRÈS le déneigement d'un véhicule et évalue:

1. **Type de véhicule** (IMPORTANT):
   - sedan (berline, voiture standard)
   - compact (petite voiture)
   - suv (VUS, crossover)
   - truck (camion, pickup)
   - minivan (fourgonnette)
   - unknown (si impossible à déterminer)

2. **Qualité du déneigement** (0-100):
   - La neige a-t-elle été correctement enlevée du véhicule?
   - Les vitres sont-elles bien dégagées?
   - Le toit, capot et coffre sont-ils dégagés?

3. **Complétude du travail** (0-100):
   - Toutes les zones visibles ont-elles été traitées?
   - Y a-t-il des zones oubliées?

4. **Estimation neige** (cm approximatif visible sur le véhicule AVANT)

5. **Problèmes détectés** (liste):
   - neige_residuelle
   - vitres_non_degagees
   - toit_non_degage
   - photo_floue
   - photo_sombre
   - vehicule_different
   - travail_incomplet
   - pas_de_vehicule (CRITIQUE: aucun véhicule visible)
   - photo_fake (image suspecte/générée)

6. **Résumé** (2-3 phrases en français québécois)

Réponds en JSON avec ce format exact:
{
  "vehicleType": "sedan",
  "vehicleDetected": true,
  "estimatedSnowDepthCm": 15,
  "qualityScore": 85,
  "completenessScore": 90,
  "issues": ["neige_residuelle"],
  "summary": "Le déneigement est bien fait dans l'ensemble...",
  "beforePhotoQuality": "good",
  "afterPhotoQuality": "good",
  "isSuspiciousPhoto": false
}`;
  }

  return `Tu es un expert en contrôle qualité pour un service de déneigement de véhicules au Québec.

Analyse cette photo ${photoType === 'after' ? 'APRÈS' : 'AVANT'} déneigement et évalue:

1. **Type de véhicule**:
   - sedan (berline), compact, suv (VUS), truck (pickup), minivan, unknown

2. **Véhicule détecté**: true/false (CRITIQUE: y a-t-il vraiment un véhicule?)

3. **Qualité de la photo** (good/average/poor)

4. **Estimation neige** (cm approximatif si photo AVANT)

5. **Observations** sur l'état du véhicule

6. **Photo suspecte**: true/false (image fake, générée, ou inappropriée)

7. **Problèmes potentiels** détectés

Réponds en JSON:
{
  "vehicleType": "sedan",
  "vehicleDetected": true,
  "estimatedSnowDepthCm": 10,
  "photoQuality": "good",
  "observations": "Description de ce qu'on voit...",
  "isSuspiciousPhoto": false,
  "issues": []
}`;
}

// --- Analyse IA principale ---

/**
 * Analyse les photos avant/après d'une réservation avec Claude Vision.
 * Évalue la qualité du déneigement, détecte le véhicule et les problèmes.
 * @param {ObjectId} reservationId - Identifiant de la réservation
 * @returns {Promise<Object>} Résultat complet de l'analyse (scores, issues, véhicule)
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
      vehicleType: analysis.vehicleType || 'unknown',
      vehicleDetected: analysis.vehicleDetected !== false,
      estimatedSnowDepthCm: analysis.estimatedSnowDepthCm || null,
      qualityScore: analysis.qualityScore || 0,
      completenessScore: analysis.completenessScore || 0,
      issues: analysis.issues || [],
      summary: analysis.summary || '',
      beforePhotoQuality: analysis.beforePhotoQuality || null,
      afterPhotoQuality: analysis.afterPhotoQuality || null,
      isSuspiciousPhoto: analysis.isSuspiciousPhoto || false,
      photosAnalyzed: {
        before: beforePhotos.length,
        after: afterPhotos.length,
      },
      analyzedAt: new Date(),
      modelVersion: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
    };

    // Mettre à jour la réservation avec toutes les infos IA
    await Reservation.findByIdAndUpdate(reservationId, {
      $set: {
        aiPhotoAnalysis: result,
        'qualityVerification.aiQualityScore': result.qualityScore,
        'qualityVerification.photoIssues': result.issues,
        'qualityVerification.vehicleType': result.vehicleType,
        'qualityVerification.vehicleDetected': result.vehicleDetected,
        'qualityVerification.isSuspiciousPhoto': result.isSuspiciousPhoto,
        // Mettre à jour l'estimation de neige si détectée par l'IA
        ...(result.estimatedSnowDepthCm && { 'aiEstimatedSnowDepthCm': result.estimatedSnowDepthCm }),
      },
    });

    return result;
  } catch (error) {
    console.error('Erreur analyse Claude Vision:', error.message);
    throw error;
  }
}

// --- Analyse rapide ---

/**
 * Analyse rapide d'une seule photo pour validation en temps réel.
 * Utilisée lors du téléversement pour vérifier la qualité et la présence d'un véhicule.
 * @param {string} photoUrl - URL de la photo à analyser
 * @param {string} [photoType='after'] - Type de photo ('before' ou 'after')
 * @returns {Promise<Object>} { valid, quality, issues, isVehicle }
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

// --- Vérification de cohérence ---

/**
 * Vérifie si les photos avant/après montrent le même véhicule.
 * Utilisée pour détecter les fraudes potentielles.
 * @param {string} beforePhotoUrl - URL de la photo avant déneigement
 * @param {string} afterPhotoUrl - URL de la photo après déneigement
 * @returns {Promise<Object>} { consistent, confidence, reason }
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
  VEHICLE_TYPES,
};

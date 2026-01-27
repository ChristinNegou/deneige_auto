/**
 * Service de vérification d'identité (KYC) avec Claude Vision.
 * Analyse les documents d'identité québécois (permis, RAMQ, passeport), compare avec le selfie,
 * et prend une décision automatique ou demande une révision manuelle.
 */

const Anthropic = require('@anthropic-ai/sdk');
const User = require('../models/User');
const Notification = require('../models/Notification');
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
      timeout: 15000,
    });
    const base64 = Buffer.from(response.data).toString('base64');
    const contentType = response.headers['content-type'] || 'image/jpeg';
    return { base64, contentType };
  } catch (error) {
    console.error('Erreur conversion image:', error.message);
    return null;
  }
}

// --- Prompt IA ---

/** Prompt Claude Vision pour l'analyse de documents d'identité et la comparaison faciale. */
const VERIFICATION_PROMPT = `Tu es un expert en vérification d'identité (KYC) pour une application de services au Québec.

Analyse ces documents d'identité et ce selfie pour vérifier l'identité d'un utilisateur.

INSTRUCTIONS:
1. Vérifie que le document d'identité est authentique (pas de retouche évidente, format correct)
2. Compare le visage sur le document avec le selfie
3. Vérifie que le selfie est une vraie personne (pas une photo de photo, pas d'écran visible)
4. Extrait les informations pertinentes du document

DOCUMENTS ACCEPTÉS:
- Permis de conduire du Québec
- Carte d'assurance maladie (RAMQ)
- Passeport canadien
- Carte de résident permanent

RÉPONDS UNIQUEMENT EN JSON VALIDE:
{
  "documentType": "permis_conduire|passeport|carte_assurance_maladie|carte_resident|autre|invalide",
  "documentAuthenticity": {
    "score": 0-100,
    "isValid": true/false,
    "issues": ["liste des problèmes détectés"]
  },
  "extractedInfo": {
    "fullName": "Nom complet extrait ou null",
    "expiryDate": "YYYY-MM-DD ou null si non visible"
  },
  "faceMatch": {
    "score": 0-100,
    "samePerson": true/false,
    "confidence": "high|medium|low"
  },
  "liveness": {
    "score": 0-100,
    "isRealPerson": true/false,
    "issues": ["photo_de_photo", "ecran_visible", "image_floue", etc.]
  },
  "overallScore": 0-100,
  "recommendation": "approve|reject|manual_review",
  "summary": "Résumé en français de l'analyse (2-3 phrases)"
}

CRITÈRES DE DÉCISION:
- approve: Score global > 80, document valide, même personne avec haute confiance
- reject: Document invalide/illisible, visages différents, photo fake
- manual_review: Cas ambigus, score entre 50-80, doutes sur l'authenticité`;

// --- Analyse IA principale ---

/**
 * Analyse les documents de vérification d'identité d'un déneigeur avec Claude Vision.
 * Compare le document avec le selfie, extrait les informations et prend une décision.
 * @param {ObjectId} userId - Identifiant du déneigeur
 * @returns {Promise<Object>} Résultat { status, aiAnalysis, decision, recommendation }
 */
async function analyzeIdentityDocuments(userId) {
  const client = getAnthropicClient();
  if (!client) {
    throw new Error('Claude API non configurée');
  }

  if (process.env.IDENTITY_VERIFICATION_ENABLED !== 'true') {
    throw new Error('Vérification d\'identité désactivée');
  }

  // Récupérer l'utilisateur
  const user = await User.findById(userId);
  if (!user || user.role !== 'snowWorker') {
    throw new Error('Utilisateur non trouvé ou non déneigeur');
  }

  const documents = user.workerProfile?.identityVerification?.documents;
  if (!documents?.idFront?.url || !documents?.selfie?.url) {
    throw new Error('Documents manquants');
  }

  // Préparer les images
  const idFrontData = await imageUrlToBase64(documents.idFront.url);
  const idBackData = documents.idBack?.url ? await imageUrlToBase64(documents.idBack.url) : null;
  const selfieData = await imageUrlToBase64(documents.selfie.url);

  if (!idFrontData || !selfieData) {
    throw new Error('Impossible de charger les images');
  }

  // Construire le contenu du message
  const content = [];

  // Document recto
  content.push({
    type: 'text',
    text: '📄 DOCUMENT D\'IDENTITÉ (RECTO):',
  });
  content.push({
    type: 'image',
    source: {
      type: 'base64',
      media_type: idFrontData.contentType,
      data: idFrontData.base64,
    },
  });

  // Document verso (si disponible)
  if (idBackData) {
    content.push({
      type: 'text',
      text: '📄 DOCUMENT D\'IDENTITÉ (VERSO):',
    });
    content.push({
      type: 'image',
      source: {
        type: 'base64',
        media_type: idBackData.contentType,
        data: idBackData.base64,
      },
    });
  }

  // Selfie
  content.push({
    type: 'text',
    text: '🤳 SELFIE DE L\'UTILISATEUR:',
  });
  content.push({
    type: 'image',
    source: {
      type: 'base64',
      media_type: selfieData.contentType,
      data: selfieData.base64,
    },
  });

  // Prompt
  content.push({
    type: 'text',
    text: VERIFICATION_PROMPT,
  });

  try {
    const response = await client.messages.create({
      model: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
      max_tokens: 1500,
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
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        analysis = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('Pas de JSON dans la réponse');
      }
    } catch (parseError) {
      console.error('Erreur parsing JSON:', parseError.message);
      // Fallback avec révision manuelle
      analysis = {
        documentType: 'autre',
        documentAuthenticity: { score: 50, isValid: false, issues: ['parsing_error'] },
        extractedInfo: { fullName: null, expiryDate: null },
        faceMatch: { score: 50, samePerson: false, confidence: 'low' },
        liveness: { score: 50, isRealPerson: false, issues: ['parsing_error'] },
        overallScore: 50,
        recommendation: 'manual_review',
        summary: 'Erreur d\'analyse, révision manuelle requise.',
      };
    }

    // Construire le résultat
    const aiAnalysis = {
      faceMatchScore: analysis.faceMatch?.score || 0,
      documentAuthenticityScore: analysis.documentAuthenticity?.score || 0,
      livenessScore: analysis.liveness?.score || 0,
      overallScore: analysis.overallScore || 0,
      issues: [
        ...(analysis.documentAuthenticity?.issues || []),
        ...(analysis.liveness?.issues || []),
      ],
      extractedData: {
        documentType: analysis.documentType || 'autre',
        fullName: analysis.extractedInfo?.fullName || null,
        expiryDate: analysis.extractedInfo?.expiryDate || null,
      },
      analyzedAt: new Date(),
      modelVersion: process.env.AI_CHAT_MODEL || 'claude-sonnet-4-20250514',
    };

    // Déterminer le statut et la décision
    const autoApproveThreshold = parseInt(process.env.IDENTITY_AUTO_APPROVE_THRESHOLD) || 80;
    let newStatus = 'pending';
    let decision = null;

    if (analysis.recommendation === 'approve' && analysis.overallScore >= autoApproveThreshold) {
      newStatus = 'approved';
      decision = {
        result: 'approved',
        decidedBy: 'auto',
        decidedAt: new Date(),
        reason: analysis.summary,
      };
    } else if (analysis.recommendation === 'reject') {
      newStatus = 'rejected';
      decision = {
        result: 'rejected',
        decidedBy: 'auto',
        decidedAt: new Date(),
        reason: analysis.summary,
      };
    }
    // Si manual_review ou score insuffisant, reste en pending

    // Mettre à jour l'utilisateur
    const updateData = {
      'workerProfile.identityVerification.aiAnalysis': aiAnalysis,
      'workerProfile.identityVerification.status': newStatus,
    };

    if (decision) {
      updateData['workerProfile.identityVerification.decision'] = decision;
      if (newStatus === 'approved') {
        updateData['workerProfile.identityVerification.verifiedAt'] = new Date();
        // Expiration dans 1 an
        const expiryDays = parseInt(process.env.IDENTITY_EXPIRY_DAYS) || 365;
        updateData['workerProfile.identityVerification.expiresAt'] = new Date(
          Date.now() + expiryDays * 24 * 60 * 60 * 1000
        );
      }
    }

    await User.findByIdAndUpdate(userId, { $set: updateData });

    // Envoyer notification
    await sendVerificationNotification(userId, newStatus, decision?.reason);

    return {
      status: newStatus,
      aiAnalysis,
      decision,
      recommendation: analysis.recommendation,
    };
  } catch (error) {
    console.error('Erreur analyse identité Claude Vision:', error.message);
    throw error;
  }
}

// --- Notifications ---

/**
 * Envoie une notification au déneigeur concernant le résultat de sa vérification d'identité.
 * @param {ObjectId} userId - Identifiant du déneigeur
 * @param {string} status - Statut de vérification ('approved', 'rejected', 'pending')
 * @param {string} [reason] - Raison du refus (si applicable)
 */
async function sendVerificationNotification(userId, status, reason) {
  try {
    let title, message;

    switch (status) {
      case 'approved':
        title = '✅ Identité vérifiée';
        message = 'Félicitations ! Votre identité a été vérifiée avec succès. Vous pouvez maintenant accepter des jobs de déneigement.';
        break;
      case 'rejected':
        title = '❌ Vérification refusée';
        message = `Votre vérification d'identité a été refusée. ${reason || 'Veuillez soumettre des documents plus clairs.'}`;
        break;
      case 'pending':
        title = '⏳ Vérification en cours';
        message = 'Vos documents sont en cours de révision par notre équipe. Vous serez notifié dès que la vérification sera terminée.';
        break;
      default:
        return;
    }

    await Notification.createNotification({
      userId,
      type: 'identityVerification',
      title,
      message,
      priority: status === 'rejected' ? 'high' : 'normal',
      metadata: {
        verificationStatus: status,
        reason,
      },
    });
  } catch (error) {
    console.error('Erreur envoi notification vérification:', error.message);
  }
}

// --- Gestion administrative ---

/**
 * Traite la décision d'un administrateur sur une vérification d'identité en attente.
 * @param {ObjectId} userId - Identifiant du déneigeur
 * @param {ObjectId} adminId - Identifiant de l'administrateur
 * @param {string} decision - Décision ('approved' ou 'rejected')
 * @param {string} [reason] - Raison de la décision
 * @param {string} [notes] - Notes internes de l'administrateur
 * @returns {Promise<Object>} { success, status }
 */
async function processAdminDecision(userId, adminId, decision, reason, notes) {
  const user = await User.findById(userId);
  if (!user || user.role !== 'snowWorker') {
    throw new Error('Utilisateur non trouvé');
  }

  const currentStatus = user.workerProfile?.identityVerification?.status;
  if (currentStatus !== 'pending') {
    throw new Error('Cette vérification n\'est plus en attente');
  }

  const updateData = {
    'workerProfile.identityVerification.status': decision,
    'workerProfile.identityVerification.decision': {
      result: decision,
      decidedBy: adminId.toString(),
      decidedAt: new Date(),
      reason: reason || null,
      adminNotes: notes || null,
    },
  };

  if (decision === 'approved') {
    updateData['workerProfile.identityVerification.verifiedAt'] = new Date();
    const expiryDays = parseInt(process.env.IDENTITY_EXPIRY_DAYS) || 365;
    updateData['workerProfile.identityVerification.expiresAt'] = new Date(
      Date.now() + expiryDays * 24 * 60 * 60 * 1000
    );
  }

  await User.findByIdAndUpdate(userId, { $set: updateData });

  // Envoyer notification
  await sendVerificationNotification(userId, decision, reason);

  return { success: true, status: decision };
}

/**
 * Vérifie si un déneigeur peut resoumettre ses documents d'identité (max 3 tentatives).
 * @param {ObjectId} userId - Identifiant du déneigeur
 * @returns {Promise<Object>} { canResubmit, reason, attemptsRemaining }
 */
async function canResubmit(userId) {
  const user = await User.findById(userId);
  if (!user || user.role !== 'snowWorker') {
    return { canResubmit: false, reason: 'Utilisateur non trouvé' };
  }

  const verification = user.workerProfile?.identityVerification;
  const maxAttempts = parseInt(process.env.IDENTITY_MAX_ATTEMPTS) || 3;
  const attemptsCount = verification?.attemptsCount || 0;

  if (verification?.status === 'approved') {
    return { canResubmit: false, reason: 'Déjà vérifié' };
  }

  if (verification?.status === 'pending') {
    return { canResubmit: false, reason: 'Vérification en cours' };
  }

  if (attemptsCount >= maxAttempts) {
    return {
      canResubmit: false,
      reason: 'Nombre maximum de tentatives atteint. Contactez le support.',
      attemptsRemaining: 0,
    };
  }

  return {
    canResubmit: true,
    attemptsRemaining: maxAttempts - attemptsCount,
  };
}

// --- Statistiques ---

/**
 * Récupère les statistiques de vérification d'identité pour le tableau de bord admin.
 * @returns {Promise<Object>} Compteurs par statut (not_submitted, pending, approved, rejected, expired)
 */
async function getVerificationStats() {
  const stats = await User.aggregate([
    { $match: { role: 'snowWorker' } },
    {
      $group: {
        _id: '$workerProfile.identityVerification.status',
        count: { $sum: 1 },
      },
    },
  ]);

  const result = {
    not_submitted: 0,
    pending: 0,
    approved: 0,
    rejected: 0,
    expired: 0,
    total: 0,
  };

  stats.forEach((s) => {
    if (s._id && result.hasOwnProperty(s._id)) {
      result[s._id] = s.count;
    } else if (!s._id) {
      result.not_submitted += s.count;
    }
    result.total += s.count;
  });

  return result;
}

module.exports = {
  analyzeIdentityDocuments,
  processAdminDecision,
  canResubmit,
  getVerificationStats,
  sendVerificationNotification,
};

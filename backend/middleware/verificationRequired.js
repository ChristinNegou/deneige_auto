/**
 * Middleware pour vérifier que le déneigeur a complété la vérification d'identité
 * Bloque l'accès aux routes protégées si non vérifié
 */

const verificationRequired = async (req, res, next) => {
  // Skip si pas un worker
  if (req.user.role !== 'snowWorker') {
    return next();
  }

  // Skip si la vérification d'identité est désactivée
  if (process.env.IDENTITY_VERIFICATION_ENABLED !== 'true') {
    return next();
  }

  const verificationStatus = req.user.workerProfile?.identityVerification?.status;

  // Vérifier si approuvé
  if (verificationStatus === 'approved') {
    // Vérifier si pas expiré
    const expiresAt = req.user.workerProfile?.identityVerification?.expiresAt;
    if (expiresAt && new Date(expiresAt) < new Date()) {
      return res.status(403).json({
        success: false,
        error: 'VERIFICATION_EXPIRED',
        message: 'Votre vérification d\'identité a expiré. Veuillez resoumettre vos documents.',
        verificationStatus: 'expired',
      });
    }
    return next();
  }

  // Messages personnalisés selon le statut
  let message;
  switch (verificationStatus) {
    case 'pending':
      message = 'Votre vérification d\'identité est en cours de traitement. Veuillez patienter.';
      break;
    case 'rejected':
      message = 'Votre vérification d\'identité a été refusée. Veuillez resoumettre vos documents.';
      break;
    case 'expired':
      message = 'Votre vérification d\'identité a expiré. Veuillez resoumettre vos documents.';
      break;
    default:
      message = 'Vous devez vérifier votre identité avant de pouvoir accepter des jobs.';
  }

  return res.status(403).json({
    success: false,
    error: 'VERIFICATION_REQUIRED',
    message,
    verificationStatus: verificationStatus || 'not_submitted',
  });
};

module.exports = verificationRequired;

process.env.CLOUDINARY_CLOUD_NAME = 'demo';
process.env.CLOUDINARY_API_KEY = 'key';
process.env.CLOUDINARY_API_SECRET = 'secret';

const { documentUrl } = require('../config/cloudinary');

describe('documents d’identité privés', () => {
  it('donne un lien signé pour un document privé', () => {
    const url = documentUrl({ private: true, publicId: 'deneige-auto/verification/u1/id-front-1', url: 'https://ignored' });
    expect(url).toContain('/image/authenticated/s--');
    expect(url).toContain('deneige-auto/verification/u1/id-front-1');
  });

  it('garde l’ancienne URL pour les documents déjà envoyés', () => {
    expect(documentUrl({ url: 'https://res.cloudinary.com/demo/image/upload/old.jpg' }))
      .toBe('https://res.cloudinary.com/demo/image/upload/old.jpg');
    expect(documentUrl(null)).toBeNull();
  });
});

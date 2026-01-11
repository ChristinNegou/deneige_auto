const request = require('supertest');
const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/User');
const {
  createTestUser,
  generateAuthToken,
  getAuthHeaders,
} = require('./helpers');

// Créer une app Express pour les tests
const createApp = () => {
  const app = express();
  app.use(express.json());

  // Mock du middleware protect pour les tests
  const { protect } = require('../middleware/auth');
  const authRoutes = require('../routes/auth');

  app.use('/api/auth', authRoutes);

  // Error handler
  app.use((err, req, res, next) => {
    res.status(err.statusCode || 500).json({
      success: false,
      message: err.message,
    });
  });

  return app;
};

describe('Auth Routes', () => {
  let app;

  beforeAll(() => {
    app = createApp();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', async () => {
      const userData = {
        email: 'newuser@example.com',
        password: 'Password123!',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+15141234567',
      };

      const res = await request(app)
        .post('/api/auth/register')
        .send(userData);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.token).toBeDefined();
      expect(res.body.user).toBeDefined();
      expect(res.body.user.email).toBe(userData.email);
      expect(res.body.user.firstName).toBe(userData.firstName);
    });

    it('should fail with invalid email', async () => {
      const userData = {
        email: 'invalid-email',
        password: 'Password123!',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+15141234567',
      };

      const res = await request(app)
        .post('/api/auth/register')
        .send(userData);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should fail with duplicate email', async () => {
      const userData = {
        email: 'duplicate@example.com',
        password: 'Password123!',
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+15141234567',
      };

      // Créer le premier utilisateur
      await request(app).post('/api/auth/register').send(userData);

      // Essayer de créer un deuxième avec le même email
      const res = await request(app)
        .post('/api/auth/register')
        .send(userData);

      // L'API retourne 409 Conflict pour un email déjà utilisé
      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
    });

    it('should fail with weak password', async () => {
      const userData = {
        email: 'test@example.com',
        password: '123', // Trop court
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+15141234567',
      };

      const res = await request(app)
        .post('/api/auth/register')
        .send(userData);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  describe('POST /api/auth/login', () => {
    beforeEach(async () => {
      // Créer un utilisateur pour les tests de login
      await User.create({
        email: 'login@example.com',
        password: 'Password123!',
        firstName: 'Login',
        lastName: 'User',
        phoneNumber: '+15149876543',
      });
    });

    it('should login successfully with valid credentials', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'login@example.com',
          password: 'Password123!',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.token).toBeDefined();
      expect(res.body.user).toBeDefined();
    });

    it('should fail with wrong password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'login@example.com',
          password: 'WrongPassword!',
        });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should fail with non-existent email', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'Password123!',
        });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });
  });

  describe('GET /api/auth/me', () => {
    it('should return current user when authenticated', async () => {
      const user = await createTestUser();
      const token = generateAuthToken(user);

      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      // L'API retourne les champs utilisateur au niveau racine, pas dans un objet user
      expect(res.body.email).toBe(user.email);
      expect(res.body.firstName).toBe(user.firstName);
    });

    it('should fail without token', async () => {
      const res = await request(app).get('/api/auth/me');

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should fail with invalid token', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid-token');

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });
  });

  describe('PUT /api/auth/update-profile', () => {
    it('should update user profile', async () => {
      const user = await createTestUser();
      const token = generateAuthToken(user);

      const res = await request(app)
        .put('/api/auth/update-profile')
        .set('Authorization', `Bearer ${token}`)
        .send({
          firstName: 'Updated',
          lastName: 'Name',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.user.firstName).toBe('Updated');
      expect(res.body.user.lastName).toBe('Name');
    });

    it('should fail without authentication', async () => {
      const res = await request(app)
        .put('/api/auth/update-profile')
        .send({
          firstName: 'Updated',
        });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });
  });

  describe('POST /api/auth/logout', () => {
    it('should logout successfully', async () => {
      const user = await createTestUser();
      const token = generateAuthToken(user);

      const res = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('GET /api/auth/preferences', () => {
    it('should return user preferences', async () => {
      const user = await createTestUser();
      const token = generateAuthToken(user);

      const res = await request(app)
        .get('/api/auth/preferences')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.preferences).toBeDefined();
    });
  });

  describe('PUT /api/auth/preferences', () => {
    it('should update user preferences', async () => {
      const user = await createTestUser();
      const token = generateAuthToken(user);

      const res = await request(app)
        .put('/api/auth/preferences')
        .set('Authorization', `Bearer ${token}`)
        .send({
          pushEnabled: false,
          soundEnabled: true,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.preferences).toBeDefined();
    });
  });
});

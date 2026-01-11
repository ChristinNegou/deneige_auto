// Mock Stripe pour les tests
// Ce fichier est chargé automatiquement par Jest via jest.mock('stripe')

const mockStripe = {
  customers: {
    create: jest.fn().mockResolvedValue({
      id: 'cus_test123',
      email: 'test@example.com',
    }),
    retrieve: jest.fn().mockResolvedValue({
      id: 'cus_test123',
      email: 'test@example.com',
      invoice_settings: { default_payment_method: 'pm_test123' },
    }),
    update: jest.fn().mockResolvedValue({
      id: 'cus_test123',
    }),
  },

  paymentMethods: {
    list: jest.fn().mockResolvedValue({
      data: [
        {
          id: 'pm_test123',
          type: 'card',
          card: {
            brand: 'visa',
            last4: '4242',
            exp_month: 12,
            exp_year: 2025,
          },
        },
      ],
    }),
    attach: jest.fn().mockResolvedValue({
      id: 'pm_test123',
    }),
    detach: jest.fn().mockResolvedValue({
      id: 'pm_test123',
    }),
  },

  paymentIntents: {
    create: jest.fn().mockResolvedValue({
      id: 'pi_test123',
      client_secret: 'pi_test123_secret_test',
      status: 'requires_payment_method',
      amount: 2500,
    }),
    retrieve: jest.fn().mockResolvedValue({
      id: 'pi_test123',
      status: 'succeeded',
      amount: 2500,
    }),
    confirm: jest.fn().mockResolvedValue({
      id: 'pi_test123',
      status: 'succeeded',
    }),
  },

  refunds: {
    create: jest.fn().mockResolvedValue({
      id: 're_test123',
      amount: 2500,
      status: 'succeeded',
    }),
  },

  transfers: {
    create: jest.fn().mockResolvedValue({
      id: 'tr_test123',
      amount: 1875,
      destination: 'acct_test123',
    }),
  },

  accounts: {
    create: jest.fn().mockResolvedValue({
      id: 'acct_test123',
      type: 'express',
    }),
    retrieve: jest.fn().mockResolvedValue({
      id: 'acct_test123',
      charges_enabled: true,
      payouts_enabled: true,
      details_submitted: true,
    }),
    del: jest.fn().mockResolvedValue({
      id: 'acct_test123',
      deleted: true,
    }),
  },

  accountLinks: {
    create: jest.fn().mockResolvedValue({
      url: 'https://connect.stripe.com/setup/test',
      expires_at: Date.now() + 3600000,
    }),
  },

  balance: {
    retrieve: jest.fn().mockResolvedValue({
      available: [{ amount: 10000, currency: 'cad' }],
      pending: [{ amount: 5000, currency: 'cad' }],
    }),
  },

  webhooks: {
    constructEvent: jest.fn().mockImplementation((body, sig, secret) => {
      return JSON.parse(body);
    }),
  },
};

// Export comme fonction factory (comme le vrai module stripe)
const stripeFactory = () => mockStripe;
stripeFactory.mockStripe = mockStripe;

module.exports = stripeFactory;

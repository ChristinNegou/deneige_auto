module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.test.js', '**/*.test.js'],
  collectCoverageFrom: [
    'routes/**/*.js',
    'controllers/**/*.js',
    'middleware/**/*.js',
    'models/**/*.js',
    'services/**/*.js',
    '!**/node_modules/**',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  testTimeout: 30000,
  // Chaque fichier de test lance sa propre base MongoDB en memoire (environ
  // 200 Mo sur le disque) : deux a la fois suffisent et evitent les echecs
  // quand le disque est presque plein.
  maxWorkers: 2,
  verbose: true,
  forceExit: true,
  clearMocks: true,
  resetMocks: true,
  restoreMocks: true,
};

module.exports = async function handler(req, res) {
  const results = [];
  const start = Date.now();

  // Step 1: Try importing express
  try {
    await import('express');
    results.push({ step: 'express', ok: true, ms: Date.now() - start });
  } catch (e) {
    results.push({ step: 'express', ok: false, error: e.message });
  }

  // Step 2: Try importing dotenv
  try {
    await import('dotenv');
    results.push({ step: 'dotenv', ok: true, ms: Date.now() - start });
  } catch (e) {
    results.push({ step: 'dotenv', ok: false, error: e.message });
  }

  // Step 3: Try importing pg
  try {
    await import('pg');
    results.push({ step: 'pg', ok: true, ms: Date.now() - start });
  } catch (e) {
    results.push({ step: 'pg', ok: false, error: e.message });
  }

  // Step 4: Try importing firebase-admin
  try {
    await import('firebase-admin/app');
    results.push({ step: 'firebase-admin', ok: true, ms: Date.now() - start });
  } catch (e) {
    results.push({ step: 'firebase-admin', ok: false, error: e.message });
  }

  // Step 5: Try importing the db config (this creates a pg.Pool)
  try {
    await import('../src/config/db.js');
    results.push({ step: 'config/db', ok: true, ms: Date.now() - start });
  } catch (e) {
    results.push({ step: 'config/db', ok: false, error: e.message });
  }

  // Step 6: Try importing the full app
  try {
    await import('../src/app.js');
    results.push({ step: 'app.js', ok: true, ms: Date.now() - start });
  } catch (e) {
    results.push({ step: 'app.js', ok: false, error: e.message, stack: e.stack });
  }

  res.status(200).json({
    totalMs: Date.now() - start,
    env: {
      NODE_ENV: process.env.NODE_ENV || '(not set)',
      DATABASE_URL: process.env.DATABASE_URL ? '(set)' : '(NOT SET)',
      PORT: process.env.PORT || '(not set)',
    },
    results
  });
};

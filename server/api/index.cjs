module.exports = async function handler(req, res) {
  process.on('uncaughtException', (err) => {
    console.error('UNCAUGHT EXCEPTION:', err);
    if (!res.headersSent) res.status(500).json({ error: 'Uncaught Exception', message: err.message, stack: err.stack });
  });
  process.on('unhandledRejection', (reason, promise) => {
    console.error('UNHANDLED REJECTION:', reason);
    if (!res.headersSent) res.status(500).json({ error: 'Unhandled Rejection', reason: String(reason) });
  });

  try {
    const { app } = await import('../src/app.js');
    return app(req, res);
  } catch (error) {
    console.error("Vercel Invocation Error:", error);
    if (!res.headersSent) {
      res.status(500).json({
        success: false,
        error: "Invocation failed",
        message: error.message,
        stack: error.stack
      });
    }
  }
};

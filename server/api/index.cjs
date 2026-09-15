module.exports = async function handler(req, res) {
  try {
    const { app } = await import('../src/app.js');
    return app(req, res);
  } catch (error) {
    console.error("Vercel Invocation Error:", error);
    res.status(500).json({
      success: false,
      error: "Invocation failed",
      message: error.message,
      stack: error.stack
    });
  }
};

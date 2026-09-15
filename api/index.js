module.exports = function handler(req, res) {
  res.status(200).json({ 
    success: true, 
    message: "Root API works!",
    nodeVersion: process.version,
    cwd: process.cwd(),
    env: {
      VERCEL: process.env.VERCEL || 'not set',
      NODE_ENV: process.env.NODE_ENV || 'not set'
    }
  });
};

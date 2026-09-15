module.exports = function handler(req, res) {
  res.status(200).json({ success: true, message: "Vercel test endpoint works!" });
};

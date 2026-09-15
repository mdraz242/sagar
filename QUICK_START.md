# VyparHub — Quick Start Guide for Collaborators

Welcome to the VyparHub FMCG Ordering & Wholesale Platform codebase!

## Prerequisites
1. Node.js (v20+ or v22+)
2. Docker Desktop (for PostgreSQL)

---

## 🚀 How to Run Locally

### 1. Database (PostgreSQL)
Open terminal in server/:
`ash
cd server
docker compose up -d
`
*PostgreSQL will run locally on port 55433.*

### 2. Configure Environment
Copy the example configuration:
`ash
copy .env.example .env
`
*(On Mac/Linux: cp .env.example .env)*

### 3. Install & Initialize
`ash
npm install
npm run migrate
npm run seed
npm run seed:admin-data
`

### 4. Start the Application Server
`ash
npm run dev
`

### 5. Open in Your Browser
- 🚀 **Main Portal**: [http://localhost:8081/](http://localhost:8081/)
- 👑 **Admin Portal**: [http://localhost:8081/admin/](http://localhost:8081/admin/)
  - Email: dmin@vyparhub.com | Password: Admin@123
- 🛍️ **Customer Mobile App Web Preview**: [http://localhost:8081/preview/](http://localhost:8081/preview/)
- 📜 **Legal Suite**: [http://localhost:8081/legal/](http://localhost:8081/legal/)
- ⚡ **Health Check**: [http://localhost:8081/health](http://localhost:8081/health)

---
*Note: Sensitive production keys, .env secrets, and node_modules have been sanitized for safe sharing.*

<img width="1350" height="611" alt="image" src="https://github.com/user-attachments/assets/78a5fe8b-463e-4ad5-ab7c-1f65111b5510" />



# ISProvisioner
UISP rack deployment &amp; device provisioning helper (beta)

This is a very rough beta of ISProvisioner. Future updates will fix bugs and enhance features. Feel free to write me an email with any requests. info@wispernetinc.com

git clone https://github.com/DrVenkman123/ISProvisioner.git

SUPPORT DEVELOPMENT: cash.app/$EricElston123 
[![CashApp](https://img.shields.io/badge/Support%20via-CashApp-00C244?logo=cashapp&logoColor=white)](https://cash.app/$EricElston123)
🖥️ 
Minimum System / VM Specs                    
Recommended	                                        Minimum
CPU	2 cores (x86_64 or ARM64)	                    1 core
RAM	2 GB	                                        1 GB
Disk Space	2–4 GB free	                           1 GB minimum
Network	Reliable LAN/WAN with access to UISP device IPs	Must be able to reach target devices via HTTPS/SSH
OS	Ubuntu Server 22.04 LTS or newer	Any Debian-based Linux (20.04+)
Architecture	AMD64 / ARM64	                    Works on x86, ARMv8
Privileges	sudo access (for install scripts & PM2/systemd setup)	—

Enterprise-grade web application for ISP technicians to remotely configure Ubiquiti network devices via SSH.

Features
47 Ubiquiti Device Types - Support for NanoStation, NanoBeam, LiteAP, AirCube, UISP switches, EdgeRouter, Wave, and more
Multiple Discovery Methods - LAN scanning, WiFi adapter detection, Bluetooth discovery (Wave devices)
Device-Specific Configuration - Radio settings, PoE output, VLAN tagging, interface management
Configuration Templates - Pre-built or custom templates filtered by device family
Bulk Operations - Change credentials across multiple devices simultaneously
PoP Profiles - Manage Point of Presence configurations (SSIDs, WPA keys, beamwidths)
Real-time SSH Feedback - Live provisioning output with detailed logs
Device Stats Retrieval - Signal strength, link quality, throughput, uptime
Multi-User Support - Role-based access (Admin, Technician, Viewer)
Secure Authentication - bcrypt password hashing, PostgreSQL session storage
Dark Mode - Full light/dark theme support
System Requirements
Server
OS: Ubuntu Server 20.04 LTS or newer
Memory: 2GB RAM minimum (4GB recommended)
Storage: 10GB free space
Database: PostgreSQL 12 or newer
Node.js: 20.x LTS or newer
Network
SSH access to target Ubiquiti devices
Network connectivity to device management interfaces
Quick Start (Development)
# Clone repository
git clone <your-repo-url>
cd isprovisioner
# Install dependencies
npm install
# Set up environment variables
cp .env.example .env
# Edit .env and set DATABASE_URL
# Push database schema
npm run db:push
# Start development server
npm run dev

Visit http://localhost:5000 and create your first admin user.

Production Deployment
Automated Installation (Recommended)
The fastest way to deploy ISProvisioner on Ubuntu Server:

# Download ISProvisioner
git clone <your-repo-url>
cd isprovisioner
# Run automated installation script
sudo ./install.sh

The installation script will:

✅ Install Node.js v20 LTS
✅ Install and configure PostgreSQL
✅ Create database and user with secure credentials
✅ Set up the application in /opt/isp-provisioner
✅ Generate secure SESSION_SECRET
✅ Configure systemd service for auto-start
✅ Optionally configure UFW firewall
Post-Installation:

Visit http://YOUR_SERVER_IP:5000
Create your first admin user
Credentials saved to /opt/isp-provisioner/credentials.txt
Service Management:

sudo systemctl status isp-provisioner   # Check status
sudo systemctl restart isp-provisioner  # Restart
sudo journalctl -u isp-provisioner -f   # View logs

Manual Installation
1. Install Prerequisites
# Update system
sudo apt update && sudo apt upgrade -y
# Install Node.js 20.x LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib
# Install build essentials (required for some npm packages)
sudo apt install -y build-essential

2. Set Up PostgreSQL
# Create database and user
sudo -u postgres psql <<EOF
CREATE DATABASE isprovisioner;
CREATE USER isprovision WITH ENCRYPTED PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE isprovisioner TO isprovision;
\c isprovisioner
GRANT ALL ON SCHEMA public TO isprovision;
EOF

3. Install Application
# Create application directory
sudo mkdir -p /opt/isprovisioner
sudo chown $USER:$USER /opt/isprovisioner
# Clone or copy application files
cd /opt/isprovisioner
# ... copy your application files here ...
# Install dependencies
npm ci --production

4. Configure Environment Variables
Create /opt/isprovisioner/.env:

# Required: Strong random session secret
SESSION_SECRET=$(openssl rand -base64 32)
# Required: PostgreSQL connection string
DATABASE_URL=postgresql://isprovision:your-secure-password@localhost:5432/isprovisioner
# Production mode
NODE_ENV=production
# Port (optional, default 5000)
PORT=5000

Security Notes:

Never commit .env to version control
Use a strong random SESSION_SECRET (at least 32 characters)
Rotate SESSION_SECRET periodically for enhanced security
Use strong PostgreSQL password
5. Push Database Schema
cd /opt/isprovisioner
npm run db:push

6. Create systemd Service
Create /etc/systemd/system/isprovisioner.service:

[Unit]
Description=ISProvisioner Network Device Management
After=network.target postgresql.service
Requires=postgresql.service
[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/isprovisioner
EnvironmentFile=/opt/isprovisioner/.env
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/isprovisioner
[Install]
WantedBy=multi-user.target

# Reload systemd and start service
sudo systemctl daemon-reload
sudo systemctl enable isprovisioner
sudo systemctl start isprovisioner
# Check status
sudo systemctl status isprovisioner
# View logs
sudo journalctl -u isprovisioner -f

7. Set Up Nginx Reverse Proxy (Recommended)
Install Nginx:

sudo apt install -y nginx certbot python3-certbot-nginx

Create /etc/nginx/sites-available/isprovisioner:

server {
    listen 80;
    server_name your-domain.com;
    client_max_body_size 10M;
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Session cookie security
        proxy_cookie_path / "/; HTTPOnly; Secure; SameSite=Lax";
    }
}

# Enable site
sudo ln -s /etc/nginx/sites-available/isprovisioner /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
# Get SSL certificate (recommended)
sudo certbot --nginx -d your-domain.com

8. Initial Setup
Visit https://your-domain.com
Create first admin user (automatic admin privileges)
Configure Settings (optional UISP API integration)
Create PoP profiles for your Points of Presence
Upload or create configuration templates
Environment Variables Reference
Variable	Required	Default	Description
SESSION_SECRET	Yes (production)	dev-secret	Strong random secret for session encryption
DATABASE_URL	Yes (production)	-	PostgreSQL connection string
NODE_ENV	No	development	Environment mode (development/production)
PORT	No	5000	HTTP server port
Security Considerations
Implemented
✅ Password Hashing: bcrypt with 10 salt rounds
✅ Session Security: PostgreSQL-backed sessions with secure cookies
✅ Session Fixation Prevention: Regenerated on login/register
✅ Input Validation: Zod schemas with strict mode
✅ SQL Injection Prevention: Drizzle ORM with parameterized queries
✅ Role-Based Access Control: Admin/Technician/Viewer roles
✅ HTTP Security Headers: Recommended via Nginx config
Additional Recommendations
1. Rate Limiting
Add rate limiting middleware to prevent brute force attacks:

// Install: npm install express-rate-limit
import rateLimit from 'express-rate-limit';
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 requests per window
  message: 'Too many login attempts, please try again later'
});
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);

2. CSRF Protection
For production deployments:

// Install: npm install csurf
import csrf from 'csurf';
const csrfProtection = csrf({ cookie: true });
app.use(csrfProtection);

3. Helmet.js
Add security headers:

// Install: npm install helmet
import helmet from 'helmet';
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

4. Firewall Rules
# Allow only necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

User Management
First User (Admin Setup)
The first user registered automatically receives admin privileges. This is the setup wizard flow.

Creating Additional Users (Admin Only)
After the first user is created, only admins can create new users:

Admin logs in with credentials
Navigate to Settings → User Management (coming in future UI)
Or use API: POST /api/auth/register with admin session
User Roles
Role	Permissions
Admin	Full access - Create/edit/delete users, PoP profiles, templates, settings, provision devices
Technician	Provision devices, view configurations, run device stats, discovery
Viewer	Read-only access to provisioning logs and device information
Database Schema
Key tables:

users - Authentication and user management
pop_profiles - Point of Presence configurations
config_templates - Device configuration templates
provision_jobs - Provisioning history and audit trail
settings - Application settings (key-value store)
session - PostgreSQL session storage (auto-created)
Backup & Recovery
Database Backup
# Create backup
sudo -u postgres pg_dump isprovisioner > backup-$(date +%Y%m%d).sql
# Restore backup
sudo -u postgres psql isprovisioner < backup-20250101.sql

Application Backup
# Backup application files and environment
tar -czf isprovisioner-backup-$(date +%Y%m%d).tar.gz \
  /opt/isprovisioner/.env \
  /opt/isprovisioner/attached_assets

Troubleshooting
Application won't start
# Check logs
sudo journalctl -u isprovisioner -n 50
# Common issues:
# 1. DATABASE_URL not set or incorrect
# 2. SESSION_SECRET missing in production
# 3. PostgreSQL not running
sudo systemctl status postgresql
# 4. Port 5000 already in use
sudo lsof -i :5000

Database connection errors
# Test PostgreSQL connection
psql -U isprovision -d isprovisioner -h localhost
# Check PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*-main.log

Session issues
# Check session table exists
sudo -u postgres psql isprovisioner -c "\dt"
# Should see 'session' table
# If missing, restart application (auto-creates table)

Development
Project Structure
isprovisioner/
├── client/          # React frontend
│   └── src/
│       ├── components/   # UI components
│       ├── pages/        # Route pages
│       └── lib/          # Utilities
├── server/          # Express backend
│   ├── routes.ts         # API routes
│   ├── storage.ts        # Database interface
│   └── lib/              # Business logic
│       ├── provisioning/ # Device provisioning strategies
│       ├── discovery.ts  # Device discovery
│       └── ssh.ts        # SSH client wrapper
├── shared/          # Shared types
│   └── schema.ts         # Drizzle schema + Zod validation
└── db/              # Database files

Adding New Device Types
Add device family to shared/schema.ts if needed
Create provisioning strategy in server/lib/provisioning/
Implement configuration interface in client/src/components/
Update device stats retrieval in server/lib/device-stats.ts
Running Tests
# Unit tests (when implemented)
npm test
# E2E tests (when implemented)
npm run test:e2e

Support This Project
If ISProvisioner helps your ISP operations, consider supporting development:

CashApp: $EricElston123

Your support helps maintain and improve this tool for the ISP community.

License
Proprietary - Copyright 2025 Eric Elston

Changelog
v2.0 (2025-01-29)
New Features:

✅ Favorites with Ping Monitoring - Save frequently used devices, test SSH connectivity, view online/offline status
✅ Factory Reset Capability - Device-family-specific reset commands with dual-layer validation
✅ PoP Overview Dashboard - Visual grid of all Point of Presence profiles with statistics
✅ Mass Update UI - Tabbed interface for bulk credential changes and factory resets with sequential progress tracking
✅ User Management - Admin-only UI for creating/editing/deleting users with role management
✅ Automated Installation Script - One-command deployment to Ubuntu Server with systemd service
✅ CashApp Donation Link - Support development via $EricElston123
Security & Authentication:

✅ Production-ready authentication with PostgreSQL session storage
✅ bcrypt password hashing and Zod validation
✅ Role-based access control (Admin/Technician/Viewer)
✅ First-user admin setup wizard
✅ Session security with regeneration on login/register
✅ Input validation with Zod schemas
Improvements:

✅ Mass update retry mechanism with device metadata synchronization
✅ CSV export for bulk operation results
✅ Comprehensive error handling with res.ok validation
✅ Device-specific factory reset commands (EdgeMax, airMAX, AirCube, etc.)
✅ Real-time ping status updates
v1.0
Initial release
SSH provisioning for 47 Ubiquiti device types
Device discovery (LAN/WiFi/Bluetooth)
Configuration templates
PoP profile management
Real-time provisioning feedback


ISProvisioner v3.0
Overview
ISProvisioner v3.0 is an enterprise-grade network device provisioning web application designed for configuring and managing Ubiquiti network equipment (NanoStation, NanoBeam, LiteAP, AirCube, UISP switches, EdgeRouter, etc.). The application provides a streamlined workflow for device discovery, configuration, and deployment through an intuitive web interface with real-time SSH execution feedback. Features include IPv4/IPv6 dual-stack support, template-based provisioning, activity logging, and comprehensive device management.

User Preferences
Preferred communication style: Simple, everyday language.

System Architecture
Frontend Architecture
Framework: React 18 with TypeScript running on Vite for fast development and optimized production builds.

UI Component System: Built on shadcn/ui (Radix UI primitives) following a Material/Carbon Design-inspired system approach with enterprise productivity patterns. The design emphasizes functional hierarchy, visual clarity, and progressive disclosure for complex technical workflows.

State Management: TanStack Query (React Query) for server state management with optimistic updates and automatic cache invalidation. Local component state managed with React hooks.

Routing: Wouter for lightweight client-side routing with support for dashboard, provisioning workflow, template management, and settings pages.

Styling: Tailwind CSS with custom design tokens for spacing (2-16 units), typography (Inter primary, JetBrains Mono for technical data), and a comprehensive color system supporting both light and dark modes. Custom CSS variables enable dynamic theming.

Form Handling: React Hook Form with Zod validation for type-safe form management across device configuration workflows.

Backend Architecture
Runtime: Node.js with Express.js HTTP server providing RESTful API endpoints.

Language: TypeScript with strict mode enabled for type safety across client, server, and shared code.

API Design: Resource-oriented REST API with dedicated route handlers for:

PoP (Point of Presence) profiles
Configuration templates
Device provisioning jobs
System settings
Device discovery
Session Management: Cookie-based sessions planned (currently mocked in frontend) with JWT authentication strategy referenced in design documents.

File Organization: Monorepo structure with shared schema definitions between client and server to ensure type consistency.

Data Storage
Primary Database: PostgreSQL accessed through Neon serverless driver for scalable cloud-native deployment.

ORM: Drizzle ORM with schema-first approach using drizzle-kit for migrations. Schema includes:

Users table with role-based access (admin, tech, viewer)
PoP profiles (SSIDs, WPA keys, beamwidths)
Configuration templates (device-specific configs)
Provision jobs (audit trail)
Key-value settings store
Data Models: Strongly typed with Drizzle schema exported as TypeScript types and Zod validation schemas for runtime safety.

Device Provisioning System
SSH Integration: ssh2 library provides low-level SSH client for executing configuration commands on network devices.

Strategy Pattern: Device family-specific provisioning strategies handle differences between:

airMAX devices (system.cfg → cfgmtd → reboot)
AirCube (UCI scripts)
UISP switches (JSON API)
EdgeMAX routers (CLI commands)
Wave devices (proprietary protocols)
Discovery Mechanisms: Multi-method device discovery supporting:

LAN scanning (nmap-style CIDR-based)
WiFi adapter scanning
Bluetooth discovery (for Wave devices)
ARP table inspection
Configuration Templates: Pre-built or user-uploaded device configurations stored in database with version control and device family filtering.

Interface Configuration
Advanced Routing: Support for complex network topologies with:

IPv4/IPv6 protocol selection with dynamic placeholder hints
WLAN0/LAN0 interface management
Bridge configurations
VLAN tagging (management and data VLANs)
Static IP and DHCP modes
MTU and Ethernet speed control
Port Management: Visual grid-based interface for switch port configuration with per-port VLAN and PoE settings (24V 2-pair/4-pair).

External Dependencies
Third-Party Services
Neon Database: Serverless PostgreSQL hosting with HTTP-based connection pooling for production deployments.

UISP Integration: Optional integration with Ubiquiti UISP management platform for automated device adoption using API tokens stored in settings.

Key NPM Packages
UI Components:

@radix-ui/* (20+ primitive components for accessible UI)
class-variance-authority + clsx for dynamic styling
cmdk for command palette
react-day-picker for date inputs
Data & Forms:

@tanstack/react-query for async state
@hookform/resolvers + zod for validation
drizzle-orm + drizzle-zod for database
Network Operations:

ssh2 for SSH connections
node-arp for MAC address lookup
node-wifi for wireless adapter discovery
Authentication (planned):

jsonwebtoken for JWT tokens
connect-pg-simple for PostgreSQL session store
Development Tools:

Vite with HMR and React Fast Refresh
TypeScript with path aliases (@/, @shared/)
Replit-specific plugins for cloud IDE integration
esbuild for production server bundling

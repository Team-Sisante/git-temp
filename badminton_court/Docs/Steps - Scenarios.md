# Steps - Scenarios.md

## Scenario 1: Local Development Setup

### Objective: Set up the complete development environment locally

#### Prerequisites
- Docker installed and running
- Node.js and npm installed
- Python and pip installed

#### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/xmione/badminton_court.git
   cd badminton_court
   ```

2. **Create environment files**
   
   Create a `.env.dev` file in the project root:
   ```env
   # .env.dev

   DEBUG=true
   ENVIRONMENT=development
   SITE_HEADER=Aeropace Badminton Court
   SITE_TITLE=Aeropace Badminton Court Administration Portal
   SITE_INDEX_TITLE=Welcome to Aeropace Badminton Court Adminstration Portal

   # Application base url
   APP_PROTOCOL=http
   APP_DOMAIN=localhost
   APP_PORT=8000

   # Django SECRET_KEY (same as in .env.dev)
   SECRET_KEY=[FILL UP]

   # Rails/Postal SECRET_KEY (generated with openssl rand -base64 32)
   RAILS_SECRET_KEY=[FILL UP]

   # POSTGRES Database settings  
   DATABASE_URL=postgres://dbuser:[FILL UP]  @localhost:5432/badminton_court
   POSTGRES_PRISMA_URL=postgres://dbuser:[FILL UP]  @localhost:5432/badminton_court  
   POSTGRES_URL_NO_SSL=postgres://dbuser:[FILL UP]  @localhost:5432/badminton_court?sslmode=disable  
   POSTGRES_URL_NON_POOLING=postgres://dbuser:[FILL UP]  @localhost:5432/badminton_court?pool=false  
   POSTGRES_USER=dbuser  
   POSTGRES_HOST=localhost  
   POSTGRES_PASSWORD=[FILL UP]    
   POSTGRES_DB=badminton_court  
   POSTGRES_PORT=5432

   REDIS_URL=redis://localhost:6379/0
   REDIS_URL=redis://redis:6379/0   
   TUNNEL_SUBDOMAIN=aeropace-portal
   TUNNEL_ENABLED=true
   TUNNEL_URL=https://aeropace-portal.loca.lt # this will be replaced dynamically on runtime
   ALLOWED_HOSTS=localhost,127.0.0.1,web
   CYPRESS_BASEURL=https://aeropace-portal.loca.lt # this will be replaced dynamically on runtime
   CYPRESS_INTERNAL_baseUrl=http://localhost:8000
   CYPRESS_headed=true

   PYTHONDONTWRITEBYTECODE=1
   PYTHONUNBUFFERED=1

   # py-ngrok settings
   NGR_AUTHTOKEN=[FILL UP]  

   # Postal SMTP settings (for Django to send emails)  
   EMAIL_HOST=smtp.gmail.com  
   EMAIL_PORT=587  
   EMAIL_HOST_USER=admin@aeropace.com  
   EMAIL_HOST_PASSWORD=[FILL UP]
   SMTP_FROM_NAME=Badminton Court Management  
   DEFAULT_FROM_EMAIL=admin@aeropace.com  
   SMTP_CERT_PATH=/postal/config/tls/cert.pem  
   SMTP_KEY_PATH=/postal/config/tls/key.pem  
   SIGNING_KEY_PATH=/postal/config/postal/signing.key

   # Admin user settings for Postal
   ADMIN_EMAIL=admin@aeropace.com
   ADMIN_FIRST_NAME=Admin
   ADMIN_LAST_NAME=User
   ADMIN_PASSWORD=[FILL UP]

   SUPPORT_EMAIL=support@aeropace.com

   # MariaDB settings
   MYSQL_ROOT_PASSWORD=[FILL UP]  
   MYSQL_DATABASE=badminton_court
   MYSQL_USER=badminton_user
   MYSQL_PASSWORD=[FILL UP]  

   # Postal DB settings  
   POSTAL_HOST=localhost  
   POSTAL_PORT=5000  
   POSTAL_USER=postal  
   POSTAL_DB_HOST=mariadb  
   POSTAL_DB_PORT=3306  
   POSTAL_DB_USER=badminton_user  
   POSTAL_DB_PASS=[FILL UP]    
   POSTAL_DB_NAME=badminton_court  

   # Postal MSG_DB settings  
   MSG_DB_PASSWORD=[FILL UP]    
   MSG_DB_HOST=mariadb  
   MSG_DB_PORT=3306  
   MSG_DB_USER=badminton_user  
   MSG_DB_PASS=[FILL UP]    
   MSG_DB_NAME=badminton_court_msg_db  

   # Social Media settings
   GOOGLE_CLIENT_ID=[FILL UP]
   GOOGLE_CLIENT_SECRET=[FILL UP]
   FACEBOOK_CLIENT_ID=your_facebook_client_id  
   FACEBOOK_CLIENT_SECRET=your_facebook_client_secret  
   TWITTER_CLIENT_ID=[FILL UP]
   TWITTER_CLIENT_SECRET=[FILL UP]
   PROFILE_EDIT_URL=http:/localhost:3000/profile-setup
   ```

   Create a `.env.docker` file for Docker configuration:
   ```env
   # .env.docker

   DEBUG=true
   ENVIRONMENT=docker

   # Application base URL
   APP_PROTOCOL=http
   APP_DOMAIN=localhost
   APP_PORT=8000

   # Django SECRET_KEY (same as in .env.dev)
   SECRET_KEY=[FILL UP]  

   # Rails/Postal SECRET_KEY (generated with openssl rand -base64 32)
   RAILS_SECRET_KEY=[FILL UP]  

   # POSTGRES Database settings  
   DATABASE_URL=postgres://dbuser:[FILL UP]  @db:5432/badminton_court
   POSTGRES_PRISMA_URL=postgres://dbuser:[FILL UP]  @db:5432/badminton_court  
   POSTGRES_URL_NO_SSL=postgres://dbuser:[FILL UP]  @db:5432/badminton_court?sslmode=disable  
   POSTGRES_URL_NON_POOLING=postgres://dbuser:[FILL UP]  @db:5432/badminton_court?pool=false  
   POSTGRES_USER=dbuser  
   POSTGRES_HOST=db 
   POSTGRES_PASSWORD=[FILL UP]    
   POSTGRES_DB=badminton_court  
   POSTGRES_PORT=5432

   REDIS_URL=redis://redis:6379/0   
   TUNNEL_SUBDOMAIN=aeropace-portal
   TUNNEL_ENABLED=true
   TUNNEL_URL=https://aeropace-portal.loca.lt # this will be replaced dynamically on runtime
   ALLOWED_HOSTS=localhost,127.0.0.1,web
   CYPRESS_BASEURL=https://aeropace-portal.loca.lt # this will be replaced dynamically on runtime
   CYPRESS_INTERNAL_baseUrl=http://web:8000
   CYPRESS_headed=true

   PYTHONDONTWRITEBYTECODE=1
   PYTHONUNBUFFERED=1

   # py-ngrok settings
   NGR_AUTHTOKEN=[FILL UP]  

   # MariaDB settings (for Postal)
   MYSQL_ROOT_PASSWORD=[FILL UP]  
   MYSQL_DATABASE=postal
   MYSQL_USER=postal
   MYSQL_PASSWORD=[FILL UP]  

   # Postal DB settings  
   POSTAL_HOST=localhost
   POSTAL_PORT=5000
   POSTAL_DB_HOST=mariadb
   POSTAL_DB_PORT=3306
   POSTAL_DB_USER=postal
   POSTRAL_DB_PASS=[FILL UP]  
   POSTAL_DB_NAME=postal

   # Postal MSG_DB settings  
   MSG_DB_HOST=mariadb
   MSG_DB_PORT=3306
   MSG_DB_USER=postal
   MSG_DB_PASS=[FILL UP]  
   MSG_DB_NAME=postal

   # Postal SMTP settings (for Postal itself to send emails)  
   EMAIL_HOST=smtp.gmail.com  
   EMAIL_PORT=587  
   EMAIL_HOST_USER=admin@aeropace.com  
   EMAIL_HOST_PASSWORD=[FILL UP]   
   SMTP_FROM_NAME=Badminton Court Management  
   DEFAULT_FROM_EMAIL=admin@aeropace.com  
   SMTP_CERT_PATH=/postal/config/tls/cert.pem  
   SMTP_KEY_PATH=/postal/config/tls/key.pem  
   SIGNING_KEY_PATH=/postal/config/postal/signing.key  

   # Admin user settings for Postal
   ADMIN_EMAIL=admin@aeropace.com
   ADMIN_FIRST_NAME=Admin
   ADMIN_LAST_NAME=User
   ADMIN_PASSWORD=[FILL UP]  

   SUPPORT_EMAIL=support@aeropace.com

   # Social Media settings
   GOOGLE_CLIENT_ID=[FILL UP]    
   GOOGLE_CLIENT_SECRET=[FILL UP]  
   FACEBOOK_CLIENT_ID=[FILL UP]  
   FACEBOOK_CLIENT_SECRET=[FILL UP]    
   TWITTER_CLIENT_ID=[FILL UP]  
   TWITTER_CLIENT_SECRET=[FILL UP]  
   PROFILE_EDIT_URL=http:/localhost:3000/profile-setup
   ```

   Alternatively, create the env files automatically using a script:
   ```powershell
   scripts/decryptenvfiles.ps1
   ```

3. **Install dependencies**
   
   Python Dependencies (add to requirements.txt):
   ```
   python-dotenv==16.0.3
   dj-database-url==2.0.0
   pyngrok=7.1.6
   ```
   
   Node.js Dependencies (already included in package.json):
   ```json
   {
     "devDependencies": {
       "cypress": "^15.3.0",
       "dotenv": "^17.2.3"
     }
   }
   ```
   
   Install dependencies:
   ```bash
   # Install Node.js dependencies
   npm install

   # Install Python dependencies
   pip install -r requirements.txt
   ```

4. **Build Docker images**
   ```bash
   npm run docker:build
   ```

5. **Start development environment**
   ```bash
   npm run docker:dev-detached
   ```

6. **Set up test data**
   ```bash
   npm run docker:test-setup
   ```

7. **Verify setup**
   ```bash
   # Check service status
   npm run status

   # Access the application
   # Open browser to http://localhost:8000
   # Login with admin/password
   ```

---

## Scenario 2: Running Tests Locally

### Objective: Run end-to-end tests locally in different modes

#### Prerequisites
- Local Development Setup completed
- All services running

#### Steps

1. **Run tests in interactive mode**
   ```bash
   npm run dev:cypress-open
   ```
   - Cypress Test Runner opens in browser
   - Select test files to run interactively
   - Watch tests execute in real-time

2. **Run tests in headed mode**
   ```bash
   npm run dev:cypress-headed
   ```
   - Browser window opens showing test execution
   - Visual debugging of test steps
   - Screenshots and videos recorded

3. **Run tests in headless mode**
   ```bash
   npm run dev:cypress-headless
   ```
   - Tests run in background without browser UI
   - Suitable for automated testing
   - Results in command line

4. **Create presentation videos**
   ```bash
   npm run dev:cypress-presentation
   ```
   - Runs tests with video recording
   - Processes videos to remove Cypress UI
   - Saves to presentation-videos folder

5. **Create presentation videos for specific test**
   ```bash
   npm run dev:cypress-presentation-spec
   ```
   - Runs specific test with video recording
   - Processes videos to remove Cypress UI
   - Useful for focused demonstrations

---

## Scenario 3: Using Ngrok Tunnel for External Testing

### Objective: Test the application externally using Ngrok tunnel

#### Prerequisites
- Local Development Setup completed
- Ngrok auth token configured in .env.docker

#### Steps

1. **Start development environment**
   ```bash
   npm run docker:dev-detached
   ```

2. **Start Ngrok tunnel**
   ```bash
   npm run docker:tunnel
   ```
   - Tunnel service starts
   - Outputs tunnel URL (e.g., https://random-string.ngrok-free.dev)
   - Note the URL for external access

3. **Verify tunnel accessibility**
   ```bash
   # Check tunnel logs
   npm run docker:tunnel-logs
   
   # Access the application via tunnel URL in browser
   # Verify admin login works
   ```

4. **Run tests against tunnel**
   ```bash
   # Update CYPRESS_BASEURL to use tunnel URL
   CYPRESS_BASEURL=https://random-string.ngrok-free.dev npm run dev:cypress-headed
   ```
   - Tests run against the tunnel URL
   - Simulates external user access
   - Validates ALLOWED_HOSTS configuration

5. **Test external features**
   ```bash
   # Run specific tests in headed mode against tunnel
   CYPRESS_BASEURL=https://random-string.ngrok-free.dev npm run dev:cypress-headed
   ```
   - Tests admin login externally
   - Validates ALLOWED_HOSTS configuration
   - Ensures external access works correctly

---

## Scenario 4: Production Deployment Simulation

### Objective: Simulate production deployment and testing

#### Prerequisites
- Local Development Setup completed
- Production-like configuration ready

#### Steps

1. **Prepare production configuration**
   ```bash
   # Create production .env.docker file
   cat > .env.docker.prod << EOF
   # Application Configuration
   DEBUG=false
   DOCKER=true

   # Django Configuration
   SECRET_KEY=your-production-secret-key
   DATABASE_URL=postgres://dbuser:password@db:5432/badminton_court
   REDIS_URL=redis://redis:6379/0
   ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
   EOF
   ```

2. **Build production Docker images**
   ```bash
   # Build without cache for clean production build
   npm run docker:build-nocache
   ```

3. **Start production services**
   ```bash
   # Using production profile (if configured)
   docker-compose --env-file .env.docker.prod --profile dev up -d
   ```

4. **Run production tests**
   ```bash
   # Run tests against production configuration
   CYPRESS_BASEURL=https://yourdomain.com npm run docker:cypress-run-headless
   ```

5. **Validate production setup**
   ```bash
   # Check all services are running
   npm run status
   
   # Verify HTTPS and security headers
   curl -I https://yourdomain.com
   
   # Test all critical user flows
   npm run docker:cypress-run-headed
   ```

---

## Scenario 5: CI/CD Pipeline Testing

### Objective: Test the complete CI/CD pipeline

#### Prerequisites
- GitHub repository set up
- GitHub Actions configured
- Docker Hub access (if pushing images)

#### Steps

1. **Set up GitHub Actions workflow**
   ```yaml
   # .github/workflows/ci-cd.yml
   name: CI/CD Pipeline

   on:
     push:
       branches: [ main, develop ]
     pull_request:
       branches: [ main ]

   jobs:
     test:
       runs-on: ubuntu-latest
       
       steps:
       - name: Checkout code
         uses: actions/checkout@v3
       
       - name: Set up Node.js
         uses: actions/setup-node@v3
         with:
           node-version: '18'
       
       - name: Install dependencies
         run: npm install
       
       - name: Build Docker images
         run: npm run docker:build
       
       - name: Start test environment
         run: npm run docker:test-detached
       
       - name: Set up test data
         run: npm run docker:test-setup
       
       - name: Run Cypress tests
         run: npm run docker:cypress-run-headless
       
       - name: Upload Cypress artifacts
         uses: actions/upload-artifact@v3
         if: always()
         with:
           name: cypress-artifacts
           path: |
             cypress/screenshots/
             cypress/videos/
             cypress/reports/
       
       - name: Stop test environment
         if: always()
         run: npm run docker:test-stop
   ```

2. **Test pipeline locally**
   ```bash
   # Act as if we're in CI
   export CI=true
   
   # Clean build
   npm run docker:build-nocache
   
   # Run tests
   npm run docker:cypress-run-headless
   ```

3. **Push and trigger pipeline**
   ```bash
   # Commit and push changes
   git add .
   git commit -m "Test CI/CD pipeline"
   git push origin main
   
   # Monitor pipeline in GitHub Actions
   # Check for any failures
   # Review uploaded artifacts
   ```

4. **Validate pipeline results**
   ```bash
   # Download artifacts from GitHub Actions
   # Review test videos and screenshots
   # Check test reports
   # Verify all tests passed
   ```

---

## Scenario 6: Docker Testing Environment

### Objective: Set up and run tests in Docker containers

#### Prerequisites
- Local Development Setup completed
- All services running

#### Steps

1. **Start test environment**
   ```bash
   npm run docker:test
   ```

2. **Start test environment in detached mode**
   ```bash
   npm run docker:test-detached
   ```

3. **Set up test data**
   ```bash
   npm run docker:test-setup
   ```

4. **Start Cypress container**
   ```bash
   npm run docker:cypress-start
   ```

5. **Run Cypress tests in existing container**
   ```bash
   npm run docker:cypress-run
   ```

6. **Run Cypress tests in new container (headed)**
   ```bash
   npm run docker:cypress-run-headed
   ```

7. **Run Cypress tests in new container (headless)**
   ```bash
   npm run docker:cypress-run-headless
   ```

8. **Stop test services**
   ```bash
   npm run docker:test-stop
   ```

9. **Show test logs**
   ```bash
   npm run docker:test-logs
   ```

---

## Scenario 7: Docker Management and Maintenance

### Objective: Manage Docker containers and images

#### Prerequisites
- Local Development Setup completed

#### Steps

1. **Build all Docker images**
   ```bash
   npm run docker:build
   ```

2. **Build all Docker images without cache**
   ```bash
   npm run docker:build-nocache
   ```

3. **Build specific profile images**
   ```bash
   npm run docker:build-dev
   npm run docker:build-test
   npm run docker:build-tunnel
   npm run docker:build-presentation
   ```

4. **Rebuild all services**
   ```bash
   npm run docker:rebuild
   ```

5. **Rebuild specific profile services**
   ```bash
   npm run docker:rebuild-dev
   npm run docker:rebuild-test
   npm run docker:rebuild-tunnel
   npm run docker:rebuild-presentation
   ```

6. **Stop all services and remove volumes**
   ```bash
   npm run docker:down-volumes
   ```

7. **Clean up unused Docker resources**
   ```bash
   npm run docker:prune
   ```

8. **Reset environment**
   ```bash
   npm run docker:reset
   ```

9. **Reset environment (keeping images)**
   ```bash
   npm run docker:reset-keep-images
   ```

10. **Show service status**
    ```bash
    npm run status
    ```

11. **Show all logs**
    ```bash
    npm run docker:logs
    ```

---

## Scenario 8: Docker Image Backup and Restore

### Objective: Backup and restore Docker images

#### Prerequisites
- Local Development Setup completed

#### Steps

1. **Backup all Docker images**
   ```bash
   npm run docker:backup-images
   ```
   This command creates a single tarball containing all Docker images and saves it to the `./backups` directory.

2. **Restore all Docker images**
   ```bash
   npm run docker:restore-images
   ```
   This command restores all Docker images from the backup tarball.

3. **Backup individual Docker images**
   ```bash
   npm run docker:backup-individual
   ```
   This command creates separate tarballs for each Docker image and saves them to the `./backups` directory.

4. **Restore a specific Docker image**
   ```bash
   npm run docker:restore-image <image-name>
   ```
   Replace `<image-name>` with the name of the image you want to restore (e.g., `web`, `postal`, `celery`, etc.).

5. **List available backups**
   ```bash
   npm run docker:list-backups
   ```
   This command lists all available image backups in the `./backups` directory.

---

## Scenario 9: Performance and Load Testing

### Objective: Test application performance under load

#### Prerequisites
- Local Development Setup completed
- k6 installed (`brew install k6` or download from https://k6.io)

#### Steps

1. **Prepare load testing script**
   ```javascript
   // load-test.js
   import http from 'k6/http';
   import { check, sleep } from 'k6';

   export let options = {
     stages: [
       { duration: '2m', target: 100 },  // Ramp up to 100 users
       { duration: '5m', target: 100 },  // Stay at 100 users
       { duration: '2m', target: 0 },    // Ramp down
     ],
   };

   export default function () {
     let res = http.get('http://localhost:8000/');
     check(res, {
       'status was 200': (r) => r.status == 200,
     });
     sleep(1);
   }
   ```

2. **Start services**
   ```bash
   npm run docker:dev-detached
   ```

3. **Run load test**
   ```bash
   k6 run load-test.js
   ```
   - Monitor application performance
   - Check for errors or timeouts
   - Review response times

4. **Analyze results**
   ```bash
   # Check logs for any errors
   npm run docker:logs
   
   # Monitor database performance
   npm run docker:logs db
   
   # Check Redis usage
   npm run docker:logs redis
   ```

5. **Optimize based on results**
   - Adjust database queries if slow
   - Add caching if needed
   - Scale services if required
   - Re-run load test to verify improvements

---

## Scenario 10: Security Testing

### Objective: Test application security vulnerabilities

#### Prerequisites
- Local Development Setup completed
- OWASP ZAP installed or access to online version

#### Steps

1. **Start services**
   ```bash
   npm run docker:dev-detached
   ```

2. **Run security tests with OWASP ZAP**
   ```bash
   # Using Docker ZAP
   docker run -t owasp/zap2docker-stable zap-baseline.py -t http://localhost:8000
   ```
   - Scans for common vulnerabilities
   - Generates security report
   - Identifies potential security issues

3. **Test authentication and authorization**
   ```bash
   # Test admin access
   npm run dev:cypress-headed
   
   # Test unauthorized access
   # Manually try accessing admin areas without login
   ```

4. **Validate security headers**
   ```bash
   # Check security headers
   curl -I http://localhost:8000
   
   # Look for headers like:
   # X-Frame-Options
   # X-Content-Type-Options
   # Strict-Transport-Security
   # Content-Security-Policy
   ```

5. **Test input validation**
   ```bash
   # Run tests that try malicious inputs
   # Create test cases for SQL injection, XSS, etc.
   # Verify proper sanitization
   ```

---

## Scenario 11: Creating Presentation Videos

### Objective: Create professional presentation videos from Cypress tests

#### Prerequisites
- Local Development Setup completed
- FFmpeg installed for video processing

#### Steps

1. **Run tests with video recording**
   ```bash
   # Run all tests with video recording
   npm run dev:cypress-presentation
   
   # Run specific test with video recording
   npm run dev:cypress-presentation-spec
   ```

2. **Select specific test for presentation**
   ```bash
   # Interactively select a test to run for presentation
   npm run dev:select-presentation
   ```
   - Interactive menu appears
   - Select test from the list
   - Test runs with video recording
   - Video is automatically processed

3. **Post-process existing videos**
   ```bash
   # Process existing videos to remove Cypress UI
   npm run dev:post-process-videos
   ```
   - Removes Cypress Test Runner sidebar
   - Creates clean presentation videos
   - Generates preview clips

4. **Create presentation videos in Docker**
   ```bash
   # Start Cypress container
   npm run docker:cypress-start
   
   # Run tests with video recording
   npm run docker:cypress-run-headed --config video=true
   
   # Process videos in Docker
   npm run docker:post-process-videos
   ```

5. **Review presentation videos**
   ```bash
   # Check output folder
   ls -la cypress/presentation-videos/
   
   # Play videos to verify quality
   # Check that Cypress UI is properly removed
   ```

---

## Troubleshooting Common Issues

### Issue: Docker containers not starting
**Solution:**
```bash
# Check Docker status
docker --version

# Reset Docker environment
npm run docker:reset

# Check for port conflicts
netstat -an | grep 8000
```

### Issue: Tests failing intermittently
**Solution:**
```bash
# Increase timeouts in Cypress config
# Add explicit waits
# Check for race conditions
# Run tests in headed mode for debugging
npm run dev:cypress-headed
```

### Issue: Tunnel not accessible
**Solution:**
```bash
# Check tunnel logs
npm run docker:tunnel-logs

# Restart tunnel
npm run docker:tunnel-stop
npm run docker:tunnel

# Verify ALLOWED_HOSTS configuration
```

### Issue: Database connection issues
**Solution:**
```bash
# Check database logs
npm run docker:logs db

# Reset database
npm run docker:test-setup

# Verify database URL in .env.docker
```

### Issue: Cypress tests not finding elements
**Solution:**
```bash
# Run in interactive mode
npm run dev:cypress-open

# Run specific test with debugging
npm run dev:cypress-headed

# Check screenshots and videos
ls cypress/screenshots/
ls cypress/videos/
```

### Issue: Video processing fails
**Solution:**
```bash
# Check if FFmpeg is installed
ffmpeg -version

# Install FFmpeg if missing
# For macOS: brew install ffmpeg
# For Ubuntu: sudo apt install ffmpeg

# Check video file permissions
ls -la cypress/videos/

# Run post-processing with verbose output
npm run dev:post-process-videos
```

### Issue: Environment variable warnings
**Solution:**
```bash
# Make sure all required variables are set in .env.docker
# Check for typos in variable names
# Verify .env.docker file exists and is properly formatted
```

### Issue: Cypress container exits with code 0
**Solution:**
```bash
# Start Cypress container first
npm run docker:cypress-start

# Then run tests
npm run docker:cypress-run

# Or use all-in-one command
npm run docker:cypress-run-headless
```

### Issue: Cypress cannot connect to web service
**Solution:**
```bash
# Check if web-test container is running
npm run status

# Check if Django server is accessible
docker-compose --env-file .env.docker --profile test exec web-test curl -I http://localhost:8000

# Check web-test container logs
npm run docker:test-logs
```
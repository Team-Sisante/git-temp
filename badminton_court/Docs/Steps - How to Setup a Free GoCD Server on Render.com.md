# Steps: How to SetUp a Free GoCD Server on Render.com

This document provides step-by-step instructions to create a free, always-on GoCD server using Render.com. This server will act as the central hub for your CI/CD pipelines.

## Architecture Overview

It is critical to understand that we are setting up two separate things:

1.  **The GoCD Server (This Guide):** A web-based application that orchestrates your deployment pipelines. We will host this for free on Render.com. This requires a **new, separate Git repository** with very simple configuration files.
2.  **Your Django Application (Your Project):** The actual web application you want to deploy. This will run on a different server (e.g., a VPS, a home server). The GoCD server will command an agent on this server to deploy your app.

**We will NOT modify your existing Django `Dockerfile` or `docker-compose.yml` in this guide.**

---

## Part 1: Deploy the GoCD Server on Render.com

### Step 1: Create a New Git Repository

Create a new, empty repository on GitHub or GitLab. This repository is **only for the GoCD server configuration**.

*   **Repository Name (Suggestion):** `gocd-server-render`
*   **Visibility:** Public or Private (Render works with both)
*   **Do NOT** add a README, .gitignore, or license. We will add the files manually.

### Step 2: Create the GoCD Server `Dockerfile`

In your local clone of the new `gocd-server-render` repository, create a file named `Dockerfile`.

```dockerfile
# Dockerfile

# Use the official GoCD server image.
# Find the latest version at: https://hub.docker.com/r/gocd/gocd-server/tags
FROM gocd/gocd-server:v23.1.0
```

**Explanation:** This file is intentionally simple. It tells Render to pull the official GoCD server image from Docker Hub and run it. It contains no code from your Django application.

### Step 3: Create the Render Configuration File

In the same repository, create a file named `render.yaml`. This file tells Render how to build and run your service.

```yaml
# render.yaml

services:
  # This is the name of your service on Render's dashboard
  - type: web
    name: gocd-server
    env: docker # Tells Render to use the Dockerfile in the repo
    region: oregon # Or a region of your choice
    plan: free # Use the free tier
    dockerfilePath: ./Dockerfile # Path to the Dockerfile
    healthCheck:
      # GoCD provides a health endpoint for Render to monitor
      path: /go/api/v1/server/health
```

**Explanation:** This file defines a "Web Service" on Render. It specifies the name, the free plan, and points to the `Dockerfile` we just created. The `healthCheck` is important so Render knows if your server is running correctly.

### Step 4: Push to Your Git Provider

Commit the two files you just created and push them to your new `gocd-server-render` repository.

```bash
# From inside your local gocd-server-render directory
git add .
git commit -m "feat: Add GoCD server configuration for Render"
git push origin main
```

### Step 5: Deploy the Service on Render

1.  Sign up for a free account on [Render.com](https://render.com).
2.  On your Render Dashboard, click **New +** and select **Web Service**.
3.  Under "Connect a repository", connect your GitHub or GitLab account.
4.  Find and select the `gocd-server-render` repository.
5.  Render will automatically detect the `render.yaml` file and pre-configure the service. The name should be `gocd-server`, the Environment should be `Docker`, and the Root Directory should be `./`.
6.  Click the **Create Web Service** button at the bottom.

Render will now build and deploy your GoCD server. This will take a few minutes. You can monitor the progress in the Render dashboard.

### Step 6: Access Your GoCD Server

1.  Once the deployment is live, Render will provide you with a URL for your service (e.g., `https://gocd-server.onrender.com`). Click this URL to open the GoCD login page.
2.  To get the initial admin password, go to your service's dashboard on Render and click the **Logs** tab. Look for a line that says:
    `The server is now ready and the administrator password is located at /godata/config/adminpassword`
3.  Now, click the **Shell** tab to get a command-line prompt inside your running container.
4.  In the shell, run the following command to display the password:
    ```sh
    cat /godata/config/adminpassword
    ```
5.  Copy the password and use it to log in to the GoCD web UI with the username `admin`.

**Congratulations! You now have a free GoCD server running.**

---

## Part 2: Understanding the Next Steps

Now that your GoCD server is running, you need to connect it to your Django application. Here is a high-level overview of what you will do next. This is for context; you do not need to do these steps right now.

1.  **Set up a Target Server:** Prepare the server where your Django application will actually run (e.g., a cheap VPS from DigitalOcean, Linode, or a home server). This server must have Docker and Docker Compose installed.
2.  **Install a GoCD Agent:** On that target server, you will install a GoCD Agent. During installation, you will point it to your new GoCD server URL (`https://gocd-server.onrender.com`).
3.  **Create a Pipeline in GoCD:** In the GoCD web UI, you will create a new pipeline that watches your Django application's Git repository.
4.  **Configure Deployment Tasks:** The pipeline will have a task that runs a deployment script on your target server. This script will look something like this:

    ```bash
    # deploy.sh - This script lives on your TARGET SERVER

    # Exit immediately if a command exits with a non-zero status.
    set -e

    # The new image tag is passed from the GoCD pipeline
    NEW_IMAGE_TAG=$1

    if [ -z "$NEW_IMAGE_TAG" ]; then
      echo "Error: No image tag supplied."
      exit 1
    fi

    echo "--- Starting Deployment ---"
    echo "Deploying new image: my-django-app:${NEW_IMAGE_TAG}"

    # IMPORTANT: Replace this with the absolute path to your project on your target server
    cd /REPLACE/THIS/WITH/YOUR/PROJECT/PATH/ON/TARGET/SERVER

    # Update the docker-compose.yml file to use the new image tag
    sed -i "s|image: my-django-app:.*|image: my-django-app:${NEW_IMAGE_TAG}|g" docker-compose.yml

    # Re-create the container with the new image
    docker-compose pull
    docker-compose up -d --remove-orphans

    echo "--- Deployment Complete ---"
    ```

This completes the setup guide for the GoCD server on Render.com.
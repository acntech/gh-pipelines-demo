# Github Pipelines Demo

This project demonstrates simple build and deployment processes using GitHub Actions workflows. The deployed application is just a simple containerized web 
server that displays the environment name and project version number in the index.html file. Different environments are emulated using different ports on a 
target server using Docker containers for the deployed application/web server - one for each environment (DEV, QA, PROD).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Usage](#usage)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Ports and Services](#ports-and-services)

## Prerequisites

- Git
- SSH client
- Docker and Docker Compose if you want to run the project locally

## Setup

1. **Fork and clone the repository:**

    ```sh
    git clone https://github.com/yourusername/your-repo.git
    cd your-repo
    ```

2. **Setup a public Ubuntu server:**
    
   - Create a new (simple and public) Ubuntu server (e.g. a simple [Linode VM](https://www.linode.com/) or [DigitalOcean Droplet](https://www.digitalocean.com)) 
   - Take note of the root password and the public IP address of the server
    
3. **Copy setup files to the remote server:**
    - Use `scp` to copy the `ubuntu-setup.sh` and `docker-compose.yml` files to the remote server:

    ```sh
    scp env/ubuntu-setup.sh root@remote-server:/tmp
    scp env/docker-compose.yml root@remote-server:/tmp
    ```

4. **Run the setup script on the remote server with root privileges:**

    ```sh
    ssh root@remote-server 'bash /tmp/ubuntu-setup.sh'
    ```

   The `ubuntu-setup.sh` script will:
    - Change the default SSH port to 50022
    - Disable SSH root login
    - Disable SSH password authentication
    - Permit key-based SSH authentication
    - Create a new user `ubuntu` with sudo privileges (no password for sudo required)
    - Add the `ubuntu` user to the `docker` group
    - Generate SSH keys for the `ubuntu` user
    - Configure UFW rules
      - Open port 50022 for SSH
      - Open port 55000 for the Docker insecure registry
      - Open port 58080 for the Registry UI
      - Open port 59443 for Portainer
      - Open port 40080 for the DEV environment
      - Open port 40081 for the QA environment
      - Open port 40082 for the PROD environment
    - Install Docker and Docker Compose
    - Call `docker-compose.yml` to set up the following Docker containers
      - Insecure Docker registry on port 55000
      - Unsecured Registry UI on port 58080
      - Portainer on port 59443    
    - Display the private SSH key for the `ubuntu` user and connection instructions
    
    \
    Point your browser to `https://remote-server:59443` to access Portainer and set the admin credentials. Note that Portainer is not secured with a signed 
    certificate, so you will need to accept the browser warning.    


5. **Set GitHub variables:**

   | **Name**         | **Value**                |
   |------------------|--------------------------|
   | `APP_NAME`       | `devops-test-app`        |
   | `DEV_PORT`       | `40080`                  |
   | `PROD_PORT`      | `40082`                  |
   | `QA_PORT`        | `40081`                  |
   | `REGISTRY_URL`   | `[remote-host-IP]:55000` |
   | `REMOTE_HOST`    | `[remote-host-IP]`       |
   | `SSH_PORT`       | `50022`                  |
   | `SSH_USER`       | `ubuntu`                 |
   | `STATUS_FAIL`    | `FAIL`                   |
   | `STATUS_PASS`    | `PASS`                   |
   | `STATUS_PENDING` | `PENDING`                |


6. **Set GitHub secrets:** 
    - `SSH_KEY`: Private SSH key for the `ubuntu` user (copy from the setup script output)
    - `UAT`: User Access Token for the GitHub repository (to trigger workflows with tag push from other workflows)

## Usage

- **Trigger the workflows:**

  - Push to `main` to trigger the build (CI) workflow
  - The deployment (CD) workflow is triggered automatically after a successful build - will deploy, pending tests, the built version to the DEV environment
  - If all tests succeed for any environment (DEV/QA), a success tag will trigger a promotion to the next environment (DEV -> QA, QA -> PROD).
  - Note that the deployment script will prevent a version from being promoted to a higher environment if it has not been deployed to a lower environment 
    first and all tests have passed in that environment.

## GitHub Actions Workflows

### Build Workflow

The build workflow (`.github/workflows/build.yml`) automates the process of building, tagging, and pushing Docker images.

#### Workflow Steps

1. **Record CI start time**
2. **Print environment variables and context**
3. **Checkout code**
4. **Fetch all tags**
5. **Calculate PATCH version and tag Git**
6. **Push to the repo**
7. **Set up Docker Buildx**
8. **Configure Docker daemon for insecure registry**
9. **Wait for Docker to restart and be available**
10. **Build and push Docker image**
11. **Trigger deploy (to DEV) workflow**

#### Success and Failure Jobs

- **Success Job:**
    - Tags the repository with a successful CI tag
    - Creates a git notes object with CI details

- **Failure Job:**
    - Tags the repository with a failed CI tag
    - Creates a git notes object with CI failure details


### Deploy Workflow

The deploy (promotion) workflow (`.github/workflows/deploy.yml`) automates the deployment process to different environments.

#### Workflow Steps

1. **Record CI start time**
2. **Print environment variables and context**
3. **Checkout code**
4. **Fetch all tags**
5. **Validate Deployment**
6. **Determine external port**
7. **Deploy to remote host via SSH**
8. **Run all defined tests**
9. **Tag the repo according to test results**
10. **Update the devops notes JSON object for the promotion**
	

### Verify and Tag workflow**

#### Workflow Steps

1. **Trigger on specific tags**
2. **Extract and validate tag information**
3. **Checkout project at specified (version) tag**
4. **Configure Git for pushing changes**
5. **Remove any corresponding PENDING for test tag**
6. **Check if all required tests for the environment are satisfied**
7. **Tag environment as passed**

 	
### Conditional Deployment Workflow**

#### Workflow Steps

1. **Trigger on environment/test passed tags**
2. **Extract and validate tag information**
3. **Checkout the project code at the specific tag**
4. **Configure Git for pushing changes and fetching tags**
5. **Remove any pending tags associated with the environment and test**
6. **Check if all required tests for the environment are satisfied**
7. **Tag the environment as passed if all tests are satisfied**

#### Workflow Logic

- The workflow is triggered by a specific tag format that indicates that all tests have passed for an environment.
- It extracts and validates tag information, ensuring it matches the required pattern.
- If the tag is valid, the workflow proceeds to check out the code and configure Git.
- It removes any existing PENDING tags for the specified environment and test.
- The workflow then checks if all required tests for the environment have been satisfied.
- If all tests are satisfied, the environment is tagged as passed, and the tag is pushed to the repository.
- If the tag does not match the required pattern, or if not all tests are satisfied, the workflow exits gracefully without making any changes.

## Ports and Services

- **SSH:** Port 50022
- **Portainer:** Port 59443 (point browser to `https://remote-server:59443`)
- **Docker Insecure Registry:** Port 55000 (validate with e.g. `curl http://remote-server:55000/v2/_catalog`)
- **Registry UI:** Port 58080 (point browser to `http://remote-server:58080`)
- **Custom Services:**
    - DEV: Port 40080 (point browser to `http://remote-server:40080`)
    - QA: Port 40081 (point browser to `http://remote-server:40081`)
    - PROD: Port 40082 (point browser to `http://remote-server:40082`)
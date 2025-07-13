# Learning GHA and CI Automation with docker

This repo is a "vile replication" of Bret Fisher's [docker-ci-automation](https://github.com/BretFisher/docker-ci-automation). It's me following step by step process on how to build a continuos integration workflow, which it's something I've interacted before, but with other tools and not me in the role of a CI workflow builder or maintainer (a simple developer hoping his PR not to fail any tests T.T). It's my first time working with Github Actions, so I'll be detailing the whats,whys, and hows of the workflows I'll be working with to be used for further references to whom might find it insterested (mostly for myself, please go check Bret Fisher's repo).

## GitHub Actions Workflows

### 01-basic-build.yaml

**Purpose:**  
This workflow automates building and pushing a Docker image to Docker Hub on every push or pull request to the `master` branch. It ensures that the latest code is always available as a Docker image, which is essential for continuous integration and deployment.

**Steps:**
- **actions/checkout@v3:**  
  This step checks out the repository code into the GitHub Actions runner. It is necessary because all subsequent steps (like building the Docker image) require access to the source code.
- **docker/login-action@v3:**  
  This step logs into Docker Hub using credentials stored in GitHub Secrets (`DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`). Logging in is required to push images to your Docker Hub account securely.
- **docker/build-push-action@v6:**  
  This step builds the Docker image from your repository's Dockerfile and pushes it to Docker Hub.  
  - The `push` parameter is set so that images are only pushed on non-pull request events (e.g., direct pushes to `master`), preventing unnecessary image uploads for PRs.
  - The `tags` parameter defines the tags for the built image, allowing you to version or label your images as needed.

### 02-cache-build.yaml

**Purpose:**  
This workflow builds on the basic workflow by adding build caching, which can significantly speed up Docker builds by reusing unchanged layers. This is especially useful for large projects or frequent builds.

**Additional Steps:**
- **docker/setup-buildx-action@v3:**  
  This step sets up Docker Buildx, an advanced builder for Docker images. Buildx enables features like multi-platform builds and build caching, which are not available in the default Docker builder.
- **cache-from / cache-to:**  
  These options in the `docker/build-push-action` step enable caching of Docker build layers using GitHub Actions' built-in cache (`type=gha`).  
  - `cache-from` tells Docker to use previously cached layers if available, speeding up builds by not rebuilding unchanged layers.
  - `cache-to` saves new layers to the cache after the build, so they can be reused in future builds.
  - `mode=max` ensures the most layers are cached, maximizing cache effectiveness.

### 03-add-multi-platform.yaml

**Purpose:**  
This workflow extends the previous ones by enabling multi-platform builds. This means the Docker image can be built for multiple CPU architectures (e.g., x86_64, ARM64, ARMv7), making it usable on a wider range of devices, such as Raspberry Pi or ARM-based cloud servers.

**Additional Steps:**
- **Install Rust toolchain:**  
  This step installs the Rust programming language and its toolchain on the GitHub Actions runner. Some dependencies required for building multi-platform Docker images (especially when using QEMU for ARM architectures) are written in Rust, so having Rust available ensures that these dependencies can be compiled and used during the build process. The command also updates the system `PATH` so that Rust binaries are accessible in.
- **docker/setup-qemu-action@v3:**  
  This step sets up QEMU, a hardware emulator that allows the GitHub Actions runner to build images for architectures different from its own. Without QEMU, you could only build images for the runner's native architecture.
- **platforms:**  
  The `platforms` parameter in the build step specifies which architectures to build for (e.g., `linux/amd64`, `linux/arm64`, `linux/arm/v7`).  
  - This is only possible because Buildx and QEMU are set up in previous steps.
  - Building for multiple platforms in one workflow ensures your image is compatible with a broader set of environments, which is important for open source projects or when targeting diverse deployment targets.

### 04-add-metadata.yaml

**Purpose:**  
This workflow builds upon the previous ones by adding automatic Docker image metadata and tagging using the `docker/metadata-action`. This ensures that images are consistently labeled and tagged based on branch, PR, version, and custom rules, improving traceability and automation in your CI/CD pipeline.

**Additional Steps:**
- **docker/metadata-action@v4:**  
  This step generates standardized Docker image tags and labels based on the current GitHub context (such as branch name, PR, or semantic version).  
  - The `images` parameter specifies the Docker image repository.
  - The `tags` parameter defines multiple tagging strategies, including:
    - Raw tags (e.g., `04`, `latest`).
    - Conditional tags (e.g., `latest` only on the default branch).
    - Reference-based tags for PRs and branches.
    - Semantic version tags if applicable.
  - The action outputs the computed tags and labels, which are then used in the Docker build step.
- **labels:**  
  The Docker build step uses the labels generated by the metadata action, ensuring that built images are annotated with useful metadata for traceability and automation.  

This workflow helps maintain a consistent and automated tagging strategy for Docker images, making it easier to manage releases and deployments.

### 05-add-comment.yaml

**Purpose:**  
This workflow extends the previous ones by adding automated commenting on pull requests (PRs) with the results of the Docker image build. It ensures that contributors and reviewers are immediately informed about the image tags and labels generated for each PR, improving visibility and traceability in the CI process.

**Addtional Steps and Permissions:**
- **permissions: pull-requests: write:**  
  This permission allows the workflow to post, edit, or update comments directly on pull requests. It is essential for enabling the workflow to communicate build results back to contributors and reviewers within the PR interface.
- **Find comment for image tags (`peter-evans/find-comment@v3`):**  
  This step checks if a previous comment (from the GitHub Actions bot) already exists on the PR containing a specific phrase about image tags. By searching for an existing comment, the workflow avoids posting duplicate information and instead prepares to update the relevant comment if needed.
  - `issue-number`: Specifies the pull request number to search for comments on.
  - `comment-author`: Filters to only comments made by the GitHub Actions bot.
  - `body-includes`: Looks for comments that include a specific string, ensuring the right comment is found.
- **Create or update comment for image tags (`peter-evans/create-or-update-comment@v3`):**  
  This step either creates a new comment or updates the one found in the previous step. The comment summarizes the Docker image tags and labels produced by the build, giving clear feedback to anyone viewing the PR.
  - `comment-id`: If a matching comment was found, this parameter ensures it is updated instead of creating a new one.
  - `issue-number`: The PR number where the comment will be posted.
  - `body`: The content of the comment, listing the tags and labels for easy reference.
  - `edit-mode: replace`: Ensures the comment is fully replaced with the latest build information, keeping the PR discussion clean and up to date.

These steps ensure that every PR receives a single, always up-to-date comment with the latest Docker image build results, improving communication and transparency in the development workflow.

### 06-add-cve-scanning.yaml

**Purpose:**  
This workflow extends the previous ones by adding automated scanning of the built Docker image for known vulnerabilities (CVEs) before pushing to Docker Hub. This ensures that images are checked for security issues as part of the CI process, increasing the security and reliability of published images.

**Key Changes and Additional Steps:**
- **Docker Build and export image for scanning:**  
  Instead of immediately pushing the image, this step builds the Docker image and loads it into the local Docker daemon (`push: false`, `load: true`). The image is tagged with the GitHub run ID and built for the `linux/amd64` platform. This prepares the image for local scanning without publishing it.
  - `target: test`: Optionally specifies a build stage to target (if using multi-stage builds).
- **Scan image for vulnerabilities (`aquasecurity/trivy-action@master`):**  
  This step uses Trivy to scan the locally built image for vulnerabilities (CVEs). The scan is performed before the image is pushed to Docker Hub.
  - `image-ref: ${{ github.run_id }}`: Scans the image built and tagged in the previous step.
  - `format: 'table'`: Outputs the scan results in a human-readable table format.
  - `exit-code: '0'`: The workflow will not fail if vulnerabilities are found (set to `'1'` to fail on detection).
- **Docker Build and Push to Docker Hub:**  
  After scanning, the image is rebuilt (now for all target platforms) and pushed to Docker Hub with the appropriate tags and labels. This ensures only images that have been scanned are published.

By introducing a vulnerability scan step before pushing images, this workflow helps catch security issues early and encourages best practices for container security in the CI/CD pipeline.
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
- **docker/setup-qemu-action@v3:**  
  This step sets up QEMU, a hardware emulator that allows the GitHub Actions runner to build images for architectures different from its own. Without QEMU, you could only build images for the runner's native architecture.
- **platforms:**  
  The `platforms` parameter in the build step specifies which architectures to build for (e.g., `linux/amd64`, `linux/arm64`, `linux/arm/v7`).  
  - This is only possible because Buildx and QEMU are set up in previous steps.
  - Building for multiple platforms in one workflow ensures your image is compatible with a broader set of environments, which is important for open source projects or when targeting diverse deployment targets.

# Check runner compatibility
echo "::group::profiler docker image setup"
echo "GitHub action: $profiler_ACTION ($profiler_ACTION_PATH)"
cd $profiler_ACTION_PATH
for DEPENDENCY in docker jq; do
  if ! which $DEPENDENCY > /dev/null 2>&1; then
    echo "::error::\"$DEPENDENCY\" is not installed on current runner but is needed to run profiler"
    MISSING_DEPENDENCIES=1
  fi
done
if [[ $MISSING_DEPENDENCIES == "1" ]]; then
  echo "Runner compatibility: missing dependencies"
  exit 1
else
  echo "Runner compatibility: compatible"
fi

# Create environment file from inputs and GitHub variables
touch .env
for INPUT in $(echo $INPUTS | jq -r 'to_entries|map("INPUT_\(.key|ascii_upcase)=\(.value|@uri)")|.[]'); do
  echo $INPUT >> .env
done
env | grep -E '^(GITHUB|ACTIONS|CI|TZ)' >> .env
echo "Environment variables: loaded"

# Renders output folder
profiler_RENDERS="/profiler_renders"
sudo mkdir -p $profiler_RENDERS
echo "Renders output folder: $profiler_RENDERS"

# Source repository (picked from action name)
profiler_SOURCE=$(echo $profiler_ACTION | sed -E 's/profiler.*?$//g' | sed -E 's/_//g')
echo "Source: $profiler_SOURCE"

# Version (picked from package.json)
profiler_VERSION=$(grep -Po '(?<="version": ").*(?=")' package.json)
echo "Version: $profiler_VERSION"

# Image tag (extracted from version or from env)
profiler_TAG=v$(echo $profiler_VERSION | sed -r 's/^([0-9]+[.][0-9]+).*/\1/')
echo "Image tag: $profiler_TAG"

# Image name
# Official action
if [[ $profiler_SOURCE == "nextlinux" ]]; then
  # Use registry with pre-built images
  if [[ ! $profiler_USE_PREBUILT_IMAGE =~ ^([Ff]alse|[Oo]ff|[Nn]o|0)$ ]]; then
    # Is released version
    set +e
    profiler_IS_RELEASED=$(expr $(expr match $profiler_VERSION .*-beta) == 0)
    set -e
    echo "Is released version: $profiler_IS_RELEASED"
    if [[ "$profiler_IS_RELEASED" -eq "0" ]]; then
      profiler_TAG="$profiler_TAG-beta"
      echo "Image tag (updated): $profiler_TAG"
    fi
    profiler_IMAGE=ghcr.io/nextlinux/profiler:$profiler_TAG
    echo "Using pre-built version $profiler_TAG, will pull docker image from GitHub registry"
    if ! docker image pull $profiler_IMAGE; then
      echo "Failed to fetch docker image from GitHub registry, will rebuild it locally"
      profiler_IMAGE=profiler:$profiler_VERSION
    fi
  # Rebuild image
  else
    echo "Using an unreleased version ($profiler_VERSION)"
    profiler_IMAGE=profiler:$profiler_VERSION
  fi
# Forked action
else
  echo "Using a forked version"
  profiler_IMAGE=profiler:forked-$profiler_VERSION
fi
echo "Image name: $profiler_IMAGE"

# Build image if necessary
set +e
docker image inspect $profiler_IMAGE
profiler_IMAGE_NEEDS_BUILD="$?"
set -e
if [[ "$profiler_IMAGE_NEEDS_BUILD" -gt "0" ]]; then
  echo "Image $profiler_IMAGE is not present locally, rebuilding it from Dockerfile"
  docker build -t $profiler_IMAGE .
else
  echo "Image $profiler_IMAGE is present locally"
fi
echo "::endgroup::"

# Run docker image with current environment
docker run --init --rm --volume $GITHUB_EVENT_PATH:$GITHUB_EVENT_PATH --volume $profiler_RENDERS:/renders --env-file .env $profiler_IMAGE
rm .env

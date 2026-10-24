.DEFAULT_GOAL := all

DOCKER ?= docker
IMAGE_NAME ?= pi-builds
PI_VERSION ?= 1.4.0
DOCKER_BUILD_ARGS ?=

# Avoid Docker Hub client-side OAuth token fetch failures with the docker Buildx driver.
# Export to every Docker build recipe; caller may override e.g. BUILDKIT_NO_CLIENT_TOKEN=0.
export BUILDKIT_NO_CLIENT_TOKEN ?= 1

BASELINE_IMAGE := $(IMAGE_NAME):baseline
BASE_IMAGE ?= $(BASELINE_IMAGE)
EXTENSIONS := lsp ast-search plan-todo subagent skills web-search

# Build the baseline first when extension images inherit our baseline tag.
# An external BASE_IMAGE is assumed to exist and is not built here.
ifeq ($(BASE_IMAGE),$(BASELINE_IMAGE))
EXTENSION_DEPENDENCIES := baseline
endif

.PHONY: all build extensions baseline $(EXTENSIONS) help

all: baseline $(EXTENSIONS)
build: all
extensions: $(EXTENSIONS)

baseline:
	$(DOCKER) build $(DOCKER_BUILD_ARGS) \
		--build-arg PI_VERSION="$(PI_VERSION)" \
		-f docker/baseline/Dockerfile \
		-t "$(BASELINE_IMAGE)" .

$(EXTENSIONS): $(EXTENSION_DEPENDENCIES)
	$(DOCKER) build $(DOCKER_BUILD_ARGS) \
		--build-arg BASE_IMAGE="$(BASE_IMAGE)" \
		-f "docker/extensions/$@/Dockerfile" \
		-t "$(IMAGE_NAME):$@" .

help:
	@printf '%s\n' \
		'Targets:' \
		'  make                 Build baseline and all six extension images' \
		'  make all             Same as make' \
		'  make baseline        Build only the Pi baseline' \
		'  make extensions      Build all six extension images (and baseline if needed)' \
		'  make lsp             Build the LSP variant' \
		'  make ast-search      Build the AST Search variant' \
		'  make plan-todo       Build the Plan/Todo variant' \
		'  make subagent        Build the Subagent variant' \
		'  make skills          Build the Skills variant' \
		'  make web-search      Build the DeepSeek Web Search variant' \
		'' \
		'Variables (override with make NAME=value):' \
		'  DOCKER=docker                 Docker CLI executable' \
		'  IMAGE_NAME=pi-builds         Image repository (tags: baseline, lsp, ...)' \
		'  PI_VERSION=1.4.0             Pi version passed to baseline Dockerfile' \
		'  BASE_IMAGE=pi-builds:baseline  Parent image for extensions' \
		'  DOCKER_BUILD_ARGS=           Extra docker build options' \
		'  BUILDKIT_NO_CLIENT_TOKEN=1  Delegate registry auth to BuildKit backend'

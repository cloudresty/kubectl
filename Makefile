include version.env

BASE = cloudresty
NAME = $$(awk -F'/' '{print $$(NF-0)}' <<< $$PWD)
DOCKER_REPO = ${BASE}/${NAME}
DOCKER_TAG = ${CLR__KUBECTL_PATCH_VERSION}

.PHONY: build shell tag push clean help

help: ## Show list of make targets and their description.
	@grep -E '^[%a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

version-update: ## Update the semvers on Dockerfile using 'version.env' file as source of truth.
	@awk '{gsub("(org.opencontainers.image.version=).*","org.opencontainers.image.version=\"${CLR__KUBECTL_PATCH_VERSION}\" \\",$$0); print $$0}' Dockerfile > Dockerfile.tmp && mv Dockerfile.tmp Dockerfile
	@awk '{gsub("(org.opencontainers.image.revision=).*","org.opencontainers.image.revision=\"${CLR__KUBECTL_APTGET_VERSION}\" \\",$$0); print $$0}' Dockerfile > Dockerfile.tmp && mv Dockerfile.tmp Dockerfile
	@awk '{gsub("(https://pkgs.k8s.io/core:/stable:/)v[0-9]+.[0-9]+","https://pkgs.k8s.io/core:/stable:/${CLR__KUBECTL_MINOR_VERSION}",$$0); print $$0}' Dockerfile > Dockerfile.tmp && mv Dockerfile.tmp Dockerfile
	@awk '{gsub("(kubectl=)[0-9]+.[0-9]+.[0-9]+-[0-9]+.[0-9]+","kubectl=${CLR__KUBECTL_APTGET_VERSION}",$$0); print $$0}' Dockerfile > Dockerfile.tmp && mv Dockerfile.tmp Dockerfile

build: version-update ## Build docker image.
	@docker buildx build \
		--platform linux/amd64 \
		--pull \
		--force-rm -t ${DOCKER_REPO}:${DOCKER_TAG} \
		--file Dockerfile .

shell: ## Run docker image locally and open a shell.
	@docker run \
		--platform linux/amd64 \
		--rm \
		--name ${NAME} \
		--hostname ${NAME} \
		-it ${DOCKER_REPO}:${DOCKER_TAG} zsh

tag-latest: ## Tag docker image.
	@docker tag ${DOCKER_REPO}:${DOCKER_TAG} ${DOCKER_REPO}:latest

push: tag-latest ## Push docker image to registry.
	@docker push ${DOCKER_REPO}:${DOCKER_TAG}
	@docker push ${DOCKER_REPO}:latest

clean: ## Remove all local docker images for this repo.
	@if [[ $$(docker images --format '{{.Repository}}:{{.Tag}}' | grep ${DOCKER_REPO}) ]]; then docker rmi $$(docker images --format '{{.Repository}}:{{.Tag}}' | grep ${DOCKER_REPO}); else echo "INFO: No images found for '${DOCKER_REPO}'"; fi
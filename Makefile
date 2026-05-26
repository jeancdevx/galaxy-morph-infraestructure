AWS_PROFILE ?= default

# Directory names (underscores) → used for paths
LAMBDA_DIRS_LIST := auth_api classification_api ingestion_api upload_api post_confirmation results_dispatcher
LAMBDA_DIRS := $(addprefix services/lambdas/,$(LAMBDA_DIRS_LIST))

# Package names (hyphens) → used for pnpm --filter
LAMBDA_PKGS := auth-api classification-api ingestion-api upload-api post-confirmation results-dispatcher

.PHONY: install build clean test lint format \
        $(LAMBDA_DIRS_LIST) $(addprefix build-,$(LAMBDA_DIRS_LIST))

## Install all workspace dependencies (run once from root)
install:
	pnpm install

## Build all Lambda packages
build: $(LAMBDA_DIRS_LIST)

## Build a single Lambda by directory name: make build-auth_api
$(addprefix build-,$(LAMBDA_DIRS_LIST)): build-%:
	pnpm --filter=$(subst _,-,$*) run build

## Build each Lambda (called by 'make build')
$(LAMBDA_DIRS_LIST):
	pnpm --filter=$(subst _,-,$@) run build

## Run all tests across the workspace
test:
	pnpm -r test

## Run tests with coverage
test-coverage:
	pnpm -r run test:coverage

## Lint all Lambda TypeScript files
lint:
	pnpm run lint

## Auto-fix lint issues
lint-fix:
	pnpm run lint:fix

## Format all files with Prettier
format:
	pnpm run format

## Remove all build artifacts (dist/) from every Lambda, node_modules and pnpm-lock.yaml
clean:
	@for dir in $(LAMBDA_DIRS); do \
		rm -rf $$dir/dist; \
		rm -rf $$dir/node_modules; \
		rm -rf $$dir/pnpm-lock.yaml; \
		echo "Cleaned: $$dir/dist"; \
	done

## Remove build artifacts AND reinstall workspace deps
clean-all: clean
	rm -rf node_modules
	pnpm install

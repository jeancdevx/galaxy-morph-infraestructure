AWS_PROFILE ?= default

.PHONY: build clean

build:
	pnpm install --frozen-lockfile
	pnpm run build
	@echo "Build complete: dist/function.zip"

clean:
	rm -rf dist node_modules

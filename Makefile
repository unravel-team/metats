HOME := $(shell echo $$HOME)
HERE := $(shell echo $$PWD)

# Set bash instead of sh for the @if [[ conditions,
# and use the usual safety flags:
SHELL = /bin/bash -Eeu

.DEFAULT_GOAL := help

.PHONY: help
help:    ## A brief listing of all available commands
	@awk '/^[a-zA-Z0-9_-]+:.*##/ { \
		printf "%-25s # %s\n", \
		substr($$1, 1, length($$1)-1), \
		substr($$0, index($$0,"##")+3) \
	}' $(MAKEFILE_LIST)

.PHONY: ci
ci:
	npm ci

node_modules: ci

.PHONY: install
install: node_modules    ## Install dependencies and create node_modules

package.json:
	@if [ ! -f package.json ]; then \
        echo "Creating package.json..."; \
        npm init -y; \
        echo "Please configure your package.json manually"; \
    fi

.PHONY: install-eslint
install-eslint: package.json
	npm install --save-dev eslint @eslint/eslintrc eslint-config-next @typescript-eslint/parser @typescript-eslint/eslint-plugin
	@if [ ! -f eslint.config.mjs ] && [ ! -f .eslintrc.json ]; then \
        echo "Creating basic eslint.config.mjs..."; \
        echo 'import { dirname } from "path";' > eslint.config.mjs; \
        echo 'import { fileURLToPath } from "url";' >> eslint.config.mjs; \
        echo 'import { FlatCompat } from "@eslint/eslintrc";' >> eslint.config.mjs; \
        echo '' >> eslint.config.mjs; \
        echo 'const __filename = fileURLToPath(import.meta.url);' >> eslint.config.mjs; \
        echo 'const __dirname = dirname(__filename);' >> eslint.config.mjs; \
        echo '' >> eslint.config.mjs; \
        echo 'const compat = new FlatCompat({' >> eslint.config.mjs; \
        echo '  baseDirectory: __dirname,' >> eslint.config.mjs; \
        echo '});' >> eslint.config.mjs; \
        echo '' >> eslint.config.mjs; \
        echo 'const eslintConfig = [' >> eslint.config.mjs; \
        echo '  ...compat.extends("next/core-web-vitals", "next/typescript"),' >> eslint.config.mjs; \
        echo '];' >> eslint.config.mjs; \
        echo '' >> eslint.config.mjs; \
        echo 'export default eslintConfig;' >> eslint.config.mjs; \
    fi

.PHONY: install-jest
install-jest: package.json
	npm install --save-dev jest @types/jest jest-environment-jsdom @testing-library/react @testing-library/jest-dom
	@if ! grep -q '"test"' package.json; then \
        echo "Adding test script to package.json..."; \
        npm pkg set scripts.test="jest"; \
        npm pkg set scripts.test:watch="jest --watch"; \
    fi
	@if [ ! -f jest.config.js ]; then \
        echo "Creating jest.config.js..."; \
        echo 'const nextJest = require("next/jest");' > jest.config.js; \
        echo '' >> jest.config.js; \
        echo 'const createJestConfig = nextJest({' >> jest.config.js; \
        echo '  dir: "./",' >> jest.config.js; \
        echo '});' >> jest.config.js; \
        echo '' >> jest.config.js; \
        echo 'const config = {' >> jest.config.js; \
        echo '  coverageProvider: "v8",' >> jest.config.js; \
        echo '  testEnvironment: "jsdom",' >> jest.config.js; \
        echo '  setupFilesAfterEnv: ["<rootDir>/jest.setup.js"],' >> jest.config.js; \
        echo '};' >> jest.config.js; \
        echo '' >> jest.config.js; \
        echo 'module.exports = createJestConfig(config);' >> jest.config.js; \
    fi
	@if [ ! -f jest.setup.js ]; then \
		echo "Creating jest.setup.js..."; \
		echo 'import "@testing-library/jest-dom";' > jest.setup.js;
		echo '' >> jest.config.js; \
	fi

.PHONY: install-prettier
install-prettier:
	npm install --save-dev prettier
	@if [ ! -f .prettierrc ]; then \
        echo "Creating .prettierrc..."; \
        echo '{' > .prettierrc; \
        echo '  "semi": true,' >> .prettierrc; \
        echo '  "trailingComma": "es5",' >> .prettierrc; \
        echo '  "singleQuote": false,' >> .prettierrc; \
        echo '  "tabWidth": 2,' >> .prettierrc; \
        echo '  "useTabs": false' >> .prettierrc; \
        echo '}' >> .prettierrc; \
    fi

.PHONY: install-typescript
install-typescript:
	npm install --save-dev typescript @types/node @types/react @types/react-dom

CONVENTIONS.md:
	@echo "Download the CONVENTIONS.md file from the [[https://github.com/unravel-team/metats][metats]] project"

.aider.conf.yml:
	@echo "Download the .aider.conf.yml file from the [[https://github.com/unravel-team/metats][metats]] project"

.gitignore:
	@echo "Download the .gitignore file from the [[https://github.com/unravel-team/metats][metats]] project"

.PHONY: install-dev-tools
install-dev-tools: install-eslint install-jest install-prettier install-typescript CONVENTIONS.md .aider.conf.yml .gitignore    ## Install all development tools (ESLint, Jest, Prettier, Typescript)

.PHONY: upgrade-libs
upgrade-libs:    ## Upgrade all dependencies to their latest versions
	npm update
	npm audit fix

.PHONY: check-tagref
check-tagref:
	@if ! command -v tagref >/dev/null 2>&1; then \
		echo "tagref executable not found. Please install it from https://github.com/stepchowfun/tagref/releases/"; \
		exit 1; \
	fi
	tagref

.PHONY: check-eslint
check-eslint:
	npm run lint

.PHONY: check-typescript
check-typescript:
	npx tsc --noEmit

.PHONY: check
check: check-eslint check-typescript check-tagref    ## Check that the code is well linted, well typed, well documented
	@echo "All checks passed!"

.PHONY: format
format:    ## Format code with Prettier and fix ESLint issues
	npx prettier --write .
	npm run lint -- --fix

.PHONY: test
test:    ## Run all the tests for the code
	npm test

.PHONY: test-watch
test-watch:    ## Run tests in watch mode
	npm run test:watch

.PHONY: dev
dev:    ## Run the Next.js development server with Turbopack
	npm run dev

.PHONY: build
build: check    ## Build the Next.js application for production
	npm run build

.PHONY: start
start:    ## Start the production server
	npm run start

.PHONY: docker-compose-build
docker-compose-build:   ## Build all the local infra (docker-compose)
	docker compose build

.PHONY: up
up:     ## Bring up all the local infra (docker-compose)
	docker compose up

.PHONY: down
down:       ## Bring down all the local infra (docker-compose)
	docker compose down -v

.PHONY: logs
logs:      ## Show all the logs (docker-compose)
	docker compose logs

.PHONY: deploy
deploy: build    ## Deploy the current code to production
	@echo "Run deployment commands here (Vercel, Netlify, etc.)!"

.PHONY: clean-cache
clean-cache:    ## Clean npm cache and Next.js cache
	npm cache clean --force
	rm -rf .next

.PHONY: clean
clean:     ## Delete any existing artifacts
	rm -rf node_modules/
	rm -rf .next/
	rm -rf dist/
	rm -rf build/
	rm -rf coverage/
	rm -f *.tsbuildinfo

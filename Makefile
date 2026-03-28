SHELL := /bin/bash
.SILENT:
.ONESHELL:
.DEFAULT_GOAL := help

BATS         := bats
COPILOT_DIR  := copilot-cli
TEST_DIR     := test

.PHONY: help sync fmt lint typecheck check qa clean distclean
.PHONY: test test.unit

check: lint
qa: check test  ## Quality gate
test: test.unit  ## Run all tests

sync:  ## Install dependencies (bats)
	command -v bats >/dev/null || brew install bats-core

fmt:  ## Format (shellcheck --format gcc for CI)
	find $(COPILOT_DIR)/hooks/scripts -name '*.sh' -exec shellcheck -f gcc {} + 2>/dev/null || true

lint:  ## Lint shell scripts with shellcheck
	find $(COPILOT_DIR)/hooks/scripts -name '*.sh' -exec shellcheck {} +

typecheck:  ## No typecheck needed (bash only)
	true

test.unit:  ## Run bats unit tests
	$(BATS) $(TEST_DIR)/copilot-cli/hooks.bats

clean:  ## Remove log files
	rm -f $(COPILOT_DIR)/hooks/logs/*.log

distclean: clean  ## Deep clean

help:  ## Show available targets
	printf "\033[1;36magent-plugin-dev\033[0m — make targets\n\n"
	grep -E '^[a-zA-Z_.]+:.*##' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

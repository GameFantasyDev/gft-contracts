SHELL := /bin/bash
MAKEFLAGS += --no-print-directory

rwildcard=$(foreach d,$(wildcard $(1:=/*)), $(filter $(subst *,%,$2),$d))
SOL_PATH=contract
SOL_GEN_PATH=bin
SOL_FILES=$(call rwildcard,$(SOL_PATH),*.sol)
SOL_GEN_FILES_BASE:=$(patsubst $(SOL_PATH)%,$(SOL_GEN_PATH)%,$(SOL_FILES))
SOL_BUILD_FILES:=$(foreach s,$(filter %.sol,$(SOL_GEN_FILES_BASE)),$(s))
SOL_ABI_GEN_FILES:=$(foreach s,$(SOL_BUILD_FILES),$(basename $(s)).abi)
SOL_BIN_GEN_FILES:=$(foreach s,$(SOL_BUILD_FILES),$(basename $(s)).bin)
SOL_GAS_CHECK_GEN_FILES:=$(foreach s,$(SOL_BUILD_FILES),$(basename $(s)).gasCheck)

MAIN_NET_ADDR:=api.iotex.one:443

DEPLOY_GO:=tools/deploy/contract/main.go

SOLC_DIR_PATH:=tools/solc
SOLC_PATH:=$(SOLC_DIR_PATH)/solc

$(SOL_GEN_PATH)/%.abi: $(SOL_PATH)/%.sol
	@$(SOLC_PATH) @openzeppelin=./node_modules/@openzeppelin --allow-paths . -o $(SOL_GEN_PATH)/$(basename $(?)) --optimize --abi $?

$(SOL_GEN_PATH)/%.bin: $(SOL_PATH)/%.sol
	@$(SOLC_PATH) @openzeppelin=./node_modules/@openzeppelin --allow-paths . -o $(SOL_GEN_PATH)/$(basename $(?)) --optimize --bin $?

$(SOL_GEN_PATH)/%.gasCheck: $(SOL_PATH)/%.sol
	@echo gas check: $(?)
	@$(SOLC_PATH) @openzeppelin=./node_modules/@openzeppelin --allow-paths . -o $(SOL_GEN_PATH)/$(basename $(?)) --optimize --gas $?

.PHONY: all
all: build

.PHONY: build
build: build-sol ## build project

.PHONY: build-sol
build-sol: pre-build-sol ## build sol files
	@"$(MAKE)" -j4 build-sol-worker

.PHONY: build-sol-worker
build-sol-worker: build-sol-bin build-sol-abi ## build sol files

.PHONY: clean-build-sol
clean-build-sol: ## clean build sol files 
	@rm -rf $(SOL_GEN_PATH)

.PHONY: pre-build-sol
pre-build-sol: clean-build-sol ## pre build sol files 
	@mkdir -p $(SOL_GEN_PATH)

.PHONY: build-sol-bin
build-sol-bin: $(SOL_BIN_GEN_FILES) ## build sol files bin

.PHONY: gas-check-sol
gas-check-sol: $(SOL_GAS_CHECK_GEN_FILES) ## check sol files gas

.PHONY: build-sol-abi
build-sol-abi: $(SOL_ABI_GEN_FILES) ## build sol files abi

.PHONY: install-token-prod
install-token-prod: ## deploy token contract
	@ go run $(DEPLOY_GO) --addr $(MAIN_NET_ADDR) --key $(TOKEN_PROD_ACCOUNT_KEY) --addrOut "address/token-prod.address" --path $(SOL_GEN_PATH)/contract/token/GAE.bin

.PHONY: deploy-token-prod
deploy-token-prod: build-sol ## deploy token contract
	@"$(MAKE)" install-token-prod

.PHONY: clean
clean: clean-build-sol ## clean

.PHONY: help
help: ## help

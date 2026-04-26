TERRAFORM_DIR  := terraform
ANSIBLE_DIR    := ansible
TFLINT_CONFIG  := $(TERRAFORM_DIR)/.tflint.hcl
CHECKOV_CONFIG := .checkov.yaml

.DEFAULT_GOAL := check

.PHONY: check lint-terraform scan-terraform lint-ansible lint-all \
        install-tools help

check: lint-terraform scan-terraform lint-ansible
	@printf ">>> All checks passed.\n"

lint-terraform:
	@printf ">>> terraform fmt\n"
	terraform -chdir=$(TERRAFORM_DIR) fmt -check -recursive
	@printf ">>> terraform init (sin backend)\n"
	terraform -chdir=$(TERRAFORM_DIR) init -backend=false -input=false -reconfigure
	@printf ">>> terraform validate\n"
	terraform -chdir=$(TERRAFORM_DIR) validate -no-color
	@printf ">>> tflint init\n"
	tflint --config=.tflint.hcl --chdir=$(TERRAFORM_DIR) --init
	@printf ">>> tflint run\n"
	tflint --config=.tflint.hcl --chdir=$(TERRAFORM_DIR) -f compact

scan-terraform:
	@printf ">>> checkov\n"
	checkov --config-file $(CHECKOV_CONFIG)

lint-ansible:
	@printf ">>> ansible-lint\n"
	ansible-lint $(ANSIBLE_DIR)/playbook.yaml

lint-all: lint-terraform scan-terraform lint-ansible
	@printf ">>> All checks passed.\n"

install-tools:
	@command -v terraform    >/dev/null 2>&1 || { printf "MISSING: terraform  → mise use terraform@1.14.9\n";    exit 1; }
	@command -v tflint       >/dev/null 2>&1 || { printf "MISSING: tflint     → mise use tflint@0.61.0\n";       exit 1; }
	@command -v checkov      >/dev/null 2>&1 || { printf "MISSING: checkov    → brew install checkov\n";          exit 1; }
	@command -v ansible      >/dev/null 2>&1 || { printf "MISSING: ansible    → brew install ansible\n";          exit 1; }
	@command -v ansible-lint >/dev/null 2>&1 || { printf "MISSING: ansible-lint → brew install ansible-lint\n";  exit 1; }
	@printf "All tools present:\n"
	@terraform version | head -1
	@tflint --version | head -1
	@checkov --version
	@ansible --version | head -1
	@ansible-lint --version | head -1

help:
	@printf "\nTargets:\n"
	@printf "  lint-terraform   terraform fmt + validate + tflint\n"
	@printf "  scan-terraform   Checkov security scan\n"
	@printf "  lint-ansible     ansible-lint\n"
	@printf "  lint-all         All checks in sequence\n"
	@printf "  install-tools    Check required local tools\n"
	@printf "  check            Run all checks (default target)\n\n"

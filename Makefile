TERRAFORM_DIR  := terraform
ANSIBLE_DIR    := ansible
TFLINT_CONFIG  := $(TERRAFORM_DIR)/.tflint.hcl
CHECKOV_CONFIG := .checkov.yaml

# .DEFAULT_GOAL: define el target que se ejecuta cuando se corre 'make' sin argumentos.
# Sin esta línea, Make ejecutaría el primer target del archivo (check en este caso,
# pero si se reordena el archivo podría cambiar). Es buena práctica declararlo explícitamente.
# Con esta línea, 'make' a secas es equivalente a 'make check'.
.DEFAULT_GOAL := check

.PHONY: check lint-terraform scan-terraform lint-ansible lint-all \
        install-tools help

# check: punto de entrada principal. Corre los tres checks en secuencia.
# Si cualquiera falla, Make se detiene y no continúa con los siguientes.
# Ideal para correr antes de hacer 'git push' y verificar que el CI pasará.
check: lint-terraform scan-terraform lint-ansible
	@printf ">>> Todos los checks pasaron.\n"

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
	@printf ">>> Todos los checks pasaron.\n"

install-tools:
	@printf "\nHerramientas requeridas para este proyecto:\n"
	@printf "  terraform   : gestión de infraestructura como código (IaC)\n"
	@printf "  tflint      : linter estático para archivos .tf\n"
	@printf "  checkov     : escáner de seguridad para IaC\n"
	@printf "  ansible     : motor de configuración de servidores\n"
	@printf "  ansible-lint: linter para playbooks y roles de Ansible\n\n"
	@command -v terraform    >/dev/null 2>&1 || { printf "MISSING: terraform  → mise use terraform@1.14.9\n";    exit 1; }
	@command -v tflint       >/dev/null 2>&1 || { printf "MISSING: tflint     → mise use tflint@0.61.0\n";       exit 1; }
	@command -v checkov      >/dev/null 2>&1 || { printf "MISSING: checkov    → brew install checkov\n";          exit 1; }
	@command -v ansible      >/dev/null 2>&1 || { printf "MISSING: ansible    → brew install ansible\n";          exit 1; }
	@command -v ansible-lint >/dev/null 2>&1 || { printf "MISSING: ansible-lint → brew install ansible-lint\n";  exit 1; }
	@printf "Todas las herramientas están instaladas:\n"
	@terraform version | head -1
	@tflint --version | head -1
	@checkov --version
	@ansible --version | head -1
	@ansible-lint --version | head -1

help:
	@printf "\nTargets disponibles:\n"
	@printf "  check          Corre todos los checks (target por defecto)\n"
	@printf "  lint-terraform terraform fmt + validate + tflint\n"
	@printf "  scan-terraform Checkov security scan\n"
	@printf "  lint-ansible   ansible-lint\n"
	@printf "  lint-all       Alias de check\n"
	@printf "  install-tools  Verifica las herramientas requeridas\n\n"

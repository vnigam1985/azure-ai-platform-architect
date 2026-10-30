# Azure AI Platform Architect: 8-week build-along course. `make help` lists everything.
# Settings (override like: make week1 RG=rg-my-lab)

SHELL    := /bin/bash
RG       ?= rg-aiplat-lab
LOCATION ?= canadaeast
PREFIX   ?= aiplat
EMAIL    ?= $(shell az account show --query user.name -o tsv 2>/dev/null)
SSH_KEY  ?= $(HOME)/.ssh/id_ed25519.pub
VM       := vm-$(PREFIX)-jump
DEPLOY   := az deployment group create -g $(RG) -o none -p prefix=$(PREFIX)
FOUNDRY   = $(shell az cognitiveservices account list -g $(RG) --query "[0].name" -o tsv)
APIM      = $(shell az apim list -g $(RG) --query "[0].name" -o tsv)
SUB_ID    = $(shell az account show --query id -o tsv)

.DEFAULT_GOAL := help
help: ## Show all commands
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ----------------------------------------------------- week 0: local, $0 -----
local-up: ## Week 0: start app + LiteLLM gateway + Ollama locally (free)
	docker compose up -d --build
	docker compose exec ollama ollama pull qwen2.5:3b

local-keys: ## Week 0: create the bank app's team key on the local gateway
	./local/team-key.sh

local-test: ## Week 0: prove keys, model access and rate limits on the local gateway
	./local/smoke.sh

local-down: ## Week 0: stop the local lab
	docker compose down

# ------------------------------------------------- week 0: Azure basics ------
check: ## Week 0: show which subscription you're about to spend money in
	@az account show --query "{subscription:name, id:id, user:user.name}" -o table
	@echo "Resource group: $(RG)   Region: $(LOCATION)   Alerts to: $(EMAIL)"

rg: ## Week 0: create the lab resource group
	az group create -n $(RG) -l $(LOCATION) --tags workload=ai-platform-lab costCenter=learning -o none

week0: rg ## Week 0: budget alert on the lab resource group
	az deployment group create -g $(RG) -o none -f infra/week00-budget/main.bicep -p contactEmail=$(EMAIL)

# ---------------------------------------------------------- weeks 1 to 7 -----
week1: ## Week 1: hub/spoke VNets, NSGs, private DNS zones, Log Analytics
	$(DEPLOY) -f infra/week01-landing-zone/main.bicep

week2: ## Week 2: private Foundry + gpt-4.1-mini, test VM, Bastion Developer
	$(DEPLOY) -f infra/week02-private-model/main.bicep -p sshPublicKey="$$(cat $(SSH_KEY))"

week2-test: ## Week 2: prove the model is private (runs on the test VM)
	@az vm run-command invoke -g $(RG) -n $(VM) --command-id RunShellScript --query "value[0].message" -o tsv \
	  --scripts "export FOUNDRY_NAME=$(FOUNDRY) MODEL=gpt-4.1-mini CLIENT_ID=$$(az identity show -g $(RG) -n id-$(PREFIX)-jump --query clientId -o tsv); $$(cat infra/week02-private-model/prove-private.sh)"

week3-audit: ## Week 3: assign AI guardrail policies in Audit mode
	az deployment sub create -l $(LOCATION) -o none -f infra/week03-policy/main.bicep -p resourceGroupName=$(RG) effect=Audit

week3-deny: ## Week 3: switch the guardrails to Deny
	az deployment sub create -l $(LOCATION) -o none -f infra/week03-policy/main.bicep -p resourceGroupName=$(RG) effect=Deny

week3-test: ## Week 3: try to break the rules (validate only, creates nothing)
	RG=$(RG) FOUNDRY=$(FOUNDRY) ./infra/week03-policy/test-guardrails.sh

week3-compliance: ## Week 3: compliance summary for the lab resource group
	az policy state summarize -g $(RG) --query "policyAssignments[].{assignment:policyAssignmentId, nonCompliant:results.nonCompliantResources}" -o table

week4: ## Week 4: API Management AI gateway (takes 30 to 40 minutes)
	$(DEPLOY) -f infra/week04-ai-gateway/main.bicep -p publisherEmail=$(EMAIL)

week4-test: ## Week 4: test keys, token limits and direct-access blocking
	RG=$(RG) ./infra/week04-ai-gateway/test-gateway.sh

week5: ## Week 5: registry, private Container Apps, build and run the bank app
	$(DEPLOY) -f infra/week05-private-app/main.bicep -p deployApp=false
	az acr build -r $$(az acr list -g $(RG) --query "[0].name" -o tsv) -t maple-bank-assistant:v1 -f app/Dockerfile . --no-logs
	$(DEPLOY) -f infra/week05-private-app/main.bicep -p deployApp=true -p apimSubscriptionKey="$$(az rest --method post \
	  --url https://management.azure.com/subscriptions/$(SUB_ID)/resourceGroups/$(RG)/providers/Microsoft.ApiManagement/service/$(APIM)/subscriptions/retail-banking-app/listSecrets?api-version=2024-05-01 \
	  --query primaryKey -o tsv)"

week5-test: ## Week 5: call the private app from inside the VNet
	@az vm run-command invoke -g $(RG) -n $(VM) --command-id RunShellScript --query "value[0].message" -o tsv \
	  --scripts "export APP_FQDN=$$(az containerapp show -g $(RG) -n ca-bank-assistant --query properties.configuration.ingress.fqdn -o tsv); $$(cat infra/week05-private-app/test-app.sh)"

week6: ## Week 6: security alerts (gateway abuse, policy denies)
	$(DEPLOY) -f infra/week06-security/main.bicep -p alertEmail=$(EMAIL)

week6-defender: ## Week 6: turn ON Defender for AI Services (subscription-wide, 30-day trial)
	az deployment sub create -l $(LOCATION) -o none -f infra/week06-security/defender.bicep -p enabled=true

week6-defender-off: ## Week 6: turn Defender for AI Services back OFF
	az deployment sub create -l $(LOCATION) -o none -f infra/week06-security/defender.bicep -p enabled=false

week7: ## Week 7: token and cost workbook, FinOps and app alerts
	$(DEPLOY) -f infra/week07-observability/main.bicep

# --------------------------------------------------------------- week 8 ------
week8-inventory: ## Week 8: compare deployed models with the model inventory
	az cognitiveservices account deployment list -g $(RG) -n $(FOUNDRY) -o json > /tmp/deployments.json
	python3 scripts/check_model_inventory.py --deployed /tmp/deployments.json

week8-gate: ## Week 8: run the release gate against the live app
	RG=$(RG) VM=$(VM) APP_FQDN=$$(az containerapp show -g $(RG) -n ca-bank-assistant --query properties.configuration.ingress.fqdn -o tsv) ./scripts/remote-eval.sh

# ------------------------------------------------------------ cost control ---
validate: ## Build and lint every Bicep file (no Azure needed)
	@for f in $$(find infra iac gateway -name '*.bicep'); do bicep build $$f --stdout > /dev/null && bicep lint $$f || exit 1; done; echo "All Bicep files build."

stop: ## Stop paying for the VM now (deallocate)
	az vm deallocate -g $(RG) -n $(VM) --no-wait

destroy: ## DELETE the whole lab (resource group and the custom policy definition)
	@read -p "Delete resource group $(RG) and everything in it? Type the name to confirm: " c && [ "$$c" = "$(RG)" ]
	az group delete -n $(RG) --yes --no-wait
	-az policy definition delete -n deny-ai-global-deployment-types || echo "Policy definition still in use. Run this again after the resource group is gone."
	@echo "Deleting in the background (10 to 30 minutes)."
	@echo "Then: make purge-apim (APIM is soft-deleted), and make week6-defender-off if YOU turned Defender for AI on."

purge-apim: ## After destroy: purge the soft-deleted APIM so the name can be reused
	-az apim deletedservice list --query "[?contains(name,'$(PREFIX)')].{name:name, location:location}" -o table
	-for n in $$(az apim deletedservice list --query "[?contains(name,'$(PREFIX)')].name" -o tsv); do az apim deletedservice purge --service-name $$n --location $(LOCATION); done

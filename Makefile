# Makefile pour Deneige-auto
# Facilite l'utilisation de Docker pour le CI local

.PHONY: help ci analyze format format-fix test test-cov build shell clean setup

# Couleurs
YELLOW := \033[1;33m
GREEN := \033[0;32m
NC := \033[0m

help: ## Afficher cette aide
	@echo "Deneige-auto - Commandes disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Construire l'image Docker
	@echo "$(YELLOW)Building Docker image...$(NC)"
	docker-compose build
	@echo "$(GREEN)Setup complete!$(NC)"

ci: ## Executer le pipeline CI complet (analyze + format + test)
	@echo "$(YELLOW)Running CI pipeline...$(NC)"
	docker-compose run --rm ci

analyze: ## Analyser le code
	docker-compose run --rm analyze

format: ## Verifier le formatage du code
	docker-compose run --rm format

format-fix: ## Corriger le formatage du code
	docker-compose run --rm format-fix

test: ## Executer les tests
	docker-compose run --rm test

test-cov: ## Executer les tests avec couverture
	docker-compose run --rm test-coverage

build: ## Construire l'APK Android (debug)
	docker-compose run --rm build-android

shell: ## Ouvrir un shell interactif dans le conteneur
	docker-compose run --rm shell

clean: ## Nettoyer les ressources Docker
	docker-compose down -v --remove-orphans
	docker system prune -f

# Alias pratiques
a: analyze
f: format
t: test

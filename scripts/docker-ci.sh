#!/bin/bash
# Script pour executer le pipeline CI localement avec Docker
# Usage: ./scripts/docker-ci.sh [command]
#
# Commands:
#   ci          - Run full CI pipeline (analyze + format + test)
#   analyze     - Run code analysis only
#   format      - Check formatting only
#   format-fix  - Fix formatting issues
#   test        - Run tests only
#   test-cov    - Run tests with coverage
#   build       - Build Android APK (debug)
#   shell       - Open interactive shell
#   clean       - Remove Docker containers and volumes

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
    echo "Usage: ./scripts/docker-ci.sh [command]"
    echo ""
    echo "Commands:"
    echo "  ci          - Run full CI pipeline"
    echo "  analyze     - Run code analysis"
    echo "  format      - Check formatting"
    echo "  format-fix  - Fix formatting"
    echo "  test        - Run tests"
    echo "  test-cov    - Run tests with coverage"
    echo "  build       - Build Android APK"
    echo "  shell       - Interactive shell"
    echo "  clean       - Cleanup Docker"
}

case "$1" in
    ci)
        echo -e "${YELLOW}Running full CI pipeline...${NC}"
        docker-compose run --rm ci
        echo -e "${GREEN}CI pipeline completed!${NC}"
        ;;
    analyze)
        echo -e "${YELLOW}Running code analysis...${NC}"
        docker-compose run --rm analyze
        ;;
    format)
        echo -e "${YELLOW}Checking code formatting...${NC}"
        docker-compose run --rm format
        ;;
    format-fix)
        echo -e "${YELLOW}Fixing code formatting...${NC}"
        docker-compose run --rm format-fix
        ;;
    test)
        echo -e "${YELLOW}Running tests...${NC}"
        docker-compose run --rm test
        ;;
    test-cov)
        echo -e "${YELLOW}Running tests with coverage...${NC}"
        docker-compose run --rm test-coverage
        ;;
    build)
        echo -e "${YELLOW}Building Android APK...${NC}"
        docker-compose run --rm build-android
        ;;
    shell)
        echo -e "${YELLOW}Opening interactive shell...${NC}"
        docker-compose run --rm shell
        ;;
    clean)
        echo -e "${YELLOW}Cleaning up Docker resources...${NC}"
        docker-compose down -v --remove-orphans
        docker system prune -f
        echo -e "${GREEN}Cleanup complete!${NC}"
        ;;
    *)
        show_help
        exit 1
        ;;
esac

#!/bin/bash

# Clone all Rootly repositories from GitHub if they don't exist
# Usage: ./clone-repos.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub organization
GITHUB_ORG="swarch-2f-rootly"
GITHUB_BASE_URL="https://github.com/${GITHUB_ORG}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Cloning Rootly Repositories${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get parent directory (where all repos should be)
PARENT_DIR=$(dirname "$(pwd)")
echo -e "${BLUE}Target directory: ${PARENT_DIR}${NC}"
echo ""

# List of repositories to clone
REPOS=(
    "rootly-analytics-backend"
    "rootly-apigateway"
    "rootly-authentication-and-roles-backend"
    "rootly-data-management-backend"
    "rootly-frontend"
    "rootly-user-plant-management-backend"
    "rootly-deploy"
)

# Function to clone a repository if it doesn't exist
clone_repo() {
    local repo_name=$1
    local repo_url="${GITHUB_BASE_URL}/${repo_name}.git"
    local repo_path="${PARENT_DIR}/${repo_name}"
    
    if [ -d "$repo_path" ]; then
        if [ -d "$repo_path/.git" ]; then
            echo -e "${GREEN}✓ ${repo_name} already exists${NC}"
        else
            echo -e "${YELLOW}⚠ ${repo_name} directory exists but is not a git repository${NC}"
        fi
    else
        echo -e "${YELLOW}→ Cloning ${repo_name}...${NC}"
        if git clone "$repo_url" "$repo_path"; then
            echo -e "${GREEN}✓ Successfully cloned ${repo_name}${NC}"
        else
            echo -e "${RED}✗ Failed to clone ${repo_name}${NC}"
            echo -e "${RED}  URL: ${repo_url}${NC}"
        fi
    fi
    echo ""
}

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed${NC}"
    exit 1
fi

# Clone all repositories
for repo in "${REPOS[@]}"; do
    clone_repo "$repo"
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Repository cloning process completed!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Navigate to rootly-deploy: cd ${PARENT_DIR}/rootly-deploy"
echo "2. Copy .env.example to .env and configure as needed"
echo "3. Run the start script: ./start.sh"
echo ""

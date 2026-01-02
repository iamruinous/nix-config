#!/usr/bin/env bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Checking Context Integrity...${NC}"

# 1. Critical Files Check
FILES=(
    ".context/index.md"
    ".context/global/protocols.md"
    ".context/global/upgrades.md"
    ".context/migrations.md"
    ".context/project/architecture.md"
    ".context/project/roster.md"
)

MISSING=0
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Missing: $file${NC}"
        MISSING=1
    else
        echo -e "${GREEN}✓ Found: $file${NC}"
    fi
done

if [ $MISSING -eq 1 ]; then
    echo -e "${RED}⚠️  Critical context files are missing! Agents may hallucinate.${NC}"
    exit 1
fi

# 2. Context Summary (Force-feed to LLM)
echo -e "\n${BLUE}📜 Context Summary (Read Carefully):${NC}"
echo "---------------------------------------------------"
# Extract the first section of index.md (usually the beacon/summary)
head -n 20 .context/index.md
echo "---------------------------------------------------"
echo -e "${GREEN}✅ Context verified. You are ready to proceed.${NC}"

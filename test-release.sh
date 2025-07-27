#!/bin/sh

# Smart shell detection: try zsh first, then bash
if [ -z "${BASH_VERSION}" -a -z "${ZSH_VERSION}" ]; then
    # We're in a basic shell, try to find zsh or bash
    if command -v zsh >/dev/null 2>&1; then
        exec zsh "$0" "$@"
    elif command -v bash >/dev/null 2>&1; then
        exec bash "$0" "$@"
    else
        echo "Error: Neither zsh nor bash found. Please install one of them."
        exit 1
    fi
fi

# Now we're guaranteed to be in either bash or zsh
set -euo pipefail

# Global test status variables
VERIFY_NODE_STATUS="unknown"
VERIFY_GO_STATUS="unknown"
BUILD_STATUS="unknown"
FINAL_JOB_STATUS="unknown"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[0;36m'
PURPLE='\033[0;35m'
GREY='\033[0;90m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m' # No Color

# Detect the correct Go executable from the launching shell
GO_EXECUTABLE=""
if [ -n "${ZSH_VERSION:-}" ]; then
    # We're in zsh, use zsh to find go
    GO_EXECUTABLE=$(zsh -c 'command -v go')
elif [ -n "${BASH_VERSION:-}" ]; then
    # We're in bash, use bash to find go
    GO_EXECUTABLE=$(bash -c 'command -v go')
fi

if [ -z "$GO_EXECUTABLE" ]; then
    echo -e "${RED}Error: Go executable not found in current shell environment${NC}"
    exit 1
fi

echo "${BLUE}==> 1. Environment Snapshot${NC}"
echo "[${GREEN}✓${NC}] Operating System: $(uname -s) ($(uname -m))"
echo "[${GREEN}✓${NC}] Go Version: $($GO_EXECUTABLE version)"
echo "[${GREEN}✓${NC}] Node.js Version: $(node --version)"
echo "[${GREEN}✓${NC}] Project Version: $(grep '"version"' package.json | cut -d'"' -f4)"

echo "${BLUE}==> 2. Environment Checks${NC}"

# Check prerequisites
check_prerequisites() {
    local issues=()
    
    if ! command -v node >/dev/null 2>&1; then
        issues+=("Node.js not found")
    fi
    
    if ! command -v npm >/dev/null 2>&1; then
        issues+=("npm not found")
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        issues+=("git not found")
    fi
    
    if [ ${#issues[@]} -eq 0 ]; then
        echo "[${GREEN}✓${NC}] Prerequisites: All required tools available"
        VERIFY_NODE_STATUS="success"
        return 0
    else
        echo "[${RED}✗${NC}] Prerequisites: ${issues[*]}"
        VERIFY_NODE_STATUS="failed"
        return 1
    fi
}

# Check Node.js dependencies (read-only)
check_node_dependencies() {
    local output
    local has_warnings=false
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        echo -e "${RED}[✗] Node.js: package.json not found${NC}"
        VERIFY_NODE_STATUS="failed"
        return 1
    fi
    
    # Check if version exists in package.json
    local version
    if ! version=$(node -p "require('./package.json').version" 2>/dev/null); then
        echo -e "${RED}[✗] Node.js: Invalid package.json or version not found${NC}"
        VERIFY_NODE_STATUS="failed"
        return 1
    fi
    
    # Check lock file strategy
    if [ -f "yarn.lock" ] && [ ! -f "package-lock.json" ]; then
        if command -v yarn >/dev/null 2>&1; then
            echo "[${GREEN}✓${NC}] Node.js: Using ${BOLD}yarn${NC} (yarn.lock detected, version: ${BOLD}$version${NC})"
        else
            echo "${YELLOW}[!] Node.js: yarn.lock detected but yarn not found, will use"
            echo "${YELLOW}    will use ${BOLD}npm install${NC} (version: ${BOLD}$version${NC})${NC}"
            has_warnings=true
        fi
    elif [ -f "package-lock.json" ]; then
        echo "[${GREEN}✓${NC}] Node.js: Using ${BOLD}npm ci${NC} (package-lock.json detected, version: ${BOLD}$version${NC})"
    else
        echo "${YELLOW}[!] Node.js: No lock file found, will use"
        echo "${YELLOW}    will use ${BOLD}npm install${NC} (version: ${BOLD}$version${NC})${NC}"
        has_warnings=true
    fi
    
    # Test dependency installation (dry run)
    if [ -f "yarn.lock" ] && command -v yarn >/dev/null 2>&1; then
        if ! output=$(yarn install --dry-run 2>&1); then
            echo "${RED}[✗] Node.js: Dependency check failed (yarn dry-run)${NC}"
            echo "Details: $output"
            VERIFY_NODE_STATUS="failed"
            return 1
        fi
    else
        if ! output=$(npm install --dry-run 2>&1); then
            echo "${RED}[✗] Node.js: Dependency check failed (npm dry-run)${NC}"
            echo "Details: $output"
            VERIFY_NODE_STATUS="failed"
            return 1
        fi
    fi
    
    echo "[${GREEN}✓${NC}] Node.js: Dependencies consistent"
    if [ "$has_warnings" = "true" ]; then
        VERIFY_NODE_STATUS="warning"
    else
        VERIFY_NODE_STATUS="success"
    fi
    return 0
}

# Check Go modules consistency (read-only)
check_go_modules_consistency() {
    local output
    output=$($GO_EXECUTABLE mod tidy -diff 2>&1)
    if [ -n "$output" ]; then

        echo "${RED}[✗] Go Modules: Inconsistent (diff check failed)${NC}"
        echo "Details: $output"
        VERIFY_GO_STATUS="failed"
        return 1
    else
        echo "[${GREEN}✓${NC}] Go Modules: Consistent"
        VERIFY_GO_STATUS="success"
        return 0
    fi

}

# Interactive fixes
run_interactive_fixes() {
    local has_issues=false
    
    if ! check_prerequisites; then
        has_issues=true
        echo "${YELLOW}==> Would you like to install missing tools? (y/n)${NC}"
        if prompt_user; then
            echo "Please install the missing tools manually and run this script again."
            exit 1
        fi
    fi
    
    if ! check_node_dependencies; then
        has_issues=true
        echo "${YELLOW}==> Would you like to fix Node.js dependency issues? (y/n)${NC}"
        if prompt_user; then
            if [ -f "yarn.lock" ] && command -v yarn >/dev/null 2>&1; then
                echo "Running: yarn install"
                yarn install
            else
                echo "Running: npm install"
                npm install
            fi
            echo "${GREEN}Node.js dependencies updated.${NC}"
        fi
    else
        # Don't override the status if it's already set
        if [ -z "$VERIFY_NODE_STATUS" ]; then
            VERIFY_NODE_STATUS="success"
        fi
    fi
    
    if ! check_go_modules_consistency; then
        has_issues=true
        echo "${YELLOW}==> Would you like to fix Go module inconsistencies? (y/n)${NC}"
        if prompt_user; then
            echo "Running: $GO_EXECUTABLE mod tidy"
            $GO_EXECUTABLE mod tidy
            echo "${GREEN}Go modules updated. Please commit the changes:${NC}"
            echo "git add go.mod go.sum"
            echo "git commit -m 'chore: update go modules'"
        fi
    else
        # Ensure status is set even when check passes
        if [ -z "$VERIFY_GO_STATUS" ]; then
            VERIFY_GO_STATUS="success"
        fi
    fi
    
    if [ "$has_issues" = false ]; then
        echo "[${GREEN}✓${NC}] All checks passed, no fixes needed"
    fi
}

# Build phase
run_build_phase() {
    echo "${BLUE}==> 3. Build Phase${NC}"
    echo "${YELLOW}==> Would you like to proceed with the build test? (y/n)${NC}"
    if ! prompt_user; then
        echo "Build phase skipped"
        return 0
    fi
    
    # Clean previous builds
    rm -rf test-build
    mkdir -p test-build
    
    # Build native binary first
    echo "${LIGHT_BLUE}Building native binary...${NC}"
    if $GO_EXECUTABLE build -ldflags="-s -w" -o "test-build/git-status-dash-go-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)" .; then
        echo "[${GREEN}✓${NC}] Native binary built successfully"
        
        # Create symlink for consistent testing
        ln -sf "git-status-dash-go-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)" "test-build/git-status-dash"
        echo "[${GREEN}✓${NC}] Created symlink: test-build/git-status-dash"
        
        # Test the binary
        # echo "${LIGHT_BLUE}Testing binary functionality...${NC}"
        # if ./test-build/git-status-dash --version >/dev/null 2>&1; then
        #     echo "[${GREEN}✓${NC}] Version command works"
        # else
        #     echo "[${RED}✗${NC}] Version command failed"
        # fi
        
        if ./test-build/git-status-dash config init >/dev/null 2>&1; then
            echo "[${GREEN}✓${NC}] Config init command works"
        else
            echo "[${RED}✗${NC}] Config init command failed"
        fi
    else
        echo "[${RED}✗${NC}] Native binary build failed"
        return 1
    fi
    
    # Cross-compilation test (matching release.yml)
    echo "${LIGHT_BLUE}Testing cross-compilation...${NC}"
    local platforms=(
        "linux/amd64"
        "linux/arm64"
        "darwin/amd64"
        "darwin/arm64"
        "windows/amd64"
    )
    local success_count=0
    
    for platform in "${platforms[@]}"; do
        IFS='/' read -r os arch <<< "$platform"
        local output_name="test-build/git-status-dash-go-${os}-${arch}"
        if [ "$os" = "windows" ]; then
            output_name="${output_name}.exe"
        fi
        
        if GOOS="$os" GOARCH="$arch" $GO_EXECUTABLE build -ldflags="-s -w" -o "$output_name" .; then
            echo "[${GREEN}✓${NC}] $platform: $(stat -c%s "$output_name" 2>/dev/null || stat -f%z "$output_name") bytes"
            ((success_count++))
        else
            echo "[${RED}✗${NC}] $platform: Build failed"
        fi
    done
    
    echo "[${GREEN}✓${NC}] Cross-compilation: $success_count/${#platforms[@]} platforms successful"
    if [ "$success_count" -eq "${#platforms[@]}" ]; then
        BUILD_STATUS="success"
    elif [ "$success_count" -gt 0 ]; then
        BUILD_STATUS="warning"
    else
        BUILD_STATUS="failed"
    fi
    return 0
}

# Calculate the final job status based on all stages
calculate_final_status() {
    if [ "$VERIFY_NODE_STATUS" = "failed" ] || \
       [ "$VERIFY_GO_STATUS" = "failed" ] || \
       [ "$BUILD_STATUS" = "failed" ]; then
        FINAL_JOB_STATUS="failed"
    elif [ "$VERIFY_NODE_STATUS" = "warning" ] || \
         [ "$VERIFY_GO_STATUS" = "warning" ] || \
         [ "$BUILD_STATUS" = "warning" ]; then
        FINAL_JOB_STATUS="warning"
    elif [ "$VERIFY_NODE_STATUS" = "success" ] && \
         [ "$VERIFY_GO_STATUS" = "success" ] && \
         [ "$BUILD_STATUS" = "success" ]; then
        FINAL_JOB_STATUS="success"
    else
        # Default to unknown if states are mixed or not set
        FINAL_JOB_STATUS="unknown"
    fi
}


# Generate final report
generate_final_report() {
    # First, calculate the final aggregated status
    calculate_final_status

    echo "${BLUE}==> 4. Final Report${NC}"
    echo
    
    # Node.js verification status
    case "$VERIFY_NODE_STATUS" in
        "success")
            echo "${GREEN}verify-node${NC}"
            ;;
        "warning")
            echo "${YELLOW}verify-node${NC}"
            ;;
        "failed")
            echo "${RED}verify-node${NC}"
            ;;
        *)
            echo "${GREY}verify-node${NC}"
            ;;
    esac
    echo "    ${BOLD}↓${NC}"
    case "$VERIFY_NODE_STATUS" in
        "success")
            echo "${GREEN}release-nodejs${NC}"
            ;;
        "warning")
            echo "${YELLOW}release-nodejs${NC}"
            ;;
        "failed")
            echo "${RED}release-nodejs${NC}"
            ;;
        *)
            echo "${GREY}release-nodejs${NC}"
            ;;
    esac
    echo "    ${BOLD}↓${NC}"
    
    # Go verification status
    case "$VERIFY_GO_STATUS" in
        "success")
            echo "${GREEN}verify-go${NC}"
            ;;
        "warning")
            echo "${YELLOW}verify-go${NC}"
            ;;
        "failed")
            echo "${RED}verify-go${NC}"
            ;;
        *)
            echo "${GREY}verify-go${NC}"
            ;;
    esac
    echo "    ${BOLD}↓${NC}"
    case "$VERIFY_GO_STATUS" in
        "success")
            echo "${GREEN}release-go${NC}"
            ;;
        "warning")
            echo "${YELLOW}release-go${NC}"
            ;;
        "failed")
            echo "${RED}release-go${NC}"
            ;;
        *)
            echo "${GREY}release-go${NC}"
            ;;
    esac
    echo "    ${BOLD}↓${NC}"
    
    # Final release status
    case "$BUILD_STATUS" in
        "success")
            echo "${GREEN}create-release${NC}"
            ;;
        "warning")
            echo "${YELLOW}create-release${NC}"
            ;;
        "failed")
            echo "${RED}create-release${NC}"
            ;;
        *)
            echo "${GREY}create-release${NC}"
            ;;
    esac
    echo "    ${BOLD}↓${NC}"
    case "$FINAL_JOB_STATUS" in
        "success")
            echo "${BOLD}${GREEN}Success${NC}${NC}"
            ;;
        "warning")
            echo "${BOLD}${YELLOW}Warning${NC}${NC}"
            ;;
        "failed")
            echo "${BOLD}${RED}Failed${NC}${NC}"
            ;;
        *)
            echo "${BOLD} ${PURPLE}Unknown${NC}${NC}"
            ;;
    esac
    echo
    # Environment summary
    echo "[${BOLD}OS${NC}]:      $(uname -s) ($(uname -m))"
    echo "[${BOLD}Go${NC}]:      $($GO_EXECUTABLE version) at $GO_EXECUTABLE"
    echo "[${BOLD}Node.js${NC}]: $(node --version)"
    echo "[${BOLD}Project${NC}]: $(grep '"version"' package.json | cut -d'"' -f4)"
    # Build details
    if [ -d "test-build" ]; then
        local file_count=$(find test-build -type f | wc -l | tr -d ' ')
        case "$FINAL_JOB_STATUS" in
            "success")
                echo "[${BOLD}Status${NC}]:  ${GREEN}Success${NC}"
                ;;
            "warning")
                echo "[${BOLD}Status${NC}]:  ${YELLOW}Warning${NC}"
                ;;
            "failed")
                echo "[${BOLD}Status${NC}]:  ${RED}Failed${NC}"
                ;;
            *)
                echo "[${BOLD}Status${NC}]:  ${PURPLE}Unknown${NC}"
                ;;
        esac
        echo "[${BOLD}Files${NC}]:   $file_count"
        echo "[${BOLD}Path${NC}]:   $(pwd)/test-build/"
        echo "${PURPLE}Try with:${NC}${UNDERLINE}./test-build/git-status-dash .${NC}"
        echo
    else
        echo "[${BOLD}Status${NC}]: ${RED}Not performed${NC}"
        echo
    fi
}

# User prompt function
prompt_user() {
    while true; do
        read -p " " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        elif [[ $REPLY =~ ^[Nn]$ ]]; then
            return 1
        else
            echo "${YELLOW}Please answer y or n${NC}"
        fi
    done
    echo
}

# Main execution
main() {
    # Run interactive fixes if needed
    run_interactive_fixes
    
    # Run build phase
    run_build_phase
    
    # Generate final report
    generate_final_report
}

main "$@"
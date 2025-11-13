#!/bin/bash
# Simple Package Validation - Stays in Terminal

echo ""
echo "=================================================="
echo "  Package Validation Check"
echo "=================================================="
echo ""

TOTAL=0
INSTALLED=0
MISSING=0

# Function to check command
check_package() {
    local name="$1"
    local cmd="$2"
    local emoji="$3"
    
    ((TOTAL++))
    echo -n "$emoji Checking $name... "
    
    if command -v "$cmd" >/dev/null 2>&1; then
        version=$($cmd --version 2>&1 | head -n1)
        echo "✅ INSTALLED - $version"
        ((INSTALLED++))
        return 0
    else
        echo "❌ NOT INSTALLED"
        ((MISSING++))
        return 1
    fi
}

# Check all packages
echo "Checking installed packages:"
echo ""

check_package "Python 3" "python3" "🐍"
check_package "pip3" "pip3" "📦"
check_package "Java Runtime" "java" "☕"
check_package "Java Compiler" "javac" "🔧"
check_package "Node.js" "node" "🟢"
check_package "npm" "npm" "📦"
check_package "PostgreSQL Client" "psql" "🐘"

# Summary
echo ""
echo "=================================================="
echo "  Summary"
echo "=================================================="
echo "Total packages checked: $TOTAL"
echo "✅ Installed: $INSTALLED"
echo "❌ Missing: $MISSING"
echo ""

if [ $MISSING -eq 0 ]; then
    echo "🎉 All packages are installed!"
    echo ""
    echo "✓ Validation completed successfully"
else
    echo "⚠️  $MISSING package(s) need to be installed"
    echo ""
    echo "Note: Run Ansible playbook to install missing packages"
    echo "(Installation requires internet connectivity via Cloud NAT)"
fi

echo ""
echo "=================================================="
echo "  Validation Complete - You're still in the VM!"
echo "=================================================="
echo ""
EOF
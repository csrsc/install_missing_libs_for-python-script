#!/bin/bash

# Usage check
if [ $# -eq 0 ]; then
    echo "Usage: $0 /path/to/python_script.py"
    exit 1
fi

# python3 check
if ! command -v python3 &> /dev/null; then
    echo "python3 is not installed. Please install python3."
    exit 1
fi

# pip3 check
if ! command -v pip3 &> /dev/null; then
    echo "pip3 is not installed. Installing pip3..."
    sudo apt-get update && sudo apt-get install -y python3-pip
fi

script="$1"

if [ ! -f "$script" ]; then
    echo "File not found: $script"
    exit 1
fi

echo "Checking python dependencies in $script..."

# python check modules
modules=$(python3 - <<EOF
import ast
with open("$script", "r") as f:
    tree = ast.parse(f.read(), filename="$script")
mods = set()
for node in ast.walk(tree):
    if isinstance(node, ast.Import):
        for alias in node.names:
            mods.add(alias.name.split('.')[0])
    elif isinstance(node, ast.ImportFrom):
        if node.module:
            mods.add(node.module.split('.')[0])
print(" ".join(sorted(mods)))
EOF
)

if [ -z "$modules" ]; then
    echo "No import statements found."
    exit 0
fi

echo "Found modules: $modules"

for mod in $modules; do
    echo "Checking module: $mod"
    if python3 -c "import $mod" &> /dev/null; then
        echo "Module $mod is already installed."
    else
        echo "Module $mod is not installed."
        read -p "Install module $mod? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pkg="$mod"
            if [ "$mod" = "daemon" ]; then
                pkg="python-daemon"
            fi
            pip3 install "$pkg"
        fi
    fi
done

echo "Pip (python) dependencies checked."

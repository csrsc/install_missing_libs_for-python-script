#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 /path/to/executable"
    exit 1
fi

executable=$1

# Ensure apt-file is installed
if ! command -v apt-file &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y apt-file
    sudo apt-file update
fi

# Find missing libraries
missing_libs=$(ldd "$executable" 2>/dev/null | grep "not found" | awk '{print $1}')

if [ -z "$missing_libs" ]; then
    echo "No missing libraries found."
    exit 0
fi

echo "Missing libraries:"
echo "$missing_libs"

# Search for packages containing the libraries
for lib in $missing_libs; do
    packages=$(apt-file search -l "$lib" | sort -u)
    if [ -n "$packages" ]; then
        echo "Packages containing $lib:"
        echo "$packages"
        read -p "Install these packages? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo apt-get install -y $packages
        fi
    else
        echo "No package found containing $lib"
    fi
done

echo "Re-checking libraries..."
ldd "$executable"

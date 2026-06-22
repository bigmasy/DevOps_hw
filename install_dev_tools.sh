#!/bin/bash

echo "Updating apt package index..."
sudo apt-get update -y
echo "----------------------------------------"

# 1. Simple loop for core system utilities
for tool in docker docker-compose python3; do
    echo "Checking tool: $tool"
    
    if command -v $tool &> /dev/null; then
        echo "$tool is already installed."
    else
        echo "$tool not found. Installing..."
        if [ "$tool" = "docker" ]; then
            sudo apt-get install -y docker.io
        elif [ "$tool" = "docker-compose" ]; then
            sudo apt-get install -y docker-compose
        elif [ "$tool" = "python3" ]; then
            sudo apt-get install -y python3 python3-pip
        fi
        echo "$tool installed successfully!"
    fi
    echo "----------------------------------------"
done

# 2. Separate check for Python version (>= 3.9)
echo "Checking Python3 version..."
python_version=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')

if [ "$(printf '%s\n' "3.9" "$python_version" | sort -V | head -n1)" != "3.9" ]; then
    echo "Current Python version ($python_version) is outdated. Upgrading..."
    sudo apt-get install -y python3.10 python3.10-venv python3-pip
else
    echo "Python version meets requirements: $python_version"
fi
echo "----------------------------------------"

# 3. Check and install Django via pip
echo "Checking Django..."
if python3 -m django --version &> /dev/null; then
    echo "Django is already installed: $(python3 -m django --version)"
else
    echo "Django not found. Installing via pip..."
    python3 -m pip install django --break-system-packages 2>/dev/null || python3 -m pip install django
    echo "Django installed successfully!"
fi

echo "----------------------------------------"
echo "All checks and installations completed!"
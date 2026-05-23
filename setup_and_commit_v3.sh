#!/bin/bash
set -e

echo "Running python generator v3..."
python3 /home/zeazdev/zeye/generate_zeye_v3.py

echo "Making scripts executable..."
find /home/zeazdev/zeye -name "*.sh" -exec chmod +x {} +

cd /home/zeazdev/zeye

echo "Validating syntax..."
bash -n zeye-v5-pro-upgrade.sh
find scripts -name "*.sh" -print0 | xargs -0 -n1 bash -n

echo "Validating secrets..."
# Allow grep to exit 0 or 1 without failing script, but fail if actual secrets are found
set +e
GREP_OUT=$(grep -RInE "(password|secret|token|key)=" . | grep -v ".git" | grep -v "generate_zeye" | grep -v "setup_and_commit")
set -e

if [ ! -z "$GREP_OUT" ]; then
    echo "Potential secrets found:"
    echo "$GREP_OUT"
    if echo "$GREP_OUT" | grep -qv "placeholder"; then
        echo "ERROR: Real secrets detected in codebase! Only placeholders are allowed."
        exit 1
    else
        echo "Only placeholders found, validation passed."
    fi
else
    echo "No secrets found."
fi

echo "Git status..."
git diff --check || true
git status --short

echo "Committing..."
git config user.email "antigravity@gemini.com" || true
git config user.name "Antigravity" || true
git add .
git commit -m "feat: add licensed pro feature readiness"
git push origin main || echo "Git push failed, check remote configuration."

#!/bin/bash
set -e
echo "Starting v5 Pro feature readiness setup..."

echo "Checking for .env.pro..."
if [ ! -f .env.pro ]; then
    echo "Copying .env.pro.example to .env.pro..."
    cp .env.pro.example .env.pro
fi

echo "Reminder: Pro features require a valid iSpyConnect subscription."
echo "Please edit .env.pro with your valid license details if applicable."
echo "Review docs/PRO_FEATURES_SETUP.md for full instructions."
echo "Done."

#!/bin/bash

# clean_ds_store.sh - Remove all .DS_Store files from the project
# Run this script periodically or before commits to clean up macOS metadata files

echo "🧹 Cleaning .DS_Store files from the project..."

# Find and remove all .DS_Store files
find . -name ".DS_Store" -type f -delete 2>/dev/null

# Count how many were removed (do a find first to count)
count=$(find . -name ".DS_Store" -type f 2>/dev/null | wc -l)

if [ "$count" -eq 0 ]; then
    echo "✅ No .DS_Store files found. Project is clean!"
else
    echo "✅ Removed $count .DS_Store file(s)"
fi

# Optional: Also clean other macOS metadata files
echo "🧹 Cleaning other macOS metadata files..."
find . -name "._*" -type f -delete 2>/dev/null
find . -name ".Spotlight-V100" -type d -exec rm -rf {} + 2>/dev/null
find . -name ".Trashes" -type d -exec rm -rf {} + 2>/dev/null

echo "✨ Cleanup complete!"

# Reminder about .gitignore
echo ""
echo "📝 Reminder: These files are already in .gitignore and won't be tracked:"
echo "   - .DS_Store"
echo "   - ._*"
echo "   - .Spotlight-V100"
echo "   - .Trashes"
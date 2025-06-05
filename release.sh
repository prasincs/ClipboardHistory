#!/bin/bash
set -e

# Distance-based release script
# Format: MAJOR.MINOR.PATCH where PATCH = last_patch + commits_since_last_tag
# Example: v1.0.4 + 2 commits = v1.0.6
# This script only creates the tag - CI will handle the actual release

# Get the last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo "Last tag: $LAST_TAG"

# Extract major, minor, and patch version
MAJOR=$(echo $LAST_TAG | cut -d. -f1 | sed 's/v//')
MINOR=$(echo $LAST_TAG | cut -d. -f2)
PATCH=$(echo $LAST_TAG | cut -d. -f3)

# Get distance (number of commits since last tag)
DISTANCE=$(git rev-list ${LAST_TAG}..HEAD --count)
echo "Commits since $LAST_TAG: $DISTANCE"

# If there are new commits, increment the patch version by the distance
if [ "$DISTANCE" -gt 0 ]; then
    NEW_PATCH=$((PATCH + DISTANCE))
else
    echo "No new commits since last tag"
    exit 0
fi

# Create new version
NEW_VERSION="v${MAJOR}.${MINOR}.${NEW_PATCH}"
echo "New version: $NEW_VERSION"

# Ensure we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "Error: Must be on main branch to create release"
    exit 1
fi

# Ensure working directory is clean
if ! git diff-index --quiet HEAD --; then
    echo "Error: Working directory has uncommitted changes"
    exit 1
fi

# Create tag
echo "Creating tag $NEW_VERSION..."
git tag -a $NEW_VERSION -m "Release $NEW_VERSION

Incremental release: $DISTANCE commits since $LAST_TAG"

echo "Tag $NEW_VERSION created successfully!"
echo ""
echo "To push the tag and trigger CI release, run:"
echo "  git push origin $NEW_VERSION"
echo ""
echo "Or to push all commits and tags:"
echo "  git push origin main --tags"
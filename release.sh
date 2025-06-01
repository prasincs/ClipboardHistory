#!/bin/bash
set -e

# Distance-based release script
# Format: MAJOR.MINOR.DISTANCE where DISTANCE is commits since last major/minor release

# Get the last tag (should be a major or minor release)
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo "Last tag: $LAST_TAG"

# Extract major and minor version
MAJOR=$(echo $LAST_TAG | cut -d. -f1 | sed 's/v//')
MINOR=$(echo $LAST_TAG | cut -d. -f2)

# Get distance (number of commits since last tag)
DISTANCE=$(git rev-list ${LAST_TAG}..HEAD --count)
echo "Commits since $LAST_TAG: $DISTANCE"

# Create new version
NEW_VERSION="v${MAJOR}.${MINOR}.${DISTANCE}"
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

# Create and push tag
echo "Creating tag $NEW_VERSION..."
git tag -a $NEW_VERSION -m "Release $NEW_VERSION

Distance-based release: $DISTANCE commits since $LAST_TAG"

echo "Pushing tag to remote..."
git push origin $NEW_VERSION

# Create GitHub release
echo "Creating GitHub release..."
gh release create $NEW_VERSION \
    --title "Release $NEW_VERSION" \
    --notes "Distance-based release: $DISTANCE commits since $LAST_TAG

See [CHANGELOG.md](https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/blob/main/CHANGELOG.md) for details." \
    --draft=false

echo "Release $NEW_VERSION created successfully!"
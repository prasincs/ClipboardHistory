#!/bin/bash
set -e

# Distance-based release script
# Format: MAJOR.MINOR.PATCH where PATCH = last_patch + commits_since_last_tag
# Example: v1.0.4 + 2 commits = v1.0.6
# 
# Usage: ./release.sh [--push]
#   --push: Automatically push the tag to origin after creating it

# Parse command line arguments
PUSH_TAG=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --push)
            PUSH_TAG=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--push]"
            exit 1
            ;;
    esac
done

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

# Run security checks
echo "Running security checks..."
if ! make security; then
    echo "Error: Security checks failed"
    echo "Please fix security issues before creating a release"
    exit 1
fi
echo "✅ Security checks passed"

# Check if CHANGELOG.md has been updated
echo "Checking CHANGELOG.md..."
if ! grep -q "## \[Unreleased\]" CHANGELOG.md; then
    echo "Error: CHANGELOG.md is missing [Unreleased] section"
    exit 1
fi

# Check if there are entries under [Unreleased]
UNRELEASED_LINE=$(grep -n "## \[Unreleased\]" CHANGELOG.md | cut -d: -f1)
NEXT_SECTION_LINE=$(tail -n +$((UNRELEASED_LINE + 1)) CHANGELOG.md | grep -n "^## \[" | head -1 | cut -d: -f1)

if [ -z "$NEXT_SECTION_LINE" ]; then
    # No next section found, check until end of file
    CHANGELOG_CONTENT=$(tail -n +$((UNRELEASED_LINE + 1)) CHANGELOG.md)
else
    # Check content between Unreleased and next section
    CHANGELOG_CONTENT=$(sed -n "$((UNRELEASED_LINE + 1)),$((UNRELEASED_LINE + NEXT_SECTION_LINE - 1))p" CHANGELOG.md)
fi

# Remove empty lines and check if there's actual content
CHANGELOG_CONTENT_TRIMMED=$(echo "$CHANGELOG_CONTENT" | grep -v "^[[:space:]]*$" | grep -v "^#")

if [ -z "$CHANGELOG_CONTENT_TRIMMED" ]; then
    echo "Error: No changes documented in [Unreleased] section of CHANGELOG.md"
    echo ""
    echo "Please update CHANGELOG.md with:"
    echo "  - A description of changes since $LAST_TAG"
    echo "  - Categorize changes as: Added, Changed, Fixed, Deprecated, Removed, Security"
    echo ""
    echo "Example:"
    echo "  ## [Unreleased]"
    echo "  "
    echo "  ### Added"
    echo "  - New feature description"
    echo "  "
    echo "  ### Fixed"
    echo "  - Bug fix description"
    exit 1
fi

echo "✓ CHANGELOG.md has unreleased changes documented"
echo ""
echo "Release Summary:"
echo "================"
echo "Version: $LAST_TAG → $NEW_VERSION ($DISTANCE commits)"
echo ""
echo "Changes to be released:"
echo "$CHANGELOG_CONTENT_TRIMMED" | sed 's/^/  /'
echo "================"
echo ""

# Check if tag already exists
if git rev-parse $NEW_VERSION >/dev/null 2>&1; then
    echo "Error: Tag $NEW_VERSION already exists!"
    echo "This might happen if the release script was run but the tag wasn't pushed."
    echo ""
    echo "To push the existing tag, run:"
    echo "  git push origin $NEW_VERSION"
    exit 1
fi

# Update CHANGELOG.md - move Unreleased content to new version
echo "Updating CHANGELOG.md..."
TODAY=$(date +%Y-%m-%d)

# Create a temporary file with updated changelog
{
    # Copy everything up to and including [Unreleased]
    sed -n '1,/## \[Unreleased\]/p' CHANGELOG.md
    
    # Add empty line after [Unreleased]
    echo ""
    
    # Add new version header
    echo "## [$NEW_VERSION] - $TODAY"
    
    # Copy unreleased content (everything between [Unreleased] and next section)
    if [ -z "$NEXT_SECTION_LINE" ]; then
        # No next section, copy to end of file
        tail -n +$((UNRELEASED_LINE + 1)) CHANGELOG.md
    else
        # Copy content between Unreleased and next section
        sed -n "$((UNRELEASED_LINE + 1)),$((UNRELEASED_LINE + NEXT_SECTION_LINE - 1))p" CHANGELOG.md
        # Copy everything from the next section onwards
        tail -n +$((UNRELEASED_LINE + NEXT_SECTION_LINE)) CHANGELOG.md
    fi
} > CHANGELOG.md.tmp

# Replace the original file
mv CHANGELOG.md.tmp CHANGELOG.md

# Commit the changelog update
git add CHANGELOG.md
git commit -m "Update CHANGELOG.md for $NEW_VERSION release"

echo "✓ CHANGELOG.md updated with version $NEW_VERSION"

# Create tag
echo "Creating tag $NEW_VERSION..."
git tag -a $NEW_VERSION -m "Release $NEW_VERSION

Incremental release: $DISTANCE commits since $LAST_TAG"

echo "Tag $NEW_VERSION created successfully!"

# Push the tag if requested
if [ "$PUSH_TAG" = true ]; then
    echo ""
    echo "Pushing changes and tag to origin..."
    # Push the changelog commit first
    git push origin main
    # Then push the tag
    git push origin $NEW_VERSION
    echo "Changes and tag pushed successfully!"
    echo ""
    echo "The CI release should start automatically."
else
    echo ""
    echo "Changes committed locally. To push everything, run:"
    echo "  git push origin main"
    echo "  git push origin $NEW_VERSION"
    echo ""
    echo "Or to push all commits and tags at once:"
    echo "  git push origin main --tags"
    echo ""
    echo "Or run this script again with --push:"
    echo "  ./release.sh --push"
fi
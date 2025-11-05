#!/bin/bash
set -e  # Exit on error

echo "🔨 Building praisonai-svc..."
echo ""

cd /Users/praison/praisonai-svc

# Extract version from pyproject.toml
VERSION=$(grep '^version = ' pyproject.toml | sed 's/version = "\(.*\)"/\1/')
echo "📦 Version: $VERSION"
echo ""

# Build
uv lock
uv build

# Git tagging
echo ""
echo "🏷️  Git tagging..."

# Check if tag already exists
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
    echo "⚠️  Tag v$VERSION already exists locally"
    read -p "   Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "v$VERSION"
        echo "   ✓ Deleted local tag"
    else
        echo "   Skipping tag creation"
    fi
fi

# Create new tag if it doesn't exist
if ! git rev-parse "v$VERSION" >/dev/null 2>&1; then
    git tag -a "v$VERSION" -m "Release v$VERSION"
    echo "✅ Created local tag: v$VERSION"
    echo ""
    echo "💡 When ready to push:"
    echo "   git push origin v$VERSION"
    echo "   # Or to force update remote tag:"
    echo "   git push origin v$VERSION --force"
fi

echo ""
echo "✅ Build complete!"
echo ""

# GitHub Release (optional)
echo "🚀 GitHub Release"
echo ""
read -p "Create GitHub release for v$VERSION? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        echo "❌ GitHub CLI (gh) not installed"
        echo "   Install: brew install gh"
        echo "   Or visit: https://cli.github.com/"
    else
        # Check if authenticated
        if ! gh auth status &> /dev/null; then
            echo "🔐 Authenticating with GitHub..."
            gh auth login
        fi
        
        # Check if release already exists
        if gh release view "v$VERSION" &> /dev/null; then
            echo "⚠️  Release v$VERSION already exists on GitHub"
            read -p "   Delete and recreate? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "Deleting existing release..."
                gh release delete "v$VERSION" --yes
                echo "   ✓ Deleted old release"
            else
                echo "   Skipping release creation"
                echo ""
                echo "💡 To update assets only:"
                echo "   gh release upload v$VERSION ./dist/* --clobber"
                return
            fi
        fi
        
        # Generate release notes from git log
        echo "📝 Generating release notes..."
        
        # Create release
        echo "Creating release v$VERSION..."
        gh release create "v$VERSION" \
            --title "v$VERSION" \
            --generate-notes \
            ./dist/*
        
        echo "✅ GitHub release created: https://github.com/MervinPraison/PraisonAI-SVC/releases/tag/v$VERSION"
    fi
fi

echo ""
echo "Next steps:"
echo "  Test:    ./publish.sh --test --token YOUR_TOKEN"
echo "  Publish: ./publish.sh --token YOUR_TOKEN"

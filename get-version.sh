#!/bin/sh

# This script reads the package version from layout/DEBIAN/control.
VERSION=$(grep -m1 '^Version:' layout/DEBIAN/control | awk '{print $2}' | tr -d '[:space:]')

if [ -z "$VERSION" ]; then
    echo "Error: Could not read Version from layout/DEBIAN/control" >&2
    exit 1
fi

echo "$VERSION"

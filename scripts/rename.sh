#!/usr/bin/env bash
# rename.sh

# Turns the template into your own app:
#
#     scripts/rename.sh <AppName> <bundle-prefix> <url-scheme>
#     scripts/rename.sh "Acme Shop" com.acme acme
#
# <AppName> is the home-screen name, as typed. Its lowercase kebab slug
# (`acme-shop`) names the project, the workspace, the package and the app's
# bundle ID. Everything else is derived from the constants at the top of
# Project.swift, so those, two manifest names and the README title are all this
# rewrites.
#
# Each value is read back from the file before it is replaced, so a second run
# reports "unchanged", and a renamed app can be renamed again. Every edit is
# anchored to a line that must appear exactly once: when the files drift from
# what this expects, it stops and names the file rather than guessing.
#
# Written for the bash 3.2 that macOS ships, and Linux CI runners.

set -euo pipefail

usage() {
    echo "usage: scripts/rename.sh <AppName> <bundle-prefix> <url-scheme>" >&2
    echo "  e.g. scripts/rename.sh \"Acme Shop\" com.acme acme" >&2
    exit 64
}

fail() {
    echo "rename.sh: $*" >&2
    exit 1
}

[ $# -eq 3 ] || usage
display_name=$1
bundle_prefix=$2
url_scheme=$3

# Quotes and backslashes are excluded because the name lands inside a Swift
# string literal.
name_pattern='^[A-Za-z][A-Za-z0-9 -]*$'
prefix_pattern='^[a-z0-9-]+(\.[a-z0-9-]+)+$'
scheme_pattern='^[a-z][a-z0-9+.-]*$'

[[ $display_name =~ $name_pattern ]] ||
    fail "AppName must start with a letter and use only letters, digits, spaces and hyphens: '$display_name'"
[[ $bundle_prefix =~ $prefix_pattern ]] ||
    fail "bundle-prefix must be lowercase reverse-DNS, such as com.acme: '$bundle_prefix'"
[[ $url_scheme =~ $scheme_pattern ]] ||
    fail "url-scheme must be a lowercase letter followed by letters, digits, '+', '.' or '-': '$url_scheme'"

# The name always starts with a letter, so the slug is never empty.
app_name=$(printf '%s' "$display_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')

cd "$(dirname "$0")/.."
[ -f Project.swift ] || fail "run from a checkout of the template; no Project.swift in $(pwd)"

# Each edit: the file, a label for messages, a Perl pattern whose single group
# captures the value, and the new value. Values pass through the environment,
# never through the Perl source, so nothing in them needs escaping.
files=(Project.swift Project.swift Project.swift Project.swift Workspace.swift Tuist/Package.swift README.md)
labels=(appName displayName bundlePrefix urlScheme 'workspace name' 'package name' title)
patterns=(
    '^let appName = "([^"]*)"$'
    '^let displayName = "([^"]*)"$'
    '^let bundlePrefix = "([^"]*)"$'
    '^let urlScheme = "([^"]*)"$'
    '^    name: "([^"]*)",$'
    '^    name: "([^"]*)",$'
    '^# (.+)$'
)
values=("$app_name" "$display_name" "$bundle_prefix" "$url_scheme" "$app_name" "$app_name" "$display_name")

# Every anchor is checked before anything is written, so drift in the last file
# cannot leave the first ones half-renamed.
for i in "${!files[@]}"; do
    [ -f "${files[$i]}" ] || fail "${files[$i]} not found"
    count=$(PATTERN=${patterns[$i]} perl -ne '$n++ if /$ENV{PATTERN}/; END { print $n + 0 }' "${files[$i]}")
    [ "$count" -eq 1 ] || fail "${files[$i]}: expected exactly one ${labels[$i]} line, found $count"
done

for i in "${!files[@]}"; do
    file=${files[$i]} label=${labels[$i]} new=${values[$i]}
    old=$(PATTERN=${patterns[$i]} perl -ne 'print $1 if /$ENV{PATTERN}/' "$file")
    if [ "$old" = "$new" ]; then
        echo "$file: $label unchanged ($new)"
        continue
    fi

    PATTERN=${patterns[$i]} NEW=$new perl -pi -e 'substr($_, $-[1], $+[1] - $-[1]) = $ENV{NEW} if /$ENV{PATTERN}/' "$file"
    echo "$file: $label $old -> $new"
done

cat <<EOF

Next:
    mise exec -- tuist install && mise exec -- tuist generate

The new package name changes the originHash in Tuist/Package.resolved when
tuist install runs; commit that with the rename. The previous generated
.xcodeproj and .xcworkspace are not deleted; remove them once the new ones open.
EOF

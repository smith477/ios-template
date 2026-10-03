#!/usr/bin/env bash
# check-feature-copy.sh

# Proves each feature still builds when copied out on its own:
#
#     scripts/check-feature-copy.sh             # every feature under Modules/Features
#     scripts/check-feature-copy.sh Products    # just these
#
# For each feature it writes a scratch Tuist project in a temporary directory
# holding only that feature, every Platform module and the APIClient package,
# which is all a feature may depend on. It then compiles the feature and its tests
# for the simulator, without booting one. Importing another feature, or leaning on
# something only the app provides, fails the build here even when the full
# project compiles.
#
# Run from anywhere; needs mise and Xcode, and network access for `tuist install`.

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if [ "$#" -gt 0 ]; then
    features=("$@")
else
    features=()
    for dir in Modules/Features/*/; do
        features+=("$(basename "$dir")")
    done
fi

platform_modules=()
for dir in Modules/Platform/*/; do
    platform_modules+=("$(basename "$dir")")
done

scratches=()
cleanup() {
    for scratch in ${scratches[@]+"${scratches[@]}"}; do
        rm -rf "$scratch"
    done
}
trap cleanup EXIT

# The settings every target shares, copied from Project.swift so the scratch
# project builds the way the real one does.
shared_settings="$(
    grep -E '^let (deploymentTargets|destinations): ' Project.swift
    awk '/^let baseSettings: /,/^\]/' Project.swift
)"
for name in deploymentTargets destinations baseSettings; do
    if ! printf '%s\n' "$shared_settings" | grep -q "^let $name: "; then
        echo "Project.swift no longer declares \`let $name\`; update $0 to match." >&2
        exit 1
    fi
done

# Writes the scratch manifest.
write_manifest() {
    local feature="$1" has_tests="$2"
    local platform_targets="" platform_deps="" models="" test_target="" scheme_targets

    for module in "${platform_modules[@]}"; do
        platform_targets+="        target(\"$module\", at: \"Modules/Platform/$module\", dependencies: []),
"
        platform_deps+=".target(name: \"$module\"), "
    done

    for model in "Modules/Features/$feature/Sources/"*.xcdatamodeld; do
        if [ -e "$model" ]; then
            models+=".coreDataModel(\"$model\"), "
        fi
    done

    scheme_targets="\"$feature\""
    if [ "$has_tests" = yes ]; then
        test_target="        .target(
            name: \"${feature}Tests\",
            destinations: destinations,
            product: .unitTests,
            bundleId: \"copycheck.${feature}Tests\",
            deploymentTargets: deploymentTargets,
            sources: [\"Modules/Features/$feature/Tests/**\"],
            dependencies: [.target(name: \"$feature\"), ${platform_deps}.external(name: \"APIClient\")]
        ),
"
        scheme_targets+=", \"${feature}Tests\""
    fi

    cat > Project.swift <<EOF
import ProjectDescription

${shared_settings}

func target(_ name: String, at path: String, dependencies: [TargetDependency], coreDataModels: [CoreDataModel] = []) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: .staticFramework,
        bundleId: "copycheck.\(name)",
        deploymentTargets: deploymentTargets,
        sources: ["\(path)/Sources/**"],
        dependencies: dependencies,
        coreDataModels: coreDataModels
    )
}

let project = Project(
    name: "FeatureCopy",
    options: .options(automaticSchemesOptions: .disabled),
    settings: .settings(base: baseSettings),
    targets: [
${platform_targets}        target(
            "$feature",
            at: "Modules/Features/$feature",
            dependencies: [${platform_deps}.external(name: "APIClient")],
            coreDataModels: [${models}]
        ),
${test_target}    ],
    schemes: [
        .scheme(name: "Check", shared: true, buildAction: .buildAction(targets: [${scheme_targets}])),
    ]
)
EOF
}

# Builds one feature in its scratch copy. `set -e` does not apply inside an `if`
# condition, so each step returns on failure itself.
check() {
    local feature="$1" scratch="$2" has_tests="$3" action=build
    [ "$has_tests" = yes ] && action=build-for-testing
    cd "$scratch" || return 1
    write_manifest "$feature" "$has_tests" || return 1
    mise exec -- tuist install >/dev/null || return 1
    mise exec -- tuist generate --no-open >/dev/null || return 1
    xcodebuild "$action" -workspace FeatureCopy.xcworkspace -scheme Check \
        -destination 'generic/platform=iOS Simulator' \
        -derivedDataPath "$scratch/DerivedData" -quiet
}

failed=()
for feature in "${features[@]}"; do
    if [ ! -d "Modules/Features/$feature/Sources" ]; then
        echo "No feature named $feature under Modules/Features" >&2
        exit 64
    fi

    scratch="$(mktemp -d)"
    scratches+=("$scratch")
    mkdir -p "$scratch/Modules/Features" "$scratch/Tuist"
    cp -R Modules/Platform "$scratch/Modules/"
    cp -R "Modules/Features/$feature" "$scratch/Modules/Features/"
    cp Tuist/Package.swift Tuist/Package.resolved "$scratch/Tuist/"
    cp Tuist.swift mise.toml "$scratch/"

    has_tests=no
    [ -d "Modules/Features/$feature/Tests" ] && has_tests=yes

    echo "==> $feature, copied alone"
    if (check "$feature" "$scratch" "$has_tests"); then
        echo "==> $feature builds alone"
    else
        echo "==> $feature does not build alone" >&2
        failed+=("$feature")
    fi
done

if [ "${#failed[@]}" -gt 0 ]; then
    echo "Not copyable: ${failed[*]}" >&2
    exit 1
fi

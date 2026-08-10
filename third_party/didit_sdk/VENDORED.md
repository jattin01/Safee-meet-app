# Why this package is vendored

This is a local copy of `didit_sdk` 4.5.3 (originally from pub.dev), with one
change: `ios/didit_sdk/Package.swift` has been removed.

Flutter's Swift Package Manager integration has no per-plugin opt-out — a
plugin either goes through SPM (if `Package.swift` exists) or CocoaPods, for
every plugin in the project at once. `didit_sdk`'s SPM manifest independently
fetches the full `DiditSDK` product straight from
`https://github.com/didit-protocol/sdk-ios`, with no way to select the
smaller `Core` variant the way the CocoaPods path does (see the
`$DiditSdkIosVariant` variable in `ios/Podfile`). With both paths active,
Xcode fails with:

    Multiple commands produce '.../Runner.app/Frameworks/DiditSDK.framework'

because CocoaPods and SPM both try to embed a `DiditSDK.framework` into the
app bundle.

Removing `Package.swift` here makes `didit_sdk` fall back to its CocoaPods
path only (`ios/didit_sdk.podspec`), which reads `$DiditSdkIosVariant` from
the Podfile and resolves to `DiditSDK/Core` — matching the original,
deliberate choice to avoid the NFC entitlement/capability that the `All`
variant requires.

`pubspec.yaml` points here via `dependency_overrides`.

## Upgrading didit_sdk

When bumping the version, re-vendor from scratch rather than patching this
copy in place:

```
rm -rf third_party/didit_sdk
flutter pub cache clean  # or: pub cache repair, to ensure the new version is fetched
# bump the version in pubspec.yaml under dependencies (not dependency_overrides), then:
flutter pub get
cp -R "$(dirname "$(dirname "$(find ~/.pub-cache -maxdepth 3 -type d -name 'didit_sdk-*' | sort -V | tail -1)")")"/didit_sdk-*/. third_party/didit_sdk
rm third_party/didit_sdk/ios/didit_sdk/Package.swift
rm -rf third_party/didit_sdk/ios/didit_sdk/.swiftpm
```

Then re-add the `dependency_overrides` entry and re-run `flutter pub get`.

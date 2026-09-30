import CoreText
import Foundation

/// JetBrains Mono, which the library bundles (`Resources/Fonts`, SIL Open Font License 1.1):
/// the design system's type, and what `.system` draws in by default (`TextFont.systemFamily`).
/// Its four weights are read from the bundle once and never registered, so the face drawn is
/// always the bundled one, whatever version the system has installed.
enum BundledFonts {
  private static let files: [(TextFont.Weight, String)] = [
    (.regular, "JetBrainsMono-Regular"),
    (.medium, "JetBrainsMono-Medium"),
    (.semibold, "JetBrainsMono-SemiBold"),
    (.bold, "JetBrainsMono-Bold"),
  ]

  /// The faces by weight. Empty if the bundle has none, and `.system` then draws in SF. Made
  /// once, then only read: a font descriptor is immutable, and CoreText's are thread-safe.
  nonisolated(unsafe) private static let jetBrainsMono: [TextFont.Weight: CTFontDescriptor] = {
    var descriptors: [TextFont.Weight: CTFontDescriptor] = [:]
    for (weight, name) in files {
      guard
        let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts"),
        let found = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
        let descriptor = found.first
      else { continue }
      descriptors[weight] = descriptor
    }
    return descriptors
  }()

  /// JetBrains Mono at `size`, in the bundled weight nearest `weight`: lighter ones draw
  /// regular, heavier ones bold. Nil when the face is missing from the bundle.
  static func jetBrainsMono(_ weight: TextFont.Weight, size: CGFloat) -> CTFont? {
    let nearest: TextFont.Weight = switch weight {
    case .ultraLight, .thin, .light, .regular: .regular
    case .medium: .medium
    case .semibold: .semibold
    case .bold, .heavy, .black: .bold
    }
    guard let descriptor = Self.jetBrainsMono[nearest] ?? Self.jetBrainsMono[.regular] else { return nil }
    return CTFontCreateWithFontDescriptor(descriptor, size, nil)
  }
}

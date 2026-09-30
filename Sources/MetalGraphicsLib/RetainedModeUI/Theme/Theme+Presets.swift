import simd

// The two built-in themes: frosted glass, light and dark. Window chrome is translucent to the
// desktop, which the system blurs; popovers, menus, sheets and tooltips are the library's own
// glass over the app; what text sits on is opaque. See docs/DesignSystem.md.

extension Theme {
  private static func black(_ alpha: Float) -> float4 { float4(0, 0, 0, alpha) }
  private static func white(_ alpha: Float) -> float4 { float4(1, 1, 1, alpha) }
  private static func rgb(_ r: Float, _ g: Float, _ b: Float, _ alpha: Float) -> float4 {
    float4(r / 255, g / 255, b / 255, alpha)
  }

  public static let light: Theme = {
    let accent = float4(hex: 0x007AFF)
    let colors = ThemeColors([
      .label: black(0.85),
      .secondaryLabel: black(0.52),
      .tertiaryLabel: black(0.28),
      .placeholder: black(0.25),
      .accent: accent,
      .accentForeground: .white,
      .destructive: float4(hex: 0xFF3B30),
      .warning: float4(hex: 0xFF9500),
      .success: float4(hex: 0x34C759),
      .info: float4(hex: 0x5856D6),
      .separator: black(0.10),
      .border: black(0.16),
      .focusRing: accent.withAlpha(0.4),
      .fill: black(0.07),
      .fillHover: black(0.10),
      .fillPressed: black(0.15),
      .controlBackground: .white,
      .controlButton: .white,
      .segmentSelected: .white,
      .controlKnob: .white,
      .hover: black(0.05),
      .pressed: black(0.11),
      .selection: accent.withAlpha(0.2),
      .selectionInactive: black(0.08),
      .selectedTab: white(0.9),
      .contentBackground: .white,
      .groupedBackground: float4(hex: 0xF2F2F7),
      .card: .white,
      .windowBackground: float4(hex: 0xECECEF),
      .sidebarTint: rgb(244, 244, 248, 0.55),
      .barTint: rgb(250, 250, 252, 0.67),
      .barOverContent: rgb(248, 248, 250, 0.85),
      .gapTint: black(0.10),
      .scrim: black(0.22),
      .scrollIndicator: black(0.35),
      .shadow: black(0.2),
    ])
    return Theme(
      appearance: .light, colors: colors, palette: lightPalette,
      materials: ThemeMaterials([
        .popover: GlassMaterial(
          blurRadius: 22, tint: white(0.72), tintBottom: rgb(250, 250, 252, 0.62), rim: white(0.85), rimBottom: 0.2,
          fallback: float4(hex: 0xF5F5F7)
        ),
        .menu: GlassMaterial(
          blurRadius: 22, tint: white(0.72), tintBottom: rgb(250, 250, 252, 0.62), rim: white(0.85), rimBottom: 0.2,
          fallback: float4(hex: 0xF5F5F7)
        ),
        .tooltip: GlassMaterial(
          blurRadius: 15, tint: white(0.86), tintBottom: rgb(248, 248, 250, 0.8), saturation: 1.6, rim: white(0.85),
          rimBottom: 0.2, fallback: float4(hex: 0xF5F5F7)
        ),
        .sheet: GlassMaterial(
          blurRadius: 30, tint: white(0.82), tintBottom: rgb(246, 246, 249, 0.74), rim: white(0.85), rimBottom: 0.2,
          fallback: float4(hex: 0xF2F2F7)
        ),
        .floatingPanel: GlassMaterial(
          blurRadius: 24, tint: white(0.66), tintBottom: rgb(246, 246, 249, 0.58), rim: white(0.7), rimBottom: 0.2,
          fallback: float4(hex: 0xECECEF)
        ),
        .dropMarker: GlassMaterial(blurRadius: 12, tint: white(0.6), rim: white(0.8)),
        .bar: GlassMaterial(blurRadius: 24, tint: rgb(248, 248, 250, 0.8), fallback: rgb(248, 248, 250, 1)),
      ]),
      shadows: ThemeShadows(
        control: ThemeShadow(color: black(0.18), radius: 1, y: 0.5),
        popover: ThemeShadow(color: black(0.16), radius: 12, y: 6),
        sheet: ThemeShadow(color: black(0.24), radius: 22, y: 10),
        float: ThemeShadow(color: black(0.22), radius: 16, y: 8)
      ),
      editor: Theme.code(.light)
    )
  }()

  public static let dark: Theme = {
    let accent = float4(hex: 0x0A84FF)
    let colors = ThemeColors([
      .label: white(0.88),
      .secondaryLabel: white(0.55),
      .tertiaryLabel: white(0.28),
      .placeholder: white(0.25),
      .accent: accent,
      .accentForeground: .white,
      .destructive: float4(hex: 0xFF453A),
      .warning: float4(hex: 0xFF9F0A),
      .success: float4(hex: 0x30D158),
      .info: float4(hex: 0x5E5CE6),
      .separator: white(0.10),
      .border: white(0.16),
      .focusRing: accent.withAlpha(0.5),
      .fill: white(0.11),
      .fillHover: white(0.15),
      .fillPressed: white(0.20),
      .controlBackground: white(0.06),
      .controlButton: white(0.14),
      .segmentSelected: white(0.22),
      .controlKnob: float4(hex: 0xF2F2F4),
      .hover: white(0.06),
      .pressed: white(0.13),
      .selection: accent.withAlpha(0.36),
      .selectionInactive: white(0.10),
      .selectedTab: white(0.13),
      .contentBackground: float4(hex: 0x1F1F24),
      .groupedBackground: float4(hex: 0x161618),
      .card: float4(hex: 0x232326),
      .windowBackground: float4(hex: 0x1E1E21),
      .sidebarTint: rgb(30, 30, 34, 0.55),
      .barTint: rgb(36, 36, 40, 0.65),
      .barOverContent: rgb(40, 40, 44, 0.85),
      .gapTint: black(0.45),
      .scrim: black(0.42),
      .scrollIndicator: white(0.35),
      .shadow: black(0.5),
    ])
    return Theme(
      appearance: .dark, colors: colors, palette: darkPalette,
      materials: ThemeMaterials([
        .popover: GlassMaterial(
          blurRadius: 22, tint: rgb(62, 62, 68, 0.65), tintBottom: rgb(44, 44, 50, 0.73), saturation: 1.5,
          rim: white(0.18), fallback: float4(hex: 0x2A2A2D)
        ),
        .menu: GlassMaterial(
          blurRadius: 22, tint: rgb(62, 62, 68, 0.65), tintBottom: rgb(44, 44, 50, 0.73), saturation: 1.5,
          rim: white(0.18), fallback: float4(hex: 0x2A2A2D)
        ),
        .tooltip: GlassMaterial(
          blurRadius: 15, tint: rgb(64, 64, 70, 0.83), tintBottom: rgb(52, 52, 58, 0.85), saturation: 1.4,
          rim: white(0.18), fallback: float4(hex: 0x2C2C30)
        ),
        .sheet: GlassMaterial(
          blurRadius: 30, tint: rgb(56, 56, 62, 0.77), tintBottom: rgb(40, 40, 46, 0.85), saturation: 1.5,
          rim: white(0.18), fallback: float4(hex: 0x262629)
        ),
        .floatingPanel: GlassMaterial(
          blurRadius: 24, tint: rgb(50, 50, 56, 0.65), tintBottom: rgb(40, 40, 46, 0.72), saturation: 1.5,
          rim: white(0.14), fallback: float4(hex: 0x232326)
        ),
        .dropMarker: GlassMaterial(blurRadius: 12, tint: rgb(56, 56, 62, 0.6), saturation: 1.5, rim: white(0.2)),
        .bar: GlassMaterial(blurRadius: 24, tint: rgb(40, 40, 44, 0.8), saturation: 1.5, fallback: rgb(40, 40, 44, 1)),
      ]),
      shadows: ThemeShadows(
        control: ThemeShadow(color: black(0.4), radius: 1, y: 0.5),
        popover: ThemeShadow(color: black(0.45), radius: 14, y: 7),
        sheet: ThemeShadow(color: black(0.55), radius: 24, y: 12),
        float: ThemeShadow(color: black(0.5), radius: 18, y: 9)
      ),
      editor: Theme.code(.dark)
    )
  }()

  /// A code editor's look in the design system: JetBrains Mono 12.5 on 20 pt lines, a 52 pt gutter.
  private static func code(_ base: EditorTheme) -> EditorTheme {
    var theme = base
    theme.font = ThemeTypography.standard.mono
    theme.lineHeight = 20
    theme.minGutterWidth = 52
    return theme
  }

  /// The one for `appearance`.
  public static func standard(_ appearance: Appearance) -> Theme {
    appearance == .dark ? .dark : .light
  }

  private static let lightPalette = ThemePalette(
    blue: float4(hex: 0x007AFF), purple: float4(hex: 0xAF52DE), pink: float4(hex: 0xFF2D55), red: float4(hex: 0xFF3B30),
    orange: float4(hex: 0xFF9500), yellow: float4(hex: 0xFFCC00), green: float4(hex: 0x34C759), mint: float4(hex: 0x00C7BE),
    teal: float4(hex: 0x30B0C7), indigo: float4(hex: 0x5856D6), brown: float4(hex: 0xA2845E), gray: float4(hex: 0x8E8E93),
    badgeClass: float4(hex: 0xC9620A), badgeStruct: float4(hex: 0x8944D4), badgeEnum: float4(hex: 0xA66A08),
    badgeProperty: float4(hex: 0x1B7F93), badgeMethod: float4(hex: 0x2F66D8), badgeVariable: float4(hex: 0x3A8445),
    folder: float4(hex: 0x5AA0F2)
  )

  private static let darkPalette = ThemePalette(
    blue: float4(hex: 0x0A84FF), purple: float4(hex: 0xBF5AF2), pink: float4(hex: 0xFF375F), red: float4(hex: 0xFF453A),
    orange: float4(hex: 0xFF9F0A), yellow: float4(hex: 0xFFD60A), green: float4(hex: 0x30D158), mint: float4(hex: 0x63E6E2),
    teal: float4(hex: 0x40C8E0), indigo: float4(hex: 0x5E5CE6), brown: float4(hex: 0xAC8E68), gray: float4(hex: 0x98989D),
    badgeClass: float4(hex: 0xC9620A), badgeStruct: float4(hex: 0x8944D4), badgeEnum: float4(hex: 0xA66A08),
    badgeProperty: float4(hex: 0x1B7F93), badgeMethod: float4(hex: 0x2F66D8), badgeVariable: float4(hex: 0x3A8445),
    folder: float4(hex: 0x64A8F5)
  )
}

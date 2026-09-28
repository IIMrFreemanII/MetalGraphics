import simd

/// Light or dark, as the system appearance is.
public enum Appearance: Hashable, Sendable {
  case light
  case dark
}

/// A colour by what it is for, not what it is: every part of the library draws with these, and
/// the current `Theme` says what each is in light and in dark. Code outside the library can too:
/// `.foregroundStyle(.secondaryLabel)`, `.background(.selection, in: ...)`.
public enum ThemeColor: Int, CaseIterable, Sendable {
  // Text, alpha-based so it reads on any glass.
  case label, secondaryLabel, tertiaryLabel, placeholder
  // Tints.
  case accent, accentForeground, destructive, warning, success, info
  // Lines.
  case separator, border, focusRing
  // Controls: a bordered button, a track, a field, a pop-up button, a segment, a knob.
  case fill, fillHover, fillPressed, controlBackground, controlButton, segmentSelected, controlKnob
  // Interaction.
  case hover, pressed, selection, selectionInactive, selectedTab
  // Opaque surfaces: what text sits on.
  case contentBackground, groupedBackground, card, windowBackground
  // Window chrome, drawn over the system's blur of the desktop: a sidebar, a bar, a dock gap.
  // A bar drawn over the app's own content is `barOverContent`, blurred by the library's glass.
  case sidebarTint, barTint, barOverContent, gapTint
  // Overlays: behind a sheet, a scroll bar, a drop shadow.
  case scrim, scrollIndicator, shadow
}

/// What each `ThemeColor` is, in one appearance.
public struct ThemeColors: Hashable, Sendable {
  private var values: [float4]

  /// Every role must be given one.
  public init(_ values: [ThemeColor: float4]) {
    self.values = ThemeColor.allCases.map { role in
      guard let value = values[role] else { preconditionFailure("ThemeColors: no colour for .\(role)") }
      return value
    }
  }

  public subscript(_ role: ThemeColor) -> float4 {
    get { self.values[role.rawValue] }
    set { self.values[role.rawValue] = newValue }
  }
}

/// Colours for things told apart by hue alone: kind badges, tags, swatches.
public struct ThemePalette: Hashable, Sendable {
  public var blue, purple, pink, red, orange, yellow, green, mint, teal, indigo, brown, gray: float4
  /// Behind white badge letters: darker than the palette, so the letters read.
  public var badgeClass, badgeStruct, badgeEnum, badgeProperty, badgeMethod, badgeVariable: float4
  /// A folder in a file tree.
  public var folder: float4 = float4(hex: 0x5AA0F2)

  public subscript(_ hue: ThemeHue) -> float4 {
    switch hue {
    case .blue: self.blue
    case .purple: self.purple
    case .pink: self.pink
    case .red: self.red
    case .orange: self.orange
    case .yellow: self.yellow
    case .green: self.green
    case .mint: self.mint
    case .teal: self.teal
    case .indigo: self.indigo
    case .brown: self.brown
    case .gray: self.gray
    case .badgeClass: self.badgeClass
    case .badgeStruct: self.badgeStruct
    case .badgeEnum: self.badgeEnum
    case .badgeProperty: self.badgeProperty
    case .badgeMethod: self.badgeMethod
    case .badgeVariable: self.badgeVariable
    case .folder: self.folder
    }
  }
}

/// A `ThemePalette` entry by name, to use as a colour that follows light and dark:
/// `float4.hue(.teal)`, resolved when drawn like a `ThemeColor` role.
public enum ThemeHue: Int, CaseIterable, Sendable {
  case blue, purple, pink, red, orange, yellow, green, mint, teal, indigo, brown, gray
  case badgeClass, badgeStruct, badgeEnum, badgeProperty, badgeMethod, badgeVariable
  case folder
}

/// A glass panel by what it is for, each with a `GlassMaterial` in the current theme.
public enum ThemeMaterial: Int, CaseIterable, Sendable {
  case popover, menu, tooltip, sheet, floatingPanel, dropMarker, bar
}

/// What each `ThemeMaterial` is, in one appearance.
public struct ThemeMaterials: Equatable, Sendable {
  private var values: [GlassMaterial]

  public init(_ values: [ThemeMaterial: GlassMaterial]) {
    self.values = ThemeMaterial.allCases.map { role in
      guard let value = values[role] else { preconditionFailure("ThemeMaterials: no material for .\(role)") }
      return value
    }
  }

  public subscript(_ role: ThemeMaterial) -> GlassMaterial {
    get { self.values[role.rawValue] }
    set { self.values[role.rawValue] = newValue }
  }
}

/// The type scale: SF throughout, macOS sizes. The same in light and dark, so switching
/// appearance never lays anything out again.
public struct ThemeTypography: Hashable, Sendable {
  public var largeTitle: TextFont
  public var title: TextFont
  public var title2: TextFont
  public var title3: TextFont
  /// Section and panel titles.
  public var headline: TextFont
  public var body: TextFont
  /// Tabs, toolbars, list details.
  public var callout: TextFont
  /// Status bars, positions.
  public var subheadline: TextFont
  public var footnote: TextFont
  /// Code.
  public var mono: TextFont
  public var monoSmall: TextFont

  public static let standard = ThemeTypography(
    largeTitle: .system(size: 26, weight: .bold),
    title: .system(size: 22, weight: .bold),
    title2: .system(size: 17, weight: .semibold),
    title3: .system(size: 15, weight: .semibold),
    headline: .system(size: 13, weight: .semibold),
    body: .system(size: 13),
    callout: .system(size: 12),
    subheadline: .system(size: 11),
    footnote: .system(size: 10),
    mono: .system(size: 12.5, design: .monospaced),
    monoSmall: .system(size: 11.5, design: .monospaced)
  )
}

/// The spacing scale, in points.
public struct ThemeSpacing: Hashable, Sendable {
  public var xxxs: Float = 2
  public var xxs: Float = 4
  public var xs: Float = 6
  public var sm: Float = 8
  public var md: Float = 12
  public var lg: Float = 16
  public var xl: Float = 20
  public var xxl: Float = 24
  public var xxxl: Float = 32

  public init() {}
}

/// Corner radii, in points.
public struct ThemeRadii: Hashable, Sendable {
  /// Badges.
  public var xs: Float = 3
  /// Rows, menu items.
  public var sm: Float = 5
  /// Buttons, fields.
  public var md: Float = 6
  /// Cards, popovers, floating panels.
  public var lg: Float = 10
  /// Sheets, alerts.
  public var xl: Float = 12

  public init() {}
}

/// A drop shadow, as `.shadow(color:radius:x:y:)` takes it.
public struct ThemeShadow: Hashable, Sendable {
  public var color: float4
  public var radius: Float
  public var x: Float
  public var y: Float

  public init(color: float4, radius: Float, x: Float = 0, y: Float = 0) {
    self.color = color
    self.radius = radius
    self.x = x
    self.y = y
  }
}

public struct ThemeShadows: Hashable, Sendable {
  /// Knobs, selected segments.
  public var control: ThemeShadow
  /// Menus, popovers, completion.
  public var popover: ThemeShadow
  /// Sheets, alerts.
  public var sheet: ThemeShadow
  /// Floating dock panels.
  public var float: ThemeShadow
}

/// How long things take to change.
public struct ThemeMotion: Sendable {
  public var hover = UIAnimation.easeOut(0.12)
  /// A knob sliding, a chevron turning: a change the user made on a control.
  public var interaction = UIAnimation.easeOut(0.18)
  public var dock = UIAnimation.easeOut(0.16)
  public var navigation = UIAnimation.easeInOut(0.3)
  public var presentation = UIAnimation.spring(response: 0.4, dampingFraction: 0.85)

  public init() {}
}

/// The look of everything the library draws, in one appearance: colours by role, glass
/// materials, type, spacing, radii, shadows, motion and the code editor's colours.
///
/// Immutable and shared: a window holds the current one (`UIContext.theme`), every draw reads it
/// from the renderer, and switching appearance swaps it for the other. Make a custom one from
/// `.light` or `.dark` with `with(_:)`.
public final class Theme: Sendable {
  public let appearance: Appearance
  public let colors: ThemeColors
  public let palette: ThemePalette
  public let materials: ThemeMaterials
  public let typography: ThemeTypography
  public let spacing: ThemeSpacing
  public let radii: ThemeRadii
  public let shadows: ThemeShadows
  public let motion: ThemeMotion
  /// What a `TextEditor` looks like unless it was given a theme of its own.
  public let editor: EditorTheme

  public init(
    appearance: Appearance, colors: ThemeColors, palette: ThemePalette, materials: ThemeMaterials,
    typography: ThemeTypography = .standard, spacing: ThemeSpacing = ThemeSpacing(), radii: ThemeRadii = ThemeRadii(),
    shadows: ThemeShadows, motion: ThemeMotion = ThemeMotion(), editor: EditorTheme
  ) {
    self.appearance = appearance
    self.colors = colors
    self.palette = palette
    self.materials = materials
    self.typography = typography
    self.spacing = spacing
    self.radii = radii
    self.shadows = shadows
    self.motion = motion
    self.editor = editor
  }

  /// Everything a theme is made of, to change in `with(_:)`.
  public struct Values {
    public var appearance: Appearance
    public var colors: ThemeColors
    public var palette: ThemePalette
    public var materials: ThemeMaterials
    public var typography: ThemeTypography
    public var spacing: ThemeSpacing
    public var radii: ThemeRadii
    public var shadows: ThemeShadows
    public var motion: ThemeMotion
    public var editor: EditorTheme
  }

  /// A copy of this theme with `change` made to it:
  ///
  ///     let brand = Theme.light.with { $0.colors[.accent] = float4(hex: 0xD97757) }
  public func with(_ change: (inout Values) -> Void) -> Theme {
    var values = Values(
      appearance: self.appearance, colors: self.colors, palette: self.palette, materials: self.materials,
      typography: self.typography, spacing: self.spacing, radii: self.radii, shadows: self.shadows,
      motion: self.motion, editor: self.editor
    )
    change(&values)
    return Theme(
      appearance: values.appearance, colors: values.colors, palette: values.palette, materials: values.materials,
      typography: values.typography, spacing: values.spacing, radii: values.radii, shadows: values.shadows,
      motion: values.motion, editor: values.editor
    )
  }

  public subscript(_ role: ThemeColor) -> float4 { self.colors[role] }

  /// `color` in this theme: a role (`float4.role`) becomes its colour here, with the alpha the
  /// role carries; any other colour is itself.
  @inline(__always)
  public func resolve(_ color: float4) -> float4 {
    guard color.w < 0 else { return color }
    var resolved = color.y == 0
      ? self.colors[ThemeColor(rawValue: Int(color.x)) ?? .label]
      : self.palette[ThemeHue(rawValue: Int(color.x)) ?? .gray]
    resolved.w *= -color.w
    return resolved
  }
  public subscript(_ role: ThemeMaterial) -> GlassMaterial { self.materials[role] }

  /// The theme of the window whose thread this runs on: for code building elements, which has
  /// no renderer to ask. Drawing code reads `Graphics2D.theme`.
  public static var current: Theme { ThreadState.current.theme }
}

/// An element that keeps more of the theme than colours, which are resolved when drawn: a
/// `TextEditor`'s whole `EditorTheme`, say. It registers with `UIContext.addThemeObserver` on
/// mount, and catches up there with any change it missed while unmounted.
public protocol ThemeObserving: AnyObject {
  func themeDidChange(_ theme: Theme, _ context: UIContext)
}

// MARK: - Roles as colours

public extension float4 {
  /// A colour that is whatever `role` is in the theme it is drawn with, resolved when drawn, so
  /// it follows light and dark with nothing rebuilt. Anything that takes a colour takes one; the
  /// roles are named on `float4` too: `.foregroundStyle(.secondaryLabel)`.
  ///
  /// Stored as the role and a negative alpha; `withAlpha` and an opacity scale it as they would
  /// any alpha. Changing to or from a role snaps rather than animates.
  static func role(_ role: ThemeColor, alpha: Float = 1) -> float4 {
    float4(Float(role.rawValue), 0, 0, -alpha)
  }

  /// A palette colour by name, resolved when drawn like a role: `.hue(.teal)`.
  static func hue(_ hue: ThemeHue, alpha: Float = 1) -> float4 {
    float4(Float(hue.rawValue), 1, 0, -alpha)
  }

  /// The role this colour stands for, if it is one.
  var themeRole: ThemeColor? {
    self.w < 0 && self.y == 0 ? ThemeColor(rawValue: Int(self.x)) : nil
  }

  static var label: float4 { .role(.label) }
  static var secondaryLabel: float4 { .role(.secondaryLabel) }
  static var tertiaryLabel: float4 { .role(.tertiaryLabel) }
  static var placeholder: float4 { .role(.placeholder) }
  static var accent: float4 { .role(.accent) }
  static var accentForeground: float4 { .role(.accentForeground) }
  static var destructive: float4 { .role(.destructive) }
  static var warning: float4 { .role(.warning) }
  static var success: float4 { .role(.success) }
  static var info: float4 { .role(.info) }
  static var separator: float4 { .role(.separator) }
  static var border: float4 { .role(.border) }
  static var focusRing: float4 { .role(.focusRing) }
  static var fill: float4 { .role(.fill) }
  static var fillHover: float4 { .role(.fillHover) }
  static var fillPressed: float4 { .role(.fillPressed) }
  static var controlBackground: float4 { .role(.controlBackground) }
  static var controlButton: float4 { .role(.controlButton) }
  static var segmentSelected: float4 { .role(.segmentSelected) }
  static var controlKnob: float4 { .role(.controlKnob) }
  static var hover: float4 { .role(.hover) }
  static var pressed: float4 { .role(.pressed) }
  static var selection: float4 { .role(.selection) }
  static var selectionInactive: float4 { .role(.selectionInactive) }
  static var selectedTab: float4 { .role(.selectedTab) }
  static var contentBackground: float4 { .role(.contentBackground) }
  static var groupedBackground: float4 { .role(.groupedBackground) }
  static var card: float4 { .role(.card) }
  static var windowBackground: float4 { .role(.windowBackground) }
  static var sidebarTint: float4 { .role(.sidebarTint) }
  static var barTint: float4 { .role(.barTint) }
  static var barOverContent: float4 { .role(.barOverContent) }
  static var gapTint: float4 { .role(.gapTint) }
  static var scrim: float4 { .role(.scrim) }
  static var scrollIndicator: float4 { .role(.scrollIndicator) }
  static var shadow: float4 { .role(.shadow) }
}

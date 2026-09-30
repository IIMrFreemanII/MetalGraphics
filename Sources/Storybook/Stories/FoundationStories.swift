import MetalGraphicsLib
import simd

enum FoundationStories {
  static let all: [ComponentStories] = [colors, palette, typography, glass, icon, animatedIcon, divider, scrollIndicator, themeScope]

  static let colors = ComponentStories(
    .foundations, "Colors", summary: "Every colour role, as the theme resolves it in light and dark. Draw with roles, never literal colours.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Theme/Theme.swift",
    args: [ArgType("filter", .text, .text(""), "Show roles whose name has this in it.")],
    stories: [Story("Roles", layout: .padded)],
    render: { args, _ in
      let filter = args.string("filter").lowercased()
      let roles = ThemeColor.allCases.filter { filter.isEmpty || "\($0)".lowercased().contains(filter) }
      return gallery(columns: 6, roles.map { role in
        VStack(alignment: .leading, spacing: 4) {
          Rectangle(.role(role)).frame(width: 96, height: 44).cornerRadius(6).border(.separator, width: 0.5, in: .rect(cornerRadius: 6))
          caption(".\(role)")
        }
      })
    },
    snippet: { _ in "Rectangle(.secondaryLabel)\n  .background(.card)\n  .foregroundColor(.accent)" }
  )

  static let palette = ComponentStories(
    .foundations, "Palette", web: "Hues", summary: "The palette's hues, for what is told apart by colour alone: swatches, badges, file types.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Theme/Theme.swift",
    args: [],
    stories: [Story("Hues", layout: .padded)],
    render: { _, _ in
      gallery(columns: 7, ThemeHue.allCases.map { hue in
        VStack(alignment: .leading, spacing: 4) {
          Rectangle(.hue(hue)).frame(width: 80, height: 36).cornerRadius(6)
          caption(".\(hue)")
        }
      })
    },
    snippet: { _ in "Image(icon: .folder).foregroundColor(.hue(.folder))\nKindBadge(\"S\", color: .hue(.badgeStruct))" }
  )

  static let typography = ComponentStories(
    .foundations, "Typography", summary: "The type scale: SF, macOS sizes, the same in light and dark.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Theme/Theme.swift",
    args: [ArgType("sample", .text, .text("The quick brown fox"), "The text each style shows.")],
    stories: [Story("Scale", layout: .padded)],
    render: { args, _ in
      let type = Theme.current.typography
      let styles: [(String, TextFont)] = [
        ("largeTitle", type.largeTitle), ("title", type.title), ("title2", type.title2), ("title3", type.title3),
        ("headline", type.headline), ("body", type.body), ("callout", type.callout), ("subheadline", type.subheadline),
        ("footnote", type.footnote), ("mono", type.mono), ("monoSmall", type.monoSmall),
      ]
      let rows: [UIElement] = styles.map { name, font in
        HStack(alignment: .firstTextBaseline, spacing: 16) {
          caption(name).frame(width: 90, alignment: .leading)
          Text(args.string("sample")).font(font)
        }
      }
      return VStack(alignment: .leading, spacing: 10) { () -> [UIElement] in return rows }
    },
    snippet: { args in "Text(\(swiftString(args.string("sample"))))\n  .font(Theme.current.typography.headline)" }
  )

  static let glass = ComponentStories(
    .foundations, "Glass", summary: "Frosted glass by role: what is under it, blurred and tinted. Only for overlays and chrome, over something to blur.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Core/UIElement+Modifiers.swift",
    args: [
      ArgType("material", .options(["all"] + ThemeMaterial.allCases.map { "\($0)" }), .option("popover"), "The material's role; all shows each."),
      ArgType("radius", .number(0 ... 24, step: 1), .number(10), "The corner radius."),
    ],
    stories: [Story("Popover", layout: .centered), Story("Every role", layout: .padded, ["material": .option("all")])],
    render: { args, _ in
      let backdrop = { (content: UIElement) -> UIElement in
        ZStack {
          Image("wallpaper", bundle: .module).resizable().scaledToFill().frame(width: 220, height: 130).clipped()
          content
        }
        .cornerRadius(8)
      }
      let card = { (role: ThemeMaterial) -> UIElement in
        backdrop(
          Text(".\(role)").font(.system(size: 13, weight: .medium))
            .frame(width: 150, height: 70)
            .glass(role, in: .rect(cornerRadius: args.float("radius")))
            .border(.separator, width: 0.5, in: .rect(cornerRadius: args.float("radius")))
        )
      }
      if args.option("material") == "all" {
        return gallery(columns: 4, ThemeMaterial.allCases.map(card))
      }
      let role = ThemeMaterial.allCases.first { "\($0)" == args.option("material") } ?? .popover
      return card(role)
    },
    snippet: { args in
      let role = args.option("material") == "all" ? "popover" : args.option("material")
      return "content\n  .glass(.\(role), in: .rect(cornerRadius: \(swiftNumber(args.number("radius")))))\n  .border(.separator, width: 0.5, in: .rect(cornerRadius: \(swiftNumber(args.number("radius")))))"
    }
  )

  static let icon = ComponentStories(
    .foundations, "Icon", summary: "The theme's glyphs, drawn as signed distance fields in any colour.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Theme/ThemeIcon.swift",
    args: [
      ArgType("icon", .options(["all"] + iconNames), .option("folder"), "Which glyph; all shows each."),
      ArgType("color", .options(roleNames + hueNames.map { "hue." + $0 }), .option("secondaryLabel"), "Its colour: a role or a hue."),
    ],
    stories: [Story("Folder", ["color": .option("hue.folder")]), Story("Every glyph", layout: .padded, ["icon": .option("all")])],
    render: { args, _ in
      let name = args.option("color")
      let color = name.hasPrefix("hue.") ? hue(named: String(name.dropFirst(4))) : role(named: name)
      if args.option("icon") == "all" {
        return gallery(columns: 9, ThemeIcon.allCases.map { icon in
          VStack(spacing: 6) {
            Image(icon: icon).foregroundColor(color)
            caption(".\(icon)")
          }
          .frame(width: 70)
        })
      }
      let icon = ThemeIcon.allCases.first { "\($0)" == args.option("icon") } ?? .folder
      return Image(icon: icon).foregroundColor(color)
    },
    snippet: { args in
      let name = args.option("color")
      let color = name.hasPrefix("hue.") ? ".hue(.\(name.dropFirst(4)))" : ".\(name)"
      return "Image(icon: .\(args.option("icon") == "all" ? "folder" : args.option("icon")))\n  .foregroundColor(\(color))"
    }
  )

  static let animatedIcon = ComponentStories(
    .foundations, "AnimatedIcon",
    summary: "Sixty-three glyphs on one spring, as the design template draws them: hover a tile, press it, click it to change state.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Renderable/AnimatedIcon.swift",
    args: [
      ArgType("show", .options(["glyph", "all", "toolbar", "sidebar", "search", "problems"]), .option("glyph"), "One glyph, every glyph, or glyphs in context."),
      ArgType("glyph", .options(AnimatedGlyph.allCases.map(\.rawValue)), .option("bell"), "Which glyph."),
      ArgType("active", .options(["none", "false", "true"]), .option("none"), "Its state; none leaves it unset."),
      ArgType("loop", .bool, .bool(false), "Loops its motion, where it has one."),
      ArgType("mount", .bool, .bool(false), "Plays its entrance as it appears."),
      ArgType("color", .options(roleNames + hueNames.map { "hue." + $0 }), .option("label"), "Its colour: a role or a hue."),
      ArgType("scale", .number(1...4, step: 0.5), .number(3), "Its size, times its box."),
      ArgType("speed", .number(0.25...1, step: 0.25), .number(1), "How fast it plays."),
    ],
    stories: [
      Story("Every glyph", layout: .padded, ["show": .option("all"), "scale": .number(2)]),
      Story("Bell", ["glyph": .option("bell"), "active": .option("true")]),
      Story("In a toolbar", layout: .padded, ["show": .option("toolbar")]),
      Story("In a sidebar", layout: .padded, ["show": .option("sidebar")]),
      Story("Search field", layout: .padded, ["show": .option("search")]),
      Story("Problems", layout: .padded, ["show": .option("problems"), "mount": .bool(true)]),
    ],
    render: { args, _ in
      let name = args.option("color")
      let color = name.hasPrefix("hue.") ? hue(named: String(name.dropFirst(4))) : role(named: name)
      let active: Bool? = args.option("active") == "none" ? nil : args.option("active") == "true"
      func icon(_ glyph: AnimatedGlyph, scale: Float) -> AnimatedIcon {
        // a click on its host changes a state it has, as a tile of the template does
        AnimatedIcon(glyph, trigger: glyph.isStateful ? .click : .hover, active: active, loop: args.bool("loop") || glyph == .spinner, mount: args.bool("mount"))
          .foregroundColor(color).scale(scale).speed(args.float("speed"))
      }
      switch args.option("show") {
      case "all":
        // Each in a row of its own, so hovering a tile plays its glyph.
        return gallery(columns: 9, AnimatedGlyph.allCases.map { glyph in
          ListRow(height: 64, margin: 0, content: {
            VStack(spacing: 6) {
              icon(glyph, scale: args.float("scale"))
              caption(glyph.rawValue)
            }
            .frame(width: 88)
          })
          .frame(width: 92)
        })
      case "toolbar":
        return HStack(spacing: 2) {
          Button { AnimatedIcon(.sidebarLeft, trigger: .click, active: false).scale(1.15) }.buttonStyle(.borderless)
          Button { AnimatedIcon(.chevronLeft).scale(1.3) }.buttonStyle(.borderless)
          Button { AnimatedIcon(.chevronRight).scale(1.3) }.buttonStyle(.borderless)
          Text("Renderer").font(.system(size: 13, weight: .semibold))
          Spacer().frame(width: 24)
          Button { AnimatedIcon(.splitRight, trigger: .click, active: false).scale(1.15).tint(.fill, .accent) }.buttonStyle(.borderless)
          Button { AnimatedIcon(.magnifier).scale(1.25) }.buttonStyle(.borderless)
          Button { AnimatedIcon(.playPause, trigger: .click, active: false).scale(1.15) }.buttonStyle(.borderless)
          Button { AnimatedIcon(.bell, trigger: .click, active: true).scale(1.15).tint(.badge, .destructive) }.buttonStyle(.borderless)
          Button { AnimatedIcon(.lock, trigger: .click, active: false).scale(1.15) }.buttonStyle(.borderless)
          Button { AnimatedIcon(.gear).scale(1.15) }.buttonStyle(.borderless)
        }
      case "sidebar":
        return VStack(spacing: 0) {
          ListRow("Sources", detail: "3", spacing: 5, content: {
            AnimatedIcon(.chevronRight, trigger: .click, active: true).foregroundColor(.secondaryLabel)
            AnimatedIcon(.folder, trigger: .click, active: true).foregroundColor(.hue(.folder))
          })
          ListRow("Renderer.swift", selected: true, indent: 26, spacing: 5, content: {
            AnimatedIcon(.swift).scale(0.9).foregroundColor(.secondaryLabel)
          })
          ListRow("Shaders.metal", indent: 26, spacing: 5, content: {
            AnimatedIcon(.langMetal).scale(0.9).foregroundColor(.secondaryLabel)
          })
          ListRow("Resources", detail: "12", spacing: 5, content: {
            AnimatedIcon(.chevronRight, trigger: .click, active: false).foregroundColor(.secondaryLabel)
            AnimatedIcon(.folder, trigger: .click, active: false).foregroundColor(.hue(.folder))
          })
        }
        .frame(width: 220)
      case "search":
        return VStack(alignment: .leading, spacing: 10) {
          TextField("Search files", text: "").leadingIcon(.magnifier).frame(width: 230)
          HStack(spacing: 8) {
            Button(role: .destructive) { AnimatedIcon(.trash); Text("Delete") }.buttonStyle(.bordered)
            Button { AnimatedIcon(.copyCheck, trigger: .click, active: false).tint(.check, .success); Text("Copy path") }.buttonStyle(.bordered)
            Button { AnimatedIcon(.refresh); Text("Refresh") }.buttonStyle(.bordered)
            Button { AnimatedIcon(.plus); Text("New file") }.buttonStyle(.borderedProminent)
          }
        }
      case "problems":
        return VStack(spacing: 0) {
          ListRow("Cannot find 'device' in scope", detail: "42", spacing: 6, content: {
            AnimatedIcon(.error, mount: args.bool("mount")).foregroundColor(.destructive)
          })
          ListRow("'scale' was never used", detail: "88", spacing: 6, content: {
            AnimatedIcon(.warning, loop: args.bool("loop"), mount: args.bool("mount")).foregroundColor(.warning)
          })
          ListRow("Metal 3 features available", detail: "1", spacing: 6, content: {
            AnimatedIcon(.note, mount: args.bool("mount")).foregroundColor(.accent)
          })
        }
        .frame(width: 300)
      default:
        let glyph = AnimatedGlyph(rawValue: args.option("glyph")) ?? .bell
        return ListRow(height: 72, margin: 0, content: { icon(glyph, scale: args.float("scale")) }).frame(width: 96)
      }
    },
    snippet: { args in
      let name = args.option("color")
      let color = name.hasPrefix("hue.") ? ".hue(.\(name.dropFirst(4)))" : ".\(name)"
      let glyph = args.option("show") == "glyph" ? args.option("glyph") : "bell"
      var arguments = ".\(glyph)"
      if args.option("active") != "none" { arguments += ", active: \(args.option("active"))" }
      if args.bool("loop") { arguments += ", loop: true" }
      if args.bool("mount") { arguments += ", mount: true" }
      return "AnimatedIcon(\(arguments))\n  .foregroundColor(\(color))" + (args.float("scale") == 1 ? "" : "\n  .scale(\(swiftNumber(args.number("scale"))))")
    }
  )

  static let divider = ComponentStories(
    .foundations, "Divider", summary: "A hairline between content: across a VStack, down an HStack.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Layout/Divider.swift",
    args: [ArgType("thickness", .number(0.5 ... 4, step: 0.5), .number(0.5), "Its thickness in points.")],
    stories: [Story("In a column")],
    render: { args, _ in
      VStack(spacing: 8) {
        Text("Above")
        Divider(thickness: args.float("thickness"))
        Text("Below")
      }
      .frame(width: 240)
    },
    snippet: { args in "Divider(thickness: \(swiftNumber(args.number("thickness"))))" }
  )

  static let scrollIndicator = ComponentStories(
    .foundations, "ScrollIndicator", summary: "A scroll view's bar, on its own: 5 points wide, capsule ended.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Layout/ScrollIndicator.swift",
    args: [
      ArgType("length", .number(20 ... 200, step: 10), .number(80), "Its length."),
      ArgType("vertical", .bool, .bool(true), "Up and down, or across."),
    ],
    stories: [Story("Vertical"), Story("Horizontal", ["vertical": .bool(false)])],
    render: { args, _ in ScrollIndicator(length: args.float("length"), vertical: args.bool("vertical")) },
    snippet: { args in "ScrollIndicator(length: \(swiftNumber(args.number("length"))), vertical: \(args.bool("vertical")))" }
  )

  static let themeScope = ComponentStories(
    .foundations, "ColorScheme", web: "MGRoot", summary: "A subtree drawn light or dark whatever its window is: .colorScheme(_:), or .theme(_:) for a theme of its own.",
    source: "Sources/MetalGraphicsLib/RetainedModeUI/Theme/ThemeScope.swift",
    args: [ArgType("appearance", .options(["light", "dark"]), .option("dark"), "What the card is drawn in.")],
    stories: [Story("A dark card"), Story("A light card", ["appearance": .option("light")])],
    render: { args, _ in
      let appearance: Appearance = args.option("appearance") == "light" ? .light : .dark
      return VStack(alignment: .leading, spacing: 8) {
        Text("Scoped").font(.system(size: 13, weight: .semibold))
        Text("Drawn in \(args.option("appearance")), whatever the window shows.").foregroundColor(.secondaryLabel)
        Button("Button") {}.buttonStyle(.borderedProminent)
      }
      .padding(16)
      .background(.card, in: .rect(cornerRadius: 10))
      .border(.separator, width: 0.5, in: .rect(cornerRadius: 10))
      .colorScheme(appearance)
    },
    snippet: { args in "card\n  .colorScheme(.\(args.option("appearance")))" }
  )
}

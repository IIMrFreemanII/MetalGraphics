import MetalGraphicsLib
import simd

enum FoundationStories {
  static let all: [ComponentStories] = [colors, palette, typography, glass, icon, divider, scrollIndicator, themeScope]

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

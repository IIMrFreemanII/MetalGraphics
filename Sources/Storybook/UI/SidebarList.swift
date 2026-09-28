import MetalGraphicsLib
import simd

/// The sidebar's stories: a title per group, a row per component that opens and closes, and a
/// row per story under an open one, the shown one selected. Filtered by the search: a component
/// matching it shows all its stories, a story matching it shows under its component.
final class SidebarList : ModelWatcher {
  static let storyIndent: Float = 18
  static let font = TextFont.system(size: 13)

  override var watched: [String] { ["search", "expanded", "selection"] }

  override init() {
    super.init()
    self.child = self.make()
  }

  override func update(_ token: Int, _ context: UIContext) {
    self.show(self.make(), context)
  }

  private func make() -> UIElement {
    let model = self.model
    let catalog = StoryRegistry.catalog()
    let query = model.search.trimmingCharacters(in: .whitespaces).lowercased()
    var rows: [UIElement] = []
    for group in StoryGroup.allCases {
      var groupRows: [UIElement] = []
      for component in catalog.components where component.group == group {
        let componentMatches = query.isEmpty || component.name.lowercased().contains(query)
        let stories = component.stories.filter { componentMatches || $0.name.lowercased().contains(query) }
        guard !stories.isEmpty else { continue }
        let open = !query.isEmpty || model.expanded.contains(component.name)
        let name = component.name
        groupRows.append(
          ListRow(name, height: NavigationMetrics.sidebarRowHeight, margin: 0, action: {
            if model.expanded.contains(name) { model.expanded.remove(name) } else { model.expanded.insert(name) }
          }, content: {
            Image(icon: open ? .chevronDown : .chevronRight).foregroundColor(.secondaryLabel)
          })
        )
        guard open else { continue }
        for story in stories {
          let id = component.id(of: story)
          groupRows.append(
            ListRow(story.name, selected: id == model.selection, height: NavigationMetrics.sidebarRowHeight, margin: 0, indent: Self.storyIndent, action: {
              model.select(id, in: StoryRegistry.catalog())
            })
          )
        }
      }
      guard !groupRows.isEmpty else { continue }
      rows.append(SidebarTitle(group.rawValue).padding(Inset(top: rows.isEmpty ? 0 : 8)))
      rows.append(contentsOf: groupRows)
    }
    if rows.isEmpty {
      rows.append(Text("No stories match “\(model.search)”").font(.system(size: 12)).foregroundColor(.secondaryLabel).padding(10))
    }
    let column = VStack(alignment: .leading, spacing: 0) { () -> [UIElement] in return rows }
    return ScrollView(.vertical) {
      column
        .font(Self.font)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

import MetalGraphicsLib

/// Every component with stories. Add a component's `ComponentStories` to its group's list; the
/// sidebar, the canvas, Controls, Docs and the tests pick it up.
enum StoryRegistry {
  static func catalog() -> StoryCatalog {
    StoryCatalog(components:
      FoundationStories.all + ControlStories.all + PickerStories.all + ListStories.all + FormStories.all
        + SurfaceStories.all + NavigationStories.all + DockingStories.all + WindowStories.all + EditorStories.all
    )
  }
}

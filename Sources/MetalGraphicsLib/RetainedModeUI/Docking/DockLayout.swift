import Foundation
import simd

// The docking layout as a value: which panels are where, in every window a `DockSpace` spans.
//
// A window's dock area is a *host*. Its docked content is a tree of splits whose leaves are tab
// groups; over it float more trees, each at its own frame. A host is either placed by the app
// (`DockArea(space, host:)` in some window's tree) or *detached*: a window of its own, opened and
// closed by `DockWindows` as the host comes and goes.
//
// Every change is one `move` or a small edit, then `normalize`, which keeps the tree minimal:
// no empty groups, no split of one, no split directly inside a split of the same axis.

/// How a split lays its children out: `.horizontal` side by side, `.vertical` one above another.
public enum DockAxis: String, Codable, Sendable {
  case horizontal, vertical
}

/// Where on a tab group a drop lands: its middle joins the group as a tab; an edge splits the
/// group's area and puts what is dropped on that side.
public enum DockZone: String, Codable, Sendable, CaseIterable {
  case center, left, right, top, bottom

  var axis: DockAxis? {
    switch self {
    case .center: nil
    case .left, .right: .horizontal
    case .top, .bottom: .vertical
    }
  }

  /// Whether what is dropped goes before what it is dropped on.
  var isLeading: Bool { self == .left || self == .top }
}

/// A rect in points, top left origin, y down.
public struct DockRect: Codable, Sendable, Equatable {
  public var x: Float
  public var y: Float
  public var width: Float
  public var height: Float

  public init(x: Float, y: Float, width: Float, height: Float) {
    self.x = x
    self.y = y
    self.width = width
    self.height = height
  }

  public init(origin: float2, size: float2) {
    self.init(x: origin.x, y: origin.y, width: size.x, height: size.y)
  }

  public var origin: float2 {
    get { float2(self.x, self.y) }
    set { self.x = newValue.x; self.y = newValue.y }
  }

  public var size: float2 {
    get { float2(self.width, self.height) }
    set { self.width = newValue.x; self.height = newValue.y }
  }

  func contains(_ point: float2) -> Bool {
    point.x >= self.x && point.y >= self.y && point.x < self.x + self.width && point.y < self.y + self.height
  }
}

/// A group of panels shown one at a time, under a bar of their tabs.
public struct DockTabs: Codable, Sendable, Equatable {
  public var id: String
  public var panels: [String]
  public var selected: String?

  /// The panel shown: `selected` when it is one of `panels`, else the first.
  public var shown: String? {
    if let selected, self.panels.contains(selected) { return selected }
    return self.panels.first
  }
}

/// Children side by side or stacked, each taking its fraction of the space.
public struct DockSplit: Codable, Sendable, Equatable {
  public var id: String
  public var axis: DockAxis
  public var children: [DockNode]
  /// One per child, summing to 1.
  public var fractions: [Float]
}

public indirect enum DockNode: Codable, Sendable, Equatable {
  case tabs(DockTabs)
  case split(DockSplit)

  public var id: String {
    switch self {
    case .tabs(let tabs): tabs.id
    case .split(let split): split.id
    }
  }

  /// Every panel in it, in order.
  public var panels: [String] {
    switch self {
    case .tabs(let tabs): tabs.panels
    case .split(let split): split.children.flatMap(\.panels)
    }
  }

  /// A tab group of `panels`, showing `selected`, or the first.
  public static func group(_ panels: [String], selected: String? = nil) -> DockNode {
    .tabs(DockTabs(id: DockLayout.newID(), panels: panels, selected: selected ?? panels.first))
  }

  /// `children` side by side, with `fractions` of the width, or equal ones.
  public static func row(_ children: [DockNode], fractions: [Float]? = nil) -> DockNode {
    .split(DockSplit(id: DockLayout.newID(), axis: .horizontal, children: children,
                     fractions: fractions ?? DockLayout.equal(children.count)))
  }

  /// `children` one above another, with `fractions` of the height, or equal ones.
  public static func column(_ children: [DockNode], fractions: [Float]? = nil) -> DockNode {
    .split(DockSplit(id: DockLayout.newID(), axis: .vertical, children: children,
                     fractions: fractions ?? DockLayout.equal(children.count)))
  }

  func find(_ id: String) -> DockNode? {
    if self.id == id { return self }
    guard case .split(let split) = self else { return nil }
    for child in split.children {
      if let found = child.find(id) { return found }
    }
    return nil
  }

  /// The tab group holding `panel`.
  func tabs(holding panel: String) -> DockTabs? {
    switch self {
    case .tabs(let tabs): return tabs.panels.contains(panel) ? tabs : nil
    case .split(let split):
      for child in split.children {
        if let found = child.tabs(holding: panel) { return found }
      }
      return nil
    }
  }
}

/// A tree floating over a host's docked content, at `frame` in the host's area.
public struct DockFloat: Codable, Sendable, Equatable {
  /// Its own, kept while what it holds changes: docking onto its edge wraps its tree in a new
  /// split, and it is still the same float.
  public var id: String
  public var node: DockNode
  public var frame: DockRect

  public init(id: String = DockLayout.newID(), node: DockNode, frame: DockRect) {
    self.id = id
    self.node = node
    self.frame = frame
  }
}

/// One dock area: what is docked in it, and what floats over it.
public struct DockHost: Codable, Sendable, Equatable {
  public var id: String
  public var root: DockNode?
  /// Bottom first: the last is drawn on top.
  public var floating: [DockFloat]
  /// A window of its own, which `DockWindows` opens; else placed by the app.
  public var isDetached: Bool
  /// Where a detached host's window is, in screen points, AppKit's bottom left origin. Nil until
  /// the window is first placed.
  public var screenFrame: DockRect?

  public init(id: String, root: DockNode?, floating: [DockFloat] = [], isDetached: Bool = false, screenFrame: DockRect? = nil) {
    self.id = id
    self.root = root
    self.floating = floating
    self.isDetached = isDetached
    self.screenFrame = screenFrame
  }

  var isEmpty: Bool { self.root == nil && self.floating.isEmpty }

  /// Everything in it as one tree: the docked content, else the one float, else a row of all.
  var combined: DockNode? {
    let nodes = (self.root.map { [$0] } ?? []) + self.floating.map(\.node)
    switch nodes.count {
    case 0: return nil
    case 1: return nodes[0]
    default: return .row(nodes)
    }
  }

  func find(_ id: String) -> DockNode? {
    if let found = self.root?.find(id) { return found }
    for float in self.floating {
      if let found = float.node.find(id) { return found }
    }
    return nil
  }
}

public struct DockPanelInfo: Codable, Sendable, Equatable {
  /// The `DockPanelKind` it is made by.
  public var kind: String
  public var title: String
  /// Its `DockPanel.storage`, encoded.
  public var storage: String

  public init(kind: String, title: String, storage: String = "") {
    self.kind = kind
    self.title = title
    self.storage = storage
  }
}

/// How detached windows look.
public enum DockWindowStyle: String, Codable, Sendable {
  /// A standard window with the system's title bar.
  case native
  /// No system title bar: the dock area draws its own, and dragging it docks the whole window.
  case custom
}

/// What a drag picks up.
public enum DockSource: Equatable, Sendable {
  /// One panel, out of its tab group.
  case panel(String)
  /// A tab group or a split, with all it holds.
  case node(String)
  /// A whole host: everything docked and floating in it.
  case host(String)
}

/// Where it lands.
public enum DockTarget: Equatable, Sendable {
  /// On the tab group or split `id`: its middle (tab groups only) or an edge.
  case node(String, DockZone)
  /// Along an edge of a host's docked content: the whole of it moves over.
  case hostEdge(String, DockZone)
  /// Floating over a host, at `frame` in its area.
  case float(String, DockRect)
  /// In a detached host of its own, `id`: a new window.
  case newHost(String)
}

public struct DockLayout: Codable, Sendable, Equatable {
  public var hosts: [DockHost]
  public var panels: [String: DockPanelInfo]
  public var windowStyle: DockWindowStyle

  public init(hosts: [DockHost] = [], panels: [String: DockPanelInfo] = [:], windowStyle: DockWindowStyle = .native) {
    self.hosts = hosts
    self.panels = panels
    self.windowStyle = windowStyle
  }

  public static func newID() -> String {
    String(UUID().uuidString.prefix(8)).lowercased()
  }

  static func equal(_ count: Int) -> [Float] {
    count == 0 ? [] : [Float](repeating: 1 / Float(count), count: count)
  }

  /// Registers a panel of `kind`, titled `title`, placed nowhere yet. Returns its id.
  @discardableResult
  public mutating func addPanel(kind: String, title: String, id: String = DockLayout.newID()) -> String {
    self.panels[id] = DockPanelInfo(kind: kind, title: title)
    return id
  }

  /// The float `id`, and the host it floats over.
  public func float(_ id: String) -> (host: DockHost, float: DockFloat)? {
    for host in self.hosts {
      if let float = host.floating.first(where: { $0.id == id }) { return (host, float) }
    }
    return nil
  }

  /// What a host's window is titled: the panel it shows, or how many it holds.
  public func title(ofHost id: String) -> String {
    guard let host = self.host(id) else { return "" }
    if host.floating.isEmpty, let root = host.root, case .tabs(let tabs) = root, let shown = tabs.shown,
       let title = self.panels[shown]?.title {
      return title
    }
    let count = host.combined?.panels.count ?? 0
    return count == 1 ? (host.combined?.panels.first.flatMap { self.panels[$0]?.title } ?? "") : "\(count) panels"
  }

  public func host(_ id: String) -> DockHost? {
    self.hosts.first { $0.id == id }
  }

  func hostIndex(_ id: String) -> Int? {
    self.hosts.firstIndex { $0.id == id }
  }

  /// The host holding node or panel `id`.
  public func host(containing id: String) -> DockHost? {
    self.hosts.first { host in
      host.find(id) != nil || host.combined?.panels.contains(id) == true
    }
  }

  public func node(_ id: String) -> DockNode? {
    for host in self.hosts {
      if let found = host.find(id) { return found }
    }
    return nil
  }

  /// The tab group holding `panel`.
  public func tabs(holding panel: String) -> DockTabs? {
    for host in self.hosts {
      if let found = host.root?.tabs(holding: panel) { return found }
      for float in host.floating {
        if let found = float.node.tabs(holding: panel) { return found }
      }
    }
    return nil
  }

  // MARK: - Moving

  /// Takes `source` out of where it is and puts it at `target`. Returns the id of the node that
  /// moved — for a panel, the new tab group made for it — or nil when nothing did: the source
  /// or the target does not exist, or the target is inside the source.
  @discardableResult
  public mutating func move(_ source: DockSource, to target: DockTarget) -> String? {
    guard self.targetExists(target), !self.target(target, isInside: source) else { return nil }
    var copy = self
    guard let node = copy.extract(source) else { return nil }
    // The extracted node may have left its host empty; the target is looked up again after.
    guard copy.insert(node, at: target) else { return nil }
    copy.normalize()
    self = copy
    return node.id
  }

  private func targetExists(_ target: DockTarget) -> Bool {
    switch target {
    case .node(let id, _): return self.node(id) != nil
    case .hostEdge(let id, _), .float(let id, _): return self.host(id) != nil
    case .newHost(let id): return self.host(id) == nil
    }
  }

  /// Whether `target` would land inside what `source` takes away.
  private func target(_ target: DockTarget, isInside source: DockSource) -> Bool {
    let targetNode: String? = switch target {
    case .node(let id, _): id
    default: nil
    }
    switch source {
    case .panel(let panel):
      // Dropping a panel on its own group's middle or edge is fine, unless it is all the group
      // holds: then the group goes away with it.
      guard let targetNode, let tabs = self.tabs(holding: panel), tabs.id == targetNode else { return false }
      return tabs.panels.count == 1
    case .node(let id):
      guard let targetNode, let node = self.node(id) else { return false }
      return node.find(targetNode) != nil
    case .host(let id):
      switch target {
      case .node(let node, _): return self.host(id)?.find(node) != nil
      case .hostEdge(let host, _), .float(let host, _): return host == id
      case .newHost: return false
      }
    }
  }

  /// Removes `source` from the layout and returns it as one tree. Leaves empty groups and
  /// splits of one behind, for `normalize`.
  private mutating func extract(_ source: DockSource) -> DockNode? {
    switch source {
    case .panel(let panel):
      guard self.panels[panel] != nil, self.tabs(holding: panel) != nil else { return nil }
      self.editTabs { tabs in
        tabs.panels.removeAll { $0 == panel }
      }
      return .group([panel])

    case .node(let id):
      for h in self.hosts.indices {
        if self.hosts[h].root?.id == id {
          defer { self.hosts[h].root = nil }
          return self.hosts[h].root
        }
        if let f = self.hosts[h].floating.firstIndex(where: { $0.node.id == id }) {
          return self.hosts[h].floating.remove(at: f).node
        }
        if let root = self.hosts[h].root, let (node, rest) = Self.remove(id, from: root) {
          self.hosts[h].root = rest
          return node
        }
        for f in self.hosts[h].floating.indices {
          if let (node, rest) = Self.remove(id, from: self.hosts[h].floating[f].node) {
            // `rest` is never nil here: the float's own root was matched above.
            if let rest { self.hosts[h].floating[f].node = rest }
            return node
          }
        }
      }
      return nil

    case .host(let id):
      guard let index = self.hostIndex(id) else { return nil }
      let host = self.hosts[index]
      self.hosts[index].root = nil
      self.hosts[index].floating = []
      return host.combined
    }
  }

  /// `root` without node `id`, and that node. Nil when `id` is not below `root`.
  private static func remove(_ id: String, from root: DockNode) -> (DockNode, DockNode?)? {
    guard case .split(var split) = root else { return nil }
    for i in split.children.indices {
      if split.children[i].id == id {
        let node = split.children.remove(at: i)
        split.fractions.remove(at: i)
        return (node, .split(split))
      }
      if let (node, rest) = Self.remove(id, from: split.children[i]) {
        split.children[i] = rest!
        return (node, .split(split))
      }
    }
    return nil
  }

  private mutating func insert(_ node: DockNode, at target: DockTarget) -> Bool {
    switch target {
    case .node(let id, let zone):
      var inserted = false
      self.editNodes { current in
        guard !inserted, current.id == id else { return nil }
        inserted = true
        return Self.dock(node, onto: current, zone)
      }
      return inserted

    case .hostEdge(let id, let zone):
      guard let index = self.hostIndex(id) else { return false }
      if let root = self.hosts[index].root, zone != .center {
        self.hosts[index].root = Self.dock(node, onto: root, zone, fraction: 0.3)
      } else if let root = self.hosts[index].root {
        self.hosts[index].root = Self.dock(node, onto: root, .center)
      } else {
        self.hosts[index].root = node
      }
      return true

    case .float(let id, let frame):
      guard let index = self.hostIndex(id) else { return false }
      self.hosts[index].floating.append(DockFloat(node: node, frame: frame))
      return true

    case .newHost(let id):
      self.hosts.append(DockHost(id: id, root: node, isDetached: true))
      return true
    }
  }

  /// `target` with `node` docked on it: `node`'s panels added as tabs for the middle, else the
  /// two side by side or stacked, `node` taking `fraction` of the space.
  private static func dock(_ node: DockNode, onto target: DockNode, _ zone: DockZone, fraction: Float = 0.5) -> DockNode {
    guard let axis = zone.axis else {
      switch target {
      case .tabs(var tabs):
        let added = node.panels.filter { !tabs.panels.contains($0) }
        tabs.panels += added
        tabs.selected = added.first ?? tabs.selected
        return .tabs(tabs)
      case .split(var split):
        // Only tab groups take a middle drop; a split takes it on its first group.
        split.children[0] = dock(node, onto: split.children[0], .center)
        return .split(split)
      }
    }
    // Into a split of the same axis: one more child, cut from the target's share. The split
    // itself is the target when docking along a whole split's edge.
    if case .split(var split) = target, split.axis == axis {
      let share = fraction
      split.fractions = split.fractions.map { $0 * (1 - share) }
      if zone.isLeading {
        split.children.insert(node, at: 0)
        split.fractions.insert(share, at: 0)
      } else {
        split.children.append(node)
        split.fractions.append(share)
      }
      return .split(split)
    }
    let children = zone.isLeading ? [node, target] : [target, node]
    let fractions = zone.isLeading ? [fraction, 1 - fraction] : [1 - fraction, fraction]
    return .split(DockSplit(id: newID(), axis: axis, children: children, fractions: fractions))
  }

  // MARK: - Edits

  /// Puts `node` — new panels from `addPanel`, as a group — at `target`, as a drop there would.
  /// Returns whether the target exists.
  @discardableResult
  public mutating func place(_ node: DockNode, at target: DockTarget) -> Bool {
    guard self.targetExists(target), self.insert(node, at: target) else { return false }
    self.normalize()
    return true
  }

  /// Takes `panel` out of the layout for good.
  public mutating func close(panel: String) {
    self.editTabs { tabs in
      tabs.panels.removeAll { $0 == panel }
    }
    self.panels[panel] = nil
    self.normalize()
  }

  /// Takes a host and every panel in it out of the layout.
  public mutating func close(host id: String) {
    guard let index = self.hostIndex(id) else { return }
    let host = self.hosts.remove(at: index)
    for panel in host.combined?.panels ?? [] {
      self.panels[panel] = nil
    }
    self.normalize()
  }

  /// Shows `panel` in its tab group.
  public mutating func select(panel: String) {
    self.editTabs { tabs in
      if tabs.panels.contains(panel) { tabs.selected = panel }
    }
  }

  public mutating func setFractions(_ fractions: [Float], of split: String) {
    self.editNodes { node in
      guard case .split(var s) = node, s.id == split, s.fractions.count == fractions.count else { return nil }
      s.fractions = fractions
      return .split(s)
    }
  }

  /// Moves float `id` to `frame`, and to the top.
  public mutating func setFrame(_ frame: DockRect, ofFloat id: String) {
    for h in self.hosts.indices {
      guard let f = self.hosts[h].floating.firstIndex(where: { $0.id == id }) else { continue }
      var float = self.hosts[h].floating.remove(at: f)
      float.frame = frame
      self.hosts[h].floating.append(float)
      return
    }
  }

  /// Applies `edit` to every tab group, where `edit` returns whether it changed the group.
  private mutating func editTabs(_ edit: (inout DockTabs) -> Void) {
    self.editNodes { node in
      guard case .tabs(var tabs) = node else { return nil }
      let before = tabs
      edit(&tabs)
      return tabs == before ? nil : .tabs(tabs)
    }
  }

  /// Walks every node, top down; where `edit` returns a node, it replaces the one it was given,
  /// and the walk does not go into it.
  private mutating func editNodes(_ edit: (DockNode) -> DockNode?) {
    func walk(_ node: DockNode) -> DockNode {
      if let replaced = edit(node) { return replaced }
      guard case .split(var split) = node else { return node }
      split.children = split.children.map(walk)
      return .split(split)
    }
    for h in self.hosts.indices {
      if let root = self.hosts[h].root {
        self.hosts[h].root = walk(root)
      }
      for f in self.hosts[h].floating.indices {
        self.hosts[h].floating[f].node = walk(self.hosts[h].floating[f].node)
      }
    }
  }

  // MARK: - Normalizing

  /// Drops empty tab groups, floats and detached hosts; replaces a split of one by its child and
  /// flattens a split into its parent of the same axis; rescales fractions to sum to 1; keeps
  /// each group's selection on one of its panels; forgets panels placed nowhere.
  public mutating func normalize() {
    for h in self.hosts.indices {
      self.hosts[h].root = self.hosts[h].root.flatMap(Self.normalized)
      self.hosts[h].floating = self.hosts[h].floating.compactMap { float in
        Self.normalized(float.node).map { DockFloat(id: float.id, node: $0, frame: float.frame) }
      }
    }
    self.hosts.removeAll { $0.isDetached && $0.isEmpty }

    var placed = Set<String>()
    for host in self.hosts {
      host.root.map { placed.formUnion($0.panels) }
      for float in host.floating {
        placed.formUnion(float.node.panels)
      }
    }
    self.panels = self.panels.filter { placed.contains($0.key) }
  }

  private static func normalized(_ node: DockNode) -> DockNode? {
    switch node {
    case .tabs(var tabs):
      guard !tabs.panels.isEmpty else { return nil }
      tabs.selected = tabs.shown
      return .tabs(tabs)

    case .split(let split):
      var children: [DockNode] = []
      var fractions: [Float] = []
      for (child, fraction) in zip(split.children, split.fractions) {
        guard let child = normalized(child) else { continue }
        if case .split(let inner) = child, inner.axis == split.axis {
          children += inner.children
          fractions += inner.fractions.map { $0 * fraction }
        } else {
          children.append(child)
          fractions.append(fraction)
        }
      }
      switch children.count {
      case 0: return nil
      case 1: return children[0]
      default:
        let total = fractions.reduce(0, +)
        let scaled = total > 0 ? fractions.map { $0 / total } : equal(children.count)
        return .split(DockSplit(id: split.id, axis: split.axis, children: children, fractions: scaled))
      }
    }
  }
}

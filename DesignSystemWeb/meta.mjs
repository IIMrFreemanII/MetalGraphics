// What the design-system project says about each component: its README index and its
// api/components/<Name>.md card. `swift` is the type it mirrors, so a design that uses it can be
// built in MetalGraphics with the same thing.

export const namespace = "mg";
export const global = "MG";

export const components = [
  {
    name: "MGRoot",
    group: "Foundations",
    swift: "ThemeStore (Theme.light / Theme.dark); .colorScheme(_:) / .theme(_:) for a subtree",
    summary: "Wrap every artboard's content in it. Picks light or dark, sets JetBrains Mono (with its ligatures) and the label colour, and can paint a surface.",
    props: [
      ["mode", `"light" | "dark" | "system"`, `"system" follows the viewer's appearance.`],
      ["surface", `"content" | "grouped" | "window" | "card" | "none"`, "The opaque background under the content."],
    ],
    jsx: "<MGRoot mode=\"light\" surface=\"window\">\n  <Button variant=\"prominent\">Run</Button>\n</MGRoot>",
  },
  {
    name: "Glass",
    group: "Foundations",
    swift: ".glass(ThemeMaterial) — Background.swift GlassBackground",
    summary: "Frosted glass by role: the backdrop blurred and saturated under the role's tint, with a light rim along the top. Only shows over something.",
    props: [
      ["role", `"popover" | "menu" | "tooltip" | "sheet" | "floatingPanel" | "dropMarker" | "bar"`, "Which material."],
      ["radius", "number", "Corner radius in px (use 10 for cards and popovers, 12 for sheets)."],
    ],
    jsx: "<Glass role=\"floatingPanel\" radius={10} style={{ padding: 12 }}>\n  <LabeledContent label=\"Line\" value=\"42\" />\n</Glass>",
  },
  {
    name: "Icon",
    group: "Foundations",
    swift: "ThemeIcon, Image(icon:)",
    summary: "The design system's glyphs at their natural size, in the text colour or a role.",
    props: [
      ["name", `"chevronRight" | "chevronDown" | "chevronLeft" | "upDown" | "checkmark" | "folder" | "document" | "magnifier" | "xmark"`, "Which glyph."],
      ["color", "colour role name", `e.g. "secondaryLabel". The text colour when left out.`],
    ],
    jsx: "<Icon name=\"folder\" color=\"secondaryLabel\" />",
  },
  {
    name: "AnimatedIcon",
    group: "Foundations",
    swift: "AnimatedIcon, AnimatedGlyph",
    summary: "Sixty-three animated glyphs, as the Claude Design template \"Animated icons\" draws them: each in its own box (the static icon's size at scale 1), in the text colour or a role, on one spring. The pointer on its host (the button, link or row it sits in, or an element marked `data-icon-host`) plays it: a one-shot as it enters, a pose held while it stays, a squash while pressed. `active` holds a state (a chevron turned, a folder open, a lock undone, a bell badged); left out, the glyph has none (the checkmark drawn, sort unsorted). `loop` repeats a motion (the gear, the bell, a warning); `mount` plays an entrance (a problem's icon appearing). Every component draws its glyphs with it (a disclosure's chevron, a pop-up's arrows, checks, a stepper's keys, a tab's document and close cross), and an `icon` prop given a static name draws the animated glyph of that name. Documents carry their type: `swift`, `fileImage`… `fileFont`, and a language's badge, `langJS`… `langShell`.",
    props: [
      ["glyph", `"chevronRight" | "chevronDown" | "chevronLeft" | "upDown" | "checkmark" | "folder" | "document" | "magnifier" | "xmark" | "plus" | "trash" | "gear" | "searchClear" | "spinner" | "copyCheck" | "bell" | "lock" | "eye" | "playPause" | "refresh" | "menuX" | "warning" | "error" | "note" | "pin" | "sort" | "stepperMinus" | "stepperPlus" | "splitRight" | "splitBottom" | "splitLeft" | "splitTop" | "sidebarLeft" | "sidebarRight" | "swift" | "fileImage" | "fileVideo" | "fileAudio" | "fileArchive" | "fileCode" | "fileJSON" | "fileSheet" | "filePDF" | "fileFont" | "langJS" | "langTS" | "langPY" | "langRS" | "langGO" | "langC" | "langCPP" | "langRB" | "langKT" | "langJava" | "langMetal" | "langShell" | "calendar" | "clock" | "color" | "slider" | "toggle" | "code" | "dock"`, "Which glyph."],
      ["active", "boolean", "Its state: true or false. Left out, it has none."],
      ["trigger", `"hover" | "click" | "none"`, `"click": a click on the host toggles \`active\` too; "none": the host's pointer does nothing.`],
      ["loop", "boolean", "Repeats its motion, where it has one."],
      ["mount", "boolean", "Plays its entrance as it appears."],
      ["replay", "number", "A changed value plays the entrance again."],
      ["scale", "number", "Its size is its box times this: 1 by default, 1.15 to 1.3 in a toolbar."],
      ["size", "number", "Fits its box's longer side to this many pixels, instead of scale."],
      ["color", "colour role or hue name", `e.g. "secondaryLabel", "accent", "folder". The text colour when left out.`],
      ["fill | badge | check | swift | fileType", "colour role or hue name", "Colours for its tintable parts: a split's or the dock's fill, the bell's badge, the copied check, the Swift bird, a document's type."],
      ["speed", "number", "Motion speed, 1 by default."],
      ["label", "string", "An accessible name; without it the glyph is hidden from assistive tech."],
    ],
    jsx: "<ListRow label=\"Sources\" detail=\"3\">\n  <AnimatedIcon glyph=\"chevronRight\" active={open} color=\"secondaryLabel\" />\n  <AnimatedIcon glyph=\"folder\" active={open} color=\"folder\" />\n</ListRow>\n<Button variant=\"plain\" label=\"Notifications\"><AnimatedIcon glyph=\"bell\" active scale={1.15} badge=\"destructive\" /></Button>",
  },
  {
    name: "Divider",
    group: "Foundations",
    swift: "Divider",
    summary: "A 1 pt separator line.",
    props: [["vertical", "boolean", "Vertical instead of horizontal."]],
    jsx: "<Divider />",
  },
  {
    name: "ScrollIndicator",
    group: "Foundations",
    swift: "ScrollIndicator (Layout/ScrollIndicator.swift); a ScrollView draws its own",
    summary: "A scroll bar thumb: 5 thick, square ends, placed 2 from the edge.",
    props: [
      ["length", "number", "Length in px, at least 20."],
      ["vertical", "boolean", "Default true."],
    ],
    jsx: "<ScrollIndicator length={80} style={{ position: \"absolute\", right: 2, top: 8 }} />",
  },
  {
    name: "Button",
    group: "Controls",
    swift: "Button with .buttonStyle(.borderless / .plain / .bordered / .borderedProminent), role: .destructive",
    summary: "Borderless (an accent label, the default), plain, bordered (a fill) or prominent (the accent). Hover, pressed and disabled follow the Swift faces.",
    props: [
      ["variant", `"borderless" | "plain" | "bordered" | "prominent"`, "The style."],
      ["destructive", "boolean", "The destructive red."],
      ["icon", "Icon name", "A glyph before the label."],
      ["label", "string", "Accessible name, for an icon-only button."],
      ["disabled", "boolean", "Dims to 0.4."],
      ["state", `"hover" | "pressed" | "disabled"`, "Draw a state without a pointer, for specs."],
    ],
    jsx: "<div style={{ display: \"flex\", gap: 8 }}>\n  <Button variant=\"bordered\">Cancel</Button>\n  <Button variant=\"prominent\">Run</Button>\n  <Button variant=\"prominent\" destructive>Delete</Button>\n</div>",
  },
  {
    name: "Toggle",
    group: "Controls",
    swift: "Toggle",
    summary: "A 38 × 22 switch; the accent when on, the knob sliding over 0.18 s.",
    props: [
      ["defaultOn / isOn", "boolean", "Uncontrolled / controlled."],
      ["label", "string", "Accessible name."],
      ["state", `"disabled"`, ""],
    ],
    jsx: "<Toggle defaultOn label=\"Show line numbers\" />",
  },
  {
    name: "TextField",
    group: "Controls",
    swift: "TextField, SecureField, .leadingIcon",
    summary: "A single-line field on the control background with a 0.5 pt border; focused shows a 3.5 pt focus ring.",
    props: [
      ["placeholder", "string", ""],
      ["defaultValue / value", "string", ""],
      ["icon", "Icon name", `A leading glyph, e.g. "magnifier" for search.`],
      ["secure", "boolean", "A password field."],
      ["width", "number", "Default 180 (240 in a form row)."],
      ["state", `"focused" | "disabled"`, ""],
    ],
    jsx: "<TextField icon=\"magnifier\" placeholder=\"Search\" width={220} />",
  },
  {
    name: "Picker",
    group: "Controls",
    swift: "Picker with .pickerStyle(.menu / .segmented / .inline), .menuIndicator(.hidden)",
    summary: "A pop-up button with the accent up-down tile, a segmented control, or inline rows with a check.",
    props: [
      ["chevrons", "boolean", "Default true. false gives the plain pill a date picker uses."],

      ["options", "string[]", ""],
      ["defaultSelection / selection", "string", ""],
      ["pickerStyle", `"menu" | "segmented" | "inline"`, "Default menu. Show the open menu with Menu."],
      ["label", "string", "Accessible name."],
    ],
    jsx: "<Picker pickerStyle=\"segmented\" options={[\"Day\", \"Week\", \"Month\"]} defaultSelection=\"Week\" label=\"Range\" />",
  },
  {
    name: "Slider",
    group: "Controls",
    swift: "Slider",
    summary: "A 4 pt track, the accent up to an 18 pt knob.",
    props: [
      ["defaultValue / value", "number", "0…1 unless min and max say otherwise."],
      ["min, max", "number", ""],
      ["width", "number", "Default 180."],
    ],
    jsx: "<Slider defaultValue={0.4} label=\"Volume\" />",
  },
  {
    name: "ProgressView",
    group: "Controls",
    swift: "ProgressView(value:)",
    summary: "A 6 pt capsule filled with the accent.",
    props: [["value", "number", "0…1."], ["width", "number", "Default 180."]],
    jsx: "<ProgressView value={0.6} label=\"Indexing\" />",
  },
  {
    name: "Stepper",
    group: "Controls",
    swift: "Stepper",
    summary: "− and + keys; a key at the end of the range dims to 0.3.",
    props: [["defaultValue / value", "number", ""], ["min, max, step", "number", ""]],
    jsx: "<Stepper defaultValue={4} min={0} max={8} label=\"Tab width\" />",
  },
  {
    name: "DisclosureGroup",
    group: "Controls",
    swift: "DisclosureGroup",
    summary: "A label with a chevron that turns down and shows its content.",
    props: [["label", "string", ""], ["defaultExpanded / isExpanded", "boolean", ""]],
    jsx: "<DisclosureGroup label=\"Advanced\" defaultExpanded>\n  <LabeledContent label=\"Configuration\" value=\"Debug\" />\n</DisclosureGroup>",
  },
  {
    name: "LabeledContent",
    group: "Controls",
    swift: "LabeledContent",
    summary: "A label and its value, the value in the secondary colour.",
    props: [["label", "string", ""], ["value", "string", "Or children."]],
    jsx: "<LabeledContent label=\"Version\" value=\"1.0\" />",
  },
  {
    name: "ListRow",
    group: "Lists",
    swift: "ListRow(label, subtitle:, detail:, status:) (Layout/ListRow.swift)",
    summary: "A 24-tall row for lists, outlines and navigators. The highlight is inset 8 and the content 8 inside it. Hover uses `hover`; selected uses `selection` and a medium label, or with `prominent` the accent. Children go before the label: a KindBadge or an Icon.",
    props: [
      ["subtitle", "string", "A second line in the secondary colour (a location); makes a 38-tall row with height={38}."],
      ["status", "\"error\" | \"warning\" | \"note\"", "An 8pt severity square before the content."],

      ["label", "string", ""],
      ["detail", "string", "Trailing, in the secondary colour."],
      ["selected, prominent", "boolean", ""],
      ["indent", "number", "Leading indent in px, for outline depth."],
      ["height", "number", "Default 24 (38 for two-line results)."],
      ["state", `"hover"`, ""],
    ],
    jsx: "<ListRow label=\"Theme\" selected>\n  <KindBadge letter=\"C\" hue=\"badgeClass\" />\n</ListRow>",
  },
  {
    name: "KindBadge",
    group: "Lists",
    swift: "KindBadge",
    summary: "A 16 × 16 tile with a white letter, radius 4 (the Swift code uses 4, not the xs radius of 3).",
    props: [
      ["letter", "string", "C, S, E, P, M, V…"],
      ["hue", "palette hue name", "badgeClass, badgeStruct, badgeEnum, badgeProperty, badgeMethod, badgeVariable, or any hue."],
    ],
    jsx: "<KindBadge letter=\"S\" hue=\"badgeStruct\" />",
  },
  {
    name: "Table",
    group: "Lists",
    swift: "Table, TableRow",
    summary: "A header in callout on the bar colour, 1 pt column dividers, cells padded 6/3, and selected rows in the selection colour.",
    props: [["columns", "string[]", ""], ["rows", "string[][]", ""], ["selected", "number[]", "Selected row indexes."]],
    jsx: "<Table columns={[\"Name\", \"Kind\"]} rows={[[\"Theme.swift\", \"Swift\"], [\"README.md\", \"Markdown\"]]} selected={[0]} />",
  },
  {
    name: "Form",
    group: "Forms",
    swift: "Form, Section, FormMetrics",
    summary: "Settings on the grouped background, in a centred column at most 600 wide with 20 between sections. Contains Section, which contains FormRow.",
    props: [],
    jsx: "<Form>\n  <Section header=\"Editor\" footer=\"Applies to every open file.\">\n    <FormRow label=\"Show line numbers\"><Toggle defaultOn label=\"Show line numbers\" /></FormRow>\n    <FormRow label=\"Location\" value=\"~/Projects\" />\n  </Section>\n</Form>",
  },
  {
    name: "Section",
    group: "Forms",
    swift: "Section",
    summary: "A card (radius 10, 0.5 pt hairline) of rows, with a 12 semibold header above and an 11 footer below.",
    props: [["header", "string", ""], ["footer", "string", ""]],
    jsx: "<Section header=\"Project\">\n  <FormRow label=\"Name\"><TextField defaultValue=\"MetalGraphics\" width={200} label=\"Name\" /></FormRow>\n</Section>",
  },
  {
    name: "FormRow",
    group: "Forms",
    swift: "LabeledContent, or any control in a Section (FormMetrics: inset 9/14)",
    summary: "A label on the leading side and a control or value on the trailing side. Hairlines between rows start 14 in.",
    props: [["label", "string", ""], ["value", "string", "A trailing value in the secondary colour."]],
    jsx: "<FormRow label=\"Appearance\"><Picker options={[\"Automatic\", \"Light\", \"Dark\"]} label=\"Appearance\" /></FormRow>",
  },
  {
    name: "DockTabBar",
    group: "Docking",
    swift: "DockTabBar (Docking/DockChrome.swift); a DockArea draws its own",
    summary: "A tab group's bar. Panel style is 30 tall with 22 pills and 11.5 type; document style is 40 tall with 28 pills, 12.5 type, a document icon and a hairline under the bar. The selected tab is a raised pill; hover shows a close cross.",
    props: [
      ["tabs", "{ title, unsaved?, count? }[]", "`unsaved` shows a dot; `count` a warning capsule."],
      ["tabStyle", `"panel" | "document"`, ""],
      ["defaultSelected / selected", "number", ""],
      ["onSidebar", "boolean", "Draw on the sidebar tint."],
      ["hovered", "number", "A tab to draw hovered, for specs."],
    ],
    jsx: "<DockTabBar tabStyle=\"document\" tabs={[{ title: \"Theme.swift\" }, { title: \"Button.swift\", unsaved: true }]} label=\"Files\" />",
  },
  {
    name: "DockTab",
    group: "Docking",
    swift: "DockTab (Docking/DockChrome.swift)",
    summary: "One tab pill. Normally rendered by DockTabBar.",
    props: [["title", "string", ""], ["selected", "boolean", ""], ["tabStyle", `"panel" | "document"`, ""]],
    jsx: "<DockTabBar tabs={[{ title: \"Console\" }, { title: \"Problems\", count: 3 }]} defaultSelected={1} label=\"Panels\" />",
  },
  {
    name: "DockGap",
    group: "Docking",
    swift: "DockGap (Docking/DockChrome.swift)",
    summary: "The 1 pt gap between docked panels, on the gap tint.",
    props: [["vertical", "boolean", "Default true."]],
    jsx: "<div style={{ display: \"flex\", height: 120 }}>\n  <div style={{ flex: 1 }} />\n  <DockGap />\n  <div style={{ flex: 1 }} />\n</div>",
  },
  {
    name: "Popover",
    group: "Surfaces",
    swift: "Popover in place, .popover to present (Presentation/Surfaces.swift)",
    summary: "A glass card: popover material, radius 10, a 0.5 pt separator hairline and the popover shadow. Place it 4 px from its anchor.",
    props: [],
    jsx: "<Popover style={{ padding: 14, width: 220 }}>\n  <LabeledContent label=\"Line\" value=\"42\" />\n</Popover>",
  },
  {
    name: "Menu",
    group: "Surfaces",
    swift: "MenuPanel in place; Menu (a button that opens one); .contextMenu { } (Presentation/Menu.swift)",
    summary: "Menu glass holding MenuItem and MenuSeparator. A hovered item takes the selection colour at radius 5, with an 18-wide check column.",
    props: [["label", "string", "Accessible name."]],
    jsx: "<Menu label=\"Appearance\">\n  <MenuItem checked>Automatic</MenuItem>\n  <MenuItem>Light</MenuItem>\n  <MenuSeparator />\n  <MenuItem shortcut=\"⌘,\">Settings…</MenuItem>\n</Menu>",
  },
  {
    name: "MenuItem",
    group: "Surfaces",
    swift: "MenuItem (Presentation/Menu.swift)",
    summary: "An item in a Menu.",
    props: [["checked", "boolean", ""], ["shortcut", "string", `e.g. "⌘,"`], ["state", `"hover" | "disabled"`, ""]],
    jsx: "<Menu>\n  <MenuItem shortcut=\"⌘R\">Run</MenuItem>\n</Menu>",
  },
  {
    name: "MenuSeparator",
    group: "Surfaces",
    swift: "MenuSeparator (Presentation/Menu.swift)",
    summary: "A line between groups of menu items.",
    props: [],
    jsx: "<Menu>\n  <MenuItem>Copy</MenuItem>\n  <MenuSeparator />\n  <MenuItem>Delete</MenuItem>\n</Menu>",
  },
  {
    name: "Tooltip",
    group: "Surfaces",
    swift: "Tooltip(text, multiline:), .help(_:) (Presentation/Tooltip.swift)",
    summary: "A short label on tooltip glass.",
    props: [
      ["multiline", "boolean", "A hover card: several lines, at most 420 wide, radius 8."],
],
    jsx: "<Tooltip>Build and run (⌘R)</Tooltip>",
  },
  {
    name: "Scrim",
    group: "Surfaces",
    swift: "Scrim (Presentation/Surfaces.swift)",
    summary: "Dims what is behind a sheet or an alert and centres it.",
    props: [],
    jsx: "<Scrim>\n  <Alert title=\"Discard changes?\" actions={[{ label: \"Cancel\" }, { label: \"Discard\", variant: \"prominent\", destructive: true }]} />\n</Scrim>",
  },
  {
    name: "Sheet",
    group: "Surfaces",
    swift: "Sheet in place, SheetLayout inside .sheet (Presentation/Surfaces.swift)",
    summary: "Sheet glass, radius 12, with the sheet shadow, a headline title, content and trailing actions.",
    props: [
      ["title", "string", ""],
      ["actions", "{ label, variant?, destructive? }[]", "Buttons at the trailing end; bordered unless a variant is given."],
      ["width", "number", "Default 420."],
    ],
    jsx: "<Sheet title=\"Rename file\" width={320} actions={[{ label: \"Cancel\" }, { label: \"Rename\", variant: \"prominent\" }]}>\n  <TextField defaultValue=\"Theme.swift\" width={280} label=\"File name\" />\n</Sheet>",
  },
  {
    name: "Alert",
    group: "Surfaces",
    swift: "Alert in place (AlertLayout), .alert to present (Presentation/Surfaces.swift)",
    summary: "An alert: a 260-wide sheet with a centred title, a message and full-width buttons. Actions carry a role (cancel, destructive); the first without one is the default, prominent. More than two stack.",
    props: [
      ["layout", "\"auto\" | \"row\" | \"stack\"", "auto: two actions or fewer side by side (cancel on the left), more stacked (cancel last)."],
      ["titleVisible", "boolean", ""],
["title", "string", ""], ["message", "string", ""], ["actions", "{ label, variant?, destructive? }[]", ""]],
    jsx: "<Alert title=\"Save changes to “Theme.swift”?\" message=\"Your edits are lost if you don’t save them.\" actions={[{ label: \"Save\" }, { label: \"Don’t Save\", role: \"destructive\" }, { label: \"Cancel\", role: \"cancel\" }]} />",
  },
  {
    name: "Sidebar",
    group: "Navigation",
    swift: "Sidebar(title:), SidebarTitle (Navigation/Sidebar.swift); NavigationSplitView's column",
    summary: "232 wide on the sidebar tint, inset 10, with a hairline edge. Holds SidebarLinks.",
    props: [["title", "string", "A small section title."]],
    jsx: "<Sidebar title=\"Demos\">\n  <SidebarLink selected>Form</SidebarLink>\n  <SidebarLink>Glass</SidebarLink>\n</Sidebar>",
  },
  {
    name: "SidebarLink",
    group: "Navigation",
    swift: "SidebarLink (Navigation/Sidebar.swift); a NavigationLink in a split view's sidebar",
    summary: "A full-width link, inset 5/10. Selected uses the selection colour and a medium label.",
    props: [["selected", "boolean", ""], ["icon", "Icon name", ""], ["state", `"hover"`, ""]],
    jsx: "<Sidebar>\n  <SidebarLink icon=\"folder\" selected>Sources</SidebarLink>\n</Sidebar>",
  },
  {
    name: "NavigationBar",
    group: "Navigation",
    swift: "NavigationBar in place; .navigationTitle and .toolbar(leading:trailing:) in a NavigationStack",
    summary: "38 tall on the bar tint, a headline title, leading and trailing slots.",
    props: [["title", "string", ""], ["leading, trailing", "element", "Buttons."]],
    jsx: "<NavigationBar title=\"Settings\" leading={<Button icon=\"chevronLeft\" label=\"Back\" />} trailing={<Button variant=\"bordered\">Share</Button>} />",
  },
  {
    "name": "ConfirmationDialog",
    "group": "Surfaces",
    "swift": "ConfirmationDialog in place, .confirmationDialog to present (Presentation/Surfaces.swift)",
    "summary": "An alert whose actions always stack, with Cancel added when none is given; the title can be hidden.",
    "props": [
      [
        "title",
        "string",
        ""
      ],
      [
        "message",
        "string",
        ""
      ],
      [
        "actions",
        "{ label, role?, variant? }[]",
        ""
      ],
      [
        "titleVisible",
        "boolean",
        ""
      ]
    ],
    "jsx": "<ConfirmationDialog title=\"Discard the build log?\" actions={[{ label: \"Discard\", role: \"destructive\" }, { label: \"Keep\" }]} />"
  },
  {
    "name": "InsertionLine",
    "group": "Lists",
    "swift": "InsertionLine (Layout/InsertionLine.swift)",
    "summary": "Where a dragged row would drop: a 2pt accent line across the list.",
    "props": [
      [
        "indent",
        "number",
        "Inset from the list's edges, default 8."
      ]
    ],
    "jsx": "<InsertionLine />"
  },
  {
    "name": "CodeEditor",
    "group": "Editor",
    "swift": "TextEditor (TextEditor/View/EditorViews.swift) with EditorTheme",
    "summary": "Code as the library's TextEditor draws it: a gutter of line numbers with diagnostic dots and fold chevrons, the current line, selections, search matches, error squiggles and a caret, in the editor theme's colours. Static: it shows the state it is given; lines and columns are 0-based.",
    "props": [
      [
        "lines",
        "{ spans?: {text, token?}[], text?, diagnostic?, fold? }[]",
        "token: keyword, type, function, string, number, comment, attribute, directive, variable, constant, …"
      ],
      [
        "currentLine",
        "number",
        ""
      ],
      [
        "selections",
        "{ line, from, to }[]",
        "Columns in characters."
      ],
      [
        "matches",
        "{ line, from, to }[]",
        "Search matches; currentMatch indexes the current one."
      ],
      [
        "squiggles",
        "{ line, from, to, severity? }[]",
        ""
      ],
      [
        "caret",
        "{ line, column }",
        ""
      ],
      [
        "focused",
        "boolean",
        "Unfocused: inactive selection, no caret."
      ],
      [
        "lineNumbers, folding",
        "boolean",
        ""
      ],
      [
        "firstLineNumber",
        "number",
        ""
      ]
    ],
    "jsx": "<CodeEditor currentLine={1} caret={{ line: 1, column: 12 }} lines={[\n  { spans: [{ text: \"public\", token: \"keyword\" }, { text: \" struct \" , token: \"keyword\" }, { text: \"Glass\", token: \"type\" }, { text: \" {\" }] },\n  { spans: [{ text: \"  let \" , token: \"keyword\" }, { text: \"blur = \" }, { text: \"22\", token: \"number\" }] },\n  { text: \"}\" },\n]} />"
  },
  {
    "name": "FindBar",
    "group": "Editor",
    "swift": "FindBar (TextEditor/Chrome/FindBar.swift)",
    "summary": "The editor's find and replace bar: query with a magnifier, match count, previous and next, the Aa / Word / .* chips, replacement, Replace, All and Done.",
    "props": [
      [
        "query, replacement, count",
        "string",
        ""
      ],
      [
        "caseSensitive, wholeWord, regex",
        "boolean",
        "The chips' state."
      ],
      [
        "showReplace",
        "boolean",
        "Default true."
      ],
      [
        "focused",
        "boolean",
        "Draws the query field focused."
      ]
    ],
    "jsx": "<FindBar query=\"blurRadius\" count=\"4 of 8\" caseSensitive />"
  },
  {
    "name": "ToggleChip",
    "group": "Editor",
    "swift": "ToggleChip (Form/ToggleChip.swift)",
    "summary": "A small on/off chip, 11.5 semibold on radius 5; on shows the selection behind the accent.",
    "props": [
      [
        "isOn",
        "boolean",
        ""
      ],
      [
        "label",
        "string",
        "Accessible name."
      ]
    ],
    "jsx": "<ToggleChip isOn>Aa</ToggleChip>"
  },
  {
    "name": "CompletionList",
    "group": "Editor",
    "swift": "CompletionList, CompletionItem (TextEditor/Chrome/CompletionList.swift)",
    "summary": "The completion popup on menu glass: a row per candidate with its kind badge, monospaced name and type, the selected one on the accent, and a detail line under a hairline.",
    "props": [
      [
        "items",
        "{ badge, label, detail? }[]",
        "badge: C, S, E, P, M, V, Pr."
      ],
      [
        "selected",
        "number",
        ""
      ],
      [
        "footer",
        "string",
        ""
      ]
    ],
    "jsx": "<CompletionList selected={0} footer=\"static let ultraThin: GlassMaterial\" items={[{ badge: \"P\", label: \"ultraThin\", detail: \"GlassMaterial\" }, { badge: \"P\", label: \"thin\", detail: \"GlassMaterial\" }]} />"
  },
  {
    "name": "StatusBar",
    "group": "Editor",
    "swift": "StatusBar (TextEditor/Chrome/StatusBar.swift)",
    "summary": "The 24pt line under an editor: caret position, the first problem in the destructive colour, and the file name.",
    "props": [
      [
        "position",
        "string",
        "\"Ln 92, Col 45\""
      ],
      [
        "problem",
        "string",
        ""
      ],
      [
        "file",
        "string",
        ""
      ]
    ],
    "jsx": "<StatusBar position=\"Ln 92, Col 45\" problem=\"Cannot find 'glassMaterial' in scope\" file=\"Background.swift\" />"
  },
  {
    "name": "Window",
    "group": "Window",
    "swift": "a translucent window (Core/TitleBar.swift TitleBarInsets)",
    "summary": "A macOS window as MetalGraphics frames one: the traffic lights in the leading 78pt, and a bar: title (32, centred title), unified (52, a toolbar in the title row), dock (40, the dock's tab row) or none (content under the lights).",
    "props": [
      [
        "bar",
        "\"title\" | \"unified\" | \"dock\" | \"none\"",
        ""
      ],
      [
        "title",
        "string",
        "For the title bar."
      ],
      [
        "toolbar",
        "element",
        "What the unified or dock bar holds."
      ],
      [
        "width, height",
        "number",
        ""
      ],
      [
        "inactive",
        "boolean",
        "Grey traffic lights."
      ]
    ],
    "jsx": "<Window bar=\"unified\" width={720} height={420} toolbar={<><span style={{ font: \"var(--mg-font-headline)\" }}>Form</span><span style={{ flex: 1 }} /><Button variant=\"bordered\">Share</Button></>}>\n  <Sidebar title=\"Demos\"><SidebarLink selected>Form</SidebarLink></Sidebar>\n</Window>"
  },
  {
    "name": "TitleBar",
    "group": "Window",
    "swift": "TitleBar (Docking/DockChrome.swift)",
    "summary": "A floating dock window's own 28pt title bar on the bar tint: traffic lights on the left, the title centred.",
    "props": [
      [
        "title",
        "string",
        ""
      ],
      [
        "state",
        "\"hover\"",
        "Shows the lights' glyphs."
      ]
    ],
    "jsx": "<TitleBar title=\"Inspector\" />"
  },
  {
    "name": "TrafficLights",
    "group": "Window",
    "swift": "TrafficLights (Docking/DockChrome.swift)",
    "summary": "Close, minimize and zoom: 12pt dots 8 apart, with ×, − and + on hover. The only literal colours in the system.",
    "props": [
      [
        "state",
        "\"hover\"",
        ""
      ],
      [
        "inactive",
        "boolean",
        ""
      ]
    ],
    "jsx": "<TrafficLights state=\"hover\" />"
  },
  {
    "name": "FloatingPanel",
    "group": "Docking",
    "swift": "FloatingPanel (Docking/DockChrome.swift)",
    "summary": "A dock panel floating over the others: floating-panel glass, radius 7, a hairline, and a 12pt grip strip with three dots.",
    "props": [
      [
        "grip",
        "boolean",
        "Default true."
      ],
      [
        "width, height",
        "number",
        "At least 180 × 110."
      ]
    ],
    "jsx": "<FloatingPanel width={280} height={160}>\n  <DockTabBar tabs={[{ title: \"Inspector\" }]} />\n</FloatingPanel>"
  },
  {
    "name": "DropMarkers",
    "group": "Docking",
    "swift": "DropMarkers (Docking/DockChrome.swift)",
    "summary": "The docking cross shown while a panel is dragged: 28pt markers 34 apart on drop-marker glass with an accent ring, each drawing its zone; the hovered one filled with the accent.",
    "props": [
      [
        "hovered",
        "\"left\" | \"right\" | \"top\" | \"bottom\" | \"center\"",
        ""
      ],
      [
        "zones",
        "DropZone[]",
        "Default all five."
      ]
    ],
    "jsx": "<DropMarkers hovered=\"center\" />"
  },
  {
    "name": "DropPreview",
    "group": "Docking",
    "swift": "DropPreview (Docking/DockChrome.swift)",
    "summary": "Where a dropped panel lands: the accent at 18% with a 2pt ring. Place it over the target area.",
    "props": [],
    "jsx": "<DropPreview style={{ width: 200, height: 120 }} />"
  },
  {
    "name": "ColorPicker",
    "group": "Controls",
    "swift": "ColorPicker (Form/ColorPicker.swift)",
    "summary": "A form row with a label and a 44 × 24 colour well. The well opens ColorPickerPanel in a Popover.",
    "props": [
      [
        "label",
        "string",
        ""
      ],
      [
        "color",
        "CSS colour",
        "Any colour: a hue variable or a value (this is user content, not UI chrome)."
      ],
      [
        "opacity",
        "number",
        "Below 1 shows the checkerboard."
      ]
    ],
    "jsx": "<ColorPicker label=\"Tint\" color=\"var(--mg-hue-teal)\" />"
  },
  {
    "name": "ColorWell",
    "group": "Controls",
    "swift": "ColorWell (Form/ColorPicker.swift)",
    "summary": "The 44 × 24 well on the control-button fill: the colour on a radius-3 patch, a checkerboard under it when translucent.",
    "props": [
      [
        "color",
        "CSS colour",
        ""
      ],
      [
        "opacity",
        "number",
        ""
      ],
      [
        "label",
        "string",
        ""
      ]
    ],
    "jsx": "<ColorWell color=\"var(--mg-hue-orange)\" />"
  },
  {
    "name": "ColorPickerPanel",
    "group": "Controls",
    "swift": "ColorPickerPanel (Form/ColorPicker.swift)",
    "summary": "What a colour well opens: 12 hues in three shades and a row of greys (16pt swatches, the selection ringed), then Hue, Saturation, Brightness and Opacity sliders.",
    "props": [
      [
        "selected",
        "[row, column]",
        ""
      ],
      [
        "hue, saturation, brightness",
        "number",
        "0…1."
      ],
      [
        "opacity",
        "number",
        "Shows the Opacity slider."
      ]
    ],
    "jsx": "<Popover><ColorPickerPanel selected={[1, 7]} opacity={1} /></Popover>"
  },
  {
    "name": "DatePicker",
    "group": "Controls",
    "swift": "DatePicker (Form/DatePicker.swift)",
    "summary": "A date and time. compact: chevron-less pills that open CalendarView and TimePanel; graphical: the calendar in place with the time pill under it. date is local ISO, \"2026-09-28T14:30\".",
    "props": [
      [
        "label",
        "string",
        ""
      ],
      [
        "date",
        "string",
        ""
      ],
      [
        "today, min, max",
        "string",
        "Today in the accent; days outside min…max faint."
      ],
      [
        "datePickerStyle",
        "\"compact\" | \"graphical\"",
        ""
      ],
      [
        "showTime",
        "boolean",
        ""
      ],
      [
        "open",
        "\"date\" | \"time\"",
        "Which pill is open, for specs."
      ]
    ],
    "jsx": "<DatePicker label=\"Deadline\" date=\"2026-09-28T14:30\" />"
  },
  {
    "name": "CalendarView",
    "group": "Controls",
    "swift": "CalendarView (Form/DatePicker.swift)",
    "summary": "A month: title with ‹ ›, weekdays, six weeks of 32 × 28 days; the selection a 26pt accent circle, today in the accent, other months at 35%, out of range at 20%.",
    "props": [
      [
        "date",
        "string",
        ""
      ],
      [
        "today, min, max",
        "string",
        ""
      ]
    ],
    "jsx": "<Popover><CalendarView date=\"2026-09-28\" today=\"2026-09-24\" /></Popover>"
  },
  {
    "name": "TimePanel",
    "group": "Controls",
    "swift": "TimePanel (Form/DatePicker.swift)",
    "summary": "What a compact date picker's time pill opens: hour and minute steppers, 180 wide.",
    "props": [
      [
        "date",
        "string",
        ""
      ]
    ],
    "jsx": "<Popover><TimePanel date=\"2026-09-28T14:30\" /></Popover>"
  },
];

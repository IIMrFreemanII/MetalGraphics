import Foundation

// Generated once from the Claude Design template "Animated icons" (its mg-anim-icons.js, kept in
// DesignSystemWeb/.design-sync/reference/), and edited here since: this file is the source now.
// Each glyph is its markup and its CSS, as the template writes them; `AnimatedGlyphStyle` reads
// them, `AnimatedIcon` plays them, and the web mirror is generated from them.

extension AnimatedGlyphSource {
  /// A duration in milliseconds at speed 1, as the template writes `T(ms)`.
  static func T(_ ms: Int) -> String { "calc(\(ms)ms*var(--mgi-t,1))" }

  /// The glyphs' spring, as the template writes `SP`: its settle time and its curve.
  static let SP = "calc(var(--mgi-sd,640ms)*var(--mgi-t,1)) var(--mgi-spring,cubic-bezier(.3,1.5,.5,1))"

  /// What every glyph shares: the press squash on the outer group and the entrance.
  static let base: [String] = [
    #".mgi{display:block;overflow:visible}"#,
    #".mgi *{transform-box:view-box}"#,
    #".mgi g{transform-origin:var(--c)}"#,
    #".mgi .fx{transform-origin:0 0}"#,
    #".mgi .press{transition:transform \#(SP)}"#,
    #".mgi[data-press] .press{transform:scale(.8);transition:transform \#(T(90)) cubic-bezier(.3,0,.5,1)}"#,
    #".mgi[data-mount] .press{animation:mgi-in \#(SP) both}"#,
  ]

  /// The keyframes the glyphs' animations name.
  static let keyframes: [(name: String, body: String)] = [
    ("mgi-in", #"from{transform:scale(.3) rotate(-25deg);opacity:0}to{transform:none;opacity:1}"#),
    ("mgi-nudge-x", #"0%{transform:none}28%{transform:translateX(2px) scaleX(.8)}52%{transform:translateX(-.9px) scaleX(1.06)}74%{transform:translateX(.4px)}100%{transform:none}"#),
    ("mgi-nudge-nx", #"0%{transform:none}28%{transform:translateX(-2px) scaleX(.8)}52%{transform:translateX(.9px) scaleX(1.06)}74%{transform:translateX(-.4px)}100%{transform:none}"#),
    ("mgi-nudge-y", #"0%{transform:none}28%{transform:translateY(2px) scaleY(.8)}52%{transform:translateY(-.9px) scaleY(1.06)}74%{transform:translateY(.4px)}100%{transform:none}"#),
    ("mgi-pop", #"0%{transform:none}30%{transform:scale(1.3)}55%{transform:scale(.88)}78%{transform:scale(1.05)}100%{transform:none}"#),
    ("mgi-spin", #"to{transform:rotate(360deg)}"#),
    ("mgi-draw", #"from{stroke-dashoffset:1}to{stroke-dashoffset:0}"#),
    ("mgi-lift", #"0%{transform:none}30%{transform:translateY(-1.5px) rotate(-9deg)}55%{transform:translateY(-.6px) rotate(5deg)}78%{transform:rotate(-2deg)}100%{transform:none}"#),
    ("mgi-orbit", #"0%{transform:none}25%{transform:translate(-1.2px,-.8px) rotate(-12deg)}50%{transform:translate(.4px,-1.4px) rotate(4deg)}75%{transform:translate(1.1px,.4px) rotate(10deg)}100%{transform:none}"#),
    ("mgi-turn90", #"0%{transform:none}40%{transform:rotate(108deg) scale(.82)}65%{transform:rotate(82deg) scale(1.1)}85%{transform:rotate(93deg)}100%{transform:rotate(90deg)}"#),
    ("mgi-turn45", #"0%{transform:none}45%{transform:rotate(64deg)}70%{transform:rotate(38deg)}88%{transform:rotate(48deg)}100%{transform:rotate(45deg)}"#),
    ("mgi-turn360", #"0%{transform:none}55%{transform:rotate(388deg)}78%{transform:rotate(352deg)}100%{transform:rotate(360deg)}"#),
    ("mgi-shake", #"0%,100%{transform:none}20%{transform:rotate(-8deg)}40%{transform:rotate(7deg)}60%{transform:rotate(-4deg)}80%{transform:rotate(2deg)}"#),
    ("mgi-dash", #"0%{stroke-dasharray:2 98;stroke-dashoffset:0}50%{stroke-dasharray:62 38;stroke-dashoffset:-20}100%{stroke-dasharray:2 98;stroke-dashoffset:-100}"#),
    ("mgi-ring", #"0%{transform:none}10%{transform:rotate(20deg)}24%{transform:rotate(-16deg)}38%{transform:rotate(11deg)}52%{transform:rotate(-7deg)}66%{transform:rotate(4deg)}80%{transform:rotate(-2deg)}100%{transform:none}"#),
    ("mgi-clap", #"0%{transform:none}10%{transform:rotate(30deg)}24%{transform:rotate(-26deg)}38%{transform:rotate(18deg)}52%{transform:rotate(-11deg)}66%{transform:rotate(6deg)}80%{transform:rotate(-3deg)}100%{transform:none}"#),
    ("mgi-ring-loop", #"0%{transform:none}4%{transform:rotate(20deg)}10%{transform:rotate(-16deg)}16%{transform:rotate(11deg)}22%{transform:rotate(-7deg)}28%{transform:rotate(4deg)}34%,100%{transform:none}"#),
    ("mgi-clap-loop", #"0%{transform:none}4%{transform:rotate(30deg)}10%{transform:rotate(-26deg)}16%{transform:rotate(18deg)}22%{transform:rotate(-11deg)}28%{transform:rotate(6deg)}34%,100%{transform:none}"#),
    ("mgi-thud", #"0%{transform:none}30%{transform:scale(1.1,.86)}55%{transform:scale(.95,1.06)}78%{transform:scale(1.02,.98)}100%{transform:none}"#),
    ("mgi-jig", #"0%,100%{transform:none}30%{transform:translateY(-1.2px)}60%{transform:translateY(.3px)}"#),
    ("mgi-blink", #"0%,100%{transform:none}40%,55%{transform:scaleY(.08)}"#),
    ("mgi-slide", #"0%{transform:none}30%{transform:scaleX(.55)}60%{transform:scaleX(1.1)}100%{transform:none}"#),
    ("mgi-up", #"0%{transform:none}30%{transform:translateY(-1.6px)}55%{transform:translateY(.5px)}78%{transform:translateY(-.2px)}100%{transform:none}"#),
    ("mgi-dn", #"0%{transform:none}30%{transform:translateY(1.6px)}55%{transform:translateY(-.5px)}78%{transform:translateY(.2px)}100%{transform:none}"#),
    ("mgi-shake-loop", #"0%,24%,100%{transform:none}4%{transform:rotate(-8deg)}8%{transform:rotate(7deg)}12%{transform:rotate(-4deg)}16%{transform:rotate(2deg)}"#),
    ("mgi-ripple", #"0%{opacity:.6;transform:scale(1)}100%{opacity:0;transform:scale(1.65)}"#),
    ("mgi-hop", #"0%{transform:none}30%{transform:translateY(-1.8px) scale(1.2)}55%{transform:translateY(.4px) scale(.9,1.1)}75%{transform:translateY(-.2px)}100%{transform:none}"#),
    ("mgi-squash", #"0%{transform:none}25%{transform:scaleY(.7)}50%{transform:scaleY(1.1)}75%{transform:scaleY(.97)}100%{transform:none}"#),
    ("mgi-stab", #"0%{transform:translateY(-2.4px)}40%{transform:translateY(.6px) scaleY(.86)}70%{transform:translateY(-.3px) scaleY(1.04)}100%{transform:none}"#),
    ("mgi-wobble", #"0%{transform:none}25%{transform:rotate(-12deg)}50%{transform:rotate(8deg)}75%{transform:rotate(-3deg)}100%{transform:none}"#),
    ("mgi-bump-up", #"0%{transform:none}35%{transform:translateY(-1.3px) scale(1.18)}70%{transform:translateY(.3px)}100%{transform:none}"#),
    ("mgi-bump-dn", #"0%{transform:none}35%{transform:translateY(1.3px) scale(1.18)}70%{transform:translateY(-.3px)}100%{transform:none}"#),
    ("mgi-fly", #"0%{transform:none}30%{transform:translate(1.6px,-1.8px) rotate(-12deg) scale(1.1)}55%{transform:translate(-.4px,.4px) rotate(4deg) scale(.96)}78%{transform:translate(.2px,-.2px) rotate(-1deg)}100%{transform:none}"#),
    ("mgi-fly-in", #"from{transform:translate(-4px,3px) rotate(18deg) scale(.4);opacity:0}to{transform:none;opacity:1}"#),
    ("mgi-flap", #"0%,100%{transform:none}20%{transform:scale(.6)}40%{transform:scale(1.1)}60%{transform:scale(.8)}80%{transform:scale(1.03)}"#),
    ("mgi-eq", #"0%,100%{transform:none}30%{transform:scaleY(.35)}60%{transform:scaleY(1.25)}80%{transform:scaleY(.9)}"#),
    ("mgi-no", #"0%,100%{transform:none}20%{transform:translateX(-1.2px)}40%{transform:translateX(1px)}60%{transform:translateX(-.6px)}80%{transform:translateX(.3px)}"#),
  ]

  /// The glyph sources, in the template's order, then ours.
  static let all: [AnimatedGlyph: AnimatedGlyphSource] = {
    var m: [AnimatedGlyph: AnimatedGlyphSource] = [:]
    m[.chevronRight] = AnimatedGlyphSource(
      box: [10, 10], weight: 1.4, triggers: [.hover, .press, .state], state: "expanded", component: "DisclosureGroup · FindBar · CalendarView",
      markup: #"<path d="M3.5 2 L6.5 5 L3.5 8"/>"#,
      css: [
        #".mgi-chevronRight .st{transition:transform \#(SP)}"#,
        #".mgi-chevronRight[data-active="true"] .st{transform:rotate(90deg)}"#,
        #".mgi-chevronRight[data-hover] .hov{animation:mgi-nudge-x \#(T(560)) ease-out}"#,
      ]
    )
    m[.chevronDown] = AnimatedGlyphSource(
      box: [10, 10], weight: 1.4, triggers: [.hover, .press, .state], state: "flipped", component: "Menu",
      markup: #"<path d="M2 3.5 L5 6.5 L8 3.5"/>"#,
      css: [
        #".mgi-chevronDown .st{transition:transform \#(SP)}"#,
        #".mgi-chevronDown[data-active="true"] .st{transform:rotate(180deg)}"#,
        #".mgi-chevronDown[data-hover] .hov{animation:mgi-nudge-y \#(T(560)) ease-out}"#,
      ]
    )
    m[.chevronLeft] = AnimatedGlyphSource(
      box: [10, 10], weight: 1.4, triggers: [.hover, .press, .state], state: "expanded", component: "FindBar · CalendarView",
      markup: #"<path d="M6.5 2 L3.5 5 L6.5 8"/>"#,
      css: [
        #".mgi-chevronLeft .st{transition:transform \#(SP)}"#,
        #".mgi-chevronLeft[data-active="true"] .st{transform:rotate(-90deg)}"#,
        #".mgi-chevronLeft[data-hover] .hov{animation:mgi-nudge-nx \#(T(560)) ease-out}"#,
      ]
    )
    m[.upDown] = AnimatedGlyphSource(
      box: [10, 10], weight: 1.2, triggers: [.hover, .press], component: "Picker",
      markup: #"<path class="u" d="M3 4 L5 2 L7 4"/><path class="d" d="M3 6 L5 8 L7 6"/>"#,
      css: [
        #".mgi-upDown .u,.mgi-upDown .d{transition:transform \#(SP)}"#,
        #".mgi-upDown[data-hover] .u{animation:mgi-up \#(T(540)) ease-out}"#,
        #".mgi-upDown[data-hover] .d{animation:mgi-dn \#(T(540)) ease-out \#(T(50))}"#,
        #".mgi-upDown[data-press] .u{transform:translateY(1px)}"#,
        #".mgi-upDown[data-press] .d{transform:translateY(-1px)}"#,
      ]
    )
    m[.checkmark] = AnimatedGlyphSource(
      box: [12, 12], weight: 1.5, triggers: [.hover, .state, .mount], state: "checked", defaultActive: true, component: "MenuItem · Picker",
      markup: #"<path class="p" pathLength="1" d="M2.5 6.5 L5 9 L9.5 3"/>"#,
      css: [
        #".mgi-checkmark .p{stroke-dasharray:1 1;stroke-dashoffset:0;transition:stroke-dashoffset \#(T(380)) cubic-bezier(.65,0,.35,1)}"#,
        #".mgi-checkmark[data-active="false"] .p{stroke-dashoffset:1;transition-duration:\#(T(160))}"#,
        #".mgi-checkmark[data-mount] .press{animation:none}"#,
        #".mgi-checkmark[data-mount] .p{animation:mgi-draw \#(T(420)) cubic-bezier(.65,0,.35,1) both}"#,
        #".mgi-checkmark[data-mount] .hov{animation:mgi-pop \#(T(620)) ease-out \#(T(260)) both}"#,
        #".mgi-checkmark[data-to="true"] .hov{animation:mgi-pop \#(T(620)) ease-out \#(T(220))}"#,
        #".mgi-checkmark[data-hover] .hov{animation:mgi-pop \#(T(620)) ease-out}"#,
      ]
    )
    m[.folder] = AnimatedGlyphSource(
      box: [16, 13], weight: 0, triggers: [.hover, .press, .state], state: "open", component: "ListRow · SidebarLink",
      markup: #"<path class="bk" fill="currentColor" stroke="none" d="M1 2.5 A1.5 1.5 0 0 1 2.5 1 H6 L7.6 2.6 H13.5 A1.5 1.5 0 0 1 15 4.1 V10.5 A1.5 1.5 0 0 1 13.5 12 H2.5 A1.5 1.5 0 0 1 1 10.5 Z"/><path class="fr" fill="currentColor" stroke="none" d="M1 4.6 H15 V10.5 A1.5 1.5 0 0 1 13.5 12 H2.5 A1.5 1.5 0 0 1 1 10.5 Z"/>"#,
      css: [
        #".mgi-folder .fr{transform-origin:8px 12px;transition:transform \#(SP)}"#,
        #".mgi-folder .bk{transition:opacity \#(T(200))}"#,
        #".mgi-folder[data-hovering] .fr,.mgi-folder[data-active="true"] .fr{transform:skewX(-18deg) scaleY(.78)}"#,
        #".mgi-folder[data-hovering] .bk,.mgi-folder[data-active="true"] .bk{opacity:.45}"#,
      ]
    )
    m[.document] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .state], state: "filled", component: "ListRow · DockTab",
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><path class="ln l1" pathLength="1" d="M3.5 7.5 H9.5"/><path class="ln l2" pathLength="1" d="M3.5 9.5 H9.5"/><path class="ln l3" pathLength="1" d="M3.5 11.5 H7"/>"#,
      css: [
        #".mgi-document .ln{stroke-dasharray:1 1;stroke-dashoffset:1;transition:stroke-dashoffset \#(T(160)) ease-in}"#,
        #".mgi-document[data-hovering] .ln,.mgi-document[data-active="true"] .ln{stroke-dashoffset:0;transition:stroke-dashoffset \#(T(260)) cubic-bezier(.3,.7,.4,1)}"#,
        #".mgi-document[data-hovering] .l2,.mgi-document[data-active="true"] .l2{transition-delay:\#(T(80))}"#,
        #".mgi-document[data-hovering] .l3,.mgi-document[data-active="true"] .l3{transition-delay:\#(T(160))}"#,
        #".mgi-document .hov{transform-origin:6.5px 14px}"#,
        #".mgi-document[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
      ]
    )
    m[.magnifier] = AnimatedGlyphSource(
      box: [12, 12], weight: 1.3, triggers: [.hover, .press, .loop], component: "TextField · FindBar",
      markup: #"<circle cx="5" cy="5" r="3.8"/><path d="M8 8 L11 11"/>"#,
      css: [
        #".mgi-magnifier[data-hover] .hov{animation:mgi-orbit \#(T(700)) ease-in-out}"#,
        #".mgi-magnifier[data-loop] .hov{animation:mgi-orbit \#(T(1100)) ease-in-out infinite}"#,
      ]
    )
    m[.xmark] = AnimatedGlyphSource(
      box: [8, 8], weight: 1.3, triggers: [.hover, .press], component: "DockTab · Sheet",
      markup: #"<path d="M1 1 L7 7 M7 1 L1 7"/>"#,
      css: [
        #".mgi-xmark[data-hover] .hov{animation:mgi-turn90 \#(T(620)) ease-out}"#,
      ]
    )
    m[.plus] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.3, triggers: [.hover, .press, .state], state: "rotated to ×", component: "Button",
      markup: #"<path d="M7 2 V12 M2 7 H12"/>"#,
      css: [
        #".mgi-plus .st{transition:transform \#(SP)}"#,
        #".mgi-plus[data-active="true"] .st{transform:rotate(135deg)}"#,
        #".mgi-plus[data-hover] .hov{animation:mgi-turn90 \#(T(620)) ease-out}"#,
      ]
    )
    m[.trash] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.3, triggers: [.hover, .press], component: "Button destructive",
      markup: #"<g class="lid"><path d="M1.8 3.5 H12.2"/><path d="M5.3 3.5 V1.8 H8.7 V3.5"/></g><g class="bd"><path d="M3.1 3.5 L3.8 12.1 A1 1 0 0 0 4.8 13 H9.2 A1 1 0 0 0 10.2 12.1 L10.9 3.5"/><path d="M5.8 5.8 V10.6 M8.2 5.8 V10.6"/></g>"#,
      css: [
        #".mgi-trash .lid{transform-origin:1.8px 3.5px;transition:transform \#(SP)}"#,
        #".mgi-trash[data-hovering] .lid{transform:translate(.4px,-1.7px) rotate(-18deg)}"#,
        #".mgi-trash .bd{transform-origin:7px 13px}"#,
        #".mgi-trash[data-press] .bd{animation:mgi-shake \#(T(380)) ease-in-out}"#,
      ]
    )
    m[.gear] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .loop], component: "Form · Section",
      markup: #"<path d="M5.72 2.37 L6.00 0.78 L8.00 0.78 L8.28 2.37 A4.8 4.8 0 0 1 9.37 2.82 L9.37 2.82 L10.69 1.89 L12.11 3.31 L11.18 4.63 A4.8 4.8 0 0 1 11.63 5.72 L11.63 5.72 L13.22 6.00 L13.22 8.00 L11.63 8.28 A4.8 4.8 0 0 1 11.18 9.37 L11.18 9.37 L12.11 10.69 L10.69 12.11 L9.37 11.18 A4.8 4.8 0 0 1 8.28 11.63 L8.28 11.63 L8.00 13.22 L6.00 13.22 L5.72 11.63 A4.8 4.8 0 0 1 4.63 11.18 L4.63 11.18 L3.31 12.11 L1.89 10.69 L2.82 9.37 A4.8 4.8 0 0 1 2.37 8.28 L2.37 8.28 L0.78 8.00 L0.78 6.00 L2.37 5.72 A4.8 4.8 0 0 1 2.82 4.63 L2.82 4.63 L1.89 3.31 L3.31 1.89 L4.63 2.82 A4.8 4.8 0 0 1 5.72 2.37 Z"/><circle cx="7" cy="7" r="1.9"/>"#,
      css: [
        #".mgi-gear[data-hover] .hov{animation:mgi-turn45 \#(T(700)) ease-out}"#,
        #".mgi-gear[data-loop] .hov{animation:mgi-spin \#(T(2600)) linear infinite}"#,
      ]
    )
    m[.searchClear] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.3, triggers: [.hover, .press, .state], state: "clear",
      markup: #"<g class="mag"><circle cx="6" cy="6" r="3.9"/><path d="M8.9 8.9 L12 12"/></g><path class="x x1" pathLength="1" d="M4 4 L10 10"/><path class="x x2" pathLength="1" d="M10 4 L4 10"/>"#,
      css: [
        #".mgi-searchClear .mag{transform-origin:7px 7px;transition:transform \#(SP) \#(T(80)),opacity \#(T(160)) \#(T(80))}"#,
        #".mgi-searchClear[data-active="true"] .mag{transform:scale(.2) rotate(-120deg);opacity:0;transition:transform \#(T(240)) cubic-bezier(.5,0,.75,0),opacity \#(T(200)) \#(T(40))}"#,
        #".mgi-searchClear .x{stroke-dasharray:1 1;stroke-dashoffset:1;transition:stroke-dashoffset \#(T(140)) ease-in}"#,
        #".mgi-searchClear[data-active="true"] .x1{stroke-dashoffset:0;transition:stroke-dashoffset \#(T(240)) cubic-bezier(.3,.7,.4,1) \#(T(150))}"#,
        #".mgi-searchClear[data-active="true"] .x2{stroke-dashoffset:0;transition:stroke-dashoffset \#(T(240)) cubic-bezier(.3,.7,.4,1) \#(T(230))}"#,
        #".mgi-searchClear[data-to="true"] .hov{animation:mgi-pop \#(T(620)) ease-out \#(T(280))}"#,
        #".mgi-searchClear:not([data-active="true"])[data-hover] .hov{animation:mgi-orbit \#(T(700)) ease-in-out}"#,
        #".mgi-searchClear[data-active="true"][data-hover] .hov{animation:mgi-turn90 \#(T(620)) ease-out}"#,
      ]
    )
    m[.spinner] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.5, triggers: [.loop, .mount], component: "ProgressView",
      markup: #"<circle cx="7" cy="7" r="5" opacity=".18"/><circle class="arc" cx="7" cy="7" r="5" pathLength="100" stroke-linecap="round"/>"#,
      css: [
        #".mgi-spinner .hov{animation:mgi-spin \#(T(1000)) linear infinite}"#,
        #".mgi-spinner .arc{stroke-dasharray:25 75;animation:mgi-dash \#(T(1500)) ease-in-out infinite}"#,
      ]
    )
    m[.copyCheck] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.3, triggers: [.hover, .press, .state], state: "copied",
      markup: #"<g class="sheets"><path class="bs" d="M9.5 2.8 V2.2 A1.2 1.2 0 0 0 8.3 1 H2.2 A1.2 1.2 0 0 0 1 2.2 V8.3 A1.2 1.2 0 0 0 2.2 9.5 H2.8"/><rect class="fs" x="4.5" y="4.5" width="8.5" height="8.5" rx="1.2"/></g><path class="ck" pathLength="1" stroke-width="1.5" d="M2.5 7.5 L5.5 10.5 L11.5 3.5"/>"#,
      css: [
        #".mgi-copyCheck .bs,.mgi-copyCheck .fs{transition:transform \#(SP)}"#,
        #".mgi-copyCheck[data-hovering]:not([data-active="true"]) .bs{transform:translate(-.9px,-.9px)}"#,
        #".mgi-copyCheck[data-hovering]:not([data-active="true"]) .fs{transform:translate(.6px,.6px)}"#,
        #".mgi-copyCheck .sheets{transform-origin:7px 7px;transition:transform \#(SP),opacity \#(T(200))}"#,
        #".mgi-copyCheck[data-active="true"] .sheets{transform:scale(.3) rotate(25deg);opacity:0;transition:transform \#(T(220)) cubic-bezier(.5,0,.75,0),opacity \#(T(180)) \#(T(40))}"#,
        #".mgi-copyCheck .ck{stroke:var(--mgi-check,currentColor);stroke-dasharray:1 1;stroke-dashoffset:1;transition:stroke-dashoffset \#(T(120))}"#,
        #".mgi-copyCheck[data-active="true"] .ck{stroke-dashoffset:0;transition:stroke-dashoffset \#(T(320)) cubic-bezier(.3,.7,.4,1) \#(T(140))}"#,
        #".mgi-copyCheck[data-to="true"] .hov{animation:mgi-pop \#(T(620)) ease-out \#(T(240))}"#,
      ]
    )
    m[.bell] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .state, .loop], state: "badge",
      markup: #"<g class="ring"><path d="M3.2 10.2 V6.4 A3.8 3.8 0 0 1 10.8 6.4 V10.2 L12 11.4 H2 L3.2 10.2 Z"/><path d="M7 1.2 V2.6"/></g><path class="cl" d="M5.6 12.6 A1.4 1.4 0 0 0 8.4 12.6"/><circle class="dot" cx="11.2" cy="2.8" r="2" fill="var(--mgi-badge,currentColor)" stroke="none"/>"#,
      css: [
        #".mgi-bell .ring{transform-origin:7px 1.4px}"#,
        #".mgi-bell .cl{transform-origin:7px 2px}"#,
        #".mgi-bell[data-hover] .ring,.mgi-bell[data-to="true"] .ring{animation:mgi-ring \#(T(900)) ease-out}"#,
        #".mgi-bell[data-hover] .cl,.mgi-bell[data-to="true"] .cl{animation:mgi-clap \#(T(900)) ease-out \#(T(40))}"#,
        #".mgi-bell[data-loop] .ring{animation:mgi-ring-loop \#(T(2400)) ease-out infinite}"#,
        #".mgi-bell[data-loop] .cl{animation:mgi-clap-loop \#(T(2400)) ease-out \#(T(40)) infinite}"#,
        #".mgi-bell .dot{transform-origin:11.2px 2.8px;transform:scale(0);transition:transform \#(T(160)) ease-in}"#,
        #".mgi-bell[data-active="true"] .dot{transform:none;transition:transform \#(SP) \#(T(120))}"#,
      ]
    )
    m[.lock] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.3, triggers: [.hover, .press, .state], state: "unlocked",
      markup: #"<path class="sh" d="M4.6 6.5 V4.6 A2.4 2.4 0 0 1 9.4 4.6 V6.5"/><g class="bd"><rect x="2.2" y="6.5" width="9.6" height="6.5" rx="1.3"/><circle cx="7" cy="9.75" r=".95" fill="currentColor" stroke="none"/></g>"#,
      css: [
        #".mgi-lock .sh{transform-origin:9.4px 6.5px;transition:transform \#(SP)}"#,
        #".mgi-lock[data-active="true"] .sh{transform:translateY(-1.8px) rotate(-22deg)}"#,
        #".mgi-lock .bd{transform-origin:7px 13px}"#,
        #".mgi-lock[data-to] .bd{animation:mgi-thud \#(T(520)) ease-out \#(T(100))}"#,
        #".mgi-lock:not([data-active="true"])[data-hover] .sh{animation:mgi-jig \#(T(460)) ease-out}"#,
      ]
    )
    m[.eye] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .state], state: "hidden", component: "TextField secure",
      markup: #"<g class="lid"><path d="M1 7 C2.8 3.4 11.2 3.4 13 7 C11.2 10.6 2.8 10.6 1 7 Z"/><g class="pw"><circle class="pu" cx="7" cy="7" r="2" fill="currentColor" stroke="none"/></g></g><path class="sl" pathLength="1" d="M2.2 1.8 L11.8 12.2"/>"#,
      css: [
        #".mgi-eye .lid{transform-origin:7px 7px;transition:transform \#(SP)}"#,
        #".mgi-eye[data-hover] .lid{animation:mgi-blink \#(T(360)) ease-in-out}"#,
        #".mgi-eye .pu{transform:translate(var(--mgi-px,0px),var(--mgi-py,0px));transition:transform \#(T(140)) ease-out}"#,
        #".mgi-eye[data-active="true"] .lid{transform:scaleY(.7)}"#,
        #".mgi-eye .pw{transform-origin:7px 7px;transition:transform \#(SP)}"#,
        #".mgi-eye[data-active="true"] .pw{transform:scale(.4)}"#,
        #".mgi-eye .sl{stroke-dasharray:1 1;stroke-dashoffset:1;transition:stroke-dashoffset \#(T(160)) ease-in}"#,
        #".mgi-eye[data-active="true"] .sl{stroke-dashoffset:0;transition:stroke-dashoffset \#(T(300)) cubic-bezier(.3,.7,.4,1) \#(T(60))}"#,
      ],
      pointer: [2.4, 1.1]
    )
    m[.playPause] = AnimatedGlyphSource(
      box: [14, 14], weight: 0, triggers: [.hover, .press, .state], state: "playing",
      markup: #"<path class="l" fill="currentColor" stroke="none" d="M3.5 2 L7.75 4.5 L7.75 9.5 L3.5 12 Z"/><path class="r" fill="currentColor" stroke="none" d="M7.75 4.5 L12 7 L12 7 L7.75 9.5 Z"/>"#,
      css: [
        #".mgi-playPause[data-hover] .hov,.mgi-playPause[data-to] .hov{animation:mgi-pop \#(T(560)) ease-out}"#,
      ],
      morphs: ["l": #"M3.5 2 L6 2 L6 12 L3.5 12 Z"#, "r": #"M8.5 2 L11 2 L11 12 L8.5 12 Z"#],
      snippetCSS: [
        #"/* morph without JS (Chromium/Firefox): */"#,
        #".mgi-playPause .l,.mgi-playPause .r{transition:d \#(SP)}"#,
        #".mgi-playPause[data-active="true"] .l{d:path("M3.5 2 L6 2 L6 12 L3.5 12 Z")}"#,
        #".mgi-playPause[data-active="true"] .r{d:path("M8.5 2 L11 2 L11 12 L8.5 12 Z")}"#,
      ]
    )
    m[.refresh] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.3, triggers: [.hover, .press, .loop],
      markup: #"<path d="M12 7 A5 5 0 1 1 9.5 2.67"/><path d="M8.68 0.41 L9.5 2.67 L7.14 3.09"/>"#,
      css: [
        #".mgi-refresh[data-hover] .hov{animation:mgi-turn360 \#(T(760)) ease-out}"#,
        #".mgi-refresh[data-loop] .hov{animation:mgi-spin \#(T(900)) linear infinite}"#,
      ]
    )
    m[.menuX] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.3, triggers: [.hover, .press, .state], state: "open (×)",
      markup: #"<path class="t" d="M2 3.5 H12"/><path class="m" d="M2 7 H12"/><path class="b" d="M2 10.5 H12"/>"#,
      css: [
        #".mgi-menuX .t{transform-origin:7px 3.5px;transition:transform \#(SP)}"#,
        #".mgi-menuX .b{transform-origin:7px 10.5px;transition:transform \#(SP)}"#,
        #".mgi-menuX .m{transform-origin:7px 7px;transition:transform \#(T(220)) cubic-bezier(.3,.7,.4,1),opacity \#(T(160))}"#,
        #".mgi-menuX[data-active="true"] .t{transform:translateY(3.5px) rotate(45deg)}"#,
        #".mgi-menuX[data-active="true"] .b{transform:translateY(-3.5px) rotate(-45deg);transition-delay:\#(T(40))}"#,
        #".mgi-menuX[data-active="true"] .m{transform:scaleX(0);opacity:0}"#,
        #".mgi-menuX:not([data-active="true"])[data-hover] .t{animation:mgi-slide \#(T(520)) ease-out}"#,
        #".mgi-menuX:not([data-active="true"])[data-hover] .m{animation:mgi-slide \#(T(520)) ease-out \#(T(50))}"#,
        #".mgi-menuX:not([data-active="true"])[data-hover] .b{animation:mgi-slide \#(T(520)) ease-out \#(T(100))}"#,
      ]
    )
    m[.warning] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .loop, .mount], component: "Alert · StatusBar",
      markup: #"<path d="M7 1.8 L12.8 12 H1.2 Z" stroke-linejoin="round"/><path d="M7 5.4 V8.3"/><circle cx="7" cy="10.2" r=".8" fill="currentColor" stroke="none"/>"#,
      css: [
        #".mgi-warning .hov{transform-origin:7px 12px}"#,
        #".mgi-warning[data-hover] .hov{animation:mgi-shake \#(T(460)) ease-in-out}"#,
        #".mgi-warning[data-loop] .hov{animation:mgi-shake-loop \#(T(2200)) ease-in-out infinite}"#,
      ]
    )
    m[.error] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .loop, .mount],
      markup: #"<circle class="halo" cx="7" cy="7" r="5.6"/><circle class="ring" cx="7" cy="7" r="5.6" pathLength="1"/><g class="x"><path d="M4.9 4.9 L9.1 9.1 M9.1 4.9 L4.9 9.1"/></g>"#,
      css: [
        #".mgi-error .halo{opacity:0;transform-origin:7px 7px}"#,
        #".mgi-error[data-hover] .halo,.mgi-error[data-to] .halo{animation:mgi-ripple \#(T(700)) ease-out}"#,
        #".mgi-error[data-loop] .halo{animation:mgi-ripple \#(T(1400)) ease-out infinite}"#,
        #".mgi-error .x{transform-origin:7px 7px}"#,
        #".mgi-error[data-hover] .x{animation:mgi-turn90 \#(T(620)) ease-out}"#,
        #".mgi-error[data-mount] .press{animation:none}"#,
        #".mgi-error[data-mount] .ring{stroke-dasharray:1 1;animation:mgi-draw \#(T(420)) cubic-bezier(.65,0,.35,1) both}"#,
        #".mgi-error[data-mount] .x{animation:mgi-in \#(SP) \#(T(260)) both}"#,
      ]
    )
    m[.note] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .mount], component: "Tooltip · Popover",
      markup: #"<circle cx="7" cy="7" r="5.6"/><circle class="dt" cx="7" cy="4.3" r=".85" fill="currentColor" stroke="none"/><path class="stem" d="M7 6.3 V10.2"/>"#,
      css: [
        #".mgi-note .dt{transform-origin:7px 4.3px}"#,
        #".mgi-note .stem{transform-origin:7px 10.2px}"#,
        #".mgi-note[data-hover] .dt{animation:mgi-hop \#(T(620)) ease-out}"#,
        #".mgi-note[data-hover] .stem{animation:mgi-squash \#(T(620)) ease-out}"#,
      ]
    )
    m[.pin] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .state], state: "pinned",
      markup: #"<path d="M4.6 1.6 H9.4"/><path d="M5.6 1.6 V5.8 L3.8 8.2 H10.2 L8.4 5.8 V1.6"/><path d="M7 8.2 V12.8"/>"#,
      css: [
        #".mgi-pin .st{transform-origin:7px 10px;transform:rotate(30deg);transition:transform \#(SP)}"#,
        #".mgi-pin[data-active="true"] .st{transform:none}"#,
        #".mgi-pin .hov{transform-origin:7px 12.8px}"#,
        #".mgi-pin[data-hover] .hov{animation:mgi-wobble \#(T(600)) ease-out}"#,
        #".mgi-pin[data-to="true"] .hov{animation:mgi-stab \#(T(560)) ease-out \#(T(120))}"#,
      ]
    )
    m[.sort] = AnimatedGlyphSource(
      box: [10, 10], weight: 1.2, triggers: [.hover, .press, .state], state: "descending (\"false\" = ascending, none = unsorted)",
      markup: #"<path class="u" d="M3 4 L5 2 L7 4"/><path class="d" d="M3 6 L5 8 L7 6"/><path class="stm" pathLength="1" d="M5 2.3 V7.7"/>"#,
      css: [
        #".mgi-sort .u{transform-origin:5px 3px;transition:transform \#(SP),opacity \#(T(160))}"#,
        #".mgi-sort .d{transform-origin:5px 7px;transition:transform \#(SP),opacity \#(T(160))}"#,
        #".mgi-sort .stm{stroke-dasharray:1 1;stroke-dashoffset:1;transition:stroke-dashoffset \#(T(160)) ease-in}"#,
        #".mgi-sort[data-active] .stm{stroke-dashoffset:0;transition:stroke-dashoffset \#(T(300)) cubic-bezier(.3,.7,.4,1) \#(T(60))}"#,
        #".mgi-sort[data-active="false"] .d{transform:scale(0);opacity:0}"#,
        #".mgi-sort[data-active="true"] .u{transform:scale(0);opacity:0}"#,
        #".mgi-sort:not([data-active])[data-hover] .u{animation:mgi-up \#(T(540)) ease-out}"#,
        #".mgi-sort:not([data-active])[data-hover] .d{animation:mgi-dn \#(T(540)) ease-out \#(T(50))}"#,
        #".mgi-sort[data-active="false"][data-hover] .hov{animation:mgi-up \#(T(540)) ease-out}"#,
        #".mgi-sort[data-active="true"][data-hover] .hov{animation:mgi-dn \#(T(540)) ease-out}"#,
      ]
    )
    m[.stepperMinus] = AnimatedGlyphSource(
      box: [10, 10], weight: 1.3, triggers: [.hover, .press, .state], state: "at end of range", component: "Stepper",
      markup: #"<path d="M2 5 H8"/>"#,
      css: [
        #".mgi-stepperMinus .hov{transition:opacity \#(T(160))}"#,
        #".mgi-stepperMinus[data-active="true"] .hov{opacity:.35}"#,
        #".mgi-stepperMinus[data-hover] .hov{animation:mgi-pop \#(T(520)) ease-out}"#,
        #".mgi-stepperMinus[data-press] .hov{animation:mgi-bump-dn \#(T(380)) ease-out}"#,
        #".mgi-stepperMinus[data-active="true"][data-press] .hov{animation:mgi-no \#(T(380)) ease-out}"#,
      ]
    )
    m[.stepperPlus] = AnimatedGlyphSource(
      box: [10, 10], weight: 1.3, triggers: [.hover, .press, .state], state: "at end of range", component: "Stepper",
      markup: #"<path d="M5 2 V8 M2 5 H8"/>"#,
      css: [
        #".mgi-stepperPlus .hov{transition:opacity \#(T(160))}"#,
        #".mgi-stepperPlus[data-active="true"] .hov{opacity:.35}"#,
        #".mgi-stepperPlus[data-hover] .hov{animation:mgi-pop \#(T(520)) ease-out}"#,
        #".mgi-stepperPlus[data-press] .hov{animation:mgi-bump-up \#(T(380)) ease-out}"#,
        #".mgi-stepperPlus[data-active="true"][data-press] .hov{animation:mgi-no \#(T(380)) ease-out}"#,
      ]
    )
    m[.splitRight] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .state], state: "targeted",
      markup: #"<g class="fx" transform="rotate(0 7 7)"><rect x="1.5" y="1.5" width="11" height="11" rx="1.6"/><path d="M7 1.5 V12.5"/><rect class="fill" x="7.7" y="2.2" width="4.1" height="9.6" rx=".7" fill="var(--mgi-fill,currentColor)" stroke="none"/></g>"#,
      css: [
        #".mgi-splitRight .fill{transform-box:fill-box;transform-origin:0 50%;transform:scaleX(0);opacity:0;transition:transform \#(SP),opacity \#(T(160))}"#,
        #".mgi-splitRight[data-hovering] .fill{transform:none;opacity:.45}"#,
        #".mgi-splitRight[data-active="true"] .fill{transform:none;opacity:.85}"#,
        #".mgi-splitRight[data-to="true"] .hov{animation:mgi-pop \#(T(560)) ease-out}"#,
      ]
    )
    m[.splitBottom] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .state], state: "targeted",
      markup: #"<g class="fx" transform="rotate(90 7 7)"><rect x="1.5" y="1.5" width="11" height="11" rx="1.6"/><path d="M7 1.5 V12.5"/><rect class="fill" x="7.7" y="2.2" width="4.1" height="9.6" rx=".7" fill="var(--mgi-fill,currentColor)" stroke="none"/></g>"#,
      css: [
        #".mgi-splitBottom .fill{transform-box:fill-box;transform-origin:0 50%;transform:scaleX(0);opacity:0;transition:transform \#(SP),opacity \#(T(160))}"#,
        #".mgi-splitBottom[data-hovering] .fill{transform:none;opacity:.45}"#,
        #".mgi-splitBottom[data-active="true"] .fill{transform:none;opacity:.85}"#,
        #".mgi-splitBottom[data-to="true"] .hov{animation:mgi-pop \#(T(560)) ease-out}"#,
      ]
    )
    m[.splitLeft] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .state], state: "targeted",
      markup: #"<g class="fx" transform="rotate(180 7 7)"><rect x="1.5" y="1.5" width="11" height="11" rx="1.6"/><path d="M7 1.5 V12.5"/><rect class="fill" x="7.7" y="2.2" width="4.1" height="9.6" rx=".7" fill="var(--mgi-fill,currentColor)" stroke="none"/></g>"#,
      css: [
        #".mgi-splitLeft .fill{transform-box:fill-box;transform-origin:0 50%;transform:scaleX(0);opacity:0;transition:transform \#(SP),opacity \#(T(160))}"#,
        #".mgi-splitLeft[data-hovering] .fill{transform:none;opacity:.45}"#,
        #".mgi-splitLeft[data-active="true"] .fill{transform:none;opacity:.85}"#,
        #".mgi-splitLeft[data-to="true"] .hov{animation:mgi-pop \#(T(560)) ease-out}"#,
      ]
    )
    m[.splitTop] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .state], state: "targeted",
      markup: #"<g class="fx" transform="rotate(270 7 7)"><rect x="1.5" y="1.5" width="11" height="11" rx="1.6"/><path d="M7 1.5 V12.5"/><rect class="fill" x="7.7" y="2.2" width="4.1" height="9.6" rx=".7" fill="var(--mgi-fill,currentColor)" stroke="none"/></g>"#,
      css: [
        #".mgi-splitTop .fill{transform-box:fill-box;transform-origin:0 50%;transform:scaleX(0);opacity:0;transition:transform \#(SP),opacity \#(T(160))}"#,
        #".mgi-splitTop[data-hovering] .fill{transform:none;opacity:.45}"#,
        #".mgi-splitTop[data-active="true"] .fill{transform:none;opacity:.85}"#,
        #".mgi-splitTop[data-to="true"] .hov{animation:mgi-pop \#(T(560)) ease-out}"#,
      ]
    )
    m[.sidebarLeft] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .state], state: "collapsed", component: "Sidebar · Window",
      markup: #"<g class="fx"><rect x="1.5" y="2.5" width="11" height="9" rx="1.6"/><rect class="sb" x="2.2" y="3.2" width="2.6" height="7.6" rx=".6" fill="currentColor" stroke="none" opacity=".35"/><path class="dv" d="M5.5 2.5 V11.5"/></g>"#,
      css: [
        #".mgi-sidebarLeft .sb{transform-box:fill-box;transform-origin:0 50%;transition:transform \#(SP),opacity \#(T(180))}"#,
        #".mgi-sidebarLeft .dv{transition:transform \#(SP)}"#,
        #".mgi-sidebarLeft[data-active="true"] .sb{transform:scaleX(0);opacity:0}"#,
        #".mgi-sidebarLeft[data-active="true"] .dv{transform:translateX(-4px)}"#,
        #".mgi-sidebarLeft:not([data-active="true"])[data-hover] .dv{animation:mgi-nudge-nx \#(T(560)) ease-out}"#,
      ]
    )
    m[.sidebarRight] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .state], state: "collapsed", component: "Window",
      markup: #"<g class="fx" transform="translate(14 0) scale(-1 1)"><rect x="1.5" y="2.5" width="11" height="9" rx="1.6"/><rect class="sb" x="2.2" y="3.2" width="2.6" height="7.6" rx=".6" fill="currentColor" stroke="none" opacity=".35"/><path class="dv" d="M5.5 2.5 V11.5"/></g>"#,
      css: [
        #".mgi-sidebarRight .sb{transform-box:fill-box;transform-origin:0 50%;transition:transform \#(SP),opacity \#(T(180))}"#,
        #".mgi-sidebarRight .dv{transition:transform \#(SP)}"#,
        #".mgi-sidebarRight[data-active="true"] .sb{transform:scaleX(0);opacity:0}"#,
        #".mgi-sidebarRight[data-active="true"] .dv{transform:translateX(-4px)}"#,
        #".mgi-sidebarRight:not([data-active="true"])[data-hover] .dv{animation:mgi-nudge-nx \#(T(560)) ease-out}"#,
      ]
    )
    m[.swift] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="bird" style="color:var(--mgi-swift,var(--mg-hue-orange,#FF9500))"><path fill="currentColor" stroke="none" d="M9.40 4.87 C8.64 4.68 7.89 5.09 7.30 5.72 L5.86 6.93 L3.65 7.34 L5.29 7.75 L5.12 9.42 L6.25 7.49 L7.88 6.56 C8.67 6.21 9.32 5.65 9.40 4.87 Z"/><path class="wg" fill="currentColor" stroke="none" d="M7.76 5.50 C6.56 4.37 4.90 4.08 3.35 4.54 C4.45 5.22 5.42 6.00 6.09 6.67 Z M8.25 6.19 C8.90 7.71 8.60 9.37 7.64 10.66 C7.38 9.40 6.98 8.23 6.58 7.36 Z"/></g>"#,
      css: [
        #".mgi-swift .bird{transform-origin:6.375px 7.5px}"#,
        #".mgi-swift .wg{transform-origin:7.17px 6.43px}"#,
        #".mgi-swift[data-hover] .bird{animation:mgi-fly \#(T(720)) ease-out}"#,
        #".mgi-swift[data-hover] .wg{animation:mgi-flap \#(T(620)) ease-out}"#,
        #".mgi-swift[data-mount] .press{animation:none}"#,
        #".mgi-swift[data-mount] .bird{animation:mgi-fly-in \#(SP) both}"#,
        #".mgi-swift[data-mount] .wg{animation:mgi-flap \#(T(620)) ease-out \#(T(240)) both}"#,
      ]
    )
    m[.fileImage] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-teal))"><path fill="currentColor" stroke="none" d="M2.6 11 L5.3 7.2 L7.1 9.6 L8.3 8.3 L10.2 11 Z"/><circle class="sun" fill="currentColor" stroke="none" cx="8.4" cy="5.7" r="1.1"/></g>"#,
      css: [
        #".mgi-fileImage .hov{transform-origin:6.5px 14px}"#,
        #".mgi-fileImage[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-fileImage .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-fileImage[data-mount] .press{animation:none}"#,
        #".mgi-fileImage[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-fileImage .sun{transition:transform \#(SP)}"#,
        #".mgi-fileImage[data-hovering] .sun{transform:translate(-.5px,-1.1px)}"#,
      ]
    )
    m[.fileVideo] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-purple))"><path class="tri" fill="currentColor" stroke="none" stroke-linejoin="round" d="M5 5.1 L9.1 7.5 L5 9.9 Z"/></g>"#,
      css: [
        #".mgi-fileVideo .hov{transform-origin:6.5px 14px}"#,
        #".mgi-fileVideo[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-fileVideo .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-fileVideo[data-mount] .press{animation:none}"#,
        #".mgi-fileVideo[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-fileVideo .tri{transform-origin:6.4px 7.5px}"#,
        #".mgi-fileVideo[data-hover] .tri{animation:mgi-nudge-x \#(T(560)) ease-out \#(T(120))}"#,
      ]
    )
    m[.fileAudio] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .loop, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-pink))"><rect class="b b0" fill="currentColor" stroke="none" x="3.35" y="6.2" width="1.1" height="2.6" rx=".55"/><rect class="b b1" fill="currentColor" stroke="none" x="5.1499999999999995" y="5.1" width="1.1" height="4.8" rx=".55"/><rect class="b b2" fill="currentColor" stroke="none" x="6.949999999999999" y="5.8" width="1.1" height="3.4" rx=".55"/><rect class="b b3" fill="currentColor" stroke="none" x="8.75" y="6.6" width="1.1" height="1.8" rx=".55"/></g>"#,
      css: [
        #".mgi-fileAudio .hov{transform-origin:6.5px 14px}"#,
        #".mgi-fileAudio[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-fileAudio .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-fileAudio[data-mount] .press{animation:none}"#,
        #".mgi-fileAudio[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-fileAudio .b{transform-box:fill-box;transform-origin:50% 50%}"#,
        #".mgi-fileAudio[data-hover] .b0{animation:mgi-eq \#(T(560)) ease-out \#(T(0))}"#,
        #".mgi-fileAudio[data-hover] .b1{animation:mgi-eq \#(T(560)) ease-out \#(T(70))}"#,
        #".mgi-fileAudio[data-hover] .b2{animation:mgi-eq \#(T(560)) ease-out \#(T(140))}"#,
        #".mgi-fileAudio[data-hover] .b3{animation:mgi-eq \#(T(560)) ease-out \#(T(210))}"#,
        #".mgi-fileAudio[data-loop] .b0{animation:mgi-eq \#(T(900)) ease-in-out \#(T(0)) infinite}"#,
        #".mgi-fileAudio[data-loop] .b1{animation:mgi-eq \#(T(900)) ease-in-out \#(T(150)) infinite}"#,
        #".mgi-fileAudio[data-loop] .b2{animation:mgi-eq \#(T(900)) ease-in-out \#(T(300)) infinite}"#,
        #".mgi-fileAudio[data-loop] .b3{animation:mgi-eq \#(T(900)) ease-in-out \#(T(450)) infinite}"#,
      ]
    )
    m[.fileArchive] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-brown))"><rect fill="currentColor" stroke="none" x="5.1" y="1.6" width="1.25" height=".8" rx=".3"/><rect fill="currentColor" stroke="none" x="6.4" y="2.9" width="1.25" height=".8" rx=".3"/><rect fill="currentColor" stroke="none" x="5.1" y="4.2" width="1.25" height=".8" rx=".3"/><rect fill="currentColor" stroke="none" x="6.4" y="5.5" width="1.25" height=".8" rx=".3"/><rect fill="currentColor" stroke="none" x="5.1" y="6.8" width="1.25" height=".8" rx=".3"/><g class="tab"><rect fill="currentColor" stroke="none" x="5.2" y="8.1" width="2.35" height="3.4" rx=".7"/><rect fill="var(--mg-color-content-background,#fff)" stroke="none" x="5.9" y="9.6" width=".95" height="1.2" rx=".35"/></g></g>"#,
      css: [
        #".mgi-fileArchive .hov{transform-origin:6.5px 14px}"#,
        #".mgi-fileArchive[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-fileArchive .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-fileArchive[data-mount] .press{animation:none}"#,
        #".mgi-fileArchive[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-fileArchive .tab{transition:transform \#(SP)}"#,
        #".mgi-fileArchive[data-hovering] .tab{transform:translateY(1.2px)}"#,
      ]
    )
    m[.fileCode] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-blue))"><g class="lt"><path stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round" d="M4.9 5.3 L2.9 7.5 L4.9 9.7"/></g><g class="gt"><path stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round" d="M7.85 5.3 L9.85 7.5 L7.85 9.7"/></g><path class="sl" stroke-width="1.1" stroke-linecap="round" d="M7 4.9 L5.75 10.1"/></g>"#,
      css: [
        #".mgi-fileCode .hov{transform-origin:6.5px 14px}"#,
        #".mgi-fileCode[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-fileCode .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-fileCode[data-mount] .press{animation:none}"#,
        #".mgi-fileCode[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-fileCode .lt,.mgi-fileCode .gt{transition:transform \#(SP)}"#,
        #".mgi-fileCode[data-hovering] .lt{transform:translateX(-.6px)}"#,
        #".mgi-fileCode[data-hovering] .gt{transform:translateX(.6px)}"#,
        #".mgi-fileCode .sl{transform-origin:6.375px 7.5px}"#,
        #".mgi-fileCode[data-hover] .sl{animation:mgi-wobble \#(T(560)) ease-out}"#,
      ]
    )
    m[.fileJSON] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-indigo))"><g class="lt"><path stroke-width="1.05" stroke-linecap="round" d="M5.1 4.8 C4.1 4.8 4.4 5.7 4.2 6.6 C4.1 7.2 3.7 7.5 3.2 7.5 C3.7 7.5 4.1 7.8 4.2 8.4 C4.4 9.3 4.1 10.2 5.1 10.2"/></g><g class="gt"><path stroke-width="1.05" stroke-linecap="round" transform="translate(12.75 0) scale(-1 1)" d="M5.1 4.8 C4.1 4.8 4.4 5.7 4.2 6.6 C4.1 7.2 3.7 7.5 3.2 7.5 C3.7 7.5 4.1 7.8 4.2 8.4 C4.4 9.3 4.1 10.2 5.1 10.2"/></g><circle class="dt" fill="currentColor" stroke="none" cx="6.375" cy="7.5" r=".6"/></g>"#,
      css: [
        #".mgi-fileJSON .hov{transform-origin:6.5px 14px}"#,
        #".mgi-fileJSON[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-fileJSON .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-fileJSON[data-mount] .press{animation:none}"#,
        #".mgi-fileJSON[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-fileJSON .lt,.mgi-fileJSON .gt{transition:transform \#(SP)}"#,
        #".mgi-fileJSON[data-hovering] .lt{transform:translateX(-.6px)}"#,
        #".mgi-fileJSON[data-hovering] .gt{transform:translateX(.6px)}"#,
        #".mgi-fileJSON .dt{transform-box:fill-box;transform-origin:50% 50%}"#,
        #".mgi-fileJSON[data-hover] .dt{animation:mgi-pop \#(T(560)) ease-out \#(T(80))}"#,
      ]
    )
    m[.fileSheet] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-green))"><rect x="3" y="4.75" width="6.75" height="5.5" rx=".6" stroke-width=".9"/><rect fill="currentColor" stroke="none" x="3" y="4.75" width="6.75" height="1.6" rx=".6"/><path stroke-width=".8" d="M3 8.3 H9.75 M5.6 6.35 V10.25"/><rect class="c c1" fill="currentColor" stroke="none" x="5.6" y="6.35" width="4.15" height="1.95"/><rect class="c c2" fill="currentColor" stroke="none" x="5.6" y="8.3" width="4.15" height="1.95" rx=".4"/></g>"#,
      css: [
        #".mgi-fileSheet .hov{transform-origin:6.5px 14px}"#,
        #".mgi-fileSheet[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-fileSheet .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-fileSheet[data-mount] .press{animation:none}"#,
        #".mgi-fileSheet[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-fileSheet .c{opacity:0;transition:opacity \#(T(160))}"#,
        #".mgi-fileSheet[data-hovering] .c{opacity:.4;transition:opacity \#(T(220))}"#,
        #".mgi-fileSheet[data-hovering] .c2{transition-delay:\#(T(110))}"#,
      ]
    )
    m[.filePDF] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-red))"><text font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" fill="currentColor" x="6.375" y="7.6" font-size="3.6">PDF</text></g>"#,
      css: [
        #".mgi-filePDF .hov{transform-origin:6.5px 14px}"#,
        #".mgi-filePDF[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-filePDF .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-filePDF[data-mount] .press{animation:none}"#,
        #".mgi-filePDF[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-filePDF[data-hover] .gl{animation:mgi-pop \#(T(620)) ease-out \#(T(100))}"#,
      ]
    )
    m[.fileFont] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-gray))"><text font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" font-family="Georgia,'Times New Roman',serif" fill="currentColor" x="6.375" y="7.7" font-size="5.2">Aa</text></g>"#,
      css: [
        #".mgi-fileFont .hov{transform-origin:6.5px 14px}"#,
        #".mgi-fileFont[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-fileFont .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-fileFont[data-mount] .press{animation:none}"#,
        #".mgi-fileFont[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-fileFont[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
      ]
    )
    m[.langJS] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-yellow))"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:#1d1d1f" x="6.375" y="7.55" font-size="3.4">JS</text></g>"#,
      css: [
        #".mgi-langJS .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langJS[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langJS .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langJS[data-mount] .press{animation:none}"#,
        #".mgi-langJS[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langJS[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langJS[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.langTS] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-blue))"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:#fff" x="6.375" y="7.55" font-size="3.4">TS</text></g>"#,
      css: [
        #".mgi-langTS .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langTS[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langTS .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langTS[data-mount] .press{animation:none}"#,
        #".mgi-langTS[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langTS[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langTS[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.langPY] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-indigo))"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:#fff" x="6.375" y="7.55" font-size="3.4">PY</text></g>"#,
      css: [
        #".mgi-langPY .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langPY[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langPY .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langPY[data-mount] .press{animation:none}"#,
        #".mgi-langPY[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langPY[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langPY[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.langRS] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-badge-class))"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:#fff" x="6.375" y="7.55" font-size="3.4">RS</text></g>"#,
      css: [
        #".mgi-langRS .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langRS[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langRS .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langRS[data-mount] .press{animation:none}"#,
        #".mgi-langRS[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langRS[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langRS[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.langGO] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-teal))"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:#fff" x="6.375" y="7.55" font-size="3.4">GO</text></g>"#,
      css: [
        #".mgi-langGO .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langGO[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langGO .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langGO[data-mount] .press{animation:none}"#,
        #".mgi-langGO[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langGO[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langGO[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.langC] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-gray))"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:#fff" x="6.375" y="7.55" font-size="3.8">C</text></g>"#,
      css: [
        #".mgi-langC .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langC[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langC .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langC[data-mount] .press{animation:none}"#,
        #".mgi-langC[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langC[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langC[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.langCPP] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-pink))"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:#fff" x="6.375" y="7.55" font-size="3">C++</text></g>"#,
      css: [
        #".mgi-langCPP .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langCPP[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langCPP .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langCPP[data-mount] .press{animation:none}"#,
        #".mgi-langCPP[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langCPP[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langCPP[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.langRB] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-red))"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:#fff" x="6.375" y="7.55" font-size="3.4">RB</text></g>"#,
      css: [
        #".mgi-langRB .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langRB[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langRB .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langRB[data-mount] .press{animation:none}"#,
        #".mgi-langRB[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langRB[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langRB[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.langKT] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-purple))"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:#fff" x="6.375" y="7.55" font-size="3.4">KT</text></g>"#,
      css: [
        #".mgi-langKT .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langKT[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langKT .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langKT[data-mount] .press{animation:none}"#,
        #".mgi-langKT[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langKT[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langKT[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.langJava] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-brown))"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:#fff" x="6.375" y="7.55" font-size="2.6">JAVA</text></g>"#,
      css: [
        #".mgi-langJava .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langJava[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langJava .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langJava[data-mount] .press{animation:none}"#,
        #".mgi-langJava[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langJava[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langJava[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.langMetal] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,var(--mg-hue-badge-struct))"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:#fff" x="6.375" y="7.55" font-size="2.9">MTL</text></g>"#,
      css: [
        #".mgi-langMetal .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langMetal[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langMetal .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langMetal[data-mount] .press{animation:none}"#,
        #".mgi-langMetal[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langMetal[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langMetal[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.langShell] = AnimatedGlyphSource(
      box: [13, 15], weight: 1.1, triggers: [.hover, .press, .mount],
      markup: #"<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="gl" style="color:var(--mgi-ft,#1d1d1f)"><rect fill="currentColor" stroke="none" x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none" style="fill:var(--mg-hue-green,#34C759)" x="6.375" y="7.55" font-size="3.4">>_</text></g>"#,
      css: [
        #".mgi-langShell .hov{transform-origin:6.5px 14px}"#,
        #".mgi-langShell[data-hover] .hov{animation:mgi-lift \#(T(640)) ease-out}"#,
        #".mgi-langShell .gl{transform-origin:6.375px 7.5px}"#,
        #".mgi-langShell[data-mount] .press{animation:none}"#,
        #".mgi-langShell[data-mount] .gl{animation:mgi-in \#(SP) both}"#,
        #".mgi-langShell[data-hover] .gl{animation:mgi-thud \#(T(560)) ease-out \#(T(100))}"#,
        #".mgi-langShell[data-hover] .tx{animation:mgi-up \#(T(520)) ease-out \#(T(160))}"#,
      ]
    )
    m[.calendar] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press], component: "DatePicker · CalendarView",
      markup: #"<rect x="1.5" y="2.5" width="11" height="10" rx="1.6"/><path d="M1.5 5.6 H12.5"/><g class="rings"><path d="M4.5 1.2 V3.6 M9.5 1.2 V3.6"/></g><rect class="day" x="8" y="8" width="2.4" height="2.4" rx=".5" fill="currentColor" stroke="none"/>"#,
      css: [
        #".mgi-calendar .rings{transform-origin:7px 2.4px}"#,
        #".mgi-calendar[data-hover] .rings{animation:mgi-jig \#(T(460)) ease-out}"#,
        #".mgi-calendar .day{transform-box:fill-box;transform-origin:50% 50%}"#,
        #".mgi-calendar[data-hover] .day{animation:mgi-pop \#(T(620)) ease-out \#(T(80))}"#,
      ]
    )
    m[.clock] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .loop], component: "TimePanel · DatePicker",
      markup: #"<circle cx="7" cy="7" r="5.6"/><path d="M7 7 V3.8"/><g class="hand"><path d="M7 7 L9.2 8.9"/></g>"#,
      css: [
        #".mgi-clock .hand{transform-origin:7px 7px}"#,
        #".mgi-clock[data-hover] .hand{animation:mgi-turn360 \#(T(760)) ease-out}"#,
        #".mgi-clock[data-loop] .hand{animation:mgi-spin \#(T(2600)) linear infinite}"#,
      ]
    )
    m[.color] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press], component: "ColorPicker · ColorWell",
      markup: #"<circle class="c1" cx="7" cy="5" r="2.9"/><circle class="c2" cx="5.1" cy="8.4" r="2.9"/><circle class="c3" cx="8.9" cy="8.4" r="2.9"/>"#,
      css: [
        #".mgi-color .c1,.mgi-color .c2,.mgi-color .c3{transition:transform \#(SP)}"#,
        #".mgi-color[data-hovering] .c1{transform:translateY(-.8px)}"#,
        #".mgi-color[data-hovering] .c2{transform:translate(-.7px,.45px)}"#,
        #".mgi-color[data-hovering] .c3{transform:translate(.7px,.45px)}"#,
      ]
    )
    m[.slider] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press], component: "Slider",
      markup: #"<path d="M1.5 4.5 H12.5 M1.5 9.5 H12.5"/><circle class="k1" cx="4.5" cy="4.5" r="1.7" fill="currentColor"/><circle class="k2" cx="9.5" cy="9.5" r="1.7" fill="currentColor"/>"#,
      css: [
        #".mgi-slider .k1,.mgi-slider .k2{transition:transform \#(SP)}"#,
        #".mgi-slider[data-hovering] .k1{transform:translateX(5px)}"#,
        #".mgi-slider[data-hovering] .k2{transform:translateX(-5px)}"#,
      ]
    )
    m[.toggle] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .state], state: "on", component: "Toggle",
      markup: #"<rect class="bg" x="1" y="3.5" width="12" height="7" rx="3.5" fill="currentColor" stroke="none"/><rect x="1" y="3.5" width="12" height="7" rx="3.5"/><circle class="kn" cx="4.5" cy="7" r="2" fill="currentColor" stroke="none"/>"#,
      css: [
        #".mgi-toggle .bg{opacity:0;transition:opacity \#(T(200))}"#,
        #".mgi-toggle[data-active="true"] .bg{opacity:.25}"#,
        #".mgi-toggle .kn{transform-box:fill-box;transform-origin:50% 50%;transition:transform \#(SP)}"#,
        #".mgi-toggle[data-active="true"] .kn{transform:translateX(5px)}"#,
        #".mgi-toggle[data-hover] .hov{animation:mgi-thud \#(T(520)) ease-out}"#,
      ]
    )
    m[.code] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press], component: "CodeEditor",
      markup: #"<g class="lt"><path d="M4.4 4 L1.5 7 L4.4 10"/></g><g class="gt"><path d="M9.6 4 L12.5 7 L9.6 10"/></g><path class="sl" d="M8.1 3 L5.9 11"/>"#,
      css: [
        #".mgi-code .lt,.mgi-code .gt{transition:transform \#(SP)}"#,
        #".mgi-code[data-hovering] .lt{transform:translateX(-.8px)}"#,
        #".mgi-code[data-hovering] .gt{transform:translateX(.8px)}"#,
        #".mgi-code .sl{transform-origin:7px 7px}"#,
        #".mgi-code[data-hover] .sl{animation:mgi-wobble \#(T(560)) ease-out}"#,
      ]
    )
    m[.dock] = AnimatedGlyphSource(
      box: [14, 14], weight: 1.2, triggers: [.hover, .press, .state], state: "docked", component: "DockTabBar · DropPreview",
      markup: #"<rect x="1.5" y="2.5" width="11" height="9" rx="1.6"/><path class="dv" d="M8 2.5 V11.5"/><rect class="pn" x="8.6" y="3.2" width="3.2" height="7.6" rx=".6" fill="var(--mgi-fill,currentColor)" stroke="none"/>"#,
      css: [
        #".mgi-dock .pn{transform-box:fill-box;transform-origin:100% 50%;transform:scaleX(0);opacity:0;transition:transform \#(SP),opacity \#(T(160))}"#,
        #".mgi-dock[data-hovering] .pn{transform:none;opacity:.45}"#,
        #".mgi-dock[data-active="true"] .pn{transform:none;opacity:.85}"#,
        #".mgi-dock[data-to="true"] .hov{animation:mgi-pop \#(T(560)) ease-out}"#,
      ]
    )
    return m
  }()
}

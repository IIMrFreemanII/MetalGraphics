import { React, kebab } from "../react";
import type { IconName } from "./foundation";
import spec from "../../generated/animated-icons.json";

// The animated glyphs of the Claude Design template "Animated icons", from
// `generated/animated-icons.json`: the markup and CSS the Swift library's `AnimatedGlyph` sources
// hold, exported by `DesignTokenExportTests`. This file plays them as the template's
// `<mg-anim-icon>` does: the CSS goes in once, and the svg's `data-*` flags drive it.

type Glyph = {
  box: [number, number];
  weight: number;
  triggers: string[];
  state?: string;
  defaultActive?: boolean;
  component?: string;
  markup: string;
  css: string[];
  morphs?: Record<string, string>;
  snippetCss?: string[];
  pointer?: [number, number];
};
type Spec = {
  spring: { stiffness: number; damping: number; ms: number; linear: string };
  morphSpring: { stiffness: number; damping: number };
  base: string[];
  keyframes: Record<string, string>;
  glyphs: Record<string, Glyph>;
};

const S = spec as unknown as Spec;

export type AnimatedGlyphName =
  | "chevronRight" | "chevronDown" | "chevronLeft" | "upDown" | "checkmark" | "folder" | "document" | "magnifier" | "xmark" | "plus" | "trash" | "gear"
  | "searchClear" | "spinner" | "copyCheck" | "bell" | "lock" | "eye" | "playPause" | "refresh" | "menuX" | "warning" | "error" | "note" | "pin" | "sort"
  | "stepperMinus" | "stepperPlus" | "splitRight" | "splitBottom" | "splitLeft" | "splitTop" | "sidebarLeft" | "sidebarRight"
  | "swift" | "fileImage" | "fileVideo" | "fileAudio" | "fileArchive" | "fileCode" | "fileJSON" | "fileSheet" | "filePDF" | "fileFont"
  | "langJS" | "langTS" | "langPY" | "langRS" | "langGO" | "langC" | "langCPP" | "langRB" | "langKT" | "langJava" | "langMetal" | "langShell"
  | "calendar" | "clock" | "color" | "slider" | "toggle" | "code" | "dock";

/** The animated glyph drawn where a component took a static `Icon` name: the one of the same name. */
export function glyphFor(icon: IconName): AnimatedGlyphName {
  return icon as AnimatedGlyphName;
}

/** Every glyph's name, and the components it belongs to (empty when none). */
export const animatedGlyphs: Record<AnimatedGlyphName, string> = Object.fromEntries(
  Object.entries(S.glyphs).map(([name, g]) => [name, g.component ?? ""])
) as Record<AnimatedGlyphName, string>;

/** A glyph's box (its size at scale 1), triggers, state and default, as the template's `meta()`. */
export function glyphMeta(name: AnimatedGlyphName) {
  const g = S.glyphs[name];
  return g && { name, size: g.box, triggers: g.triggers, state: g.state ?? null, defaultActive: !!g.defaultActive };
}

/** The CSS custom properties the glyphs' spring reads, as the template sets them on its host. */
export const animatedIconRootVars = `--mgi-spring:${S.spring.linear};--mgi-sd:${S.spring.ms}ms`;

const markupFor = (name: AnimatedGlyphName) =>
  `<g class="press"><g class="st"><g class="hov">${S.glyphs[name].markup}</g></g></g>`;

function keyframesFor(rules: string[]) {
  const used = new Set((rules.join(" ").match(/mgi-[a-z0-9-]+/g) || []).filter((k) => S.keyframes[k]));
  return [...used].map((k) => `@keyframes ${k}{${S.keyframes[k]}}`);
}

// An HTML comment's opening, made at run time: the bundle is inlined into a <script>, where the
// literal would be read as markup.
const COMMENT = String.fromCharCode(60) + "!--";

/** One glyph as standalone SVG and CSS, as the template's Code panel shows it. */
export function animatedIconSnippet(name: AnimatedGlyphName) {
  const g = S.glyphs[name];
  if (!g) return "";
  const [w, h] = g.box;
  const rules = [...S.base, ...g.css];
  return `${COMMENT} ${name}: ${g.triggers.join(", ")}${g.state ? ` · data-active="true" = ${g.state}` : ""} -->
<svg class="mgi mgi-${name}" xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" fill="none" stroke="currentColor" stroke-width="${g.weight || 1}" style="--c:${w / 2}px ${h / 2}px" aria-hidden="true">
  ${markupFor(name)}
</svg>

<style>
:root{${animatedIconRootVars};--mgi-t:1}
${[...rules, ...keyframesFor(rules)].join("\n")}${g.snippetCss ? "\n" + g.snippetCss.join("\n") : ""}
</style>

${COMMENT} Drive it with attributes on the <svg>:
  data-hover     re-add on pointerenter (one-shot)
  data-hovering  present while the pointer is over
  data-press     present while pressed
  data-active    "true" | "false" (state)
  data-to        re-add when the state changes (one-shot)
  data-loop      loops
  data-mount     entrance (one-shot) -->`;
}

/** Every glyph's CSS, the shared rules and the keyframes, in the page once. */
function installStyles() {
  if (typeof document === "undefined" || document.getElementById("mg-anim-icons")) return;
  const rules = [...S.base, ...Object.values(S.glyphs).flatMap((g) => g.css)];
  const style = document.createElement("style");
  style.id = "mg-anim-icons";
  style.textContent = [`.mgi{${animatedIconRootVars}}`, ...rules, ...keyframesFor(rules)].join("\n");
  document.head.appendChild(style);
}

const ROLES = new Set(["label", "secondaryLabel", "tertiaryLabel", "accent", "accentForeground", "destructive", "warning", "success", "placeholder"]);
/** A role ("secondaryLabel") or a hue ("folder") as its variable; any CSS colour as it is. */
function colour(c?: string) {
  if (!c) return undefined;
  if (/^(#|var\(|rgb|hsl|oklch|currentColor)/.test(c)) return c;
  return ROLES.has(c) ? `var(--mg-color-${kebab(c)})` : `var(--mg-hue-${kebab(c)})`;
}

/** The element whose pointer plays the glyph: a marked host, else its button, link or row, else itself. */
const HOSTS = 'button,a,label,[role=option],[role=button],[role=switch],[role=menuitem],[role=menuitemcheckbox],[role=tab],[role=radio],[role=treeitem]';
function findHost(svg: SVGSVGElement): Element {
  return svg.closest("[data-icon-host],[data-anim-host]") || svg.parentElement?.closest(HOSTS) || svg;
}

const NUM = /-?\d*\.?\d+/g;
function lerpD(a: string, b: string, p: number) {
  const A = a.match(NUM)!.map(Number), B = b.match(NUM)!.map(Number), parts = a.split(NUM);
  let o = parts[0];
  for (let i = 0; i < A.length; i++) o += (A[i] + (B[i] - A[i]) * p).toFixed(2) + parts[i + 1];
  return o;
}

export type AnimatedIconTrigger = "hover" | "click" | "active" | "loop" | "none";

/**
 * One of the design system's animated glyphs, as the Claude Design template "Animated icons"
 * draws it: its own box (the static icon's size at `scale` 1), in the text colour or a role. The
 * pointer on its host (the button, link or row it sits in) plays it: a one-shot as it enters, a
 * pose while it stays, a squash while pressed. `active` holds a state (undefined leaves it unset),
 * `loop` repeats a motion, `mount` plays an entrance. Mirrors `AnimatedIcon` in MetalGraphics.
 */
export function AnimatedIcon({
  glyph,
  active,
  loop,
  mount,
  replay,
  trigger = "hover",
  scale = 1,
  size,
  speed = 1,
  color,
  fill,
  badge,
  check,
  swift,
  fileType,
  label,
  state,
  className,
  style,
}: {
  glyph: AnimatedGlyphName;
  /** Its state: true or false; undefined for none. */
  active?: boolean;
  /** Repeats its motion, where it has one. */
  loop?: boolean;
  /** Plays its entrance as it appears. */
  mount?: boolean;
  /** A changed value plays the entrance again. */
  replay?: number;
  /** `click`: a click on its host toggles `active`; `none`: its host does nothing. */
  trigger?: AnimatedIconTrigger;
  /** Its size is its box times this. */
  scale?: number;
  /** When set, fits its box's longer side to this many pixels. */
  size?: number;
  /** How fast it plays: 0.5 is half speed. */
  speed?: number;
  color?: string;
  /** Colours for its tintable parts: a split's or the dock's fill, the bell's badge, the copied check, the Swift bird, a document's type. */
  fill?: string;
  badge?: string;
  check?: string;
  swift?: string;
  fileType?: string;
  label?: string;
  /** Shows a pointer state without a pointer (previews). */
  state?: "hover" | "pressed" | "focused" | "disabled";
  className?: string;
  style?: React.CSSProperties;
}) {
  installStyles();
  const g = S.glyphs[glyph] ?? S.glyphs.checkmark;
  const [w, h] = g.box;
  const k = size ? size / Math.max(w, h) : scale;
  const ref = React.useRef<SVGSVGElement>(null);
  const timers = React.useRef<Record<string, ReturnType<typeof setTimeout>>>({});
  const t = 1 / Math.max(0.05, +speed || 1);

  // A click on the host toggles an uncontrolled state.
  const [toggled, setToggled] = React.useState<boolean | undefined>(active);
  React.useEffect(() => setToggled(active), [active]);
  const current = trigger === "click" ? toggled : active;
  const looping = !!loop || trigger === "loop";

  const pulse = React.useCallback((attr: string, value: string, ms: number) => {
    const s = ref.current;
    if (!s) return;
    s.removeAttribute(attr);
    void s.getBoundingClientRect();
    s.setAttribute(attr, value);
    clearTimeout(timers.current[attr]);
    timers.current[attr] = setTimeout(() => s.isConnected && s.removeAttribute(attr), ms * t);
  }, [t]);

  // The play/pause morph: a spring stepped by hand, as the template does.
  const morph = React.useRef({ p: 0, v: 0, target: 0, raf: 0 });
  const drawMorph = React.useCallback(() => {
    const s = ref.current;
    if (!s || !g.morphs) return;
    for (const [cls, to] of Object.entries(g.morphs)) {
      const path = s.querySelector<SVGPathElement>(`.${cls}`);
      const from = path?.dataset.from ?? path?.getAttribute("d");
      if (!path || !from) continue;
      path.dataset.from = from;
      path.setAttribute("d", lerpD(from, to, morph.current.p));
    }
  }, [g]);
  const startMorph = React.useCallback((target: number) => {
    const m = morph.current;
    m.target = target;
    if (m.raf) return;
    const { stiffness: kk, damping } = S.morphSpring, c = 2 * damping * Math.sqrt(kk);
    let last = performance.now();
    const step = (now: number) => {
      const dt = Math.min(0.032, (now - last) / 1000) / t; last = now;
      m.v += (-kk * (m.p - m.target) - c * m.v) * dt; m.p += m.v * dt;
      if (Math.abs(m.p - m.target) < 0.001 && Math.abs(m.v) < 0.01) { m.p = m.target; m.v = 0; drawMorph(); m.raf = 0; return; }
      drawMorph(); m.raf = requestAnimationFrame(step);
    };
    m.raf = requestAnimationFrame(step);
  }, [drawMorph, t]);

  // `active`: data-active, and a data-to pulse when it changes after the first render.
  const first = React.useRef(true);
  React.useLayoutEffect(() => {
    const s = ref.current;
    if (!s) return;
    const v = current === undefined ? null : current ? "true" : "false";
    const prev = s.getAttribute("data-active");
    if (v === null) s.removeAttribute("data-active"); else s.setAttribute("data-active", v);
    if (g.morphs) {
      if (first.current) { morph.current.p = morph.current.target = v === "true" ? 1 : 0; drawMorph(); }
      else startMorph(v === "true" ? 1 : 0);
    }
    if (!first.current && v !== null && prev !== v) pulse("data-to", v, 1400);
    first.current = false;
  }, [current, glyph]);

  React.useLayoutEffect(() => {
    const s = ref.current;
    if (!s) return;
    if (looping) s.setAttribute("data-loop", ""); else s.removeAttribute("data-loop");
  }, [looping, glyph]);

  React.useEffect(() => {
    if (mount) pulse("data-mount", "", 1400);
  }, []);
  const replayed = React.useRef(replay);
  React.useEffect(() => {
    if (replay !== replayed.current) { replayed.current = replay; pulse("data-mount", "", 1400); }
  }, [replay]);

  // Previews: a pointer state held without a pointer.
  React.useEffect(() => {
    const s = ref.current;
    if (!s || !state) return;
    if (state === "hover" || state === "focused") { s.setAttribute("data-hovering", ""); pulse("data-hover", "", 1600); }
    if (state === "pressed") { s.setAttribute("data-hovering", ""); s.setAttribute("data-press", ""); }
    return () => { s.removeAttribute("data-hovering"); s.removeAttribute("data-press"); };
  }, [state]);

  // The host's pointer.
  React.useEffect(() => {
    const s = ref.current;
    if (!s || trigger === "none" || state) return;
    const host = findHost(s);
    const handlers: Record<string, (e: PointerEvent) => void> = {
      pointerenter: () => { s.setAttribute("data-hovering", ""); pulse("data-hover", "", 1600); },
      pointerleave: () => { s.removeAttribute("data-hovering"); s.removeAttribute("data-press"); s.style.removeProperty("--mgi-px"); s.style.removeProperty("--mgi-py"); },
      pointerdown: () => s.setAttribute("data-press", ""),
      pointerup: () => s.removeAttribute("data-press"),
      pointercancel: () => s.removeAttribute("data-press"),
    };
    if (g.pointer) {
      const [rx, ry] = g.pointer;
      handlers.pointermove = (e) => {
        const r = s.getBoundingClientRect(), cl = (x: number) => Math.max(-1, Math.min(1, x));
        s.style.setProperty("--mgi-px", (cl((e.clientX - r.left - r.width / 2) / (r.width * 1.2)) * rx).toFixed(2) + "px");
        s.style.setProperty("--mgi-py", (cl((e.clientY - r.top - r.height / 2) / (r.height * 1.2)) * ry).toFixed(2) + "px");
      };
    }
    const click = () => setToggled((a) => !a);
    for (const [name, fn] of Object.entries(handlers)) host.addEventListener(name, fn as EventListener);
    if (trigger === "click") host.addEventListener("click", click);
    return () => {
      for (const [name, fn] of Object.entries(handlers)) host.removeEventListener(name, fn as EventListener);
      host.removeEventListener("click", click);
    };
  }, [glyph, trigger, state, pulse]);

  React.useEffect(() => () => {
    cancelAnimationFrame(morph.current.raf);
    for (const id of Object.values(timers.current)) clearTimeout(id);
  }, []);

  const vars: Record<string, string> = { "--c": `${w / 2}px ${h / 2}px` };
  if (t !== 1) vars["--mgi-t"] = String(t);
  const tints: [string, string | undefined][] = [["--mgi-fill", fill], ["--mgi-badge", badge], ["--mgi-check", check], ["--mgi-swift", swift], ["--mgi-ft", fileType]];
  for (const [name, value] of tints) if (value) vars[name] = colour(value)!;

  return (
    <svg
      ref={ref}
      key={glyph}
      className={["mgi", `mgi-${glyph}`, className].filter(Boolean).join(" ")}
      width={+(w * k).toFixed(2)}
      height={+(h * k).toFixed(2)}
      viewBox={`0 0 ${w} ${h}`}
      fill="none"
      stroke="currentColor"
      strokeWidth={g.weight || 1}
      role={label ? "img" : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
      style={{ display: "inline-block", flex: "none", verticalAlign: "middle", overflow: "visible", color: colour(color), ...vars, ...style } as React.CSSProperties}
      dangerouslySetInnerHTML={{ __html: markupFor(glyph) }}
    />
  );
}

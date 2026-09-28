import { React, cx, type Common } from "../react";
import { Glass, Icon } from "./foundation";
import { Button, TextField } from "./controls";
import { KindBadge, ListRow } from "./lists";

// ── CodeEditor ──────────────────────────────────────────────────────────

export type SyntaxToken =
  | "keyword" | "type" | "function" | "string" | "number" | "comment" | "attribute" | "directive"
  | "operatorSymbol" | "punctuation" | "variable" | "constant" | "heading1" | "emphasis" | "strong"
  | "code" | "link" | "markup" | "quote" | "listMarker" | "strikethrough" | "output" | "error" | "prompt"
  | "success";

export type Severity = "error" | "warning" | "info" | "hint";

export interface CodeSpan {
  text: string;
  token?: SyntaxToken;
}

export interface CodeLine {
  /** The line as styled runs; or `text` for a plain line. */
  spans?: CodeSpan[];
  text?: string;
  /** A dot in the gutter by the line number. */
  diagnostic?: Severity;
  /** The fold column's chevron: "open" (down) or "closed" (right, and a "⋯" after the text). */
  fold?: "open" | "closed";
}

/** A range on one line, in characters (the font is monospaced: a column is 1ch). */
export interface CodeRange {
  line: number;
  from: number;
  to: number;
}

const kebab = (s: string) => s.replace(/([a-z0-9])([A-Z])/g, "$1-$2").replace(/([a-z])([0-9])/g, "$1-$2").toLowerCase();

/**
 * Code, drawn as the library's `TextEditor` draws it with the design system's `EditorTheme`: a gutter
 * of line numbers (diagnostic dots, fold chevrons), the current line, selections, search matches,
 * error squiggles and a caret. Static: it shows the state it is given. Lines and columns are 0-based.
 */
export function CodeEditor({
  lines,
  firstLineNumber = 1,
  currentLine,
  selections = [],
  matches = [],
  currentMatch,
  squiggles = [],
  caret,
  focused = true,
  lineNumbers = true,
  folding = false,
  className,
  style,
}: Common & {
  lines: CodeLine[];
  firstLineNumber?: number;
  /** The line with the caret, highlighted across the view. */
  currentLine?: number;
  selections?: CodeRange[];
  matches?: CodeRange[];
  /** The index in `matches` of the current one. */
  currentMatch?: number;
  squiggles?: (CodeRange & { severity?: Severity })[];
  caret?: { line: number; column: number };
  /** Unfocused, selections take the inactive colour and the caret hides. */
  focused?: boolean;
  lineNumbers?: boolean;
  /** Shows the fold column. */
  folding?: boolean;
}) {
  const places = Math.max(3, String(firstLineNumber + lines.length - 1).length);
  const overlay = (r: CodeRange, cls: string, key: string, extra?: Record<string, string>) => (
    <span
      key={key}
      className={cls}
      style={{ left: `calc(var(--mg-editor-inset-x) + ${r.from}ch)`, width: `${Math.max(r.to - r.from, 0)}ch`, ...extra }}
    />
  );
  return (
    <div
      className={cx("mg-code", className)}
      data-focused={focused ? "" : undefined}
      style={{ "--code-places": places, ...style } as React.CSSProperties}
    >
      {lines.map((line, i) => {
        const sel = selections.filter((r) => r.line === i);
        const found = matches.map((m, j) => ({ ...m, j })).filter((m) => m.line === i);
        const waves = squiggles.filter((s) => s.line === i);
        return (
          <div key={i} className="mg-code__line" data-current={i === currentLine ? "" : undefined}>
            {(lineNumbers || folding) && (
              <span className="mg-code__gutter">
                {line.diagnostic && <span className="mg-code__dot" data-severity={line.diagnostic} />}
                {lineNumbers && <span className="mg-code__number">{firstLineNumber + i}</span>}
                {folding && (
                  <span className="mg-code__fold">
                    {line.fold && <Icon name={line.fold === "open" ? "chevronDown" : "chevronRight"} />}
                  </span>
                )}
              </span>
            )}
            <span className="mg-code__text">
              {sel.map((r, k) => overlay(r, "mg-code__selection", `s${k}`))}
              {found.map((m) => overlay(m, "mg-code__match", `m${m.j}`, m.j === currentMatch ? { background: "var(--mg-editor-current-search-match)" } : undefined))}
              <span className="mg-code__runs">
                {line.spans
                  ? line.spans.map((s, k) => (
                      <span key={k} className={s.token ? `mg-syntax-${kebab(s.token)}` : undefined}>
                        {s.text}
                      </span>
                    ))
                  : line.text}
                {line.fold === "closed" && (
                  <span className="mg-code__folded" aria-label="Folded">
                    <i />
                    <i />
                    <i />
                  </span>
                )}
              </span>
              {waves.map((w, k) => overlay(w, "mg-code__squiggle", `w${k}`, { background: `var(--mg-editor-diagnostic-${w.severity ?? "error"})` }))}
              {caret && caret.line === i && focused && (
                <span className="mg-code__caret" style={{ left: `calc(var(--mg-editor-inset-x) + ${caret.column}ch)` }} />
              )}
            </span>
          </div>
        );
      })}
    </div>
  );
}

// ── Find bar ────────────────────────────────────────────────────────────

/** A small on/off chip: Aa, Word, .* in the find bar. The selection behind it when on. */
export function ToggleChip({ isOn = false, onToggle, label, className, style, children }: Common & { isOn?: boolean; onToggle?: () => void; label?: string }) {
  return (
    <button type="button" className={cx("mg-toggle-chip", className)} aria-pressed={isOn} aria-label={label} onClick={onToggle} style={style}>
      {children}
    </button>
  );
}

/**
 * The editor's find (and replace) bar: the query with a magnifier, the match count, previous and
 * next, the Aa / Word / .* options, the replacement, Replace and All, and Done. Mirrors the
 * Editor's `FileEditorPanel` find bar.
 */
export function FindBar({
  query,
  replacement,
  count,
  caseSensitive = false,
  wholeWord = false,
  regex = false,
  showReplace = true,
  focused = true,
  className,
  style,
}: Common & {
  query?: string;
  replacement?: string;
  /** "4 of 8", "No results". */
  count?: string;
  caseSensitive?: boolean;
  wholeWord?: boolean;
  regex?: boolean;
  showReplace?: boolean;
  /** Draws the query field focused. */
  focused?: boolean;
}) {
  return (
    <div className={cx("mg-find-bar", className)} role="search" style={style}>
      <TextField icon="magnifier" placeholder="Find" defaultValue={query} width={220} label="Find" state={focused ? "focused" : undefined} />
      <span className="mg-find-bar__count">{count}</span>
      <Button variant="bordered" icon="chevronLeft" label="Previous match" />
      <Button variant="bordered" icon="chevronRight" label="Next match" />
      <ToggleChip isOn={caseSensitive} label="Match case">Aa</ToggleChip>
      <ToggleChip isOn={wholeWord} label="Whole word">Word</ToggleChip>
      <ToggleChip isOn={regex} label="Regular expression">.*</ToggleChip>
      {showReplace && (
        <>
          <span className="mg-find-bar__rule" />
          <TextField placeholder="Replace" defaultValue={replacement} width={160} label="Replace" />
          <Button variant="bordered">Replace</Button>
          <Button variant="bordered">All</Button>
        </>
      )}
      <span style={{ flex: 1 }} />
      <Button>Done</Button>
    </div>
  );
}

// ── Completion ──────────────────────────────────────────────────────────

export interface CompletionItem {
  /** C class, S struct, E enum, P property, M method, V variable, Pr protocol. */
  badge: string;
  label: string;
  detail?: string;
}

const badgeHue = (letter: string) =>
  ({ M: "badgeMethod", P: "badgeProperty", V: "badgeVariable", C: "badgeClass", S: "badgeStruct", E: "badgeEnum", c: "badgeEnum", Pr: "indigo" })[letter] ?? "gray";

/**
 * The completion popup: menu glass, a row per candidate with its kind badge, name and type, the
 * selected one on the accent, and a detail line under a hairline. Mirrors the Editor's completion.
 */
export function CompletionList({ items, selected = 0, footer, className, style }: Common & { items: CompletionItem[]; selected?: number; footer?: string }) {
  return (
    <Glass role="menu" className={cx("mg-completion", className)} style={style}>
      <div role="listbox" aria-label="Completions">
        {items.map((item, i) => (
          <ListRow key={item.label + i} selected={i === selected} prominent height={26} margin={0} spacing={8}>
            <KindBadge letter={item.badge} hue={badgeHue(item.badge)} />
            <span className="mg-completion__label">{item.label}</span>
            <span style={{ flex: 1 }} />
            {item.detail && <span className="mg-completion__detail">{item.detail}</span>}
          </ListRow>
        ))}
      </div>
      {footer && <div className="mg-completion__footer">{footer}</div>}
    </Glass>
  );
}

// ── Status bar ──────────────────────────────────────────────────────────

/** The line under an editor: where the caret is, the first problem, and the file. Mirrors the Editor's status line. */
export function StatusBar({ position, problem, file, className, style, children }: Common & { position?: string; problem?: string; file?: string }) {
  return (
    <div className={cx("mg-status-bar", className)} style={style}>
      {position && <span>{position}</span>}
      {problem && <span className="mg-status-bar__problem">{problem}</span>}
      {children}
      <span style={{ flex: 1 }} />
      {file && <span>{file}</span>}
    </div>
  );
}


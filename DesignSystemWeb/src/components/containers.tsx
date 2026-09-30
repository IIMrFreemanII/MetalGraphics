import { React, cx, type Common } from "../react";
import { Glass, type IconName } from "./foundation";
import { AnimatedIcon, glyphFor } from "./motion";
import { Button, type ButtonVariant } from "./controls";

/** Settings on the grouped background, in a column at most 600 wide. Mirrors `Form`. */
export function Form({ className, style, children }: Common) {
  return (
    <div className={cx("mg-form", className)} style={style}>
      <div className="mg-form__column">{children}</div>
    </div>
  );
}

/** A card of rows, with a header above and a footer below. Mirrors `Section`. */
export function Section({ header, footer, className, style, children }: Common & { header?: string; footer?: string }) {
  return (
    <section className={cx("mg-section", className)} style={style}>
      {header && <h3 className="mg-section__header">{header}</h3>}
      <div className="mg-section__card">{children}</div>
      {footer && <p className="mg-section__footer">{footer}</p>}
    </section>
  );
}

/** A row in a `Section`: a label on the leading side, a control or `value` on the trailing side, hairlines between rows. */
export function FormRow({ label, value, className, style, children }: Common & { label?: string; value?: string }) {
  return (
    <div className={cx("mg-form-row", className)} style={style}>
      {label !== undefined && <span className="mg-form-row__label">{label}</span>}
      {value !== undefined && <span className="mg-form-row__value">{value}</span>}
      {children}
    </div>
  );
}

// ── Surfaces ────────────────────────────────────────────────────────────

/** A popover's glass card, radius 10, with a hairline and a shadow. Mirrors `.popover`'s card. */
export function Popover({ className, style, children }: Common) {
  return (
    <Glass role="popover" className={cx("mg-popover", className)} style={style}>
      {children}
    </Glass>
  );
}

/** A menu on menu glass: `MenuItem`s and `MenuSeparator`s. Mirrors a picker's or context menu. */
export function Menu({ label, className, style, children }: Common & { label?: string }) {
  return (
    <Glass role="menu" className={cx("mg-menu", className)} style={style}>
      <div role="menu" aria-label={label} style={{ display: "contents" }}>
        {children}
      </div>
    </Glass>
  );
}

/** An item in a `Menu`: a check column, the label, a shortcut. Hover shows the selection. */
export function MenuItem({
  checked = false,
  shortcut,
  onClick,
  state,
  className,
  style,
  children,
}: Common & { checked?: boolean; shortcut?: string; onClick?: () => void }) {
  return (
    <button
      type="button"
      role={checked ? "menuitemcheckbox" : "menuitem"}
      aria-checked={checked || undefined}
      className={cx("mg-menu-item", className)}
      data-state={state}
      disabled={state === "disabled"}
      onClick={onClick}
      style={style}
    >
      <span className="mg-menu-item__check">
        <AnimatedIcon glyph="checkmark" active={!!checked} />
      </span>
      <span className="mg-menu-item__label">{children}</span>
      {shortcut && <span className="mg-menu-item__shortcut">{shortcut}</span>}
    </button>
  );
}

export function MenuSeparator() {
  return <div className="mg-menu-separator" role="separator" />;
}

/** A tooltip on tooltip glass. */
export function Tooltip({ multiline = false, className, style, children }: Common & { multiline?: boolean }) {
  return (
    <Glass role="tooltip" className={cx("mg-tooltip", multiline && "mg-tooltip--card", className)} style={style}>
      <span role="tooltip">{children}</span>
    </Glass>
  );
}

/** Dims what is behind a sheet or alert, and centres it. */
export function Scrim({ className, style, children }: Common) {
  return (
    <div className={cx("mg-scrim", className)} style={style}>
      {children}
    </div>
  );
}

export interface SheetAction {
  label: string;
  variant?: ButtonVariant;
  destructive?: boolean;
  /** An alert orders and styles its actions by role: cancel goes first side by side, last when stacked. */
  role?: "cancel" | "destructive";
  onClick?: () => void;
}

/** A sheet: sheet glass, radius 12, a title, content and actions at the trailing end. Mirrors `.sheet`. */
export function Sheet({ title, actions = [], width = 420, className, style, children }: Common & { title?: string; actions?: SheetAction[]; width?: number }) {
  return (
    <Glass role="sheet" className={cx("mg-sheet", className)} style={{ width, ...style }}>
      <div role="dialog" aria-label={title} style={{ display: "contents" }}>
        {title && <h2 className="mg-sheet__title">{title}</h2>}
        {children}
        {actions.length > 0 && (
          <div className="mg-sheet__actions">
            {actions.map((a) => (
              <Button key={a.label} variant={a.variant ?? "bordered"} destructive={a.destructive} onClick={a.onClick}>
                {a.label}
              </Button>
            ))}
          </div>
        )}
      </div>
    </Glass>
  );
}

/**
 * An alert: a narrow sheet with a centred title, a message and full-width buttons. As the library lays
 * it out: two actions or fewer sit side by side with cancel on the left; more stack, cancel last. The
 * first action without a role is the default, prominent; the rest are bordered (an explicit `variant`
 * wins). Mirrors `.alert`.
 */
export function Alert({
  title,
  message,
  actions = [{ label: "OK" }],
  layout = "auto",
  titleVisible = true,
  className,
  style,
}: Common & { title: string; message?: string; actions?: SheetAction[]; layout?: "auto" | "row" | "stack"; titleVisible?: boolean }) {
  const stacked = layout === "stack" || (layout === "auto" && actions.length > 2);
  const cancels = actions.filter((a) => a.role === "cancel");
  const others = actions.filter((a) => a.role !== "cancel");
  const ordered = stacked ? [...others, ...cancels] : [...cancels, ...others];
  // The library's default: the first action without a role is prominent. Actions that set their own
  // variant keep the old rule: whatever they do not set is bordered.
  const primary = actions.some((a) => a.variant) ? undefined : ordered.find((a) => !a.role);
  return (
    <Glass role="sheet" className={cx("mg-sheet mg-alert", className)} style={style}>
      <div role="alertdialog" aria-label={title} style={{ display: "contents" }}>
        {titleVisible && <h2 className="mg-sheet__title">{title}</h2>}
        {message && <p className="mg-alert__message">{message}</p>}
        <div className="mg-sheet__actions" data-stacked={stacked ? "" : undefined}>
          {ordered.map((a) => (
            <Button
              key={a.label}
              variant={a.variant ?? (a === primary ? "prominent" : "bordered")}
              destructive={a.destructive || a.role === "destructive"}
              onClick={a.onClick}
            >
              {a.label}
            </Button>
          ))}
        </div>
      </div>
    </Glass>
  );
}

/**
 * A confirmation dialog: an alert whose actions always stack, with a Cancel added when none is given;
 * its title can be hidden. Mirrors `.confirmationDialog`.
 */
export function ConfirmationDialog({
  title,
  message,
  actions = [],
  titleVisible = true,
  className,
  style,
}: Common & { title: string; message?: string; actions?: SheetAction[]; titleVisible?: boolean }) {
  const all = actions.some((a) => a.role === "cancel") ? actions : [...actions, { label: "Cancel", role: "cancel" as const }];
  return <Alert title={title} message={message} actions={all} layout="stack" titleVisible={titleVisible} className={className} style={style} />;
}

// ── Navigation ──────────────────────────────────────────────────────────

/** A 232-wide sidebar on the sidebar tint, with a hairline edge. Mirrors `NavigationSplitView`'s sidebar. */
export function Sidebar({ title, label, className, style, children }: Common & { title?: string; label?: string }) {
  return (
    <nav className={cx("mg-sidebar", className)} aria-label={label ?? title} style={style}>
      {title && <div className="mg-sidebar__title">{title}</div>}
      {children}
    </nav>
  );
}

/** A link in a `Sidebar`: full width, the selection and a medium label when selected. Mirrors `NavigationLink` in a sidebar. */
export function SidebarLink({
  icon,
  selected = false,
  onClick,
  state,
  className,
  style,
  children,
}: Common & { icon?: IconName; selected?: boolean; onClick?: () => void }) {
  return (
    <button
      type="button"
      className={cx("mg-sidebar-link", className)}
      aria-current={selected ? "page" : undefined}
      data-selected={selected ? "" : undefined}
      data-state={state}
      onClick={onClick}
      style={style}
    >
      {icon && <AnimatedIcon glyph={glyphFor(icon)} color="secondaryLabel" />}
      {children}
    </button>
  );
}

/** A 38-tall bar on the bar tint with a headline title; `leading` and `trailing` hold buttons. Mirrors the navigation bar. */
export function NavigationBar({ title, leading, trailing, className, style }: Common & { title: string; leading?: unknown; trailing?: unknown }) {
  return (
    <header className={cx("mg-nav-bar", className)} style={style}>
      <span className="mg-nav-bar__side">{leading as any}</span>
      <span className="mg-nav-bar__title">{title}</span>
      <span className="mg-nav-bar__side mg-nav-bar__side--trailing">{trailing as any}</span>
    </header>
  );
}

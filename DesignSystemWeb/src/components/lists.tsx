import { React, cx, hue, type Common } from "../react";

/**
 * A row in a list, outline or navigator: 24 tall, its highlight inset 8 from the list's edges and
 * its content 8 inside that. Hover shows `hover`; selected shows `selection` and a medium label,
 * or with `prominent` the accent and white. Mirrors `ListRow`.
 *
 * Put a `KindBadge` or `Icon` first, then the label; `detail` goes on the trailing side.
 */
export function ListRow({
  label,
  subtitle,
  detail,
  status,
  selected = false,
  prominent = false,
  height = 24,
  margin = 8,
  indent = 0,
  spacing = 6,
  onClick,
  state,
  className,
  style,
  children,
}: Common & {
  label?: string;
  /** A second line under the label, in the secondary colour: a location, a path. */
  subtitle?: string;
  detail?: string;
  /** An 8pt square before the content: a problem's severity. */
  status?: "error" | "warning" | "note";
  selected?: boolean;
  prominent?: boolean;
  height?: number;
  margin?: number;
  indent?: number;
  spacing?: number;
  onClick?: () => void;
}) {
  return (
    <div
      className={cx("mg-list-row", className)}
      role="option"
      aria-selected={selected}
      data-selected={selected ? "" : undefined}
      data-prominent={prominent ? "" : undefined}
      data-state={state}
      onClick={onClick}
      style={{
        "--row-height": `${height}px`,
        "--row-margin": `${margin}px`,
        "--row-indent": `${indent}px`,
        "--row-spacing": `${spacing}px`,
        ...style,
      } as React.CSSProperties}
    >
      <div className="mg-list-row__face">
        {status && <span className="mg-list-row__status" data-status={status} aria-label={status} />}
        {children}
        {label && !subtitle && <span className="mg-list-row__label">{label}</span>}
        {label && subtitle && (
          <span className="mg-list-row__label mg-list-row__stack">
            <span>{label}</span>
            <span className="mg-list-row__subtitle">{subtitle}</span>
          </span>
        )}
        {detail && <span className="mg-list-row__detail">{detail}</span>}
      </div>
    </div>
  );
}

/** Where a dragged row would drop: a 2pt accent line across the list. Mirrors `ReorderIndicator`. */
export function InsertionLine({ indent = 8, className, style }: { indent?: number; className?: string; style?: React.CSSProperties }) {
  return <div className={cx("mg-insertion-line", className)} role="presentation" style={{ marginInline: indent, ...style }} />;
}

export type BadgeHue = "badgeClass" | "badgeStruct" | "badgeEnum" | "badgeProperty" | "badgeMethod" | "badgeVariable" | string;

/** A symbol's kind as a 16 × 16 tile with a letter: C a class, S a struct, M a method. Mirrors `KindBadge`. */
export function KindBadge({ letter, hue: h = "badgeStruct", className, style }: { letter: string; hue?: BadgeHue; className?: string; style?: React.CSSProperties }) {
  return (
    <span className={cx("mg-kind-badge", className)} style={{ background: hue(h), ...style }} aria-hidden="true">
      {letter}
    </span>
  );
}

/** Columns of cells with a header on the bar colour; selected rows take the selection. Mirrors `Table`. */
export function Table({
  columns,
  rows,
  selected = [],
  className,
  style,
}: Common & { columns: string[]; rows: string[][]; selected?: number[] }) {
  return (
    <table className={cx("mg-table", className)} style={style}>
      <thead>
        <tr>
          {columns.map((column) => (
            <th key={column}>{column}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {rows.map((row, i) => (
          <tr key={i} data-selected={selected.includes(i) ? "" : undefined} aria-selected={selected.includes(i)}>
            {row.map((cell, j) => (
              <td key={j}>{cell}</td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

import { React, cx, type Common } from "../react";
import { Icon } from "./foundation";
import { Slider, Stepper } from "./controls";

// ── ColorPicker ─────────────────────────────────────────────────────────

/** HSB (0…1 each) to a CSS colour, as the library's `rgbFromHSB`. */
function hsb(h: number, s: number, b: number): string {
  const i = Math.floor(h * 6), f = h * 6 - i, p = b * (1 - s), q = b * (1 - f * s), t = b * (1 - (1 - f) * s);
  const [r, g, bl] = [[b, t, p], [q, b, p], [p, b, t], [p, q, b], [t, p, b], [b, p, q]][i % 6];
  return `rgb(${Math.round(r * 255)}, ${Math.round(g * 255)}, ${Math.round(bl * 255)})`;
}

/** The picker's grid, as `ColorPicker.palette`: 12 hues in three shades, and a row of greys. It is the content, not a theme colour. */
const PALETTE: string[][] = [
  ...[[0.35, 1], [0.8, 0.95], [0.9, 0.6]].map(([s, b]) => Array.from({ length: 12 }, (_, i) => hsb(i / 12, s, b))),
  Array.from({ length: 12 }, (_, i) => hsb(0, 0, 1 - i / 11)),
];

/** The 44 × 24 colour well a colour-picker row shows: the colour on a rounded patch, a checkerboard under it when translucent. Mirrors `ColorWell`. */
export function ColorWell({ color = "var(--mg-color-accent)", opacity = 1, label, state, className, style }: Common & { color?: string; opacity?: number; label?: string }) {
  return (
    <button type="button" className={cx("mg-color-well", className)} aria-label={label ?? "Colour"} aria-haspopup="dialog" data-state={state} disabled={state === "disabled"} style={style}>
      <span className="mg-color-well__patch" data-translucent={opacity < 1 ? "" : undefined}>
        <span style={{ background: color, opacity }} />
      </span>
    </button>
  );
}

/** A form row with a label and a colour well. Mirrors `ColorPicker`. */
export function ColorPicker({ label, color, opacity, state, className, style }: Common & { label: string; color?: string; opacity?: number }) {
  return (
    <div className={cx("mg-labeled", "mg-color-picker", className)} style={style}>
      <span>{label}</span>
      <ColorWell color={color} opacity={opacity} label={label} state={state} />
    </div>
  );
}

/**
 * What a colour well opens: the swatch grid (the selection ringed) and Hue, Saturation, Brightness
 * and Opacity sliders. Put it in a `Popover`. Mirrors `ColorPicker.open()`.
 */
export function ColorPickerPanel({
  selected = [2, 7],
  hue = 0.58,
  saturation = 0.9,
  brightness = 0.95,
  opacity,
  className,
  style,
}: Common & { selected?: [number, number]; hue?: number; saturation?: number; brightness?: number; opacity?: number }) {
  const channels: [string, number][] = [["Hue", hue], ["Saturation", saturation], ["Brightness", brightness]];
  if (opacity !== undefined) channels.push(["Opacity", opacity]);
  return (
    <div className={cx("mg-color-panel", className)} style={style}>
      <div className="mg-color-panel__grid" role="listbox" aria-label="Colours">
        {PALETTE.map((row, r) =>
          row.map((c, i) => (
            <span
              key={`${r}-${i}`}
              className="mg-color-swatch"
              role="option"
              aria-selected={selected[0] === r && selected[1] === i}
              data-selected={selected[0] === r && selected[1] === i ? "" : undefined}
              style={{ background: c }}
            />
          ))
        )}
      </div>
      <div className="mg-color-panel__sliders">
        {channels.map(([name, value]) => (
          <div key={name} className="mg-color-panel__channel">
            <span>{name}</span>
            <Slider defaultValue={value} width={148} label={name} />
          </div>
        ))}
      </div>
    </div>
  );
}

// ── DatePicker ──────────────────────────────────────────────────────────

const parse = (iso: string) => {
  const [d, t = "00:00"] = iso.split("T");
  const [y, m, day] = d.split("-").map(Number);
  const [hh, mm] = t.split(":").map(Number);
  return new Date(y, m - 1, day, hh, mm);
};
const sameDay = (a: Date, b: Date) => a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();

/** The chevron-less pill a compact date picker shows its date and time in. Mirrors `PopupFace(chevrons: false)`. */
function Pill({ children, open }: { children: React.ReactNode; open?: boolean }) {
  return (
    <button type="button" className="mg-popup mg-popup--pill" aria-haspopup="dialog" aria-expanded={open}>
      {children}
    </button>
  );
}

/**
 * A month: title with ‹ ›, weekdays, and six weeks of days. The selection is a 26pt accent circle,
 * today is in the accent, days of other months are faint, days outside `min`…`max` fainter. Mirrors `CalendarView`.
 */
export function CalendarView({ date, today, min, max, className, style }: Common & { date: string; today?: string; min?: string; max?: string }) {
  const selected = parse(date);
  const now = today ? parse(today) : selected;
  const lo = min ? parse(min) : undefined, hi = max ? parse(max) : undefined;
  const first = new Date(selected.getFullYear(), selected.getMonth(), 1);
  const start = new Date(first);
  start.setDate(1 - first.getDay());
  const days = Array.from({ length: 42 }, (_, i) => new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
  const title = first.toLocaleDateString("en-US", { month: "long", year: "numeric" });
  return (
    <div className={cx("mg-calendar", className)} style={style}>
      <div className="mg-calendar__header">
        <span className="mg-calendar__title">{title}</span>
        <span style={{ flex: 1 }} />
        <button type="button" className="mg-calendar__step" aria-label="Previous month"><Icon name="chevronLeft" /></button>
        <button type="button" className="mg-calendar__step" aria-label="Next month"><Icon name="chevronRight" /></button>
      </div>
      <div className="mg-calendar__grid" role="grid" aria-label={title}>
        {["S", "M", "T", "W", "T", "F", "S"].map((d, i) => (
          <span key={`w${i}`} className="mg-calendar__weekday">{d}</span>
        ))}
        {days.map((d) => {
          const pickable = (!lo || d >= new Date(lo.getFullYear(), lo.getMonth(), lo.getDate())) && (!hi || d <= hi);
          return (
            <span
              key={d.toISOString()}
              className="mg-calendar__day"
              role="gridcell"
              aria-selected={sameDay(d, selected)}
              data-selected={sameDay(d, selected) ? "" : undefined}
              data-today={sameDay(d, now) ? "" : undefined}
              data-outside={d.getMonth() !== first.getMonth() ? "" : undefined}
              data-disabled={pickable ? undefined : ""}
            >
              <span>{d.getDate()}</span>
            </span>
          );
        })}
      </div>
    </div>
  );
}

/** What a compact picker's time pill opens: hour and minute steppers. Put it in a `Popover`. */
export function TimePanel({ date, className, style }: Common & { date: string }) {
  const d = parse(date);
  return (
    <div className={cx("mg-time-panel", className)} style={style}>
      <div className="mg-labeled"><span>Hour: {d.getHours()}</span><Stepper defaultValue={d.getHours()} min={0} max={23} label="Hour" /></div>
      <div className="mg-labeled"><span>Minute: {String(d.getMinutes()).padStart(2, "0")}</span><Stepper defaultValue={d.getMinutes()} min={0} max={59} label="Minute" /></div>
    </div>
  );
}

/**
 * A date (and time). `compact` shows chevron-less pills that open a calendar and time steppers;
 * `graphical` shows the calendar in place, with the time pill under it. `date` is ISO local time,
 * "2026-09-28T14:30". Mirrors `DatePicker`.
 */
export function DatePicker({
  label,
  date,
  today,
  min,
  max,
  datePickerStyle = "compact",
  showTime = true,
  open,
  state,
  className,
  style,
}: Common & {
  label?: string;
  date: string;
  today?: string;
  min?: string;
  max?: string;
  datePickerStyle?: "compact" | "graphical";
  showTime?: boolean;
  /** Which pill is open, for specs (render its panel in a Popover beside it). */
  open?: "date" | "time";
}) {
  const d = parse(date);
  const day = d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
  const time = d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });
  const pills = (
    <span className="mg-date-picker__pills">
      <Pill open={open === "date"}>{day}</Pill>
      {showTime && <Pill open={open === "time"}>{time}</Pill>}
    </span>
  );
  if (datePickerStyle === "graphical") {
    return (
      <div className={cx("mg-date-picker", "mg-date-picker--graphical", className)} data-state={state} style={style}>
        {label && <span>{label}</span>}
        <CalendarView date={date} today={today} min={min} max={max} />
        {showTime && (
          <div className="mg-labeled">
            <span className="mg-labeled__value">Time</span>
            <Pill>{time}</Pill>
          </div>
        )}
      </div>
    );
  }
  return (
    <div className={cx("mg-labeled", "mg-date-picker", className)} data-state={state} style={style}>
      {label && <span>{label}</span>}
      {pills}
    </div>
  );
}

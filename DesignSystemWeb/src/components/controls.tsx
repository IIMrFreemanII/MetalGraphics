import { React, cx, type Common } from "../react";
import { Icon, type IconName } from "./foundation";

export type ButtonVariant = "borderless" | "plain" | "bordered" | "prominent";

/**
 * A button. `borderless` (the default, like `.automatic`) is an accent label; `plain` a label;
 * `bordered` a fill; `prominent` the accent. `destructive` turns it red. Mirrors `Button` with
 * `.buttonStyle(...)` and `role:`.
 */
export function Button({
  variant = "borderless",
  destructive = false,
  icon,
  label,
  disabled,
  state,
  onClick,
  className,
  style,
  children,
}: Common & { variant?: ButtonVariant; destructive?: boolean; icon?: IconName; label?: string; disabled?: boolean; onClick?: () => void }) {
  return (
    <button
      type="button"
      className={cx("mg-button", `mg-button--${variant}`, className)}
      data-state={state}
      data-role={destructive ? "destructive" : undefined}
      aria-label={label}
      disabled={disabled || state === "disabled"}
      onClick={onClick}
      style={style}
    >
      {icon && <Icon name={icon} />}
      {children}
    </button>
  );
}

/** An on/off switch: a 38 × 22 capsule, the accent when on. Mirrors `Toggle`. */
export function Toggle({
  isOn: controlled,
  defaultOn = false,
  onChange,
  label,
  state,
  className,
  style,
}: Common & { isOn?: boolean; defaultOn?: boolean; onChange?: (on: boolean) => void; label?: string }) {
  const [own, setOwn] = React.useState(defaultOn);
  const on = controlled ?? own;
  return (
    <button
      type="button"
      role="switch"
      aria-checked={on}
      aria-label={label}
      className={cx("mg-toggle", className)}
      data-state={state}
      disabled={state === "disabled"}
      onClick={() => {
        setOwn(!on);
        onChange?.(!on);
      }}
      style={style}
    />
  );
}

/** A single-line text field; `icon` puts a glyph before the text. Mirrors `TextField`, `SecureField` (`secure`), `.leadingIcon`. */
export function TextField({
  placeholder,
  value,
  defaultValue,
  onChange,
  icon,
  secure = false,
  width,
  label,
  state,
  className,
  style,
}: Common & {
  placeholder?: string;
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  icon?: IconName;
  secure?: boolean;
  width?: number;
  label?: string;
}) {
  return (
    <label className={cx("mg-text-field", className)} data-state={state} style={{ "--field-width": width ? `${width}px` : undefined, ...style } as React.CSSProperties}>
      {icon && <Icon name={icon} className="mg-text-field__icon" />}
      <input
        className="mg-text-field__input"
        type={secure ? "password" : "text"}
        placeholder={placeholder}
        value={value}
        defaultValue={defaultValue}
        aria-label={label ?? placeholder}
        disabled={state === "disabled"}
        onChange={onChange ? (e: any) => onChange(e.target.value) : undefined}
      />
    </label>
  );
}

export type PickerStyle = "menu" | "segmented" | "inline";

/**
 * One of several options. `menu` is a pop-up button (it shows the selection; open the menu with
 * `Menu`), `segmented` a row of segments, `inline` rows with a check. Mirrors `Picker` and its
 * `.pickerStyle(...)`.
 */
export function Picker({
  options,
  selection: controlled,
  defaultSelection,
  onChange,
  pickerStyle = "menu",
  chevrons = true,
  label,
  state,
  className,
  style,
}: Common & {
  options: string[];
  selection?: string;
  defaultSelection?: string;
  onChange?: (option: string) => void;
  pickerStyle?: PickerStyle;
  /** The menu style's accent up-down tile; off gives a plain pill, as a date picker's. */
  chevrons?: boolean;
  label?: string;
}) {
  const [own, setOwn] = React.useState(defaultSelection ?? options[0]);
  const selected = controlled ?? own;
  const pick = (option: string) => {
    setOwn(option);
    onChange?.(option);
  };
  if (pickerStyle === "segmented") {
    return (
      <div className={cx("mg-segmented", className)} role="group" aria-label={label} style={style}>
        {options.map((option) => (
          <button
            key={option}
            type="button"
            className="mg-segmented__segment"
            aria-pressed={option === selected}
            onClick={() => pick(option)}
          >
            {option}
          </button>
        ))}
      </div>
    );
  }
  if (pickerStyle === "inline") {
    return (
      <div className={cx("mg-inline-picker", className)} role="radiogroup" aria-label={label} style={style}>
        {options.map((option) => (
          <FormRowLike key={option} onClick={() => pick(option)} checked={option === selected}>
            {option}
          </FormRowLike>
        ))}
      </div>
    );
  }
  return (
    <button type="button" className={cx("mg-popup", !chevrons && "mg-popup--pill", className)} data-state={state} aria-label={label} aria-haspopup="menu" style={style}>
      <span>{selected}</span>
      {chevrons && (
        <span className="mg-popup__arrows">
          <Icon name="upDown" />
        </span>
      )}
    </button>
  );
}

function FormRowLike({ checked, onClick, children }: { checked: boolean; onClick: () => void; children: unknown }) {
  return (
    <div className="mg-form-row mg-inline-picker__option" role="radio" aria-checked={checked} tabIndex={0} onClick={onClick}>
      <span>{children as any}</span>
      {checked && <Icon name="checkmark" className="mg-inline-picker__check" />}
    </div>
  );
}

/** A value along a track, 0…1 by default. Mirrors `Slider`. */
export function Slider({
  value: controlled,
  defaultValue = 0.5,
  min = 0,
  max = 1,
  width,
  label,
  onChange,
  state,
  className,
  style,
}: Common & { value?: number; defaultValue?: number; min?: number; max?: number; width?: number; label?: string; onChange?: (value: number) => void }) {
  const [own, setOwn] = React.useState(defaultValue);
  const value = controlled ?? own;
  const fraction = Math.min(Math.max((value - min) / (max - min || 1), 0), 1);
  const set = (next: number) => {
    const clamped = Math.min(Math.max(next, min), max);
    setOwn(clamped);
    onChange?.(clamped);
  };
  const drag = (e: any) => {
    if (state === "disabled") return;
    const rect = e.currentTarget.getBoundingClientRect();
    const move = (x: number) => set(min + ((x - rect.left) / rect.width) * (max - min));
    move(e.clientX);
    const onMove = (m: any) => move(m.clientX);
    const onUp = () => {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
    };
    window.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", onUp);
  };
  return (
    <div
      className={cx("mg-slider", className)}
      role="slider"
      tabIndex={0}
      aria-label={label}
      aria-valuemin={min}
      aria-valuemax={max}
      aria-valuenow={value}
      data-state={state}
      onPointerDown={drag}
      onKeyDown={(e: any) => {
        const step = (max - min) / 20;
        if (e.key === "ArrowRight" || e.key === "ArrowUp") set(value + step);
        if (e.key === "ArrowLeft" || e.key === "ArrowDown") set(value - step);
      }}
      style={{ "--slider-width": width ? `${width}px` : undefined, ...style } as React.CSSProperties}
    >
      <div className="mg-slider__track">
        <div className="mg-slider__fill" style={{ width: `${fraction * 100}%` }} />
      </div>
      <div className="mg-slider__knob" style={{ left: `calc(9px + (100% - 18px) * ${fraction})` }} />
    </div>
  );
}

/** How far along something is, 0…1. Mirrors `ProgressView(value:)`. */
export function ProgressView({ value = 0.5, width, label, className, style }: Common & { value?: number; width?: number; label?: string }) {
  const fraction = Math.min(Math.max(value, 0), 1);
  return (
    <div
      className={cx("mg-progress", className)}
      role="progressbar"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={1}
      aria-valuenow={fraction}
      style={{ "--progress-width": width ? `${width}px` : undefined, ...style } as React.CSSProperties}
    >
      <div className="mg-progress__fill" style={{ width: `${fraction * 100}%` }} />
    </div>
  );
}

/** − and + keys that step a number; a key at the end of the range dims. Mirrors `Stepper`. */
export function Stepper({
  value: controlled,
  defaultValue = 0,
  min = -Infinity,
  max = Infinity,
  step = 1,
  label,
  onChange,
  className,
  style,
}: Common & { value?: number; defaultValue?: number; min?: number; max?: number; step?: number; label?: string; onChange?: (value: number) => void }) {
  const [own, setOwn] = React.useState(defaultValue);
  const value = controlled ?? own;
  const set = (next: number) => {
    setOwn(next);
    onChange?.(next);
  };
  return (
    <div className={cx("mg-stepper", className)} role="group" aria-label={label} style={style}>
      <button type="button" className="mg-stepper__key" aria-label="Decrement" disabled={value - step < min} onClick={() => set(value - step)}>
        −
      </button>
      <button type="button" className="mg-stepper__key" aria-label="Increment" disabled={value + step > max} onClick={() => set(value + step)}>
        +
      </button>
    </div>
  );
}

/** A label with a chevron that shows or hides its content. Mirrors `DisclosureGroup`. */
export function DisclosureGroup({
  label,
  isExpanded: controlled,
  defaultExpanded = false,
  onToggle,
  className,
  style,
  children,
}: Common & { label: string; isExpanded?: boolean; defaultExpanded?: boolean; onToggle?: (expanded: boolean) => void }) {
  const [own, setOwn] = React.useState(defaultExpanded);
  const expanded = controlled ?? own;
  return (
    <div className={cx("mg-disclosure", className)} data-expanded={expanded ? "" : undefined} style={style}>
      <button
        type="button"
        className="mg-disclosure__header"
        aria-expanded={expanded}
        onClick={() => {
          setOwn(!expanded);
          onToggle?.(!expanded);
        }}
      >
        <svg className="mg-disclosure__chevron" width="14" height="14" viewBox="0 0 14 14" aria-hidden="true">
          <path d="M5 3 L9 7 L5 11" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
        {label}
      </button>
      {expanded && <div className="mg-disclosure__content">{children}</div>}
    </div>
  );
}

/** A label and its value, the value in the secondary colour. Mirrors `LabeledContent`. */
export function LabeledContent({ label, value, className, style, children }: Common & { label: string; value?: string }) {
  return (
    <div className={cx("mg-labeled", className)} style={style}>
      <span>{label}</span>
      <span className="mg-labeled__value">{value ?? children}</span>
    </div>
  );
}

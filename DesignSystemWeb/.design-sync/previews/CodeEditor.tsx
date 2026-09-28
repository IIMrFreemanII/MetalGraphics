import * as React from "react";
import { MGRoot, CodeEditor } from "@metalgraphics/frosted-glass";

// Each cell shows light and dark side by side: the design system is drawn in both.
const Both = ({ children, surface = "content", pad = 16 }: { children: React.ReactNode; surface?: "content" | "grouped" | "window" | "wallpaper"; pad?: number }) => (
  <div style={{ display: "flex", flexDirection: "column" }}>
    {(["light", "dark"] as const).map((mode) => (
      <MGRoot
        key={mode}
        mode={mode}
        surface={surface === "wallpaper" ? "none" : surface}
        style={{
          flex: "1 1 0",
          minWidth: 0,
          padding: pad,
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-start",
          gap: 10,
          background:
            surface === "wallpaper"
              ? "radial-gradient(circle at 20% 25%, var(--mg-hue-teal), transparent 55%), radial-gradient(circle at 80% 30%, var(--mg-hue-pink), transparent 50%), radial-gradient(circle at 50% 90%, var(--mg-hue-indigo), transparent 60%), var(--mg-color-window-background)"
              : undefined,
        }}
      >
        {children}
      </MGRoot>
    ))}
  </div>
);
const Row = ({ children }: { children: React.ReactNode }) => <div style={{ display: "flex", gap: 12, alignItems: "center", flexWrap: "wrap" }}>{children}</div>;

const code = [
  { spans: [{ text: "public struct ", token: "keyword" }, { text: "GlassMaterial", token: "type" }, { text: ": " }, { text: "Hashable", token: "type" }, { text: " {" }], fold: "open" },
  { spans: [{ text: "  /// About the backdrop blur's standard deviation.", token: "comment" }] },
  { spans: [{ text: "  public var ", token: "keyword" }, { text: "blurRadius" }, { text: ": " }, { text: "Float", token: "type" }] },
  { spans: [{ text: "  public var ", token: "keyword" }, { text: "tint" }, { text: ": " }, { text: "float4", token: "type" }] },
  { spans: [{ text: "  public static let ", token: "keyword" }, { text: "thin" }, { text: " = " }, { text: "GlassMaterial", token: "type" }, { text: "(" }, { text: "blurRadius", token: "variable" }, { text: ": " }, { text: "16", token: "number" }, { text: ")" }], diagnostic: "warning" },
  { spans: [{ text: "  public static let ", token: "keyword" }, { text: "thick" }, { text: " = " }, { text: "glassMaterial", token: "function" }, { text: "(" }, { text: "32", token: "number" }, { text: ")" }], diagnostic: "error" },
  { spans: [{ text: "  public init", token: "keyword" }, { text: "(" }, { text: "blurRadius" }, { text: ": " }, { text: "Float", token: "type" }, { text: ") {" }], fold: "closed" },
  { text: "}" },
] as const;

export const Editing = () => (
  <Both pad={12}>
    <div style={{ width: "100%", borderRadius: 8, overflow: "hidden", boxShadow: "0 0 0 0.5px var(--mg-color-separator)" }}>
      <CodeEditor lines={code as any} firstLineNumber={76} currentLine={2} caret={{ line: 2, column: 22 }} folding
        selections={[{ line: 3, from: 13, to: 17 }]} squiggles={[{ line: 5, from: 28, to: 41, severity: "error" }]} />
    </div>
  </Both>
);
export const SearchMatches = () => (
  <Both pad={12}>
    <div style={{ width: "100%", borderRadius: 8, overflow: "hidden", boxShadow: "0 0 0 0.5px var(--mg-color-separator)" }}>
      <CodeEditor lines={code.slice(2, 6) as any} firstLineNumber={78} matches={[{ line: 0, from: 13, to: 23 }, { line: 2, from: 41, to: 51 }]} currentMatch={1} focused={false} />
    </div>
  </Both>
);

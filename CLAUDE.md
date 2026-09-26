## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

## Performance

Before implementing or changing any feature in MetalGraphicsLib, GPURayMarching or ReactiveUIMacros, load the `performance` skill (`.claude/skills/performance/SKILL.md`) and apply its checklist. Report the change's per-frame cost (section 8 of the skill) in the final summary.

## Hot reload

Debug builds reload Swift (via InjectionNext), shaders and the ReactiveUI macros live, and restore the selected tab from `UIStorage`. Setup, limits and what still needs a relaunch: `MetalGraphicsLib/docs/HotReload.md`.

## UI tests

Check UI changes with the headless tests in `MetalGraphicsLibTests` (the `ui-tests` skill, `.claude/skills/ui-tests/SKILL.md`): no window, synthetic input, fake clock, golden PNGs, seconds per run. Launch the app with `drive-app` only for what the harness does not cover (real `NSEvent`s, windowing, hot reload, frame pacing) and for a final end-to-end check.

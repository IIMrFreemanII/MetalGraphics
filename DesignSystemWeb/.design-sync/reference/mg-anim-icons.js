/* <mg-anim-icon name="trash" scale="2" active="true|false" loop mount replay="n">
   Animated MetalGraphics glyphs. Colour = currentColor. Speed = --mgi-t (1 normal, 2 half speed).
   Hover/press read from the nearest [data-icon-host], button, a, label or [role=option|button|switch]. */
(() => {
  const T = ms => `calc(${ms}ms*var(--mgi-t,1))`;
  const SP = `calc(var(--mgi-sd,640ms)*var(--mgi-t,1)) var(--mgi-spring,cubic-bezier(.3,1.5,.5,1))`;

  function spring(k, z) {
    const c = 2 * z * Math.sqrt(k), dt = 1 / 2000, s = [];
    let x = 0, v = 0, t = 0, settle = 0;
    while (t < 3) {
      v += (-k * (x - 1) - c * v) * dt; x += v * dt; t += dt; s.push(x);
      if (Math.abs(x - 1) < .001 && Math.abs(v) < .01) { if (!settle) settle = t; if (t - settle > .02) break; } else settle = 0;
    }
    const N = 44, out = [];
    for (let i = 0; i <= N; i++) out.push(+s[Math.min(s.length - 1, Math.round(i / N * (s.length - 1)))].toFixed(3));
    out[0] = 0; out[N] = 1;
    return { lin: `linear(${out.join(', ')})`, ms: Math.round(t * 1000) };
  }
  const SPRING = spring(210, .38);
  const ROOTVARS = `--mgi-spring:${SPRING.lin};--mgi-sd:${SPRING.ms}ms`;

  const KF = {
    'mgi-in': 'from{transform:scale(.3) rotate(-25deg);opacity:0}to{transform:none;opacity:1}',
    'mgi-nudge-x': '0%{transform:none}28%{transform:translateX(2px) scaleX(.8)}52%{transform:translateX(-.9px) scaleX(1.06)}74%{transform:translateX(.4px)}100%{transform:none}',
    'mgi-nudge-nx': '0%{transform:none}28%{transform:translateX(-2px) scaleX(.8)}52%{transform:translateX(.9px) scaleX(1.06)}74%{transform:translateX(-.4px)}100%{transform:none}',
    'mgi-nudge-y': '0%{transform:none}28%{transform:translateY(2px) scaleY(.8)}52%{transform:translateY(-.9px) scaleY(1.06)}74%{transform:translateY(.4px)}100%{transform:none}',
    'mgi-pop': '0%{transform:none}30%{transform:scale(1.3)}55%{transform:scale(.88)}78%{transform:scale(1.05)}100%{transform:none}',
    'mgi-spin': 'to{transform:rotate(360deg)}',
    'mgi-draw': 'from{stroke-dashoffset:1}to{stroke-dashoffset:0}',
    'mgi-lift': '0%{transform:none}30%{transform:translateY(-1.5px) rotate(-9deg)}55%{transform:translateY(-.6px) rotate(5deg)}78%{transform:rotate(-2deg)}100%{transform:none}',
    'mgi-orbit': '0%{transform:none}25%{transform:translate(-1.2px,-.8px) rotate(-12deg)}50%{transform:translate(.4px,-1.4px) rotate(4deg)}75%{transform:translate(1.1px,.4px) rotate(10deg)}100%{transform:none}',
    'mgi-turn90': '0%{transform:none}40%{transform:rotate(108deg) scale(.82)}65%{transform:rotate(82deg) scale(1.1)}85%{transform:rotate(93deg)}100%{transform:rotate(90deg)}',
    'mgi-turn45': '0%{transform:none}45%{transform:rotate(64deg)}70%{transform:rotate(38deg)}88%{transform:rotate(48deg)}100%{transform:rotate(45deg)}',
    'mgi-turn360': '0%{transform:none}55%{transform:rotate(388deg)}78%{transform:rotate(352deg)}100%{transform:rotate(360deg)}',
    'mgi-shake': '0%,100%{transform:none}20%{transform:rotate(-8deg)}40%{transform:rotate(7deg)}60%{transform:rotate(-4deg)}80%{transform:rotate(2deg)}',
    'mgi-dash': '0%{stroke-dasharray:2 98;stroke-dashoffset:0}50%{stroke-dasharray:62 38;stroke-dashoffset:-20}100%{stroke-dasharray:2 98;stroke-dashoffset:-100}',
    'mgi-ring': '0%{transform:none}10%{transform:rotate(20deg)}24%{transform:rotate(-16deg)}38%{transform:rotate(11deg)}52%{transform:rotate(-7deg)}66%{transform:rotate(4deg)}80%{transform:rotate(-2deg)}100%{transform:none}',
    'mgi-clap': '0%{transform:none}10%{transform:rotate(30deg)}24%{transform:rotate(-26deg)}38%{transform:rotate(18deg)}52%{transform:rotate(-11deg)}66%{transform:rotate(6deg)}80%{transform:rotate(-3deg)}100%{transform:none}',
    'mgi-ring-loop': '0%{transform:none}4%{transform:rotate(20deg)}10%{transform:rotate(-16deg)}16%{transform:rotate(11deg)}22%{transform:rotate(-7deg)}28%{transform:rotate(4deg)}34%,100%{transform:none}',
    'mgi-clap-loop': '0%{transform:none}4%{transform:rotate(30deg)}10%{transform:rotate(-26deg)}16%{transform:rotate(18deg)}22%{transform:rotate(-11deg)}28%{transform:rotate(6deg)}34%,100%{transform:none}',
    'mgi-thud': '0%{transform:none}30%{transform:scale(1.1,.86)}55%{transform:scale(.95,1.06)}78%{transform:scale(1.02,.98)}100%{transform:none}',
    'mgi-jig': '0%,100%{transform:none}30%{transform:translateY(-1.2px)}60%{transform:translateY(.3px)}',
    'mgi-blink': '0%,100%{transform:none}40%,55%{transform:scaleY(.08)}',
    'mgi-slide': '0%{transform:none}30%{transform:scaleX(.55)}60%{transform:scaleX(1.1)}100%{transform:none}',
    'mgi-up': '0%{transform:none}30%{transform:translateY(-1.6px)}55%{transform:translateY(.5px)}78%{transform:translateY(-.2px)}100%{transform:none}',
    'mgi-dn': '0%{transform:none}30%{transform:translateY(1.6px)}55%{transform:translateY(-.5px)}78%{transform:translateY(.2px)}100%{transform:none}',
    'mgi-shake-loop': '0%,24%,100%{transform:none}4%{transform:rotate(-8deg)}8%{transform:rotate(7deg)}12%{transform:rotate(-4deg)}16%{transform:rotate(2deg)}',
    'mgi-ripple': '0%{opacity:.6;transform:scale(1)}100%{opacity:0;transform:scale(1.65)}',
    'mgi-hop': '0%{transform:none}30%{transform:translateY(-1.8px) scale(1.2)}55%{transform:translateY(.4px) scale(.9,1.1)}75%{transform:translateY(-.2px)}100%{transform:none}',
    'mgi-squash': '0%{transform:none}25%{transform:scaleY(.7)}50%{transform:scaleY(1.1)}75%{transform:scaleY(.97)}100%{transform:none}',
    'mgi-stab': '0%{transform:translateY(-2.4px)}40%{transform:translateY(.6px) scaleY(.86)}70%{transform:translateY(-.3px) scaleY(1.04)}100%{transform:none}',
    'mgi-wobble': '0%{transform:none}25%{transform:rotate(-12deg)}50%{transform:rotate(8deg)}75%{transform:rotate(-3deg)}100%{transform:none}',
    'mgi-bump-up': '0%{transform:none}35%{transform:translateY(-1.3px) scale(1.18)}70%{transform:translateY(.3px)}100%{transform:none}',
    'mgi-bump-dn': '0%{transform:none}35%{transform:translateY(1.3px) scale(1.18)}70%{transform:translateY(-.3px)}100%{transform:none}',
    'mgi-fly': '0%{transform:none}30%{transform:translate(1.6px,-1.8px) rotate(-12deg) scale(1.1)}55%{transform:translate(-.4px,.4px) rotate(4deg) scale(.96)}78%{transform:translate(.2px,-.2px) rotate(-1deg)}100%{transform:none}',
    'mgi-fly-in': 'from{transform:translate(-4px,3px) rotate(18deg) scale(.4);opacity:0}to{transform:none;opacity:1}',
    'mgi-flap': '0%,100%{transform:none}20%{transform:scale(.6)}40%{transform:scale(1.1)}60%{transform:scale(.8)}80%{transform:scale(1.03)}',
    'mgi-eq': '0%,100%{transform:none}30%{transform:scaleY(.35)}60%{transform:scaleY(1.25)}80%{transform:scaleY(.9)}',
    'mgi-no': '0%,100%{transform:none}20%{transform:translateX(-1.2px)}40%{transform:translateX(1px)}60%{transform:translateX(-.6px)}80%{transform:translateX(.3px)}'
  };

  const BASE = [
    '.mgi{display:block;overflow:visible}',
    '.mgi *{transform-box:view-box}',
    '.mgi g{transform-origin:var(--c)}',
    '.mgi .fx{transform-origin:0 0}',
    `.mgi .press{transition:transform ${SP}}`,
    `.mgi[data-press] .press{transform:scale(.8);transition:transform ${T(90)} cubic-bezier(.3,0,.5,1)}`,
    `.mgi[data-mount] .press{animation:mgi-in ${SP} both}`
  ];

  function gearPath(cx, cy, n, R, r, tw, bw) {
    const p = (a, rad) => `${(cx + rad * Math.cos(a)).toFixed(2)} ${(cy + rad * Math.sin(a)).toFixed(2)}`;
    let d = '';
    for (let i = 0; i < n; i++) {
      const a = i * 2 * Math.PI / n - Math.PI / 2;
      d += `${i ? ' L' : 'M'}${p(a - bw, r)} L${p(a - tw, R)} L${p(a + tw, R)} L${p(a + bw, r)} A${r} ${r} 0 0 1 ${p(a + 2 * Math.PI / n - bw, r)}`;
    }
    return d + ' Z';
  }

  const PP = {
    l: ['M3.5 2 L7.75 4.5 L7.75 9.5 L3.5 12 Z', 'M3.5 2 L6 2 L6 12 L3.5 12 Z'],
    r: ['M7.75 4.5 L12 7 L12 7 L7.75 9.5 Z', 'M8.5 2 L11 2 L11 12 L8.5 12 Z']
  };
  const NUM = /-?\d*\.?\d+/g;
  function lerpD(a, b, p) {
    const A = a.match(NUM).map(Number), B = b.match(NUM).map(Number), parts = a.split(NUM);
    let o = parts[0];
    for (let i = 0; i < A.length; i++) o += (A[i] + (B[i] - A[i]) * p).toFixed(2) + parts[i + 1];
    return o;
  }

  const DL = 'pathLength="1"';
  const ICONS = {
    chevronRight: { vb: [10, 10], sw: 1.4, triggers: ['hover', 'press', 'state'], state: 'expanded',
      parts: '<path d="M3.5 2 L6.5 5 L3.5 8"/>',
      css: [`.mgi-chevronRight .st{transition:transform ${SP}}`, '.mgi-chevronRight[data-active="true"] .st{transform:rotate(90deg)}', `.mgi-chevronRight[data-hover] .hov{animation:mgi-nudge-x ${T(560)} ease-out}`] },
    chevronDown: { vb: [10, 10], sw: 1.4, triggers: ['hover', 'press', 'state'], state: 'flipped',
      parts: '<path d="M2 3.5 L5 6.5 L8 3.5"/>',
      css: [`.mgi-chevronDown .st{transition:transform ${SP}}`, '.mgi-chevronDown[data-active="true"] .st{transform:rotate(180deg)}', `.mgi-chevronDown[data-hover] .hov{animation:mgi-nudge-y ${T(560)} ease-out}`] },
    chevronLeft: { vb: [10, 10], sw: 1.4, triggers: ['hover', 'press', 'state'], state: 'expanded',
      parts: '<path d="M6.5 2 L3.5 5 L6.5 8"/>',
      css: [`.mgi-chevronLeft .st{transition:transform ${SP}}`, '.mgi-chevronLeft[data-active="true"] .st{transform:rotate(-90deg)}', `.mgi-chevronLeft[data-hover] .hov{animation:mgi-nudge-nx ${T(560)} ease-out}`] },
    upDown: { vb: [10, 10], sw: 1.2, triggers: ['hover', 'press'],
      parts: '<path class="u" d="M3 4 L5 2 L7 4"/><path class="d" d="M3 6 L5 8 L7 6"/>',
      css: [`.mgi-upDown .u,.mgi-upDown .d{transition:transform ${SP}}`, `.mgi-upDown[data-hover] .u{animation:mgi-up ${T(540)} ease-out}`, `.mgi-upDown[data-hover] .d{animation:mgi-dn ${T(540)} ease-out ${T(50)}}`, '.mgi-upDown[data-press] .u{transform:translateY(1px)}', '.mgi-upDown[data-press] .d{transform:translateY(-1px)}'] },
    checkmark: { vb: [12, 12], sw: 1.5, triggers: ['hover', 'state', 'mount'], state: 'checked', def: true,
      parts: `<path class="p" ${DL} d="M2.5 6.5 L5 9 L9.5 3"/>`,
      css: [`.mgi-checkmark .p{stroke-dasharray:1 1;stroke-dashoffset:0;transition:stroke-dashoffset ${T(380)} cubic-bezier(.65,0,.35,1)}`, `.mgi-checkmark[data-active="false"] .p{stroke-dashoffset:1;transition-duration:${T(160)}}`, '.mgi-checkmark[data-mount] .press{animation:none}', `.mgi-checkmark[data-mount] .p{animation:mgi-draw ${T(420)} cubic-bezier(.65,0,.35,1) both}`, `.mgi-checkmark[data-mount] .hov{animation:mgi-pop ${T(620)} ease-out ${T(260)} both}`, `.mgi-checkmark[data-to="true"] .hov{animation:mgi-pop ${T(620)} ease-out ${T(220)}}`, `.mgi-checkmark[data-hover] .hov{animation:mgi-pop ${T(620)} ease-out}`] },
    folder: { vb: [16, 13], sw: 0, triggers: ['hover', 'press', 'state'], state: 'open',
      parts: '<path class="bk" fill="currentColor" stroke="none" d="M1 2.5 A1.5 1.5 0 0 1 2.5 1 H6 L7.6 2.6 H13.5 A1.5 1.5 0 0 1 15 4.1 V10.5 A1.5 1.5 0 0 1 13.5 12 H2.5 A1.5 1.5 0 0 1 1 10.5 Z"/><path class="fr" fill="currentColor" stroke="none" d="M1 4.6 H15 V10.5 A1.5 1.5 0 0 1 13.5 12 H2.5 A1.5 1.5 0 0 1 1 10.5 Z"/>',
      css: [`.mgi-folder .fr{transform-origin:8px 12px;transition:transform ${SP}}`, `.mgi-folder .bk{transition:opacity ${T(200)}}`, '.mgi-folder[data-hovering] .fr,.mgi-folder[data-active="true"] .fr{transform:skewX(-18deg) scaleY(.78)}', '.mgi-folder[data-hovering] .bk,.mgi-folder[data-active="true"] .bk{opacity:.45}'] },
    document: { vb: [13, 15], sw: 1.1, triggers: ['hover', 'press', 'state'], state: 'filled',
      parts: `<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><path class="ln l1" ${DL} d="M3.5 7.5 H9.5"/><path class="ln l2" ${DL} d="M3.5 9.5 H9.5"/><path class="ln l3" ${DL} d="M3.5 11.5 H7"/>`,
      css: [`.mgi-document .ln{stroke-dasharray:1 1;stroke-dashoffset:1;transition:stroke-dashoffset ${T(160)} ease-in}`, `.mgi-document[data-hovering] .ln,.mgi-document[data-active="true"] .ln{stroke-dashoffset:0;transition:stroke-dashoffset ${T(260)} cubic-bezier(.3,.7,.4,1)}`, `.mgi-document[data-hovering] .l2,.mgi-document[data-active="true"] .l2{transition-delay:${T(80)}}`, `.mgi-document[data-hovering] .l3,.mgi-document[data-active="true"] .l3{transition-delay:${T(160)}}`, '.mgi-document .hov{transform-origin:6.5px 14px}', `.mgi-document[data-hover] .hov{animation:mgi-lift ${T(640)} ease-out}`] },
    magnifier: { vb: [12, 12], sw: 1.3, triggers: ['hover', 'press', 'loop'],
      parts: '<circle cx="5" cy="5" r="3.8"/><path d="M8 8 L11 11"/>',
      css: [`.mgi-magnifier[data-hover] .hov{animation:mgi-orbit ${T(700)} ease-in-out}`, `.mgi-magnifier[data-loop] .hov{animation:mgi-orbit ${T(1100)} ease-in-out infinite}`] },
    xmark: { vb: [8, 8], sw: 1.3, triggers: ['hover', 'press'],
      parts: '<path d="M1 1 L7 7 M7 1 L1 7"/>',
      css: [`.mgi-xmark[data-hover] .hov{animation:mgi-turn90 ${T(620)} ease-out}`] },
    plus: { vb: [14, 14], sw: 1.3, triggers: ['hover', 'press', 'state'], state: 'rotated to ×',
      parts: '<path d="M7 2 V12 M2 7 H12"/>',
      css: [`.mgi-plus .st{transition:transform ${SP}}`, '.mgi-plus[data-active="true"] .st{transform:rotate(135deg)}', `.mgi-plus[data-hover] .hov{animation:mgi-turn90 ${T(620)} ease-out}`] },
    trash: { vb: [14, 14], sw: 1.3, triggers: ['hover', 'press'],
      parts: '<g class="lid"><path d="M1.8 3.5 H12.2"/><path d="M5.3 3.5 V1.8 H8.7 V3.5"/></g><g class="bd"><path d="M3.1 3.5 L3.8 12.1 A1 1 0 0 0 4.8 13 H9.2 A1 1 0 0 0 10.2 12.1 L10.9 3.5"/><path d="M5.8 5.8 V10.6 M8.2 5.8 V10.6"/></g>',
      css: [`.mgi-trash .lid{transform-origin:1.8px 3.5px;transition:transform ${SP}}`, '.mgi-trash[data-hovering] .lid{transform:translate(.4px,-1.7px) rotate(-18deg)}', '.mgi-trash .bd{transform-origin:7px 13px}', `.mgi-trash[data-press] .bd{animation:mgi-shake ${T(380)} ease-in-out}`] },
    gear: { vb: [14, 14], sw: 1.2, triggers: ['hover', 'press', 'loop'],
      parts: `<path d="${gearPath(7, 7, 8, 6.3, 4.8, .16, .27)}"/><circle cx="7" cy="7" r="1.9"/>`,
      css: [`.mgi-gear[data-hover] .hov{animation:mgi-turn45 ${T(700)} ease-out}`, `.mgi-gear[data-loop] .hov{animation:mgi-spin ${T(2600)} linear infinite}`] },
    searchClear: { vb: [14, 14], sw: 1.3, triggers: ['hover', 'press', 'state'], state: 'clear',
      parts: `<g class="mag"><circle cx="6" cy="6" r="3.9"/><path d="M8.9 8.9 L12 12"/></g><path class="x x1" ${DL} d="M4 4 L10 10"/><path class="x x2" ${DL} d="M10 4 L4 10"/>`,
      css: [`.mgi-searchClear .mag{transform-origin:7px 7px;transition:transform ${SP} ${T(80)},opacity ${T(160)} ${T(80)}}`, `.mgi-searchClear[data-active="true"] .mag{transform:scale(.2) rotate(-120deg);opacity:0;transition:transform ${T(240)} cubic-bezier(.5,0,.75,0),opacity ${T(200)} ${T(40)}}`, `.mgi-searchClear .x{stroke-dasharray:1 1;stroke-dashoffset:1;transition:stroke-dashoffset ${T(140)} ease-in}`, `.mgi-searchClear[data-active="true"] .x1{stroke-dashoffset:0;transition:stroke-dashoffset ${T(240)} cubic-bezier(.3,.7,.4,1) ${T(150)}}`, `.mgi-searchClear[data-active="true"] .x2{stroke-dashoffset:0;transition:stroke-dashoffset ${T(240)} cubic-bezier(.3,.7,.4,1) ${T(230)}}`, `.mgi-searchClear[data-to="true"] .hov{animation:mgi-pop ${T(620)} ease-out ${T(280)}}`, `.mgi-searchClear:not([data-active="true"])[data-hover] .hov{animation:mgi-orbit ${T(700)} ease-in-out}`, `.mgi-searchClear[data-active="true"][data-hover] .hov{animation:mgi-turn90 ${T(620)} ease-out}`] },
    spinner: { vb: [14, 14], sw: 1.5, triggers: ['loop', 'mount'],
      parts: '<circle cx="7" cy="7" r="5" opacity=".18"/><circle class="arc" cx="7" cy="7" r="5" pathLength="100" stroke-linecap="round"/>',
      css: [`.mgi-spinner .hov{animation:mgi-spin ${T(1000)} linear infinite}`, `.mgi-spinner .arc{stroke-dasharray:25 75;animation:mgi-dash ${T(1500)} ease-in-out infinite}`] },
    copyCheck: { vb: [14, 14], sw: 1.3, triggers: ['hover', 'press', 'state'], state: 'copied',
      parts: `<g class="sheets"><path class="bs" d="M9.5 2.8 V2.2 A1.2 1.2 0 0 0 8.3 1 H2.2 A1.2 1.2 0 0 0 1 2.2 V8.3 A1.2 1.2 0 0 0 2.2 9.5 H2.8"/><rect class="fs" x="4.5" y="4.5" width="8.5" height="8.5" rx="1.2"/></g><path class="ck" ${DL} stroke-width="1.5" d="M2.5 7.5 L5.5 10.5 L11.5 3.5"/>`,
      css: [`.mgi-copyCheck .bs,.mgi-copyCheck .fs{transition:transform ${SP}}`, '.mgi-copyCheck[data-hovering]:not([data-active="true"]) .bs{transform:translate(-.9px,-.9px)}', '.mgi-copyCheck[data-hovering]:not([data-active="true"]) .fs{transform:translate(.6px,.6px)}', `.mgi-copyCheck .sheets{transform-origin:7px 7px;transition:transform ${SP},opacity ${T(200)}}`, `.mgi-copyCheck[data-active="true"] .sheets{transform:scale(.3) rotate(25deg);opacity:0;transition:transform ${T(220)} cubic-bezier(.5,0,.75,0),opacity ${T(180)} ${T(40)}}`, `.mgi-copyCheck .ck{stroke:var(--mgi-check,currentColor);stroke-dasharray:1 1;stroke-dashoffset:1;transition:stroke-dashoffset ${T(120)}}`, `.mgi-copyCheck[data-active="true"] .ck{stroke-dashoffset:0;transition:stroke-dashoffset ${T(320)} cubic-bezier(.3,.7,.4,1) ${T(140)}}`, `.mgi-copyCheck[data-to="true"] .hov{animation:mgi-pop ${T(620)} ease-out ${T(240)}}`] },
    bell: { vb: [14, 14], sw: 1.2, triggers: ['hover', 'press', 'state', 'loop'], state: 'badge',
      parts: '<g class="ring"><path d="M3.2 10.2 V6.4 A3.8 3.8 0 0 1 10.8 6.4 V10.2 L12 11.4 H2 L3.2 10.2 Z"/><path d="M7 1.2 V2.6"/></g><path class="cl" d="M5.6 12.6 A1.4 1.4 0 0 0 8.4 12.6"/><circle class="dot" cx="11.2" cy="2.8" r="2" fill="var(--mgi-badge,currentColor)" stroke="none"/>',
      css: ['.mgi-bell .ring{transform-origin:7px 1.4px}', '.mgi-bell .cl{transform-origin:7px 2px}', `.mgi-bell[data-hover] .ring,.mgi-bell[data-to="true"] .ring{animation:mgi-ring ${T(900)} ease-out}`, `.mgi-bell[data-hover] .cl,.mgi-bell[data-to="true"] .cl{animation:mgi-clap ${T(900)} ease-out ${T(40)}}`, `.mgi-bell[data-loop] .ring{animation:mgi-ring-loop ${T(2400)} ease-out infinite}`, `.mgi-bell[data-loop] .cl{animation:mgi-clap-loop ${T(2400)} ease-out ${T(40)} infinite}`, `.mgi-bell .dot{transform-origin:11.2px 2.8px;transform:scale(0);transition:transform ${T(160)} ease-in}`, `.mgi-bell[data-active="true"] .dot{transform:none;transition:transform ${SP} ${T(120)}}`] },
    lock: { vb: [14, 14], sw: 1.3, triggers: ['hover', 'press', 'state'], state: 'unlocked',
      parts: '<path class="sh" d="M4.6 6.5 V4.6 A2.4 2.4 0 0 1 9.4 4.6 V6.5"/><g class="bd"><rect x="2.2" y="6.5" width="9.6" height="6.5" rx="1.3"/><circle cx="7" cy="9.75" r=".95" fill="currentColor" stroke="none"/></g>',
      css: [`.mgi-lock .sh{transform-origin:9.4px 6.5px;transition:transform ${SP}}`, '.mgi-lock[data-active="true"] .sh{transform:translateY(-1.8px) rotate(-22deg)}', '.mgi-lock .bd{transform-origin:7px 13px}', `.mgi-lock[data-to] .bd{animation:mgi-thud ${T(520)} ease-out ${T(100)}}`, `.mgi-lock:not([data-active="true"])[data-hover] .sh{animation:mgi-jig ${T(460)} ease-out}`] },
    eye: { vb: [14, 14], sw: 1.2, triggers: ['hover', 'press', 'state'], state: 'hidden',
      parts: `<g class="lid"><path d="M1 7 C2.8 3.4 11.2 3.4 13 7 C11.2 10.6 2.8 10.6 1 7 Z"/><g class="pw"><circle class="pu" cx="7" cy="7" r="2" fill="currentColor" stroke="none"/></g></g><path class="sl" ${DL} d="M2.2 1.8 L11.8 12.2"/>`,
      css: [`.mgi-eye .lid{transform-origin:7px 7px;transition:transform ${SP}}`, `.mgi-eye[data-hover] .lid{animation:mgi-blink ${T(360)} ease-in-out}`, `.mgi-eye .pu{transform:translate(var(--mgi-px,0px),var(--mgi-py,0px));transition:transform ${T(140)} ease-out}`, '.mgi-eye[data-active="true"] .lid{transform:scaleY(.7)}', `.mgi-eye .pw{transform-origin:7px 7px;transition:transform ${SP}}`, '.mgi-eye[data-active="true"] .pw{transform:scale(.4)}', `.mgi-eye .sl{stroke-dasharray:1 1;stroke-dashoffset:1;transition:stroke-dashoffset ${T(160)} ease-in}`, `.mgi-eye[data-active="true"] .sl{stroke-dashoffset:0;transition:stroke-dashoffset ${T(300)} cubic-bezier(.3,.7,.4,1) ${T(60)}}`] },
    playPause: { vb: [14, 14], sw: 0, triggers: ['hover', 'press', 'state'], state: 'playing',
      parts: `<path class="l" fill="currentColor" stroke="none" d="${PP.l[0]}"/><path class="r" fill="currentColor" stroke="none" d="${PP.r[0]}"/>`,
      css: [`.mgi-playPause[data-hover] .hov,.mgi-playPause[data-to] .hov{animation:mgi-pop ${T(560)} ease-out}`],
      snippetCss: [`/* morph without JS (Chromium/Firefox): */`, `.mgi-playPause .l,.mgi-playPause .r{transition:d ${SP}}`, `.mgi-playPause[data-active="true"] .l{d:path("${PP.l[1]}")}`, `.mgi-playPause[data-active="true"] .r{d:path("${PP.r[1]}")}`] },
    refresh: { vb: [14, 14], sw: 1.3, triggers: ['hover', 'press', 'loop'],
      parts: '<path d="M12 7 A5 5 0 1 1 9.5 2.67"/><path d="M8.68 0.41 L9.5 2.67 L7.14 3.09"/>',
      css: [`.mgi-refresh[data-hover] .hov{animation:mgi-turn360 ${T(760)} ease-out}`, `.mgi-refresh[data-loop] .hov{animation:mgi-spin ${T(900)} linear infinite}`] },
    menuX: { vb: [14, 14], sw: 1.3, triggers: ['hover', 'press', 'state'], state: 'open (×)',
      parts: '<path class="t" d="M2 3.5 H12"/><path class="m" d="M2 7 H12"/><path class="b" d="M2 10.5 H12"/>',
      css: [`.mgi-menuX .t{transform-origin:7px 3.5px;transition:transform ${SP}}`, `.mgi-menuX .b{transform-origin:7px 10.5px;transition:transform ${SP}}`, `.mgi-menuX .m{transform-origin:7px 7px;transition:transform ${T(220)} cubic-bezier(.3,.7,.4,1),opacity ${T(160)}}`, '.mgi-menuX[data-active="true"] .t{transform:translateY(3.5px) rotate(45deg)}', `.mgi-menuX[data-active="true"] .b{transform:translateY(-3.5px) rotate(-45deg);transition-delay:${T(40)}}`, '.mgi-menuX[data-active="true"] .m{transform:scaleX(0);opacity:0}', `.mgi-menuX:not([data-active="true"])[data-hover] .t{animation:mgi-slide ${T(520)} ease-out}`, `.mgi-menuX:not([data-active="true"])[data-hover] .m{animation:mgi-slide ${T(520)} ease-out ${T(50)}}`, `.mgi-menuX:not([data-active="true"])[data-hover] .b{animation:mgi-slide ${T(520)} ease-out ${T(100)}}`] }
  };

  Object.assign(ICONS, {
    warning: { vb: [14, 14], sw: 1.2, triggers: ['hover', 'press', 'loop', 'mount'],
      parts: '<path d="M7 1.8 L12.8 12 H1.2 Z" stroke-linejoin="round"/><path d="M7 5.4 V8.3"/><circle cx="7" cy="10.2" r=".8" fill="currentColor" stroke="none"/>',
      css: ['.mgi-warning .hov{transform-origin:7px 12px}', `.mgi-warning[data-hover] .hov{animation:mgi-shake ${T(460)} ease-in-out}`, `.mgi-warning[data-loop] .hov{animation:mgi-shake-loop ${T(2200)} ease-in-out infinite}`] },
    error: { vb: [14, 14], sw: 1.2, triggers: ['hover', 'press', 'loop', 'mount'],
      parts: '<circle class="halo" cx="7" cy="7" r="5.6"/><circle class="ring" cx="7" cy="7" r="5.6" pathLength="1"/><g class="x"><path d="M4.9 4.9 L9.1 9.1 M9.1 4.9 L4.9 9.1"/></g>',
      css: ['.mgi-error .halo{opacity:0;transform-origin:7px 7px}', `.mgi-error[data-hover] .halo,.mgi-error[data-to] .halo{animation:mgi-ripple ${T(700)} ease-out}`, `.mgi-error[data-loop] .halo{animation:mgi-ripple ${T(1400)} ease-out infinite}`, '.mgi-error .x{transform-origin:7px 7px}', `.mgi-error[data-hover] .x{animation:mgi-turn90 ${T(620)} ease-out}`, '.mgi-error[data-mount] .press{animation:none}', `.mgi-error[data-mount] .ring{stroke-dasharray:1 1;animation:mgi-draw ${T(420)} cubic-bezier(.65,0,.35,1) both}`, `.mgi-error[data-mount] .x{animation:mgi-in ${SP} ${T(260)} both}`] },
    note: { vb: [14, 14], sw: 1.2, triggers: ['hover', 'press', 'mount'],
      parts: '<circle cx="7" cy="7" r="5.6"/><circle class="dt" cx="7" cy="4.3" r=".85" fill="currentColor" stroke="none"/><path class="stem" d="M7 6.3 V10.2"/>',
      css: ['.mgi-note .dt{transform-origin:7px 4.3px}', '.mgi-note .stem{transform-origin:7px 10.2px}', `.mgi-note[data-hover] .dt{animation:mgi-hop ${T(620)} ease-out}`, `.mgi-note[data-hover] .stem{animation:mgi-squash ${T(620)} ease-out}`] },
    pin: { vb: [14, 14], sw: 1.2, triggers: ['hover', 'press', 'state'], state: 'pinned',
      parts: '<path d="M4.6 1.6 H9.4"/><path d="M5.6 1.6 V5.8 L3.8 8.2 H10.2 L8.4 5.8 V1.6"/><path d="M7 8.2 V12.8"/>',
      css: [`.mgi-pin .st{transform-origin:7px 10px;transform:rotate(30deg);transition:transform ${SP}}`, '.mgi-pin[data-active="true"] .st{transform:none}', '.mgi-pin .hov{transform-origin:7px 12.8px}', `.mgi-pin[data-hover] .hov{animation:mgi-wobble ${T(600)} ease-out}`, `.mgi-pin[data-to="true"] .hov{animation:mgi-stab ${T(560)} ease-out ${T(120)}}`] },
    sort: { vb: [10, 10], sw: 1.2, triggers: ['hover', 'press', 'state'], state: 'descending ("false" = ascending, none = unsorted)',
      parts: `<path class="u" d="M3 4 L5 2 L7 4"/><path class="d" d="M3 6 L5 8 L7 6"/><path class="stm" ${DL} d="M5 2.3 V7.7"/>`,
      css: [`.mgi-sort .u{transform-origin:5px 3px;transition:transform ${SP},opacity ${T(160)}}`, `.mgi-sort .d{transform-origin:5px 7px;transition:transform ${SP},opacity ${T(160)}}`, `.mgi-sort .stm{stroke-dasharray:1 1;stroke-dashoffset:1;transition:stroke-dashoffset ${T(160)} ease-in}`, `.mgi-sort[data-active] .stm{stroke-dashoffset:0;transition:stroke-dashoffset ${T(300)} cubic-bezier(.3,.7,.4,1) ${T(60)}}`, '.mgi-sort[data-active="false"] .d{transform:scale(0);opacity:0}', '.mgi-sort[data-active="true"] .u{transform:scale(0);opacity:0}', `.mgi-sort:not([data-active])[data-hover] .u{animation:mgi-up ${T(540)} ease-out}`, `.mgi-sort:not([data-active])[data-hover] .d{animation:mgi-dn ${T(540)} ease-out ${T(50)}}`, `.mgi-sort[data-active="false"][data-hover] .hov{animation:mgi-up ${T(540)} ease-out}`, `.mgi-sort[data-active="true"][data-hover] .hov{animation:mgi-dn ${T(540)} ease-out}`] }
  });
  for (const [n, dir, d] of [['stepperMinus', 'dn', 'M2 5 H8'], ['stepperPlus', 'up', 'M5 2 V8 M2 5 H8']]) ICONS[n] = {
    vb: [10, 10], sw: 1.3, triggers: ['hover', 'press', 'state'], state: 'at end of range',
    parts: `<path d="${d}"/>`,
    css: [`.mgi-${n} .hov{transition:opacity ${T(160)}}`, `.mgi-${n}[data-active="true"] .hov{opacity:.35}`, `.mgi-${n}[data-hover] .hov{animation:mgi-pop ${T(520)} ease-out}`, `.mgi-${n}[data-press] .hov{animation:mgi-bump-${dir} ${T(380)} ease-out}`, `.mgi-${n}[data-active="true"][data-press] .hov{animation:mgi-no ${T(380)} ease-out}`]
  };
  for (const [n, rot] of [['splitRight', 0], ['splitBottom', 90], ['splitLeft', 180], ['splitTop', 270]]) ICONS[n] = {
    vb: [14, 14], sw: 1.2, triggers: ['hover', 'press', 'state'], state: 'targeted',
    parts: `<g class="fx" transform="rotate(${rot} 7 7)"><rect x="1.5" y="1.5" width="11" height="11" rx="1.6"/><path d="M7 1.5 V12.5"/><rect class="fill" x="7.7" y="2.2" width="4.1" height="9.6" rx=".7" fill="var(--mgi-fill,currentColor)" stroke="none"/></g>`,
    css: [`.mgi-${n} .fill{transform-box:fill-box;transform-origin:0 50%;transform:scaleX(0);opacity:0;transition:transform ${SP},opacity ${T(160)}}`, `.mgi-${n}[data-hovering] .fill{transform:none;opacity:.45}`, `.mgi-${n}[data-active="true"] .fill{transform:none;opacity:.85}`, `.mgi-${n}[data-to="true"] .hov{animation:mgi-pop ${T(560)} ease-out}`]
  };
  for (const [n, mirror] of [['sidebarLeft', false], ['sidebarRight', true]]) ICONS[n] = {
    vb: [14, 14], sw: 1.2, triggers: ['hover', 'press', 'state'], state: 'collapsed',
    parts: `<g class="fx"${mirror ? ' transform="translate(14 0) scale(-1 1)"' : ''}><rect x="1.5" y="2.5" width="11" height="9" rx="1.6"/><rect class="sb" x="2.2" y="3.2" width="2.6" height="7.6" rx=".6" fill="currentColor" stroke="none" opacity=".35"/><path class="dv" d="M5.5 2.5 V11.5"/></g>`,
    css: [`.mgi-${n} .sb{transform-box:fill-box;transform-origin:0 50%;transition:transform ${SP},opacity ${T(180)}}`, `.mgi-${n} .dv{transition:transform ${SP}}`, `.mgi-${n}[data-active="true"] .sb{transform:scaleX(0);opacity:0}`, `.mgi-${n}[data-active="true"] .dv{transform:translateX(-4px)}`, `.mgi-${n}:not([data-active="true"])[data-hover] .dv{animation:mgi-nudge-nx ${T(560)} ease-out}`]
  };

  ICONS.swift = { vb: [13, 15], sw: 1.1, triggers: ['hover', 'press', 'mount'],
    parts: '<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/><g class="bird" style="color:var(--mgi-swift,var(--mg-hue-orange,#FF9500))"><path fill="currentColor" stroke="none" d="M9.40 4.87 C8.64 4.68 7.89 5.09 7.30 5.72 L5.86 6.93 L3.65 7.34 L5.29 7.75 L5.12 9.42 L6.25 7.49 L7.88 6.56 C8.67 6.21 9.32 5.65 9.40 4.87 Z"/><path class="wg" fill="currentColor" stroke="none" d="M7.76 5.50 C6.56 4.37 4.90 4.08 3.35 4.54 C4.45 5.22 5.42 6.00 6.09 6.67 Z M8.25 6.19 C8.90 7.71 8.60 9.37 7.64 10.66 C7.38 9.40 6.98 8.23 6.58 7.36 Z"/></g>',
    css: ['.mgi-swift .bird{transform-origin:6.375px 7.5px}', '.mgi-swift .wg{transform-origin:7.17px 6.43px}', `.mgi-swift[data-hover] .bird{animation:mgi-fly ${T(720)} ease-out}`, `.mgi-swift[data-hover] .wg{animation:mgi-flap ${T(620)} ease-out}`, '.mgi-swift[data-mount] .press{animation:none}', `.mgi-swift[data-mount] .bird{animation:mgi-fly-in ${SP} both}`, `.mgi-swift[data-mount] .wg{animation:mgi-flap ${T(620)} ease-out ${T(240)} both}`] };

  const DOC = '<path d="M2 0.75 H8 L11.75 4.5 V13.25 A1 1 0 0 1 10.75 14.25 H2 A1 1 0 0 1 1 13.25 V1.75 A1 1 0 0 1 2 0.75 Z"/>';
  const FONT = 'font-family="-apple-system,system-ui,sans-serif" font-weight="700" text-anchor="middle" dominant-baseline="central" stroke="none"';
  const H = h => `var(--mgi-ft,var(--mg-hue-${h}))`;
  function fileIcon(n, color, glyph, css = [], triggers = ['hover', 'press', 'mount']) {
    ICONS[n] = { vb: [13, 15], sw: 1.1, triggers,
      parts: DOC + `<g class="gl" style="color:${color}">${glyph}</g>`,
      css: ['.mgi-' + n + ' .hov{transform-origin:6.5px 14px}', `.mgi-${n}[data-hover] .hov{animation:mgi-lift ${T(640)} ease-out}`, `.mgi-${n} .gl{transform-origin:6.375px 7.5px}`, `.mgi-${n}[data-mount] .press{animation:none}`, `.mgi-${n}[data-mount] .gl{animation:mgi-in ${SP} both}`, ...css] };
  }
  const F = 'fill="currentColor" stroke="none"';
  fileIcon('fileImage', H('teal'), `<path ${F} d="M2.6 11 L5.3 7.2 L7.1 9.6 L8.3 8.3 L10.2 11 Z"/><circle class="sun" ${F} cx="8.4" cy="5.7" r="1.1"/>`,
    [`.mgi-fileImage .sun{transition:transform ${SP}}`, '.mgi-fileImage[data-hovering] .sun{transform:translate(-.5px,-1.1px)}']);
  fileIcon('fileVideo', H('purple'), `<path class="tri" ${F} stroke-linejoin="round" d="M5 5.1 L9.1 7.5 L5 9.9 Z"/>`,
    ['.mgi-fileVideo .tri{transform-origin:6.4px 7.5px}', `.mgi-fileVideo[data-hover] .tri{animation:mgi-nudge-x ${T(560)} ease-out ${T(120)}}`]);
  fileIcon('fileAudio', H('pink'), [[3.5, 2.6], [5.3, 4.8], [7.1, 3.4], [8.9, 1.8]].map(([x, h], i) => `<rect class="b b${i}" ${F} x="${x - .15}" y="${7.5 - h / 2}" width="1.1" height="${h}" rx=".55"/>`).join(''),
    ['.mgi-fileAudio .b{transform-box:fill-box;transform-origin:50% 50%}', ...[0, 1, 2, 3].map(i => `.mgi-fileAudio[data-hover] .b${i}{animation:mgi-eq ${T(560)} ease-out ${T(i * 70)}}`), ...[0, 1, 2, 3].map(i => `.mgi-fileAudio[data-loop] .b${i}{animation:mgi-eq ${T(900)} ease-in-out ${T(i * 150)} infinite}`)],
    ['hover', 'press', 'loop', 'mount']);
  fileIcon('fileArchive', H('brown'), [1.6, 2.9, 4.2, 5.5, 6.8].map((y, i) => `<rect ${F} x="${i % 2 ? 6.4 : 5.1}" y="${y}" width="1.25" height=".8" rx=".3"/>`).join('') + `<g class="tab"><rect ${F} x="5.2" y="8.1" width="2.35" height="3.4" rx=".7"/><rect fill="var(--mg-color-content-background,#fff)" stroke="none" x="5.9" y="9.6" width=".95" height="1.2" rx=".35"/></g>`,
    [`.mgi-fileArchive .tab{transition:transform ${SP}}`, '.mgi-fileArchive[data-hovering] .tab{transform:translateY(1.2px)}']);
  fileIcon('fileCode', H('blue'), '<g class="lt"><path stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round" d="M4.9 5.3 L2.9 7.5 L4.9 9.7"/></g><g class="gt"><path stroke-width="1.1" stroke-linecap="round" stroke-linejoin="round" d="M7.85 5.3 L9.85 7.5 L7.85 9.7"/></g><path class="sl" stroke-width="1.1" stroke-linecap="round" d="M7 4.9 L5.75 10.1"/>',
    [`.mgi-fileCode .lt,.mgi-fileCode .gt{transition:transform ${SP}}`, '.mgi-fileCode[data-hovering] .lt{transform:translateX(-.6px)}', '.mgi-fileCode[data-hovering] .gt{transform:translateX(.6px)}', '.mgi-fileCode .sl{transform-origin:6.375px 7.5px}', `.mgi-fileCode[data-hover] .sl{animation:mgi-wobble ${T(560)} ease-out}`]);
  const brace = 'M5.1 4.8 C4.1 4.8 4.4 5.7 4.2 6.6 C4.1 7.2 3.7 7.5 3.2 7.5 C3.7 7.5 4.1 7.8 4.2 8.4 C4.4 9.3 4.1 10.2 5.1 10.2';
  fileIcon('fileJSON', H('indigo'), `<g class="lt"><path stroke-width="1.05" stroke-linecap="round" d="${brace}"/></g><g class="gt"><path stroke-width="1.05" stroke-linecap="round" transform="translate(12.75 0) scale(-1 1)" d="${brace}"/></g><circle class="dt" ${F} cx="6.375" cy="7.5" r=".6"/>`,
    [`.mgi-fileJSON .lt,.mgi-fileJSON .gt{transition:transform ${SP}}`, '.mgi-fileJSON[data-hovering] .lt{transform:translateX(-.6px)}', '.mgi-fileJSON[data-hovering] .gt{transform:translateX(.6px)}', '.mgi-fileJSON .dt{transform-box:fill-box;transform-origin:50% 50%}', `.mgi-fileJSON[data-hover] .dt{animation:mgi-pop ${T(560)} ease-out ${T(80)}}`]);
  fileIcon('fileSheet', H('green'), `<rect x="3" y="4.75" width="6.75" height="5.5" rx=".6" stroke-width=".9"/><rect ${F} x="3" y="4.75" width="6.75" height="1.6" rx=".6"/><path stroke-width=".8" d="M3 8.3 H9.75 M5.6 6.35 V10.25"/><rect class="c c1" ${F} x="5.6" y="6.35" width="4.15" height="1.95"/><rect class="c c2" ${F} x="5.6" y="8.3" width="4.15" height="1.95" rx=".4"/>`,
    [`.mgi-fileSheet .c{opacity:0;transition:opacity ${T(160)}}`, `.mgi-fileSheet[data-hovering] .c{opacity:.4;transition:opacity ${T(220)}}`, `.mgi-fileSheet[data-hovering] .c2{transition-delay:${T(110)}}`]);
  fileIcon('filePDF', H('red'), `<text ${FONT} fill="currentColor" x="6.375" y="7.6" font-size="3.6">PDF</text>`, [`.mgi-filePDF[data-hover] .gl{animation:mgi-pop ${T(620)} ease-out ${T(100)}}`]);
  fileIcon('fileFont', H('gray'), `<text ${FONT} font-family="Georgia,'Times New Roman',serif" fill="currentColor" x="6.375" y="7.7" font-size="5.2">Aa</text>`, [`.mgi-fileFont[data-hover] .gl{animation:mgi-thud ${T(560)} ease-out ${T(100)}}`]);
  for (const [n, label, bg, fg, fs] of [['langJS', 'JS', 'yellow', '#1d1d1f', 3.4], ['langTS', 'TS', 'blue', '#fff', 3.4], ['langPY', 'PY', 'indigo', '#fff', 3.4], ['langRS', 'RS', 'badge-class', '#fff', 3.4], ['langGO', 'GO', 'teal', '#fff', 3.4], ['langC', 'C', 'gray', '#fff', 3.8], ['langCPP', 'C++', 'pink', '#fff', 3], ['langRB', 'RB', 'red', '#fff', 3.4], ['langKT', 'KT', 'purple', '#fff', 3.4], ['langJava', 'JAVA', 'brown', '#fff', 2.6], ['langMetal', 'MTL', 'badge-struct', '#fff', 2.9], ['langShell', '>_', 'gray', '#fff', 3.4]]) {
    const bgc = n === 'langShell' ? 'var(--mgi-ft,#1d1d1f)' : H(bg), fgc = n === 'langShell' ? 'var(--mg-hue-green,#34C759)' : fg;
    fileIcon(n, bgc, `<rect ${F} x="2.1" y="5.1" width="8.55" height="4.8" rx="1.2"/><text class="tx" ${FONT} style="fill:${fgc}" x="6.375" y="7.55" font-size="${fs}">${label}</text>`,
      [`.mgi-${n}[data-hover] .gl{animation:mgi-thud ${T(560)} ease-out ${T(100)}}`, `.mgi-${n}[data-hover] .tx{animation:mgi-up ${T(520)} ease-out ${T(160)}}`]);
  }

  function svgMarkup(name, scale = 1) {
    const d = ICONS[name], [w, h] = d.vb;
    return `<svg class="mgi mgi-${name}" xmlns="http://www.w3.org/2000/svg" width="${+(w * scale).toFixed(2)}" height="${+(h * scale).toFixed(2)}" viewBox="0 0 ${w} ${h}" fill="none" stroke="currentColor" stroke-width="${d.sw || 1}" style="--c:${w / 2}px ${h / 2}px" aria-hidden="true"><g class="press"><g class="st"><g class="hov">${d.parts}</g></g></g></svg>`;
  }
  function keyframesFor(rules) {
    const used = new Set((rules.join(' ').match(/mgi-[a-z0-9-]+/g) || []).filter(k => KF[k]));
    return [...used].map(k => `@keyframes ${k}{${KF[k]}}`);
  }
  function cssFor(name) {
    const rules = [...BASE, ...ICONS[name].css];
    return [...rules, ...keyframesFor(rules)].join('\n');
  }
  function snippet(name) {
    const d = ICONS[name];
    if (!d) return '';
    const markup = svgMarkup(name).replace('<g class="press">', '\n  <g class="press">').replace('</svg>', '\n</svg>');
    return `<!-- ${name}: ${d.triggers.join(', ')}${d.state ? ` · data-active="true" = ${d.state}` : ''} -->
${markup}

<style>
:root{${ROOTVARS};--mgi-t:1}
${cssFor(name)}${d.snippetCss ? '\n' + d.snippetCss.join('\n') : ''}
</style>

<!-- Drive it with attributes on the <svg>:
  data-hover     re-add on pointerenter (one-shot)
  data-hovering  present while the pointer is over
  data-press     present while pressed
  data-active    "true" | "false" (state)
  data-to        re-add when the state changes (one-shot)
  data-loop      loops
  data-mount     entrance (one-shot) -->`;
  }

  const HOSTS = 'button,a,label,[role=option],[role=button],[role=switch],[role=menuitem],[role=menuitemcheckbox],[role=tab],[role=radio]';
  class MGAnimIcon extends HTMLElement {
    static observedAttributes = ['name', 'active', 'loop', 'scale', 'replay'];
    constructor() { super(); this.attachShadow({ mode: 'open' }); this._t = {}; this._p = 0; this._v = 0; this._pt = 0; }
    connectedCallback() {
      this.render();
      queueMicrotask(() => this.bind());
      if (this.hasAttribute('mount')) this.pulse('data-mount', '', 1400);
    }
    disconnectedCallback() { this.unbind(); cancelAnimationFrame(this._raf); this._raf = 0; }
    attributeChangedCallback(n, o, v) {
      if (o === v || !this.isConnected) return;
      if (n === 'name' || n === 'scale') return this.render();
      if (!this.svg) return;
      if (n === 'active') this.applyActive(true);
      if (n === 'loop') this.applyLoop();
      if (n === 'replay') this.pulse('data-mount', '', 1400);
    }
    speed() { return parseFloat(getComputedStyle(this).getPropertyValue('--mgi-t')) || 1; }
    render() {
      const name = this.getAttribute('name');
      if (!ICONS[name]) { this.shadowRoot.innerHTML = ''; this.svg = null; return; }
      const scale = parseFloat(this.getAttribute('scale')) || 1;
      this.shadowRoot.innerHTML = `<style>:host{display:inline-flex;line-height:0;vertical-align:middle;flex:none;${ROOTVARS}}\n${cssFor(name)}</style>${svgMarkup(name, scale)}`;
      this.svg = this.shadowRoot.querySelector('svg');
      this.applyActive(false); this.applyLoop();
    }
    activeVal() {
      const a = this.getAttribute('active');
      if (a === null || a === '' && !ICONS[this.getAttribute('name')]?.state) return null;
      return a === 'false' ? 'false' : 'true';
    }
    applyActive(animate) {
      const v = this.activeVal(), s = this.svg, prev = s.getAttribute('data-active');
      if (v === null) s.removeAttribute('data-active'); else s.setAttribute('data-active', v);
      if (this.getAttribute('name') === 'playPause') {
        const target = v === 'true' ? 1 : 0;
        if (animate) this.morph(target); else { this._p = this._pt = target; this._v = 0; this.drawPP(); }
      }
      if (animate && v !== null && prev !== v) this.pulse('data-to', v, 1400);
    }
    applyLoop() {
      const l = this.getAttribute('loop');
      if (l !== null && l !== 'false') this.svg.setAttribute('data-loop', ''); else this.svg.removeAttribute('data-loop');
    }
    pulse(attr, val, ms) {
      const s = this.svg;
      if (!s) return;
      s.removeAttribute(attr); void s.getBoundingClientRect(); s.setAttribute(attr, val);
      clearTimeout(this._t[attr]);
      this._t[attr] = setTimeout(() => s.isConnected && s.removeAttribute(attr), ms * this.speed());
    }
    drawPP() {
      const s = this.svg;
      if (!s) return;
      s.querySelector('.l').setAttribute('d', lerpD(PP.l[0], PP.l[1], this._p));
      s.querySelector('.r').setAttribute('d', lerpD(PP.r[0], PP.r[1], this._p));
    }
    morph(target) {
      this._pt = target;
      if (this._raf) return;
      const k = 380, c = 2 * .34 * Math.sqrt(k);
      let last = performance.now();
      const step = now => {
        const dt = Math.min(.032, (now - last) / 1000) / this.speed(); last = now;
        this._v += (-k * (this._p - this._pt) - c * this._v) * dt; this._p += this._v * dt;
        if (Math.abs(this._p - this._pt) < .001 && Math.abs(this._v) < .01) { this._p = this._pt; this._v = 0; this.drawPP(); this._raf = 0; return; }
        this.drawPP(); this._raf = requestAnimationFrame(step);
      };
      this._raf = requestAnimationFrame(step);
    }
    bind() {
      if (this._host || !this.isConnected) return;
      const host = this.closest('[data-icon-host]') || this.parentElement?.closest(HOSTS) || this;
      this._host = host;
      this._h = {
        pointerenter: () => { if (!this.svg) return; this.svg.setAttribute('data-hovering', ''); this.pulse('data-hover', '', 1600); },
        pointerleave: () => { if (!this.svg) return; this.svg.removeAttribute('data-hovering'); this.svg.removeAttribute('data-press'); this.svg.style.removeProperty('--mgi-px'); this.svg.style.removeProperty('--mgi-py'); },
        pointerdown: () => this.svg?.setAttribute('data-press', ''),
        pointerup: () => this.svg?.removeAttribute('data-press'),
        pointercancel: () => this.svg?.removeAttribute('data-press'),
        pointermove: e => {
          if (!this.svg || this.getAttribute('name') !== 'eye') return;
          const r = this.svg.getBoundingClientRect(), cl = x => Math.max(-1, Math.min(1, x));
          this.svg.style.setProperty('--mgi-px', (cl((e.clientX - r.left - r.width / 2) / (r.width * 1.2)) * 2.4).toFixed(2) + 'px');
          this.svg.style.setProperty('--mgi-py', (cl((e.clientY - r.top - r.height / 2) / (r.height * 1.2)) * 1.1).toFixed(2) + 'px');
        }
      };
      for (const k in this._h) host.addEventListener(k, this._h[k]);
    }
    unbind() {
      if (!this._host) return;
      for (const k in this._h) this._host.removeEventListener(k, this._h[k]);
      this._host = null;
    }
  }
  MGAnimIcon.names = Object.keys(ICONS);
  MGAnimIcon.meta = name => { const d = ICONS[name]; return d && { name, size: d.vb, triggers: d.triggers, state: d.state || null, defaultActive: !!d.def }; };
  MGAnimIcon.snippet = snippet;
  MGAnimIcon.rootVars = ROOTVARS;
  MGAnimIcon.svg = svgMarkup;
  if (!customElements.get('mg-anim-icon')) customElements.define('mg-anim-icon', MGAnimIcon);
  window.MGAnimIcon = MGAnimIcon;
})();

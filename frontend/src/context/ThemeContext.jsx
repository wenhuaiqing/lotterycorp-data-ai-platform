import { createContext, useContext, useState } from "react";

// The Lottery Corporation palette, read from thelotterycorporation.com's
// stylesheet (clientlib-site.css) and its logo on 02/11/2026:
//   #232396  indigo  — logo, body text, primary buttons, nav, active states
//   #000067  navy    — button drop-shadow / pressed state
//   #DEDEF2  lilac   — dividers, soft tints
//   #009BD7  blue    — focus rings; one of the logo rays (AI accent here)
//   #8C50A0  purple  — link colour; one of the logo rays
//   #E80F17  red     — "red" buttons, invalid state; one of the logo rays
//   #30C462  green   — valid state; one of the logo rays
//   #D2E623  lime    — "lime" buttons, ASX widget; one of the logo rays
//   #FFDB00  yellow  — one of the logo rays
//   #F59B00  orange  — one of the logo rays
// Central theme tokens: components read t.* so the palette swaps in one
// place, and shared components (PlasmaOrb, UnifiedOrb) inherit it.

export const light = {
  name: "light",
  bg: "#F4F4FB",                          // soft indigo-tinted grey
  surface: "#FFFFFF",
  surfaceRaised: "#FAFAFE",
  border: "rgba(35,35,150,0.16)",
  borderBright: "rgba(35,35,150,0.34)",
  accent: "#232396",                      // brand indigo
  accentGlow: "rgba(35,35,150,0.10)",
  accent2: "#009BD7",                     // brand blue — AI accent
  accent2Glow: "rgba(0,155,215,0.16)",
  text: "#14143F",                        // near-black indigo
  textMuted: "rgba(20,20,63,0.62)",
  textDim: "rgba(20,20,63,0.30)",
  sidebarBg: "#FFFFFF",
  sidebarText: "rgba(20,20,63,0.74)",
  sidebarActive: "rgba(35,35,150,0.10)",
  sidebarActiveText: "#232396",
  sidebarBorder: "rgba(35,35,150,0.10)",
  rowHover: "rgba(35,35,150,0.06)",
  rowDivider: "rgba(35,35,150,0.10)",
  groupDivider: "rgba(35,35,150,0.45)",
  gridDot: "rgba(35,35,150,0.07)",
  labelColBg: "rgba(35,35,150,0.04)",
  dot: {
    grey: "rgba(20,20,63,0.18)",
    green: "#30C462",                     // brand green
    yellow: "#F59B00",                    // brand orange (yellow #FFDB00 fails on white)
    blue: "#009BD7",                      // brand blue
    red: "#E80F17",                       // brand red
  },
  dotGlow: {
    green: "rgba(48,196,98,0.45)",
    yellow: "rgba(245,155,0,0.42)",
    blue: "rgba(0,155,215,0.42)",
    red: "rgba(232,15,23,0.42)",
  },
  colGroup: ["rgba(35,35,150,0.88)", "rgba(0,155,215,0.80)", "rgba(140,80,160,0.80)"],
  colGroupDim: ["rgba(35,35,150,0.07)", "rgba(0,155,215,0.07)", "rgba(140,80,160,0.07)"],
};

export const dark = {
  name: "dark",
  bg: "#0C0C2A",
  surface: "#15153A",
  surfaceRaised: "#1B1B47",
  border: "rgba(160,160,240,0.20)",
  borderBright: "rgba(160,160,240,0.38)",
  accent: "#8E8EF0",                      // lighter indigo for dark-mode visibility
  accentGlow: "rgba(142,142,240,0.22)",
  accent2: "#3FC0F2",                     // brand blue popped up for dark bg
  accent2Glow: "rgba(63,192,242,0.20)",
  text: "#E8E8F7",
  textMuted: "rgba(232,232,247,0.55)",
  textDim: "rgba(232,232,247,0.28)",
  sidebarBg: "#080821",
  sidebarText: "rgba(232,232,247,0.62)",
  sidebarActive: "rgba(142,142,240,0.18)",
  sidebarActiveText: "#CACAF8",
  sidebarBorder: "rgba(142,142,240,0.18)",
  rowHover: "rgba(142,142,240,0.08)",
  rowDivider: "rgba(142,142,240,0.16)",
  groupDivider: "rgba(142,142,240,0.50)",
  gridDot: "rgba(142,142,240,0.07)",
  labelColBg: "rgba(0,0,0,0.22)",
  dot: {
    grey: "rgba(255,255,255,0.22)",
    green: "#4FD67E",
    yellow: "#FFB547",
    blue: "#3FC0F2",
    red: "#F0484E",
  },
  dotGlow: {
    green: "rgba(79,214,126,0.72)",
    yellow: "rgba(255,181,71,0.72)",
    blue: "rgba(63,192,242,0.72)",
    red: "rgba(240,72,78,0.72)",
  },
  colGroup: ["rgba(142,142,240,0.88)", "rgba(63,192,242,0.80)", "rgba(190,130,210,0.80)"],
  colGroupDim: ["rgba(142,142,240,0.10)", "rgba(63,192,242,0.08)", "rgba(190,130,210,0.08)"],
};

const Ctx = createContext(null);

export function ThemeProvider({ children }) {
  const [isDark, setIsDark] = useState(false);
  return (
    <Ctx.Provider value={{ t: isDark ? dark : light, isDark, toggle: () => setIsDark(v => !v) }}>
      {children}
    </Ctx.Provider>
  );
}

export function useTheme() {
  return useContext(Ctx);
}

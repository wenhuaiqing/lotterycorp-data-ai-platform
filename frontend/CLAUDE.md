# Frontend conventions

React 18.3 + Vite 5 + React Router 7. Themed to The Lottery Corporation's palette (see the root CLAUDE.md).

## Layout

```
frontend/
├── package.json
├── vite.config.js
├── index.html
└── src/
    ├── main.jsx                       Entry: ThemeProvider + BrowserRouter + App
    ├── App.jsx                        Sidebar + Header + <Routes> + <UnifiedOrb>
    ├── navigation.js                  Auto-discovers pages via import.meta.glob
    ├── config.js                      API_BASE_URL
    ├── context/ThemeContext.jsx       Indigo/blue palette + dark mode
    ├── components/
    │   ├── common/
    │   │   ├── HeaderBar.jsx
    │   │   ├── SidebarNav.jsx
    │   │   ├── PlasmaOrb.jsx          Animated orb (canvas)
    │   │   ├── UnifiedOrb.jsx         Streaming agent UI (SSE)
    │   │   └── PagePlaceholder.jsx
    │   └── agents/
    │       ├── AgentTrace.jsx         Renders the streamed SSE timeline
    │       ├── ToolCallCard.jsx
    │       └── AgentBadge.jsx
    └── pages/<Section>/<Page>.jsx     One file per route, auto-discovered
```

## Patterns

- **Auto-discovery** — `pages/<Section>/<Page>.jsx` becomes the URL `/<section-slug>`.
  `Home/Dashboard.jsx` is the index ("/"). The sidebar comes from `navigation.js`
  which maps each section to an icon + display order.
- **Theme tokens** — every styled element reads from `useTheme().t`. Primary
  `t.accent` is indigo `#232396`; `t.accent2` is blue `#009BD7` for AI
  badges and the second gradient stop. `t.dot.red` is `#E80F17` and
  `t.dot.yellow` is orange `#F59B00`. The logo SVG is single-colour indigo;
  the square mark is multicoloured and must never be inverted.
- **Inline styles** — no CSS-in-JS dependency.
- **Icons** — `lucide-react`. Property-native: Building2, Users, Calculator,
  Scale, LineChart, Home.
- **Pill CTAs** — `borderRadius: 999`. Cards: 10-14px.
- **SSE streaming** — `UnifiedOrb` reads `/orb/chat` using `fetch` +
  `ReadableStream` + manual SSE parsing. No EventSource (it can't POST).
- **Agent trace** — tool_result events are merged into the preceding tool_call
  card so each tool call shows as one block with the result preview attached.
- **No frontend tests yet** — the backend Tier-1 suite is the safety net for
  Phase 1.

## Run

```powershell
npm install
npm run dev    # :5173 with Vite proxy -> backend :8000
```

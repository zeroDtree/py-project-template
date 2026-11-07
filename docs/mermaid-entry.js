import mermaid from "mermaid";

const config = {
  securityLevel: "loose",
  startOnLoad: false,
  layout: "elk",
  look: "neo",
  theme: "redux-color",
  themeVariables: {
    fontSize: "15px",
    fontFamily: 'Inter, "PingFang SC", "Noto Sans SC", ui-sans-serif, system-ui, sans-serif',
  },
  flowchart: {
    useMaxWidth: false,
    htmlLabels: true,
    wrappingWidth: 260,
    nodeSpacing: 32,
    rankSpacing: 52,
    padding: 10,
    curve: "linear",
  },
  elk: {
    lineHops: "arc",
  },
};

function renderDiagrams() {
  const nodes = document.querySelectorAll(".mermaid:not([data-processed])");
  if (nodes.length === 0) {
    return;
  }
  mermaid.initialize(config);
  mermaid.run({ nodes, suppressErrors: false }).catch((error) => {
    console.error(error);
  });
}

const document$ = window.document$;
if (document$ && typeof document$.subscribe === "function") {
  document$.subscribe(() => {
    renderDiagrams();
  });
} else if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", renderDiagrams);
} else {
  renderDiagrams();
}

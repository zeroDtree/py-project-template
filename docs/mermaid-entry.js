import mermaid from "mermaid";

const config = {
  securityLevel: "loose",
  startOnLoad: false,
  layout: "elk",
  elk: {
    lineHops: "arc",
  },
  // Fallback when a label is still a pixel taller than its foreignObject.
  themeCSS: `
    .edgeLabel foreignObject,
    .node foreignObject {
      overflow: visible;
    }
  `,
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

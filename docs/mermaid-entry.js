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

const sources = new WeakMap();
let renderedTheme = null;

function themeName() {
  return document.body.getAttribute("data-md-color-scheme") === "slate" ? "dark" : "default";
}

function renderDiagrams() {
  const theme = themeName();
  const themeChanged = theme !== renderedTheme;
  const nodes = [...document.querySelectorAll(".mermaid")];
  if (nodes.length === 0) {
    return;
  }

  for (const node of nodes) {
    if (!sources.has(node)) {
      sources.set(node, node.innerHTML);
    } else if (themeChanged) {
      node.removeAttribute("data-processed");
      node.innerHTML = sources.get(node);
    }
  }

  const pending = nodes.filter((node) => !node.hasAttribute("data-processed"));
  if (pending.length === 0) {
    return;
  }

  renderedTheme = theme;
  mermaid.initialize({ ...config, theme });
  mermaid.run({ nodes: pending, suppressErrors: false }).catch((error) => {
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

new MutationObserver(() => {
  renderDiagrams();
}).observe(document.body, {
  attributes: true,
  attributeFilter: ["data-md-color-scheme"],
});

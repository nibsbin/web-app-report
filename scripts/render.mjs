// Render Quillmark documents with the local container_security_report quill,
// using the @quillmark/wasm engine (Typst backend). No native toolchain needed.
//
//   node scripts/render.mjs                       # render every examples/*.md -> out/
//   node scripts/render.mjs path/to/doc.md        # render one doc -> out/<name>.pdf
//   node scripts/render.mjs doc.md -o report.pdf  # render one doc to a chosen path
//   node scripts/render.mjs -f svg doc.md         # choose format (pdf|svg|png|txt)
//
// Exit status is non-zero if any document fails to render.

import { readFileSync, readdirSync, statSync, writeFileSync, mkdirSync } from "node:fs";
import { join, relative, dirname, basename, extname } from "node:path";
import { fileURLToPath } from "node:url";
import { Document, Quill, Engine } from "@quillmark/wasm";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const quillDir = join(repoRoot, "container_security_report");
const outDir = join(repoRoot, "out");

// Parse args: [-f format] [-o output] [markdown...]
const argv = process.argv.slice(2);
let format = "pdf";
let output = null;
const docs = [];
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === "-f" || a === "--format") format = argv[++i];
  else if (a === "-o" || a === "--output") output = argv[++i];
  else docs.push(a);
}

// Default to every Markdown document under examples/.
if (docs.length === 0) {
  const examples = join(repoRoot, "examples");
  for (const name of readdirSync(examples)) {
    if (name.endsWith(".md")) docs.push(join(examples, name));
  }
}
if (output && docs.length !== 1) {
  console.error("-o/--output requires exactly one input document");
  process.exit(2);
}

// Read a quill bundle directory into the Map<path, Uint8Array> tree fromTree wants.
function readTree(dir) {
  const tree = new Map();
  const walk = (d) => {
    for (const name of readdirSync(d)) {
      const p = join(d, name);
      if (statSync(p).isDirectory()) walk(p);
      else tree.set(relative(dir, p).split("\\").join("/"), new Uint8Array(readFileSync(p)));
    }
  };
  walk(dir);
  return tree;
}

// Build + validate the quill once (engine-free), then reuse it for every doc.
const quill = Quill.fromTree(readTree(quillDir));
const engine = new Engine();

let failures = 0;
for (const md of docs) {
  try {
    const doc = Document.fromMarkdown(readFileSync(md, "utf8"));
    const result = await engine.render(quill, doc, { format });
    for (const w of result.warnings) console.warn(`  warning [${md}]: ${w.message}`);
    const artifact = result.artifacts[0];
    const dest = output ?? join(outDir, `${basename(md, extname(md))}.${format}`);
    mkdirSync(dirname(dest), { recursive: true });
    writeFileSync(dest, artifact.bytes);
    console.log(`rendered ${md} -> ${dest} (${artifact.bytes.length} bytes, ${result.renderTimeMs}ms)`);
  } catch (err) {
    failures++;
    console.error(`failed ${md}: ${err.message}`);
    for (const d of err.diagnostics ?? []) console.error(`  - ${d.code ?? d.severity}: ${d.message}`);
  }
}
process.exit(failures ? 1 : 0);

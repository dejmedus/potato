import { EditorState } from "https://esm.sh/@codemirror/state@6";
import {
  EditorView,
  keymap,
  highlightActiveLine
} from "https://esm.sh/@codemirror/view@6";
import {
  defaultKeymap,
  history,
  historyKeymap
} from "https://esm.sh/@codemirror/commands@6";
import {
  StreamLanguage,
  LanguageSupport
} from "https://esm.sh/@codemirror/language@6";

/* syntax highlighting */
const KEYWORDS = ["say", "gains", "and", "or"];
const OPS = ["equals?", "bigger?", "atleast?", "is"];
const RAINBOW = ["ptok-p", "ptok-o", "ptok-t1", "ptok-a", "ptok-t2", "ptok-o2"];

const potatoStream = StreamLanguage.define({
  name: "potato",
  startState: () => ({ ri: -1 }),
  token(stream, state) {
    if (state.ri >= 0 && state.ri < 6) {
      const cls = RAINBOW[state.ri];
      stream.next();
      state.ri = state.ri + 1 < 6 ? state.ri + 1 : -1;
      return cls;
    }
    if (stream.eatSpace()) return null;
    if (stream.match(/🍠.*/)) return "ptok-comment";
    if (stream.match(/"(?:\\.|[^"])*"/)) return "ptok-string";
    if (stream.match(/\d+(\.\d+)?/)) return "ptok-number";
    if (stream.match(/:\)/)) return "ptok-operator";
    if (stream.match(/:\(/)) return "ptok-operator";
    if (stream.match(/\bpotato\b/, false)) {
      state.ri = 1;
      stream.next();
      return "ptok-p";
    }
    for (const op of OPS) {
      if (stream.match(op)) return "ptok-operator";
    }
    for (const kw of KEYWORDS) {
      if (stream.match(new RegExp(`\\b${kw}\\b`))) return "ptok-keyword";
    }
    if (stream.match(/[()]/)) return "ptok-paren";
    stream.next();
    return null;
  }
});

/* editor */
const SAMPLE = `🍠 Welcome to the Potato Playground!

greeting is "Hello from potato!"
say greeting
`;

let editor;
function runCode() {
  execute(editor.state.doc.toString());
}

editor = new EditorView({
  state: EditorState.create({
    doc: SAMPLE,
    extensions: [
      history(),
      keymap.of([
        {
          key: "Mod-Enter",
          run() {
            runCode();
            return true;
          }
        },
        ...defaultKeymap,
        ...historyKeymap
      ]),
      new LanguageSupport(potatoStream),
      highlightActiveLine(),
      EditorView.theme({
        "&": {
          height: "100%",
          background: "var(--surface)",
          color: "var(--text)"
        },
        ".cm-scroller": { overflow: "auto" },
        ".cm-focused": { outline: "none" }
      })
    ]
  }),
  parent: document.getElementById("editor-wrap")
});

/* setup */
const loadBar = document.getElementById("load-bar");
const loadMsg = document.getElementById("load-msg");
const overlay = document.getElementById("loading-overlay");
const badge = document.getElementById("status-badge");
const runBtn = document.getElementById("run-btn");
const outputEl = document.getElementById("output");

function setLoad(pct, msg) {
  loadBar.style.width = pct + "%";
  loadMsg.textContent = msg;
}

let rubyVM = null;
let interpreterBundle = null;

async function initRuby() {
  try {
    const { DefaultRubyVM } = window["ruby-wasm-wasi"];
    if (!DefaultRubyVM)
      throw new Error("ruby-wasm-wasi UMD script did not load");

    setLoad(10, "Fetching Ruby runtime + Potato bundle…");
    const WASM_URL =
      "https://cdn.jsdelivr.net/npm/@ruby/4.0-wasm-wasi@2.8.1/dist/ruby+stdlib.wasm";

    const BUNDLE_URL = "./potato_bundle.rb";

    const wasmPromise = (async () => {
      const res = await fetch(WASM_URL);
      if (!res.ok) throw new Error(`WASM fetch failed: ${res.status}`);
      const buf = await res.arrayBuffer();
      return await WebAssembly.compile(buf);
    })();

    const bundlePromise = fetch(BUNDLE_URL).then((r) => {
      if (!r.ok) throw new Error(`Bundle missing: ${r.status}`);
      return r.text();
    });

    const [wasmModule, bundleText] = await Promise.all([
      wasmPromise,
      bundlePromise
    ]);

    interpreterBundle = bundleText;

    setLoad(80, "Booting Ruby VM…");
    const { vm } = await DefaultRubyVM(wasmModule);
    rubyVM = vm;

    setLoad(92, "Loading Potato interpreter…");

    rubyVM.eval(`
      require 'stringio'
      def abort(msg = nil)
        raise RuntimeError, msg.to_s.gsub(/\\e\\[[0-9;]*m/, '')
      end
    `);
    rubyVM.eval(interpreterBundle);

    setLoad(100, "Ready!");
    setTimeout(() => {
      overlay.classList.add("hidden");
      badge.textContent = "Ready";
      badge.className = "ready";
      runBtn.disabled = false;
    }, 300);
  } catch (err) {
    console.error("Init error:", err);
    setLoad(100, err.message);
    loadMsg.style.color = "var(--red)";
    badge.textContent = "Error";
    badge.className = "error";
  }
}

/* run */
function execute(source) {
  if (!rubyVM) return;
  outputEl.className = "";
  outputEl.innerHTML =
    '<span class="spinner"></span><span style="color:var(--muted);font-size:.75rem">Running…</span>';

  setTimeout(() => {
    try {
      rubyVM.eval(`
        $__out = StringIO.new
        $stdout = $__out
      `);

      const escaped = source
        .replace(/\\/g, "\\\\")
        .replace(/"/g, '\\"')
        .replace(/#{/g, "\#{");

      rubyVM.eval(`Potato.run("${escaped}")`);

      const out = rubyVM
        .eval(
          `
        $stdout = STDOUT
        $__out.string
      `
        )
        .toString();

      outputEl.className = "";
      outputEl.textContent = out.length > 0 ? out : "(no output)";
    } catch (err) {
      try {
        rubyVM.eval("$stdout = STDOUT");
      } catch {}
      outputEl.className = "is-error";

      outputEl.textContent =
        "Error:\n" + err.message.replace(/\x1b\[[0-9;]*m/g, "");
    }
  }, 20);
}

document.getElementById("run-btn").addEventListener("click", runCode);
initRuby();

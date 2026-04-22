import { EditorState } from "https://esm.sh/@codemirror/state@6";
import {
  EditorView,
  keymap,
  highlightActiveLine
} from "https://esm.sh/@codemirror/view@6";
import {
  defaultKeymap,
  history,
  historyKeymap,
  toggleLineComment
} from "https://esm.sh/@codemirror/commands@6";
import {
  StreamLanguage,
  LanguageSupport,
  syntaxHighlighting,
  HighlightStyle
} from "https://esm.sh/@codemirror/language@6";
import { tags as t, Tag } from "https://esm.sh/@lezer/highlight@1";

/* syntax highlight */
const T = {
  comment: t.lineComment,
  string: t.string,
  number: t.number,
  keyword: t.keyword,
  operator: t.operator,
  paren: t.paren,
  rp: Tag.define(),
  ro: Tag.define(),
  rt1: Tag.define(),
  ra: Tag.define(),
  rt2: Tag.define(),
  ro2: Tag.define(),
  rtrue: Tag.define(),
  rfalse: Tag.define()
};

const OPERATORS = ["is?", "bigger?", "atleast?", "gains", "is"];
const KEYWORDS = ["say", "and", "or"];

const potatoLang = StreamLanguage.define({
  name: "potato",
  languageData: {
    commentTokens: { line: "🍠 " }
  },
  startState: () => ({ rainbow: -1 }),
  token(stream, state) {
    if (state.rainbow >= 0) {
      const keys = ["rp", "ro", "rt1", "ra", "rt2", "ro2"];
      const key = keys[state.rainbow];
      stream.next();
      state.rainbow = state.rainbow + 1 < 6 ? state.rainbow + 1 : -1;
      return key;
    }

    if (stream.eatSpace()) return null;
    if (stream.match(/🍠.*/)) return "comment";
    if (stream.match(/"(?:\\.|[^"])*"/)) return "string";
    if (stream.match(/\d+(\.\d+)?/)) return "number";
    if (stream.match(/:\)/)) return "rtrue";
    if (stream.match(/:\(/)) return "rfalse";

    if (stream.match(/\bpotato\b/, false)) {
      state.rainbow = 1;
      stream.next();
      return "rp";
    }

    for (const op of OPERATORS) if (stream.match(op)) return "operator";
    for (const kw of KEYWORDS)
      if (stream.match(new RegExp(`\\b${kw}\\b`))) return "keyword";
    if (stream.match(/[()]/)) return "paren";

    stream.next();
    return null;
  },
  tokenTable: T
});

const potatoHighlight = HighlightStyle.define([
  { tag: t.lineComment, color: "#a08969", fontStyle: "italic" },
  { tag: t.string, color: "#c8aa80" },
  { tag: t.number, color: "#c8aa80" },
  { tag: t.keyword, color: "#674e35" },
  { tag: t.operator, color: "#a07850" },
  { tag: t.paren, color: "#5a4a38" },
  { tag: T.rp, color: "#ff6060" },
  { tag: T.ro, color: "#ffb326" },
  { tag: T.rt1, color: "#fa95ff" },
  { tag: T.ra, color: "#63f221" },
  { tag: T.rt2, color: "#45daff" },
  { tag: T.ro2, color: "#b255ff" },
  { tag: T.rtrue, color: "#aa8dff" },
  { tag: T.rfalse, color: "#6bceff" }
]);

/* editor */
const SAMPLE = `🍠 Welcome to the Potato Playground!

greeting is "Hello from potato!"
say greeting

add (a, b) a potato b
say add(2, 2)

happy is :)
say happy ? "yay" : "oh no"

📢 is "what do we want? "
💬 is "emoji vars!!"
say 📢 potato 💬
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
        { key: "Mod-/", run: toggleLineComment },
        ...defaultKeymap,
        ...historyKeymap
      ]),
      new LanguageSupport(potatoLang),
      syntaxHighlighting(potatoHighlight),
      highlightActiveLine(),
      EditorView.theme({
        "&": {
          height: "100%",
          background: "var(--surface)",
          color: "var(--text)"
        },
        ".cm-scroller": { overflow: "auto" },
        ".cm-focused": { outline: "none" },
        ".cm-content ::selection": {
          backgroundColor: "rgba(145, 129, 109, 0.45)"
        },
        ".cm-content": {
          caretColor: "#a59a85"
        },
        "&.cm-focused .cm-cursor-primary": {
          borderLeftColor: "#675941b4",
          borderLeftWidth: "2.5px"
        }
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

async function initRuby() {
  try {
    const { DefaultRubyVM } = window["ruby-wasm-wasi"];
    if (!DefaultRubyVM)
      throw new Error("ruby-wasm-wasi UMD script did not load");

    setLoad(10, "Fetching Ruby runtime + Potato bundle…");
    const WASM_URL =
      "https://cdn.jsdelivr.net/npm/@ruby/4.0-wasm-wasi@2.8.1/dist/ruby+stdlib.wasm";
    const BUNDLE_URL = "./potato_bundle.rb";

    const [wasmModule, bundleText] = await Promise.all([
      fetch(WASM_URL)
        .then((r) => {
          if (!r.ok) throw new Error(`WASM fetch failed: ${r.status}`);
          return r.arrayBuffer();
        })
        .then((b) => WebAssembly.compile(b)),
      fetch(BUNDLE_URL).then((r) => {
        if (!r.ok) throw new Error(`Bundle missing: ${r.status}`);
        return r.text();
      })
    ]);

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
    rubyVM.eval(bundleText);

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
      rubyVM.eval(`$__out = StringIO.new; $stdout = $__out`);
      const escaped = source
        .replace(/\\/g, "\\\\")
        .replace(/"/g, '\\"')
        .replace(/#{/g, "\\#{");
      rubyVM.eval(`Potato.run("${escaped}")`);
      const out = rubyVM.eval(`$stdout = STDOUT; $__out.string`).toString();
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

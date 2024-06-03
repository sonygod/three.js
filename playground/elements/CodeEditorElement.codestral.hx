import js.html.Element;
import js.html.Window;
import js.html.HTMLDocument;
import js.html.InputData;
import js.html.Event;
import js.html.Requester;
import js.html.IExternallyVisible;
import js.html.window.IWindow;
import js.html.document.IDocument;

@:native("monaco.editor")
external class Editor {
    static function create(dom: Element, config: Dynamic): Dynamic;
}

class CodeEditorElement extends Element {
    private var _source: String;
    private var editor: Dynamic;
    private var updateInterval: Int;
    private var timeout: Int;

    public function new(source: String = "") {
        super();
        updateInterval = 500;
        _source = source;
        this.get_style().setProperty("z-index", "-1");
        this.classList.add("no-zoom");
        this.setHeight(500);

        var editorDOM: Element = Window.document.createElement("div");
        editorDOM.get_style().setProperty("width", "100%");
        editorDOM.get_style().setProperty("height", "100%");
        this.appendChild(editorDOM);

        editor = null;

        Window.require.config({ paths: { "vs": "https://cdn.jsdelivr.net/npm/monaco-editor@0.48.0/min/vs" } });

        Window.require(["vs/editor/editor.main"], function() {
            editor = Editor.create(editorDOM, {
                value: source,
                language: "javascript",
                theme: "vs-dark",
                automaticLayout: true,
                minimap: { enabled: false }
            });

            editor.getModel().onDidChangeContent(function() {
                _source = editor.getValue();

                if (timeout != null) Window.clearTimeout(timeout);

                timeout = Window.setTimeout(function() {
                    var event = new Event("change");
                    this.dispatchEvent(event);
                }, updateInterval);
            });
        });
    }

    public function get source(): String {
        return _source;
    }

    public function set source(value: String) {
        if (_source == value) return;

        _source = value;

        if (editor != null) editor.setValue(value);

        var event = new Event("change");
        this.dispatchEvent(event);
    }

    public function focus() {
        if (editor != null) editor.focus();
    }

    public function serialize(data: Dynamic) {
        super.serialize(data);
        data.source = source;
    }

    public function deserialize(data: Dynamic) {
        super.deserialize(data);
        source = (data.source != null) ? data.source : "";
    }
}

typedef LoaderLib = js.html.Window;
LoaderLib.setProperty("CodeEditorElement", Type.getClass<CodeEditorElement>());
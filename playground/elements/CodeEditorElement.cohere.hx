package;

import js.Browser;
import js.html.Document;
import js.html.HTMLElement;
import js.html.Window;

class CodeEditorElement extends Element {
    private var _source:String;
    private var editor:MonacoEditor;
    private var editorDOM:HTMLElement;
    private var timeout:Null<Int>;
    private static var monaco:Monaco;

    public var updateInterval:Int;

    public function new(source:String = "") {
        super();
        _source = source;
        this.dom.style.zIndex = -1;
        this.dom.classList.add("no-zoom");
        this.setHeight(500);

        editorDOM = Document.createDivElement();
        editorDOM.style.width = "100%";
        editorDOM.style.height = "100%";
        this.dom.appendChild(editorDOM);

        window.require.config({ paths: { 'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.48.0/min/vs' } } );

        window.require(["vs/editor/editor.main"], function(_) {
            monaco = cast Window.require("vs/editor/editor.main").Monaco;
            editor = monaco.editor.create(editorDOM, {
                value: _source,
                language: 'javascript',
                theme: 'vs-dark',
                automaticLayout: true,
                minimap: { enabled: false }
            });

            timeout = null;

            editor.getModel().onDidChangeContent(function() {
                _source = editor.getValue();
                if (timeout != null) {
                    window.clearTimeout(timeout);
                }
                timeout = window.setTimeout(function() {
                    dispatchEvent(Event.change);
                }, updateInterval);
            });
        });
    }

    public function set source(value:String) {
        if (_source == value) {
            return;
        }
        _source = value;
        if (editor != null) {
            editor.setValue(value);
        }
        dispatchEvent(Event.change);
    }

    public function get source():String {
        return _source;
    }

    public function focus() {
        if (editor != null) {
            editor.focus();
        }
    }

    public override function serialize(data:Dynamic) {
        super.serialize(data);
        data.source = source;
    }

    public override function deserialize(data:Dynamic) {
        super.deserialize(data);
        source = data.source ?? "";
    }
}
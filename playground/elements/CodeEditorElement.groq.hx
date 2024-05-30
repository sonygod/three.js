package three.js.playground.elements;

import js.html.Element;
import js.html.Document;
import js.Browser;

class CodeEditorElement extends Element {
    
    private var _source:String;
    private var editor:Dynamic;
    private var updateInterval:Int;

    public function new(?source:String = '') {
        super();
        
        this.updateInterval = 500;
        this._source = source;

        dom.style.zIndex = -1;
        dom.classList.add('no-zoom');

        setHeight(500);

        var editorDOM = Browser.document.createElement('div');
        editorDOM.style.width = '100%';
        editorDOM.style.height = '100%';
        dom.appendChild(editorDOM);

        haxe.Timer.delay(initEditor, 0);
    }

    private function initEditor() {
        var require = js.Lib.require;
        require.config({ paths: { 'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.48.0/min/vs' } });
        require(['vs/editor/editor.main'], () -> {
            editor = window.monaco.editor.create(editorDOM, {
                value: _source,
                language: 'javascript',
                theme: 'vs-dark',
                automaticLayout: true,
                minimap: { enabled: false }
            });

            var timeout:Null<haxe.Timer> = null;

            editor.getModel().onDidChangeContent(() -> {
                _source = editor.getValue();

                if (timeout != null) timeout.stop();
                timeout = haxe.Timer.delay(() -> {
                    dispatchEvent(new Event('change'));
                }, updateInterval);
            });
        });
    }

    public function set_source(value:String):Void {
        if (_source == value) return;
        _source = value;

        if (editor != null) editor.setValue(value);

        dispatchEvent(new Event('change'));
    }

    public function get_source():String {
        return _source;
    }

    public function focus():Void {
        if (editor != null) editor.focus();
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.source = _source;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        _source = data.source == null ? '' : data.source;
    }
}

LoaderLib.CodeEditorElement = CodeEditorElement;
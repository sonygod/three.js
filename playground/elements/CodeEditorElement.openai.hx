package three.js.playground.elements;

import js.Browser;
import js.html.DivElement;
import js.html.Event;
import js.lib.monaco.editor.Editor;
import js.lib.monaco.editor.IStandaloneCodeEditor;

using LoaderLib;

class CodeEditorElement extends Element {
    public var source(get, set):String;
    private var _source:String;
    private var updateInterval:Float = 500;
    private var editor:Editor;

    public function new(?source:String = '') {
        super();
        _source = source;
        js.Browser.window.require.config({ paths: { 'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.48.0/min/vs' } });
        var editorDOM = Browser.document.createElement('div');
        editorDOM.style.width = '100%';
        editorDOM.style.height = '100%';
        dom.appendChild(editorDOM);
        require(['vs/editor/editor.main'], () -> {
            editor = monaco.editor.create(editorDOM, {
                value: _source,
                language: 'javascript',
                theme: 'vs-dark',
                automaticLayout: true,
                minimap: { enabled: false }
            });
            var timeout:Null<Float> = null;
            editor.getModel().onDidChangeContent(() -> {
                _source = editor.getValue();
                if (timeout != null) {
                    Browser.window.clearTimeout(timeout);
                }
                timeout = Browser.window.setTimeout(() -> {
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

    override public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.source = _source;
    }

    override public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        _source = data.source != null ? data.source : '';
        if (editor != null) editor.setValue(_source);
    }
}

LoaderLib['CodeEditorElement'] = CodeEditorElement;
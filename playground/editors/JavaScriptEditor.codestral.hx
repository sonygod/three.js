import BaseNodeEditor from '../BaseNodeEditor.hx';
import CodeEditorElement from '../elements/CodeEditorElement.hx';
import js from 'three.nodes.js.Js';
import EventDispatcher from 'haxe.events.EventDispatcher';

class JavaScriptEditor extends BaseNodeEditor {

    public var editorElement: CodeEditorElement;

    public function new(source: String = '') {
        var codeNode = js.call(source);
        super('JavaScript', codeNode, 500);

        this.setResizable(true);

        this.editorElement = new CodeEditorElement(source);
        this.editorElement.addEventListener(new EventDispatcher().on('change', function(_) {
            codeNode.code = this.editorElement.source;
            this.invalidate();
            this.editorElement.focus();
        }, this));

        this.add(this.editorElement);
    }

    public function set source(value: String) {
        this.codeNode.code = value;
    }

    public function get source(): String {
        return this.codeNode.code;
    }

    public function get codeNode(): Dynamic {
        return this.value;
    }
}
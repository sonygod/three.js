package three.js.playground.editors;

import js.html.Element;
import js.Browser;
import haxe.Json;

typedef Layout = {
    name: String,
    outputType: String,
    icon: String,
    width: Int,
    elements: Array<{name: String, inputType: String}>
}

class NodePrototypeEditor extends JavaScriptEditor {
    private var codeNode:js.html.Element;
    private var scriptableNode:Scriptable;
    private var nodeClass:WeakMap<Dynamic, Dynamic>;
    private var instances:Array<Dynamic>;
    private var _prototype:Dynamic;

    public function new(source:String = defaultCode) {
        super(source);
        setName('Node Prototype');

        codeNode = Browser.document.createElement('div');
        scriptableNode = scriptable(codeNode);
        nodeClass = new WeakMap();
        instances = [];

        editorElement.addEventListener('change', updatePrototypes);

        updatePrototypes();
    }

    override public function serialize(data:Dynamic) {
        super.serialize(data);
        data.source = source;
    }

    override public function deserialize(data:Dynamic) {
        super.deserialize(data);
        source = data.source;
    }

    override public function deserializeLib(data:Dynamic, lib:Dynamic) {
        super.deserializeLib(data, lib);
        source = data.source;

        var nodePrototype = createPrototype();
        lib[nodePrototype.name] = nodePrototype.nodeClass;
    }

    public function setEditor(editor:Dynamic) {
        if (editor == null && this.editor != null) {
            this.editor.removeClass(_prototype);
        }

        super.setEditor(editor);

        if (editor == null) {
            for (proto in instances) {
                proto.dispose();
            }
            instances = [];
        }

        updatePrototypes();
    }

    private function createPrototype():Dynamic {
        if (_prototype != null) return _prototype;

        var nodePrototype = this;
        var scriptableNode = this.scriptableNode;
        var editorElement = this.editorElement;

        var nodeClass = new ScriptableEditor(scriptableNode.codeNode, false);
        nodeClass.serializePriority = -1;
        nodeClass.onCode = nodeClass.onCode.bind(nodeClass);

        nodeClass.onCode = function() {
            nodeClass.update();
        }

        nodeClass.setEditor = function(editor) {
            super.setEditor(editor);

            var index = nodePrototype.instances.indexOf(this);

            if (editor != null) {
                if (index == -1) nodePrototype.instances.push(this);
                editorElement.addEventListener('change', nodeClass.onCode);
            } else {
                if (index != -1) nodePrototype.instances.splice(index, 1);
                editorElement.removeEventListener('change', nodeClass.onCode);
            }
        }

        nodeClass.getClassName = function() {
            return scriptableNode.getLayout().name;
        }

        _prototype = {
            get_name: function() {
                return scriptableNode.getLayout().name;
            },
            get_icon: function() {
                return scriptableNode.getLayout().icon;
            },
            nodeClass: nodeClass,
            reference: this,
            editor: this.editor
        };

        return _prototype;
    }

    private function updatePrototypes() {
        if (_prototype != null && _prototype.editor != null) {
            _prototype.editor.removeClass(_prototype);
        }

        var layout = scriptableNode.getLayout();

        if (layout != null && layout.name != null) {
            if (editor != null) {
                editor.addClass(createPrototype());
            }
        }
    }
}
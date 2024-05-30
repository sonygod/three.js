package three.js.playground.editors;

import js.html.DOMElement;
import js.html.Event;

class NodePrototypeEditor extends JavaScriptEditor {
    private var nodeClass:WeakMap<Dynamic, Dynamic>;
    private var scriptableNode:Scriptable;
    private var instances:Array<Dynamic>;
    private var _prototype:Dynamic;

    public function new(?source:String) {
        super(source != null ? source : defaultCode);

        setName("Node Prototype");

        nodeClass = new WeakMap();
        scriptableNode = scriptable(codeNode);

        instances = [];

        editorElement.addEventListener(Event.CHANGE, function(_) {
            updatePrototypes();
        });

        _prototype = null;

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
        if (editor == null && editor != null) {
            editor.removeClass(_prototype);
        }

        super.setEditor(editor);

        if (editor == null) {
            for (proto in instances) {
                proto.dispose();
            }

            instances = [];

            updatePrototypes();
        }
    }

    private function createPrototype():Dynamic {
        if (_prototype != null) return _prototype;

        var nodePrototype:NodePrototypeEditor = this;
        var scriptableNode:Scriptable = this.scriptableNode;
        var editorElement:DOMElement = this.editorElement;

        var nodeClass = new ScriptableEditorClass(scriptableNode.codeNode, false);

        nodeClass.serializePriority = -1;

        nodeClass.onCode = function() {
            nodeClass.update();
        }

        nodeClass.setEditor = function(editor:Dynamic) {
            super.setEditor(editor);

            var index = instances.indexOf(this);

            if (editor != null) {
                if (index == -1) instances.push(this);

                editorElement.addEventListener(Event.CHANGE, nodeClass.onCode);
            } else {
                if (index != -1) instances.splice(index, 1);

                editorElement.removeEventListener(Event.CHANGE, nodeClass.onCode);
            }
        }

        nodeClass.className = function() {
            return scriptableNode.getLayout().name;
        }

        _prototype = {
            get_name():String {
                return scriptableNode.getLayout().name;
            },
            get_icon():String {
                return scriptableNode.getLayout().icon;
            },
            nodeClass: nodeClass,
            reference: this,
            editor: this.editor
        };

        return _prototype;
    }

    private function updatePrototypes():Void {
        if (_prototype != null && _prototype.editor != null) {
            _prototype.editor.removeClass(_prototype);
        }

        var layout:Dynamic = scriptableNode.getLayout();

        if (layout != null && layout.name != null) {
            if (editor != null) {
                editor.addClass(createPrototype());
            }
        }
    }
}

private class ScriptableEditorClass extends ScriptableEditor {
    public function new(codeNode:Dynamic, ?_super:Bool) {
        super(codeNode, _super);

        serializePriority = -1;

        onCode = onCode.bind(this);
    }

    public function onCode():Void {
        update();
    }

    override public function setEditor(editor:Dynamic):Void {
        super.setEditor(editor);

        var index:Int = nodePrototype.instances.indexOf(this);

        if (editor != null) {
            if (index == -1) nodePrototype.instances.push(this);

            editorElement.addEventListener(Event.CHANGE, onCode);
        } else {
            if (index != -1) nodePrototype.instances.splice(index, 1);

            editorElement.removeEventListener(Event.CHANGE, onCode);
        }
    }

    public function get_className():String {
        return scriptableNode.getLayout().name;
    }
}

private var defaultCode:String = '
// Addition Node Example
// Enjoy! :)

// layout must be the first variable.

layout = {
    name: "Custom Addition",
    outputType: \'node\",
    icon: \'heart-plus\",
    width: 200,
    elements: [
        { name: \'A\', inputType: \'node\' },
        { name: \'B\', inputType: \'node\' }
    ]
};

// THREE and TSL (Three.js Shading Language) namespaces are available.
// main code must be in the output function.

const { add, float } = TSL;

function main() {

    const nodeA = parameters.get( \'A\' ) || float();
    const nodeB = parameters.get( \'B\' ) || float();

    return add( nodeA, nodeB );

}
';
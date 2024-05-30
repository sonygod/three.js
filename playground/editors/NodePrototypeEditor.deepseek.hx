import three.nodes.Scriptable;
import three.nodes.JavaScriptEditor;
import three.nodes.ScriptableEditor;

class NodePrototypeEditor extends JavaScriptEditor {

    static var defaultCode:String = `// Addition Node Example
// Enjoy! :)

// layout must be the first variable.

layout = {
	name: "Custom Addition",
	outputType: 'node',
	icon: 'heart-plus',
	width: 200,
	elements: [
		{ name: 'A', inputType: 'node' },
		{ name: 'B', inputType: 'node' }
	]
};

// THREE and TSL (Three.js Shading Language) namespaces are available.
// main code must be in the output function.

const { add, float } = TSL;

function main() {

	const nodeA = parameters.get( 'A' ) || float();
	const nodeB = parameters.get( 'B' ) || float();

	return add( nodeA, nodeB );

}`;

    public function new(source:String = defaultCode) {
        super(source);

        this.setName('Node Prototype');

        this.nodeClass = new WeakMap();
        this.scriptableNode = Scriptable.scriptable(this.codeNode);

        this.instances = [];

        this.editorElement.addEventListener('change', () -> {
            this.updatePrototypes();
        });

        this._prototype = null;

        this.updatePrototypes();
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        data.source = this.source;
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        this.source = data.source;
    }

    public function deserializeLib(data:Dynamic, lib:Dynamic):Void {
        super.deserializeLib(data, lib);
        this.source = data.source;

        var nodePrototype = this.createPrototype();
        lib[nodePrototype.name] = nodePrototype.nodeClass;
    }

    public function setEditor(editor:Dynamic):Void {
        if (editor == null && this.editor) {
            this.editor.removeClass(this._prototype);
        }

        super.setEditor(editor);

        if (editor == null) {
            for (proto in this.instances) {
                proto.dispose();
            }

            this.instances = [];
        }

        this.updatePrototypes();
    }

    public function createPrototype():Dynamic {
        if (this._prototype != null) return this._prototype;

        var nodePrototype = this;
        var scriptableNode = this.scriptableNode;
        var editorElement = this.editorElement;

        var nodeClass = {
            public function new() {
                super(scriptableNode.codeNode, false);

                this.serializePriority = -1;

                this.onCode = function() {
                    this.update();
                };
            }

            public function onCode():Void {
                this.update();
            }

            public function setEditor(editor:Dynamic):Void {
                super.setEditor(editor);

                var index = nodePrototype.instances.indexOf(this);

                if (editor) {
                    if (index == -1) nodePrototype.instances.push(this);

                    editorElement.addEventListener('change', this.onCode);
                } else {
                    if (index != -1) nodePrototype.instances.splice(index, 1);

                    editorElement.removeEventListener('change', this.onCode);
                }
            }

            public function get className():String {
                return scriptableNode.getLayout().name;
            }
        };

        this._prototype = {
            public function get name():String {
                return scriptableNode.getLayout().name;
            },
            public function get icon():String {
                return scriptableNode.getLayout().icon;
            },
            nodeClass: nodeClass,
            reference: this,
            editor: this.editor
        };

        return this._prototype;
    }

    public function updatePrototypes():Void {
        if (this._prototype != null && this._prototype.editor != null) {
            this._prototype.editor.removeClass(this._prototype);
        }

        var layout = this.scriptableNode.getLayout();

        if (layout && layout.name) {
            if (this.editor) {
                this.editor.addClass(this.createPrototype());
            }
        }
    }
}
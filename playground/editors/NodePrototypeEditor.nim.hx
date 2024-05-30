import JavaScriptEditor.JavaScriptEditor;
import ScriptableEditor.ScriptableEditor;
import scriptable.scriptable;

class NodePrototypeEditor extends JavaScriptEditor {

    public var defaultCode:String =
    `// Addition Node Example
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

    }
    `;

    public var nodeClass:NodeClass<Dynamic>;
    public var scriptableNode:ScriptableNode<Dynamic>;
    public var instances:Array<Dynamic>;
    public var _prototype:Dynamic;

    public function new(source:String = defaultCode) {
        super(source);

        this.setName("Node Prototype");

        this.nodeClass = new WeakMap();
        this.scriptableNode = scriptable(this.codeNode);

        this.instances = [];

        this.editorElement.addEventListener("change", function() {
            this.updatePrototypes();
        });

        this._prototype = null;

        this.updatePrototypes();
    }

    public function serialize(data:Dynamic) {
        super.serialize(data);

        data.source = this.source;
    }

    public function deserialize(data:Dynamic) {
        super.deserialize(data);

        this.source = data.source;
    }

    public function deserializeLib(data:Dynamic, lib:Dynamic) {
        super.deserializeLib(data, lib);

        this.source = data.source;

        const nodePrototype = this.createPrototype();
        lib[nodePrototype.name] = nodePrototype.nodeClass;
    }

    public function setEditor(editor:Dynamic) {
        if (editor === null && this.editor) {
            this.editor.removeClass(this._prototype);
        }

        super.setEditor(editor);

        if (editor === null) {
            for (proto in this.instances) {
                proto.dispose();
            }

            this.instances = [];
        }

        this.updatePrototypes();
    }

    public function createPrototype() {
        if (this._prototype !== null) return this._prototype;

        const nodePrototype = this;
        const scriptableNode = this.scriptableNode;
        const editorElement = this.editorElement;

        const nodeClass = class extends ScriptableEditor {
            public function new() {
                super(scriptableNode.codeNode, false);

                this.serializePriority = -1;

                this.onCode = this.onCode.bind(this);
            }

            public function onCode() {
                this.update();
            }

            public function setEditor(editor:Dynamic) {
                super.setEditor(editor);

                const index = nodePrototype.instances.indexOf(this);

                if (editor) {
                    if (index === -1) nodePrototype.instances.push(this);

                    editorElement.addEventListener("change", this.onCode);
                } else {
                    if (index !== -1) nodePrototype.instances.splice(index, 1);

                    editorElement.removeEventListener("change", this.onCode);
                }
            }

            public function get className() {
                return scriptableNode.getLayout().name;
            }
        };

        this._prototype = {
            get name() {
                return scriptableNode.getLayout().name;
            },
            get icon() {
                return scriptableNode.getLayout().icon;
            },
            nodeClass,
            reference: this,
            editor: this.editor
        };

        return this._prototype;
    }

    public function updatePrototypes() {
        if (this._prototype !== null && this._prototype.editor !== null) {
            this._prototype.editor.removeClass(this._prototype);
        }

        const layout = this.scriptableNode.getLayout();

        if (layout && layout.name) {
            if (this.editor) {
                this.editor.addClass(this.createPrototype());
            }
        }
    }
}
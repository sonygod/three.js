import three.nodes.ScriptableEditor;
import three.nodes.Scriptable;

class NodePrototypeEditor extends JavaScriptEditor {

	public var source:String;
	public var nodeClass:WeakMap<Dynamic,Dynamic>;
	public var scriptableNode:Scriptable;
	public var instances:Array<Dynamic>;
	private var _prototype:Dynamic;

	public function new(source:String = defaultCode) {
		super(source);
		this.setName("Node Prototype");
		this.nodeClass = new WeakMap();
		this.scriptableNode = Scriptable.fromCode(this.codeNode);
		this.instances = [];
		this.editorElement.addEventListener("change", this.updatePrototypes);
		this._prototype = null;
		this.updatePrototypes();
	}

	override public function serialize(data:Dynamic) {
		super.serialize(data);
		data.source = this.source;
	}

	override public function deserialize(data:Dynamic) {
		super.deserialize(data);
		this.source = data.source;
	}

	override public function deserializeLib(data:Dynamic, lib:Dynamic) {
		super.deserializeLib(data, lib);
		this.source = data.source;
		var nodePrototype = this.createPrototype();
		lib[nodePrototype.name] = nodePrototype.nodeClass;
	}

	override public function setEditor(editor:Dynamic) {
		if (editor == null && this.editor != null) {
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
		var nodeClass = class extends ScriptableEditor {
			public function new() {
				super(scriptableNode.codeNode, false);
				this.serializePriority = -1;
				this.onCode = this.onCode.bind(this);
			}
			public function onCode():Void {
				this.update();
			}
			override public function setEditor(editor:Dynamic) {
				super.setEditor(editor);
				var index = nodePrototype.instances.indexOf(this);
				if (editor) {
					if (index == -1) nodePrototype.instances.push(this);
					editorElement.addEventListener("change", this.onCode);
				} else {
					if (index != -1) nodePrototype.instances.splice(index, 1);
					editorElement.removeEventListener("change", this.onCode);
				}
			}
			public function get className():String {
				return scriptableNode.getLayout().name;
			}
		};
		this._prototype = {
			get name():String {
				return scriptableNode.getLayout().name;
			},
			get icon():String {
				return scriptableNode.getLayout().icon;
			},
			nodeClass:nodeClass,
			reference:this,
			editor:this.editor
		};
		return this._prototype;
	}

	public function updatePrototypes():Void {
		if (this._prototype != null && this._prototype.editor != null) {
			this._prototype.editor.removeClass(this._prototype);
		}
		var layout = this.scriptableNode.getLayout();
		if (layout != null && layout.name != null) {
			if (this.editor != null) {
				this.editor.addClass(this.createPrototype());
			}
		}
	}
}

private var defaultCode:String = "// Addition Node Example\n// Enjoy! :)\n\n// layout must be the first variable.\n\nlayout = {\n\tname: \"Custom Addition\",\n\toutputType: 'node',\n\ticon: 'heart-plus',\n\twidth: 200,\n\telements: [\n\t\t{ name: 'A', inputType: 'node' },\n\t\t{ name: 'B', inputType: 'node' }\n\t]\n};\n\n// THREE and TSL (Three.js Shading Language) namespaces are available.\n// main code must be in the output function.\n\nconst { add, float } = TSL;\n\nfunction main() {\n\n\tconst nodeA = parameters.get( 'A' ) || float();\n\tconst nodeB = parameters.get( 'B' ) || float();\n\n\treturn add( nodeA, nodeB );\n\n}";
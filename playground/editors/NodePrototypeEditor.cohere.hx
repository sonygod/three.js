import js.JavaScriptEditor from './JavaScriptEditor.js';
import js.ScriptableEditor from './ScriptableEditor.js';
import js.scriptable from 'three/nodes';

var defaultCode = '/*\n' +
' * 加法节点示例\n' +
' * 玩得开心! :)\n' +
' *\n' +
' * 布局必须是第一个变量。\n' +
' */\n' +
'\n' +
'layout = {\n' +
'    name: "自定义加法",\n' +
'    outputType: "node",\n' +
'    icon: "heart-plus",\n' +
'    width: 200,\n' +
'    elements: [\n' +
'        { name: "A", inputType: "node" },\n' +
'        { name: "B", inputType: "node" }\n' +
'    ]\n' +
'};\n' +
'\n' +
'// 可使用 THREE 和 TSL (Three.js Shading Language) 命名空间。\n' +
'// 主代码必须在 output 函数中。\n' +
'\n' +
'const { add, float } = TSL;\n' +
'\n' +
'function output( parameters ) {\n' +
'\n' +
'    const nodeA = parameters.get( "A" ) || float();\n' +
'    const nodeB = parameters.get( "B" ) || float();\n' +
'\n' +
'    return add( nodeA, nodeB );\n' +
'\n' +
'}';

class NodePrototypeEditor extends js.JavaScriptEditor {

	public function new( source : String = defaultCode ) {

		super( source );

		this.setName( 'Node Prototype' );

		this.nodeClass = new WeakMap();
		this.scriptableNode = js.scriptable( this.codeNode );

		this.instances = [];

		this.editorElement.addEventListener( 'change', $bind( this, this.updatePrototypes ) );

		this._prototype = null;

		this.updatePrototypes();

	}

	public function serialize( data : Dynamic ) : Void {

		super.serialize( data );

		data.source = this.source;

	}

	public function deserialize( data : Dynamic ) : Void {

		super.deserialize( data );

		this.source = data.source;

	}

	public function deserializeLib( data : Dynamic, lib : Dynamic ) : Void {

		super.deserializeLib( data, lib );

		this.source = data.source;

		var nodePrototype = this.createPrototype();
		lib[ nodePrototype.name ] = nodePrototype.nodeClass;

	}

	public function setEditor( editor : Dynamic ) : Void {

		if ( editor == null && this.editor != null ) {

			this.editor.removeClass( this._prototype );

		}

		super.setEditor( editor );

		if ( editor == null ) {

			for ( proto in this.instances ) {

				proto.dispose();

			}

			this.instances = [];

		}

		this.updatePrototypes();

	}

	private function createPrototype() : Dynamic {

		if ( this._prototype != null ) return this._prototype;

		var nodePrototype = this;
		var scriptableNode = this.scriptableNode;
		var editorElement = this.editorElement;

		var nodeClass = class extends js.ScriptableEditor {

			public function new() {

				super( scriptableNode.codeNode, false );

				this.serializePriority = - 1;

				this.onCode = $bind( this, this.onCode );

			}

			private function onCode() : Void {

				this.update();

			}

			public function setEditor( editor : Dynamic ) : Void {

				super.setEditor( editor );

				var index = nodePrototype.instances.indexOf( this );

				if ( editor != null ) {

					if ( index == - 1 ) nodePrototype.instances.push( this );

					editorElement.addEventListener( 'change', this.onCode );

				} else {

					if ( index != - 1 ) nodePrototype.instances.splice( index, 1 );

					editorElement.removeEventListener( 'change', this.onCode );

				}

			}

			public function get className() : String {

				return scriptableNode.getLayout().name;

			}

		};

		this._prototype = {
			get_name: function() : String {

				return scriptableNode.getLayout().name;

			},
			get_icon: function() : String {

				return scriptableNode.getLayout().icon;

			},
			nodeClass: nodeClass,
			reference: this,
			editor: this.editor
		};

		return this._prototype;

	}

	private function updatePrototypes() : Void {

		if ( this._prototype != null && this._prototype.editor != null ) {

			this._prototype.editor.removeClass( this._prototype );

		}

		//

		var layout = this.scriptableNode.getLayout();

		if ( layout != null && layout.name != null ) {

			if ( this.editor != null ) {

				this.editor.addClass( this.createPrototype() );

			}

		}

	}

}
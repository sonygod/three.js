import BaseNodeEditor from '../BaseNodeEditor.js';
import CodeEditorElement from '../elements/CodeEditorElement.js';
import { disposeScene, createElementFromJSON, isGPUNode, onValidType } from '../NodeEditorUtils.js';
import { global, scriptable, js, scriptableValue } from 'three/nodes';
import { getColorFromType, setInputAestheticsFromType, setOutputAestheticsFromType } from '../DataTypeLib.js';

const defaultTitle:String = 'Scriptable';
const defaultWidth:Int = 500;

class ScriptableEditor extends BaseNodeEditor {

	var codeNode:Dynamic;
	var scriptableNode:Dynamic;

	public function new( source:Dynamic = null, enableEditor:Bool = true ) {

		if ( source && source.isCodeNode ) {

			codeNode = source;

		} else {

			codeNode = js( source || '' );

		}

		scriptableNode = scriptable( codeNode );

		super( defaultTitle, scriptableNode, defaultWidth );

		this.scriptableNode = scriptableNode;
		this.editorCodeNode = codeNode;
		this.editorOutput = null;
		this.editorOutputAdded = null;

		this.layout = null;
		this.editorElement = null;

		this.layoutJSON = '';
		this.initCacheKey = '';
		this.initId = 0;
		this.waitToLayoutJSON = null;

		this.hasInternalEditor = false;

		this._updating = false;

		this.onValidElement = function() {};

		if ( enableEditor ) {

			this.title.setSerializable( true );

			this._initExternalConnection();

			this._toInternal();

		}

		var defaultOutput = this.scriptableNode.getDefaultOutput();
		defaultOutput.events.addEventListener( 'refresh', function() {

			this.update();

		} );

		this.update();

	}

	public function getColor():String {

		var color = getColorFromType( this.layout ? this.layout.outputType : null );

		return color ? color + 'BB' : null;

	}

	public function hasJSON():Bool {

		return true;

	}

	public function exportJSON():Dynamic {

		return this.scriptableNode.toJSON();

	}

	public function setSource( source:String ):ScriptableEditor {

		this.editorCodeNode.code = source;

		this.update();

		return this;

	}

	public function update( force:Bool = false ):Void {

		if ( this._updating === true ) return;

		this._updating = true;

		this.scriptableNode.codeNode = this.codeNode;
		this.scriptableNode.needsUpdate = true;

		var layout:Dynamic = null;
		var scriptableValueOutput:Dynamic = null;

		try {

			var object = this.scriptableNode.getObject();

			layout = this.scriptableNode.getLayout();

			this.updateLayout( layout, force );

			scriptableValueOutput = this.scriptableNode.getDefaultOutput();

			var initCacheKey = Type.typeof( object.init ) == 'Function' ? Std.string( object.init ) : '';

			if ( initCacheKey !== this.initCacheKey ) {

				this.initCacheKey = initCacheKey;

				var initId = ++ this.initId;

				this.scriptableNode.callAsync( 'init' ).then( function() {

					if ( initId === this.initId ) {

						this.update();

						if ( this.editor ) this.editor.tips.message( 'ScriptEditor: Initialized.' );

					}

				} );

			}

		} catch ( e:Dynamic ) {

			trace( e );

			if ( this.editor ) this.editor.tips.error( e.message );

		}

		var editorOutput = scriptableValueOutput ? scriptableValueOutput.value : null;

		this.value = isGPUNode( editorOutput ) ? this.scriptableNode : scriptableValueOutput;
		this.layout = layout;
		this.editorOutput = editorOutput;

		this.updateOutputInEditor();
		this.updateOutputConnection();

		this.invalidate();

		this._updating = false;

	}

	public function updateOutputConnection():Void {

		var layout = this.layout;

		if ( layout ) {

			var outputType = layout.outputType;

			setOutputAestheticsFromType( this.title, outputType );

		} else {

			this.title.setOutput( 0 );

		}

	}

	public function updateOutputInEditor():Void {

		var editor = this.editor;
		var editorOutput = this.editorOutput;
		var editorOutputAdded = this.editorOutputAdded;

		if ( editor && editorOutput === editorOutputAdded ) return;

		var scene = global.get( 'scene' );
		var composer = global.get( 'composer' );

		if ( editor ) {

			if ( editorOutputAdded && editorOutputAdded.isObject3D === true ) {

				editorOutputAdded.removeFromParent();

				disposeScene( editorOutputAdded );

			} else if ( composer && editorOutputAdded && editorOutputAdded.isPass === true ) {

				composer.removePass( editorOutputAdded );

			}

			if ( editorOutput && editorOutput.isObject3D === true ) {

				scene.add( editorOutput );

			} else if ( composer && editorOutput && editorOutput.isPass === true ) {

				composer.addPass( editorOutput );

			}

			this.editorOutputAdded = editorOutput;

		} else {

			if ( editorOutputAdded && editorOutputAdded.isObject3D === true ) {

				editorOutputAdded.removeFromParent();

				disposeScene( editorOutputAdded );

			} else if ( composer && editorOutputAdded && editorOutputAdded.isPass === true ) {

				composer.removePass( editorOutputAdded );

			}

			this.editorOutputAdded = null;

		}

	}

	public function setEditor( editor:Dynamic ):Void {

		super.setEditor( editor );

		this.updateOutputInEditor();

	}

	public function clearParameters():Void {

		this.layoutJSON = '';

		this.scriptableNode.clearParameters();

		for ( element in this.elements.concat() ) {

			if ( element !== this.editorElement && element !== this.title ) {

				this.remove( element );

			}

		}

	}

	public function addElementFromJSON( json:Dynamic ):Dynamic {

		var { id, element, inputNode, outputType } = createElementFromJSON( json );

		this.add( element );

		this.scriptableNode.setParameter( id, inputNode );

		if ( outputType ) {

			element.setObjectCallback( function() {

				return this.scriptableNode.getOutput( id );

			} );

		}

		//

		var onUpdate = function() {

			var value = element.value;
			var paramValue = value && value.isScriptableValueNode ? value : scriptableValue( value );

			this.scriptableNode.setParameter( id, paramValue );

			this.update();

		};

		element.addEventListener( 'changeInput', onUpdate );
		element.onConnect( onUpdate, true );

		//element.onConnect( () => this.getScriptable().call( 'onDeepChange' ), true );

		return element;

	}

	public function updateLayout( layout:Dynamic = null, force:Bool = false ):Void {

		var needsUpdateWidth = this.hasExternalEditor || this.editorElement === null;

		if ( this.waitToLayoutJSON !== null ) {

			if ( this.waitToLayoutJSON === Std.string( layout || '{}' ) ) {

				this.waitToLayoutJSON = null;

				if ( needsUpdateWidth ) this.setWidth( layout.width );

			} else {

				return;

			}

		}

		if ( layout ) {

			var layoutCacheKey = Std.string( layout );

			if ( this.layoutJSON !== layoutCacheKey || force === true ) {

				this.clearParameters();

				if ( layout.name ) {

					this.setName( layout.name );

				}


				if ( layout.icon ) {

					this.setIcon( layout.icon );

				}

				if ( needsUpdateWidth ) {

					if ( layout.width !== undefined ) {

						this.setWidth( layout.width );

					} else {

						this.setWidth( defaultWidth );

					}

				}

				if ( layout.elements ) {

					for ( element in layout.elements ) {

						this.addElementFromJSON( element );

					}

					if ( this.editorElement ) {

						this.remove( this.editorElement );
						this.add( this.editorElement );

					}

				}

				this.layoutJSON = layoutCacheKey;

			}

		} else {

			this.setName( defaultTitle );
			this.setIcon( null );
			this.setWidth( defaultWidth );

			this.clearParameters();

		}

		this.updateOutputConnection();

	}

	public function get hasExternalEditor():Bool {

		return this.title.getLinkedObject() !== null;

	}

	public function get codeNode():Dynamic {

		return this.hasExternalEditor ? this.title.getLinkedObject() : this.editorCodeNode;

	}

	private function _initExternalConnection():Void {

		setInputAestheticsFromType(this.title, 'CodeNode' ).onValid( onValidType( 'CodeNode' ) ).onConnect( function() {

			this.hasExternalEditor ? this._toExternal() : this._toInternal();

			this.update();

		}, true );

	}

	private function _toInternal():Void {

		if ( this.hasInternalEditor === true ) return;

		if ( this.editorElement === null ) {

			this.editorElement = new CodeEditorElement( this.editorCodeNode.code );
			this.editorElement.addEventListener( 'change', function() {

				this.setSource( this.editorElement.source );

				this.editorElement.focus();

			} );

			this.add( this.editorElement );

		}

		this.setResizable( true );

		this.editorElement.setVisible( true );

		this.hasInternalEditor = true;

		this.update( /*true*/ );

	}

	private function _toExternal():Void {

		if ( this.hasInternalEditor === false ) return;

		this.editorElement.setVisible( false );

		this.setResizable( false );

		this.hasInternalEditor = false;

		this.update( /*true*/ );

	}

	public function serialize( data:Dynamic ):Void {

		super.serialize( data );

		data.layoutJSON = this.layoutJSON;

	}

	public function deserialize( data:Dynamic ):Void {

		this.updateLayout( Std.parse( data.layoutJSON || '{}' ), true );

		this.waitToLayoutJSON = data.layoutJSON;

		super.deserialize( data );

	}

}
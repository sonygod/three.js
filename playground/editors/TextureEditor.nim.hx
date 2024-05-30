import flow.LabelElement;
import flow.ToggleInput;
import flow.SelectInput;
import BaseNodeEditor from '../BaseNodeEditor.js';
import { onValidNode, onValidType } from '../NodeEditorUtils.js';
import { texture, uv } from 'three/nodes';
import { Texture, TextureLoader, RepeatWrapping, ClampToEdgeWrapping, MirroredRepeatWrapping } from 'three';
import { setInputAestheticsFromType } from '../DataTypeLib.js';

class TextureEditor extends BaseNodeEditor {

  var textureLoader:TextureLoader = new TextureLoader();
  var defaultTexture:Texture = new Texture();
  var defaultUV:Dynamic = null;

  function getTexture( url:String ) {
    return textureLoader.load( url );
  }

  public function new() {
    super();
    var node:Dynamic = texture( defaultTexture );
    super('Texture', node, 250);
    this.texture = null;
    this._initFile();
    this._initParams();
    this.onValidElement = function() {};
  }

  private function _initFile() {
    var fileElement:LabelElement = setInputAestheticsFromType( new LabelElement( 'File' ), 'URL' );
    fileElement.onValid( onValidType( 'URL' ) ).onConnect( function() {
      var textureNode:Dynamic = this.value;
      var fileEditorElement:Dynamic = fileElement.getLinkedElement();
      this.texture = fileEditorElement ? getTexture( fileEditorElement.node.getURL() ) : null;
      textureNode.value = this.texture || defaultTexture;
      this.update();
    }, true );
    this.add( fileElement );
  }

  private function _initParams() {
    var uvField:LabelElement = setInputAestheticsFromType( new LabelElement( 'UV' ), 'Vector2' );
    uvField.onValid( onValidNode ).onConnect( function() {
      var node:Dynamic = this.value;
      node.uvNode = uvField.getLinkedObject() || defaultUV || ( defaultUV = uv() );
    } );
    this.wrapSInput = new SelectInput( [
      { name: 'Repeat Wrapping', value: RepeatWrapping },
      { name: 'Clamp To Edge Wrapping', value: ClampToEdgeWrapping },
      { name: 'Mirrored Repeat Wrapping', value: MirroredRepeatWrapping }
    ], RepeatWrapping ).onChange( function() {
      this.update();
    } );
    this.wrapTInput = new SelectInput( [
      { name: 'Repeat Wrapping', value: RepeatWrapping },
      { name: 'Clamp To Edge Wrapping', value: ClampToEdgeWrapping },
      { name: 'Mirrored Repeat Wrapping', value: MirroredRepeatWrapping }
    ], RepeatWrapping ).onChange( function() {
      this.update();
    } );
    this.flipYInput = new ToggleInput( false ).onChange( function() {
      this.update();
    } );
    this.add( uvField )
      .add( new LabelElement( 'Wrap S' ).add( this.wrapSInput ) )
      .add( new LabelElement( 'Wrap T' ).add( this.wrapTInput ) )
      .add( new LabelElement( 'Flip Y' ).add( this.flipYInput ) );
  }

  public function update() {
    var texture:Texture = this.texture;
    if ( texture ) {
      texture.wrapS = Std.int( this.wrapSInput.getValue() );
      texture.wrapT = Std.int( this.wrapTInput.getValue() );
      texture.flipY = this.flipYInput.getValue();
      texture.dispose();
      this.invalidate();
    }
  }

}
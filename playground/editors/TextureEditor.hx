package three.js.playground.editors;

import flow.LabelElement;
import flow.ToggleInput;
import flow.SelectInput;
import three.nodes.Texture;
import three.TextureLoader;
import three.RepeatWrapping;
import three.ClampToEdgeWrapping;
import three.MirroredRepeatWrapping;
import three.nodes.UV;
import three.DataTypeLib;

class TextureEditor extends BaseNodeEditor {
  var texture:Texture;
  var defaultUV:UV;

  public function new() {
    var node = new Texture(defaultTexture);
    super('Texture', node, 250);

    this.texture = null;

    _initFile();
    _initParams();
  }

  function _initFile() {
    var fileElement = setInputAestheticsFromType(new LabelElement('File'), 'URL');
    fileElement.onValid(onValidType('URL')).onConnect(() -> {
      var textureNode = this.value;
      var fileEditorElement = fileElement.getLinkedElement();

      this.texture = fileEditorElement ? getTexture(fileEditorElement.node.getURL()) : null;

      textureNode.value = this.texture || defaultTexture;

      update();
    }, true);

    add(fileElement);
  }

  function _initParams() {
    var uvField = setInputAestheticsFromType(new LabelElement('UV'), 'Vector2');
    uvField.onValid(onValidNode).onConnect(() -> {
      var node = this.value;

      node.uvNode = uvField.getLinkedObject() || defaultUV || (defaultUV = new UV());
    });

    var wrapSInput = new SelectInput([
      { name: 'Repeat Wrapping', value: RepeatWrapping },
      { name: 'Clamp To Edge Wrapping', value: ClampToEdgeWrapping },
      { name: 'Mirrored Repeat Wrapping', value: MirroredRepeatWrapping }
    ], RepeatWrapping);
    wrapSInput.onChange(() -> {
      update();
    });

    var wrapTInput = new SelectInput([
      { name: 'Repeat Wrapping', value: RepeatWrapping },
      { name: 'Clamp To Edge Wrapping', value: ClampToEdgeWrapping },
      { name: 'Mirrored Repeat Wrapping', value: MirroredRepeatWrapping }
    ], RepeatWrapping);
    wrapTInput.onChange(() -> {
      update();
    });

    var flipYInput = new ToggleInput(false);
    flipYInput.onChange(() -> {
      update();
    });

    add(uvField)
      .add(new LabelElement('Wrap S').add(wrapSInput))
      .add(new LabelElement('Wrap T').add(wrapTInput))
      .add(new LabelElement('Flip Y').add(flipYInput));
  }

  function update() {
    var texture = this.texture;

    if (texture != null) {
      texture.wrapS = Std.parseInt(wrapSInput.getValue());
      texture.wrapT = Std.parseInt(wrapTInput.getValue());
      texture.flipY = flipYInput.getValue();
      texture.dispose();

      invalidate();
    }
  }

  static function getTexture(url:String):Texture {
    var textureLoader = new TextureLoader();
    return textureLoader.load(url);
  }
}
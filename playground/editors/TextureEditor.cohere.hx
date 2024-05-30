import js.Browser.Location;
import js.Browser.Window;
import js.three.Texture;
import js.three.TextureLoader;
import js.three.nodes.TextureNode;
import js.three.nodes.UVNode;
import js.three.enums.TextureWrappingMode;

class TextureEditor extends BaseNodeEditor {
    private _texture: Texture;
    private _defaultUV: UVNode;
    private _textureLoader: TextureLoader;
    private _defaultTexture: Texture;

    public function new() {
        super('Texture', new TextureNode(defaultTexture), 250);
        _texture = null;
        _initFile();
        _initParams();
        onValidElement = function() {};
    }

    private function _initFile() {
        var fileElement = setInputAestheticsFromType(new LabelElement('File'), 'URL');
        fileElement.onValid(onValidType('URL')).onConnect(function() {
            var textureNode = value;
            var fileEditorElement = fileElement.getLinkedElement();
            _texture = fileEditorElement ? getTexture(fileEditorElement.node.getURL()) : null;
            textureNode.value = _texture != null ? _texture : defaultTexture;
            update();
        }, true);
        add(fileElement);
    }

    private function _initParams() {
        var uvField = setInputAestheticsFromType(new LabelElement('UV'), 'Vector2');
        uvField.onValid(onValidNode).onConnect(function() {
            var node = value;
            node.uvNode = uvField.getLinkedObject() != null ? _defaultUV : (_defaultUV = new UVNode());
        });
        var wrapSInput = new SelectInput([
            {'name': 'Repeat Wrapping', 'value': TextureWrappingMode.RepeatWrapping},
            {'name': 'Clamp To Edge Wrapping', 'value': TextureWrappingMode.ClampToEdgeWrapping},
            {'name': 'Mirrored Repeat Wrapping', 'value': TextureWrappingMode.MirroredRepeatWrapping}
        ], TextureWrappingMode.RepeatWrapping);
        wrapSInput.onChange(function() {
            update();
        });
        var wrapTInput = new SelectInput([
            {'name': 'Repeat Wrapping', 'value': TextureWrappingMode.RepeatWrapping},
            {'name': 'Clamp To Edge Wrapping', 'value': TextureWrappingMode.ClampToEdgeWrapping},
            {'name': 'Mirrored Repeat Wrapping', 'value': TextureWrappingMode.MirroredRepeatWrapping}
        ], TextureWrappingMode.RepeatWrapping);
        wrapTInput.onChange(function() {
            update();
        });
        var flipYInput = new ToggleInput(false);
        flipYInput.onChange(function() {
            update();
        });
        add(uvField);
        add(new LabelElement('Wrap S').add(wrapSInput));
        add(new LabelElement('Wrap T').add(wrapTInput));
        add(new LabelElement('Flip Y').add(flipYInput));
    }

    private function getTexture(url:String):Texture {
        return _textureLoader.load(url);
    }

    private function update() {
        if (_texture != null) {
            _texture.wrapS = Std.int(wrapSInput.getValue());
            _texture.wrapT = Std.int(wrapTInput.getValue());
            _texture.flipY = flipYInput.getValue();
            _texture.dispose();
            invalidate();
        }
    }

    public static function main() {
        var editor = new TextureEditor();
        Window.document.body.appendChild(editor);
    }
}

var defaultTexture = new Texture();
var defaultUV = null;
var textureLoader = new TextureLoader();
import flow.LabelElement;
import flow.ToggleInput;
import flow.SelectInput;
import three.nodes.texture;
import three.nodes.uv;
import three.Texture;
import three.TextureLoader;
import three.RepeatWrapping;
import three.ClampToEdgeWrapping;
import three.MirroredRepeatWrapping;
import three.BaseNodeEditor;
import three.NodeEditorUtils.onValidNode;
import three.NodeEditorUtils.onValidType;
import three.DataTypeLib.setInputAestheticsFromType;

class TextureEditor extends BaseNodeEditor {

    public var texture:Texture;
    private var wrapSInput:SelectInput;
    private var wrapTInput:SelectInput;
    private var flipYInput:ToggleInput;
    private static var defaultTexture:Texture = new Texture();
    private static var defaultUV:Dynamic = null;
    private static var textureLoader:TextureLoader = new TextureLoader();

    public function new() {
        var node = texture(defaultTexture);
        super('Texture', node, 250);
        this.texture = null;
        this._initFile();
        this._initParams();
        this.onValidElement = () -> {};
    }

    private function _initFile():Void {
        var fileElement = setInputAestheticsFromType(new LabelElement('File'), 'URL');

        fileElement.onValid(onValidType('URL')).onConnect(() -> {
            var textureNode = this.value;
            var fileEditorElement = fileElement.getLinkedElement();
            this.texture = fileEditorElement != null ? getTexture(fileEditorElement.node.getURL()) : null;
            textureNode.value = this.texture != null ? this.texture : defaultTexture;
            this.update();
        }, true);

        this.add(fileElement);
    }

    private function _initParams():Void {
        var uvField = setInputAestheticsFromType(new LabelElement('UV'), 'Vector2');

        uvField.onValid(onValidNode).onConnect(() -> {
            var node = this.value;
            node.uvNode = uvField.getLinkedObject() != null ? uvField.getLinkedObject() : defaultUV != null ? defaultUV : (defaultUV = uv());
        });

        this.wrapSInput = new SelectInput([
            { name: 'Repeat Wrapping', value: RepeatWrapping },
            { name: 'Clamp To Edge Wrapping', value: ClampToEdgeWrapping },
            { name: 'Mirrored Repeat Wrapping', value: MirroredRepeatWrapping }
        ], RepeatWrapping).onChange(() -> this.update());

        this.wrapTInput = new SelectInput([
            { name: 'Repeat Wrapping', value: RepeatWrapping },
            { name: 'Clamp To Edge Wrapping', value: ClampToEdgeWrapping },
            { name: 'Mirrored Repeat Wrapping', value: MirroredRepeatWrapping }
        ], RepeatWrapping).onChange(() -> this.update());

        this.flipYInput = new ToggleInput(false).onChange(() -> this.update());

        this.add(uvField)
            .add(new LabelElement('Wrap S').add(this.wrapSInput))
            .add(new LabelElement('Wrap T').add(this.wrapTInput))
            .add(new LabelElement('Flip Y').add(this.flipYInput));
    }

    public function update():Void {
        var texture = this.texture;

        if (texture != null) {
            texture.wrapS = this.wrapSInput.getValue();
            texture.wrapT = this.wrapTInput.getValue();
            texture.flipY = this.flipYInput.getValue();
            texture.dispose();
            this.invalidate();
        }
    }

    private static function getTexture(url:String):Texture {
        return textureLoader.load(url);
    }

}
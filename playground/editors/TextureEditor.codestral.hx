import flow.LabelElement;
import flow.ToggleInput;
import flow.SelectInput;
import playground.editors.BaseNodeEditor;
import playground.NodeEditorUtils;
import three.nodes.TextureNode;
import three.nodes.UvNode;
import three.Texture;
import three.TextureLoader;
import three.Wrapping;
import playground.DataTypeLib;

class TextureEditor extends BaseNodeEditor {

    private var textureLoader:TextureLoader = new TextureLoader();
    private var defaultTexture:Texture = new Texture();
    private var defaultUV:UvNode = null;

    private function getTexture(url:String):Texture {
        return textureLoader.load(url);
    }

    private var texture:Texture = null;

    public function new() {
        var node = new TextureNode(defaultTexture);
        super('Texture', node, 250);

        _initFile();
        _initParams();
    }

    private function _initFile() {
        var fileElement = DataTypeLib.setInputAestheticsFromType(new LabelElement('File'), 'URL');

        fileElement.onValid(NodeEditorUtils.onValidType('URL')).onConnect(() => {
            var textureNode = this.value;
            var fileEditorElement = fileElement.getLinkedElement();

            this.texture = fileEditorElement ? getTexture(fileEditorElement.node.getURL()) : null;

            textureNode.value = this.texture || defaultTexture;

            this.update();
        }, true);

        this.add(fileElement);
    }

    private function _initParams() {
        var uvField = DataTypeLib.setInputAestheticsFromType(new LabelElement('UV'), 'Vector2');

        uvField.onValid(NodeEditorUtils.onValidNode).onConnect(() => {
            var node = this.value;

            node.uvNode = uvField.getLinkedObject() || defaultUV || (defaultUV = new UvNode());
        });

        this.wrapSInput = new SelectInput([
            { name: 'Repeat Wrapping', value: Wrapping.RepeatWrapping },
            { name: 'Clamp To Edge Wrapping', value: Wrapping.ClampToEdgeWrapping },
            { name: 'Mirrored Repeat Wrapping', value: Wrapping.MirroredRepeatWrapping }
        ], Wrapping.RepeatWrapping).onChange(() => {
            this.update();
        });

        this.wrapTInput = new SelectInput([
            { name: 'Repeat Wrapping', value: Wrapping.RepeatWrapping },
            { name: 'Clamp To Edge Wrapping', value: Wrapping.ClampToEdgeWrapping },
            { name: 'Mirrored Repeat Wrapping', value: Wrapping.MirroredRepeatWrapping }
        ], Wrapping.RepeatWrapping).onChange(() => {
            this.update();
        });

        this.flipYInput = new ToggleInput(false).onChange(() => {
            this.update();
        });

        this.add(uvField)
            .add(new LabelElement('Wrap S').add(this.wrapSInput))
            .add(new LabelElement('Wrap T').add(this.wrapTInput))
            .add(new LabelElement('Flip Y').add(this.flipYInput));
    }

    public function update() {
        if (this.texture != null) {
            this.texture.wrapS = this.wrapSInput.getValue();
            this.texture.wrapT = this.wrapTInput.getValue();
            this.texture.flipY = this.flipYInput.getValue();
            this.texture.dispose();

            this.invalidate();
        }
    }
}
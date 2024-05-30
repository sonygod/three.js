package three.js.playground.editors;

import flow.LabelElement;
import flow.ToggleInput;
import flow.SelectInput;
import three.nodes.Texture;
import three.TextureLoader;
import three.Wrapping;
import three.RepeatWrapping;
import three.ClampToEdgeWrapping;
import three.MirroredRepeatWrapping;
import DataTypeLib;
import NodeEditorUtils;

class TextureEditor extends BaseNodeEditor {
    public var texture:Texture;

    public function new() {
        super("Texture", new Texture(defaultTexture));
        this.texture = null;

        _initFile();
        _initParams();
    }

    private function _initFile() {
        var fileElement = setInputAestheticsFromType(new LabelElement("File"), "URL");
        fileElement.onValid(onValidType("URL")).onConnect(function() {
            var textureNode = this.value;
            var fileEditorElement = fileElement.getLinkedElement();
            this.texture = fileEditorElement != null ? getTexture(fileEditorElement.node.getURL()) : null;
            textureNode.value = this.texture != null ? this.texture : defaultTexture;
            update();
        }, true);
        add(fileElement);
    }

    private function _initParams() {
        var uvField = setInputAestheticsFromType(new LabelElement("UV"), "Vector2");
        uvField.onValid(onValidNode).onConnect(function() {
            var node = this.value;
            node.uvNode = uvField.getLinkedObject() != null ? uvField.getLinkedObject() : (defaultUV != null ? defaultUV : uv());
        });

        wrapSInput = new SelectInput([
            { name: "Repeat Wrapping", value: RepeatWrapping },
            { name: "Clamp To Edge Wrapping", value: ClampToEdgeWrapping },
            { name: "Mirrored Repeat Wrapping", value: MirroredRepeatWrapping }
        ], RepeatWrapping);
        wrapSInput.onChange(update);

        wrapTInput = new SelectInput([
            { name: "Repeat Wrapping", value: RepeatWrapping },
            { name: "Clamp To Edge Wrapping", value: ClampToEdgeWrapping },
            { name: "Mirrored Repeat Wrapping", value: MirroredRepeatWrapping }
        ], RepeatWrapping);
        wrapTInput.onChange(update);

        flipYInput = new ToggleInput(false);
        flipYInput.onChange(update);

        add(uvField)
            .add(new LabelElement("Wrap S").add(wrapSInput))
            .add(new LabelElement("Wrap T").add(wrapTInput))
            .add(new LabelElement("Flip Y").add(flipYInput));
    }

    private function update() {
        if (texture != null) {
            texture.wrapS = Std.parseInt(wrapSInput.getValue());
            texture.wrapT = Std.parseInt(wrapTInput.getValue());
            texture.flipY = flipYInput.getValue();
            texture.dispose();
            invalidate();
        }
    }

    private static function getTexture(url:String):Texture {
        return new TextureLoader().load(url);
    }

    private static var defaultTexture = new Texture();
    private static var defaultUV:UV;
}
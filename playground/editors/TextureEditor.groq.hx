package three.js.playground.editors;

import js.html.Texture;
import js.html.TextureLoader;
import js.html.RepeatWrapping;
import js.html.ClampToEdgeWrapping;
import js.html.MirroredRepeatWrapping;
import three.nodes.TextureNode;
import three.nodes.UVNode;
import flow.LabelElement;
import flow.ToggleInput;
import flow.SelectInput;
import BaseNodeEditor;
import NodeEditorUtils;
import DataTypeLib;

class TextureEditor extends BaseNodeEditor {
    private var texture:Texture;
    private var wrapSInput:SelectInput;
    private var wrapTInput:SelectInput;
    private var flipYInput:ToggleInput;

    public function new() {
        super("Texture", new TextureNode(new Texture()), 250);
        texture = null;
        _initFile();
        _initParams();
        onValidElement = function() {};
    }

    private function _initFile() {
        var fileElement:LabelElement = setInputAestheticsFromType(new LabelElement("File"), "URL");
        fileElement.onValid(NodeEditorUtils.onValidType("URL")).onConnect(function() {
            var textureNode:TextureNode = value;
            var fileEditorElement = fileElement.getLinkedElement();
            texture = fileEditorElement ? getTexture(fileEditorElement.node.getURL()) : null;
            textureNode.value = texture || new Texture();
            update();
        }, true);
        add(fileElement);
    }

    private function _initParams() {
        var uvField:LabelElement = setInputAestheticsFromType(new LabelElement("UV"), "Vector2");
        uvField.onValid(NodeEditorUtils.onValidNode).onConnect(function() {
            var node:TextureNode = value;
            node.uvNode = uvField.getLinkedObject() || defaultUV || (defaultUV = new UVNode());
        });
        wrapSInput = new SelectInput([
            { name: "Repeat Wrapping", value: RepeatWrapping },
            { name: "Clamp To Edge Wrapping", value: ClampToEdgeWrapping },
            { name: "Mirrored Repeat Wrapping", value: MirroredRepeatWrapping }
        ], RepeatWrapping).onChange(update);
        wrapTInput = new SelectInput([
            { name: "Repeat Wrapping", value: RepeatWrapping },
            { name: "Clamp To Edge Wrapping", value: ClampToEdgeWrapping },
            { name: "Mirrored Repeat Wrapping", value: MirroredRepeatWrapping }
        ], RepeatWrapping).onChange(update);
        flipYInput = new ToggleInput(false).onChange(update);
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

    private function getTexture(url:String):Texture {
        return textureLoader.load(url);
    }

    static var defaultTexture:Texture = new Texture();
    static var defaultUV:UVNode = null;
    static var textureLoader:TextureLoader = new TextureLoader();
}
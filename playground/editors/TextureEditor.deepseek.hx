package three.js.playground.editors;

import flow.LabelElement;
import flow.ToggleInput;
import flow.SelectInput;
import BaseNodeEditor from '../BaseNodeEditor.js';
import NodeEditorUtils from '../NodeEditorUtils.js';
import texture from 'three/nodes';
import Texture from 'three.Texture';
import TextureLoader from 'three.TextureLoader';
import RepeatWrapping from 'three.RepeatWrapping';
import ClampToEdgeWrapping from 'three.ClampToEdgeWrapping';
import MirroredRepeatWrapping from 'three.MirroredRepeatWrapping';
import setInputAestheticsFromType from '../DataTypeLib.js';

class TextureEditor extends BaseNodeEditor {

    static var textureLoader = new TextureLoader();
    static var defaultTexture = new Texture();
    static var defaultUV = null;

    var texture:Texture;
    var wrapSInput:SelectInput;
    var wrapTInput:SelectInput;
    var flipYInput:ToggleInput;

    public function new() {

        var node = texture(defaultTexture);

        super('Texture', node, 250);

        this.texture = null;

        this._initFile();
        this._initParams();

        this.onValidElement = function() {};

    }

    private function _initFile() {

        var fileElement = setInputAestheticsFromType(new LabelElement('File'), 'URL');

        fileElement.onValid(NodeEditorUtils.onValidType('URL')).onConnect(function() {

            var textureNode = this.value;
            var fileEditorElement = fileElement.getLinkedElement();

            this.texture = fileEditorElement ? getTexture(fileEditorElement.node.getURL()) : null;

            textureNode.value = this.texture || defaultTexture;

            this.update();

        }, true);

        this.add(fileElement);

    }

    private function _initParams() {

        var uvField = setInputAestheticsFromType(new LabelElement('UV'), 'Vector2');

        uvField.onValid(NodeEditorUtils.onValidNode).onConnect(function() {

            var node = this.value;

            node.uvNode = uvField.getLinkedObject() || defaultUV || (defaultUV = uv());

        });

        this.wrapSInput = new SelectInput([
            {name: 'Repeat Wrapping', value: RepeatWrapping},
            {name: 'Clamp To Edge Wrapping', value: ClampToEdgeWrapping},
            {name: 'Mirrored Repeat Wrapping', value: MirroredRepeatWrapping}
        ], RepeatWrapping).onChange(function() {

            this.update();

        });

        this.wrapTInput = new SelectInput([
            {name: 'Repeat Wrapping', value: RepeatWrapping},
            {name: 'Clamp To Edge Wrapping', value: ClampToEdgeWrapping},
            {name: 'Mirrored Repeat Wrapping', value: MirroredRepeatWrapping}
        ], RepeatWrapping).onChange(function() {

            this.update();

        });

        this.flipYInput = new ToggleInput(false).onChange(function() {

            this.update();

        });

        this.add(uvField)
            .add(new LabelElement('Wrap S').add(this.wrapSInput))
            .add(new LabelElement('Wrap T').add(this.wrapTInput))
            .add(new LabelElement('Flip Y').add(this.flipYInput));

    }

    function update() {

        var texture = this.texture;

        if (texture) {

            texture.wrapS = Number(this.wrapSInput.getValue());
            texture.wrapT = Number(this.wrapTInput.getValue());
            texture.flipY = this.flipYInput.getValue();
            texture.dispose();

            this.invalidate();

        }

    }

    static function getTexture(url:String):Texture {

        return textureLoader.load(url);

    }

}
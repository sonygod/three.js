package three.js.playground.editors;

import flow.ColorInput;
import flow.SliderInput;
import flow.LabelElement;
import three.nodes.MeshBasicNodeMaterial;
import DataTypeLib;

class BasicMaterialEditor extends MaterialEditor {
    public var color:LabelElement;
    public var opacity:LabelElement;
    public var position:LabelElement;

    public function new() {
        var material = new MeshBasicNodeMaterial();

        super('Basic Material', material);

        color = setInputAestheticsFromType(new LabelElement('color'), 'Color');
        opacity = setInputAestheticsFromType(new LabelElement('opacity'), 'Number');
        position = setInputAestheticsFromType(new LabelElement('position'), 'Vector3');

        color.addChild(new ColorInput(material.color.getHex()).onChange(function(input) {
            material.color.setHex(input.getValue());
        }));

        opacity.addChild(new SliderInput(material.opacity, 0, 1).onChange(function(input) {
            material.opacity = input.getValue();
            updateTransparent();
        }));

        color.onConnect(function() {
            update();
        }, true);

        opacity.onConnect(function() {
            update();
        }, true);

        position.onConnect(function() {
            update();
        }, true);

        add(color).add(opacity).add(position);

        this.update();
    }

    public function update() {
        var material = this.material;
        var color = this.color;
        var opacity = this.opacity;
        var position = this.position;

        color.setEnabledInputs(!color.getLinkedObject());
        opacity.setEnabledInputs(!opacity.getLinkedObject());

        material.colorNode = color.getLinkedObject();
        material.opacityNode = opacity.getLinkedObject() || null;

        material.positionNode = position.getLinkedObject() || null;

        material.dispose();

        updateTransparent();
    }

    public function updateTransparent() {
        var material = this.material;
        var opacity = this.opacity;

        var transparent = opacity.getLinkedObject() || material.opacity < 1 ? true : false;
        var needsUpdate = transparent != material.transparent;

        material.transparent = transparent;

        opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');

        if (needsUpdate) material.dispose();
    }
}
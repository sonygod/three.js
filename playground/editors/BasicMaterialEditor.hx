package three.js.playground.editors;

import flow.ColorInput;
import flow.SliderInput;
import flow.LabelElement;
import three.nodes.MeshBasicNodeMaterial;
import DataTypeLib;

class BasicMaterialEditor extends MaterialEditor {
    private var color:LabelElement;
    private var opacity:LabelElement;
    private var position:LabelElement;

    public function new() {
        var material:MeshBasicNodeMaterial = new MeshBasicNodeMaterial();
        super('Basic Material', material);

        color = setInputAestheticsFromType(new LabelElement('color'), 'Color');
        opacity = setInputAestheticsFromType(new LabelElement('opacity'), 'Number');
        position = setInputAestheticsFromType(new LabelElement('position'), 'Vector3');

        color.add(new ColorInput(material.color.getHex()).onChange(function(input) {
            material.color.setHex(input.getValue());
        }));

        opacity.add(new SliderInput(material.opacity, 0, 1).onChange(function(input) {
            material.opacity = input.getValue();
            updateTransparent();
        }));

        color.onConnect(update);
        opacity.onConnect(update);
        position.onConnect(update);

        add(color);
        add(opacity);
        add(position);

        color = color;
        opacity = opacity;
        position = position;

        update();
    }

    private function update():Void {
        var material:MeshBasicNodeMaterial = cast this.material;
        color.setEnabledInputs(!color.getLinkedObject());
        opacity.setEnabledInputs(!opacity.getLinkedObject());

        material.colorNode = color.getLinkedObject();
        material.opacityNode = opacity.getLinkedObject() || null;
        material.positionNode = position.getLinkedObject() || null;

        material.dispose();

        updateTransparent();
    }

    private function updateTransparent():Void {
        var material:MeshBasicNodeMaterial = cast this.material;
        var transparent:Bool = (opacity.getLinkedObject() != null || material.opacity < 1);
        var needsUpdate:Bool = transparent != material.transparent;

        material.transparent = transparent;
        opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');

        if (needsUpdate) material.dispose();
    }
}
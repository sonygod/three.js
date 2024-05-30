import js.npm.three.nodes.MeshBasicNodeMaterial;
import js.npm.three.Color;

class BasicMaterialEditor {
    public var material:MeshBasicNodeMaterial;
    public var color:ColorInput;
    public var opacity:SliderInput;
    public var position:LabelElement;

    public function new() {
        material = new MeshBasicNodeMaterial();
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

        color.onConnect(function() update(), true);
        opacity.onConnect(function() update(), true);
        position.onConnect(function() update(), true);

        add(color);
        add(opacity);
        add(position);

        this.color = color;
        this.opacity = opacity;
        this.position = position;

        update();
    }

    public function update() {
        color.setEnabledInputs(!color.getLinkedObject());
        opacity.setEnabledInputs(!opacity.getLinkedObject());

        material.colorNode = color.getLinkedObject();
        material.opacityNode = if (opacity.getLinkedObject() != null) opacity.getLinkedObject() else null;

        material.positionNode = if (position.getLinkedObject() != null) position.getLinkedObject() else null;

        material.dispose();

        updateTransparent();
    }

    public function updateTransparent() {
        var transparent = if (opacity.getLinkedObject() != null) true else material.opacity < 1;
        var needsUpdate = transparent != material.transparent;

        material.transparent = transparent;

        opacity.setIcon(if (material.transparent) 'ti ti-layers-intersect' else 'ti ti-layers-subtract');

        if (needsUpdate)
            material.dispose();
    }
}
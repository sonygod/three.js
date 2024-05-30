import flow.ColorInput;
import flow.SliderInput;
import flow.LabelElement;
import three.nodes.MeshBasicNodeMaterial;
import MaterialEditor;
import DataTypeLib.setInputAestheticsFromType;

class BasicMaterialEditor extends MaterialEditor {

    var color:LabelElement;
    var opacity:LabelElement;
    var position:LabelElement;

    public function new() {

        var material = new MeshBasicNodeMaterial();

        super('Basic Material', material);

        color = setInputAestheticsFromType(new LabelElement('color'), 'Color');
        opacity = setInputAestheticsFromType(new LabelElement('opacity'), 'Number');
        position = setInputAestheticsFromType(new LabelElement('position'), 'Vector3');

        color.add(new ColorInput(material.color.getHex()).onChange(function(input) {
            material.color.setHex(input.getValue());
        }));

        opacity.add(new SliderInput(material.opacity, 0, 1).onChange(function(input) {
            material.opacity = input.getValue();
            this.updateTransparent();
        }));

        color.onConnect(() -> this.update(), true);
        opacity.onConnect(() -> this.update(), true);
        position.onConnect(() -> this.update(), true);

        this.add(color)
            .add(opacity)
            .add(position);

        this.color = color;
        this.opacity = opacity;
        this.position = position;

        this.update();
    }

    public function update():Void {

        var material = cast this.material, MeshBasicNodeMaterial;

        color.setEnabledInputs(!color.getLinkedObject());
        opacity.setEnabledInputs(!opacity.getLinkedObject());

        material.colorNode = color.getLinkedObject();
        material.opacityNode = opacity.getLinkedObject() || null;
        material.positionNode = position.getLinkedObject() || null;

        material.dispose();

        this.updateTransparent();
    }

    public function updateTransparent():Void {

        var material = cast this.material, MeshBasicNodeMaterial;
        var opacityNode = opacity.getLinkedObject();

        var transparent = opacityNode != null || material.opacity < 1;
        var needsUpdate = transparent != material.transparent;

        material.transparent = transparent;

        opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');

        if (needsUpdate) {
            material.dispose();
        }
    }
}
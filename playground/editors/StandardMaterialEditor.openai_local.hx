import flow.ColorInput;
import flow.SliderInput;
import flow.LabelElement;
import three.nodes.MeshStandardNodeMaterial;
import threejs.playground.editors.MaterialEditor;
import threejs.playground.DataTypeLib.setInputAestheticsFromType;

class StandardMaterialEditor extends MaterialEditor {

    var color:LabelElement;
    var opacity:LabelElement;
    var metalness:LabelElement;
    var roughness:LabelElement;
    var emissive:LabelElement;
    var normal:LabelElement;
    var position:LabelElement;

    public function new() {
        var material = new MeshStandardNodeMaterial();

        super('Standard Material', material);

        color = setInputAestheticsFromType(new LabelElement('color'), 'Color');
        opacity = setInputAestheticsFromType(new LabelElement('opacity'), 'Number');
        metalness = setInputAestheticsFromType(new LabelElement('metalness'), 'Number');
        roughness = setInputAestheticsFromType(new LabelElement('roughness'), 'Number');
        emissive = setInputAestheticsFromType(new LabelElement('emissive'), 'Color');
        normal = setInputAestheticsFromType(new LabelElement('normal'), 'Vector3');
        position = setInputAestheticsFromType(new LabelElement('position'), 'Vector3');

        color.add(new ColorInput(material.color.getHex()).onChange(function(input) {
            material.color.setHex(input.getValue());
        }));

        opacity.add(new SliderInput(material.opacity, 0, 1).onChange(function(input) {
            material.opacity = input.getValue();
            updateTransparent();
        }));

        metalness.add(new SliderInput(material.metalness, 0, 1).onChange(function(input) {
            material.metalness = input.getValue();
        }));

        roughness.add(new SliderInput(material.roughness, 0, 1).onChange(function(input) {
            material.roughness = input.getValue();
        }));

        color.onConnect(function() update(), true);
        opacity.onConnect(function() update(), true);
        metalness.onConnect(function() update(), true);
        roughness.onConnect(function() update(), true);
        emissive.onConnect(function() update(), true);
        normal.onConnect(function() update(), true);
        position.onConnect(function() update(), true);

        this.add(color)
            .add(opacity)
            .add(metalness)
            .add(roughness)
            .add(emissive)
            .add(normal)
            .add(position);

        this.color = color;
        this.opacity = opacity;
        this.metalness = metalness;
        this.roughness = roughness;
        this.emissive = emissive;
        this.normal = normal;
        this.position = position;

        update();
    }

    function update() {
        var material = cast this.material, MeshStandardNodeMaterial;
        color.setEnabledInputs(!color.getLinkedObject());
        opacity.setEnabledInputs(!opacity.getLinkedObject());
        roughness.setEnabledInputs(!roughness.getLinkedObject());
        metalness.setEnabledInputs(!metalness.getLinkedObject());

        material.colorNode = color.getLinkedObject();
        material.opacityNode = opacity.getLinkedObject();
        material.metalnessNode = metalness.getLinkedObject();
        material.roughnessNode = roughness.getLinkedObject();
        material.emissiveNode = emissive.getLinkedObject();
        material.normalNode = normal.getLinkedObject();
        material.positionNode = position.getLinkedObject();

        material.dispose();

        updateTransparent();
    }

    function updateTransparent() {
        var material = cast this.material, MeshStandardNodeMaterial;
        var transparent = opacity.getLinkedObject() != null || material.opacity < 1;
        var needsUpdate = transparent != material.transparent;

        material.transparent = transparent;

        opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');

        if (needsUpdate) {
            material.dispose();
        }
    }
}
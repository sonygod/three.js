import js.Browser.window;
import js.html.CanvasElement;
import js.html.Input;
import js.html.LabelElement;
import js.html.SliderElement;
import js.three.MeshStandardNodeMaterial;
import js.three.nodes.ColorNode;
import js.three.nodes.FloatNode;
import js.three.nodes.Vector3Node;

class StandardMaterialEditor {
    var material: MeshStandardNodeMaterial;
    var color: Input;
    var opacity: SliderElement;
    var metalness: SliderElement;
    var roughness: SliderElement;
    var emissive: Input;
    var normal: Input;
    var position: Input;

    public function new() {
        material = new MeshStandardNodeMaterial();
        var materialName = 'Standard Material';

        color = setInputAestheticsFromType(LabelElement('color'), 'Color');
        opacity = setInputAestheticsFromType(SliderElement('opacity'), 'Number');
        metalness = setInputAestheticsFromType(SliderElement('metalness'), 'Number');
        roughness = setInputAestheticsFromType(SliderElement('roughness'), 'Number');
        emissive = setInputAestheticsFromType(LabelElement('emissive'), 'Color');
        normal = setInputAestheticsFromType(LabelElement('normal'), 'Vector3');
        position = setInputAestheticsFromType(LabelElement('position'), 'Vector3');

        color.addChild(ColorInput(material.color.getHex()).onChange(function(input) {
            material.color.setHex(input.getValue());
        }));

        opacity.addChild(SliderInput(material.opacity, 0, 1).onChange(function(input) {
            material.opacity = input.getValue();
            updateTransparent();
        }));

        metalness.addChild(SliderInput(material.metalness, 0, 1).onChange(function(input) {
            material.metalness = input.getValue();
        }));

        roughness.addChild(SliderInput(material.roughness, 0, 1).onChange(function(input) {
            material.roughness = input.getValue();
        }));

        color.onConnect(update);
        opacity.onConnect(update);
        metalness.onConnect(update);
        roughness.onConnect(update);
        emissive.onConnect(update);
        normal.onConnect(update);
        position.onConnect(update);

        addChild(color);
        addChild(opacity);
        addChild(metalness);
        addChild(roughness);
        addChild(emissive);
        addChild(normal);
        addChild(position);

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
        color.setEnabledInputs(!color.getLinkedObject());
        opacity.setEnabledInputs(!opacity.getLinkedObject());
        roughness.setEnabledInputs(!roughness.getLinkedObject());
        metalness.setEnabledInputs(!metalness.getLinkedObject());

        material.colorNode = color.getLinkedObject() as ColorNode;
        material.opacityNode = opacity.getLinkedObject() as FloatNode;
        material.metalnessNode = metalness.getLinkedObject() as FloatNode;
        material.roughnessNode = roughness.getLinkedObject() as FloatNode;
        material.emissiveNode = emissive.getLinkedObject() as ColorNode;
        material.normalNode = normal.getLinkedObject() as Vector3Node;
        material.positionNode = position.getLinkedObject() as Vector3Node;

        material.dispose();
    }

    function updateTransparent() {
        var transparent = opacity.getLinkedObject() != null || material.opacity < 1;
        var needsUpdate = transparent != material.transparent;

        material.transparent = transparent;

        if (needsUpdate) {
            opacity.setIcon(if (transparent) 'ti ti-layers-intersect' else 'ti ti-layers-subtract');
            material.dispose();
        }
    }
}

function setInputAestheticsFromType(element: LabelElement, type: String) {
    var input = element;
    input.setClass('property-name');
    input.setStyle('width', '100px');
    input.setStyle('display', 'inline-block');
    input.setStyle('text-align', 'right');
    input.setStyle('padding', '5px 10px 5px 0px');
    input.setStyle('vertical-align', 'top');
    input.innerHTML = type;
    return input;
}

class ColorInput {
    public function new(hex: Int) {
        var input = CanvasElement('canvas');
        input.setStyle('width', '32px');
        input.setStyle('height', '32px');
        input.setStyle('display', 'inline-block');
        input.setStyle('vertical-align', 'middle');
        input.setStyle('margin', '0px 5px 0px 5px');
        input.getContext2d().fillStyle = '#' + hex.toString();
        input.getContext2d().fillRect(0, 0, 32, 32);
        return input;
    }
}

class SliderInput {
    public function new(value: Float, min: Float, max: Float) {
        var slider = SliderElement();
        slider.setMin(min);
        slider.setMax(max);
        slider.setValue(value);
        return slider;
    }
}
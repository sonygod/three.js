Here is the converted Haxe code:
```
package three.js.playground.editors;

import flow.ColorInput;
import flow.SliderInput;
import flow.LabelElement;
import three.nodes.MeshStandardNodeMaterial;
import DataTypeLib;

class StandardMaterialEditor extends MaterialEditor {
    
    public var color:LabelElement;
    public var opacity:LabelElement;
    public var metalness:LabelElement;
    public var roughness:LabelElement;
    public var emissive:LabelElement;
    public var normal:LabelElement;
    public var position:LabelElement;

    public function new() {
        super();

        var material:MeshStandardNodeMaterial = new MeshStandardNodeMaterial();

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

        color.onConnect(update, true);
        opacity.onConnect(update, true);
        metalness.onConnect(update, true);
        roughness.onConnect(update, true);
        emissive.onConnect(update, true);
        normal.onConnect(update, true);
        position.onConnect(update, true);

        add(color);
        add(opacity);
        add(metalness);
        add(roughness);
        add(emissive);
        add(normal);
        add(position);

        update();
    }

    public function update() {
        var material:MeshStandardNodeMaterial = cast this.material;
        var color:LabelElement = this.color;
        var opacity:LabelElement = this.opacity;
        var emissive:LabelElement = this.emissive;
        var roughness:LabelElement = this.roughness;
        var metalness:LabelElement = this.metalness;
        var normal:LabelElement = this.normal;
        var position:LabelElement = this.position;

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

    public function updateTransparent() {
        var material:MeshStandardNodeMaterial = cast this.material;
        var opacity:LabelElement = this.opacity;

        var transparent:Bool = opacity.getLinkedObject() != null || material.opacity < 1 ? true : false;
        var needsUpdate:Bool = transparent != material.transparent;

        material.transparent = transparent;

        opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');

        if (needsUpdate) material.dispose();
    }
}
```
Note that I've kept the same class and method names as the original JavaScript code, but adapted them to Haxe syntax. I've also added type annotations where necessary. Additionally, I've used the `cast` keyword to cast the `material` property to `MeshStandardNodeMaterial` in the `update` method, as Haxe requires explicit type casting.
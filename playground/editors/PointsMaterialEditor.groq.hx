Here is the converted Haxe code:
```
package three.js.playground.editors;

import flow.ColorInput;
import flow.ToggleInput;
import flow.SliderInput;
import flow.LabelElement;
import three.nodes.PointsNodeMaterial;
import three.THREE;

class PointsMaterialEditor extends MaterialEditor {
    public var color:LabelElement;
    public var opacity:LabelElement;
    public var size:LabelElement;
    public var position:LabelElement;
    public var sizeAttenuation:LabelElement;

    public function new() {
        var material = new PointsNodeMaterial();

        super('Points Material', material);

        color = setInputAestheticsFromType(new LabelElement('color'), 'Color');
        opacity = setInputAestheticsFromType(new LabelElement('opacity'), 'Number');
        size = setInputAestheticsFromType(new LabelElement('size'), 'Number');
        position = setInputAestheticsFromType(new LabelElement('position'), 'Vector3');
        sizeAttenuation = setInputAestheticsFromType(new LabelElement('Size Attenuation'), 'Number');

        color.add(new ColorInput(material.color.getHex()).onChange(function(input) {
            material.color.setHex(input.getValue());
        }));

        opacity.add(new SliderInput(material.opacity, 0, 1).onChange(function(input) {
            material.opacity = input.getValue();
            updateTransparent();
        }));

        sizeAttenuation.add(new ToggleInput(material.sizeAttenuation).onClick(function(input) {
            material.sizeAttenuation = input.getValue();
            material.dispose();
        }));

        color.onConnect(update, true);
        opacity.onConnect(update, true);
        size.onConnect(update, true);
        position.onConnect(update, true);

        add(color)
            .add(opacity)
            .add(size)
            .add(position)
            .add(sizeAttenuation);
    }

    public function update() {
        var material = cast(this.material, PointsNodeMaterial);
        var color = this.color;
        var opacity = this.opacity;
        var size = this.size;
        var position = this.position;

        color.setEnabledInputs(!color.getLinkedObject());
        opacity.setEnabledInputs(!opacity.getLinkedObject());

        material.colorNode = color.getLinkedObject();
        material.opacityNode = opacity.getLinkedObject() || null;

        material.sizeNode = size.getLinkedObject() || null;
        material.positionNode = position.getLinkedObject() || null;

        material.dispose();

        updateTransparent();

        // TODO: Fix on NodeMaterial System
        material.customProgramCacheKey = function() {
            return THREE.MathUtils.generateUUID();
        };
    }

    public function updateTransparent() {
        var material = cast(this.material, PointsNodeMaterial);
        var opacity = this.opacity;

        material.transparent = opacity.getLinkedObject() || material.opacity < 1 ? true : false;

        opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');
    }
}
```
Note that I've made the following assumptions:

* `MaterialEditor` is a class that is already defined in your Haxe project.
* `setInputAestheticsFromType` is a function that is already defined in your Haxe project.
* `LabelElement`, `ColorInput`, `SliderInput`, and `ToggleInput` are classes that are already defined in your Haxe project.
* `THREE` is a class that is already defined in your Haxe project, and it has a `MathUtils` class with a `generateUUID` method.
* `PointsNodeMaterial` is a class that is already defined in your Haxe project.

Please let me know if these assumptions are incorrect, and I'll be happy to help further.
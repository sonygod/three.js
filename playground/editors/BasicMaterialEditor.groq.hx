Here is the converted Haxe code:
```
package three.js.playground.editors;

import flow.ColorInput;
import flow.SliderInput;
import flow.LabelElement;
import three.nodes.MeshBasicNodeMaterial;
import DataTypeLib;

class BasicMaterialEditor extends MaterialEditor {
    private var material:MeshBasicNodeMaterial;
    private var color:LabelElement;
    private var opacity:LabelElement;
    private var position:LabelElement;

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

        color.onConnect(update, true);
        opacity.onConnect(update, true);
        position.onConnect(update, true);

        add(color).add(opacity).add(position);

        this.color = color;
        this.opacity = opacity;
        this.position = position;

        update();
    }

    private function update() {
        color.setEnabledInputs(!color.getLinkedObject());
        opacity.setEnabledInputs(!opacity.getLinkedObject());

        material.colorNode = color.getLinkedObject();
        material.opacityNode = opacity.getLinkedObject() || null;
        material.positionNode = position.getLinkedObject() || null;

        material.dispose();

        updateTransparent();
    }

    private function updateTransparent() {
        var transparent = opacity.getLinkedObject() || material.opacity < 1 ? true : false;
        var needsUpdate = transparent != material.transparent;

        material.transparent = transparent;

        opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');

        if (needsUpdate) material.dispose();
    }
}
```
Note that I've kept the same class and function names as the original JavaScript code, and translated the syntax to Haxe. I've also preserved the same logic and functionality as the original code.
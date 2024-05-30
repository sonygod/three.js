import flow.ColorInput;
import flow.ToggleInput;
import flow.SliderInput;
import flow.LabelElement;
import threejs.playground.editors.MaterialEditor;
import three.nodes.PointsNodeMaterial;
import three.THREE;
import threejs.playground.DataTypeLib;

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

        color.add(new ColorInput(material.color.getHex()).onChange((input) -> {
            material.color.setHex(input.getValue());
        }));

        opacity.add(new SliderInput(material.opacity, 0, 1).onChange((input) -> {
            material.opacity = input.getValue();
            this.updateTransparent();
        }));

        sizeAttenuation.add(new ToggleInput(material.sizeAttenuation).onClick((input) -> {
            material.sizeAttenuation = input.getValue();
            material.dispose();
        }));

        color.onConnect(() -> this.update(), true);
        opacity.onConnect(() -> this.update(), true);
        size.onConnect(() -> this.update(), true);
        position.onConnect(() -> this.update(), true);

        this.add(color)
            .add(opacity)
            .add(size)
            .add(position)
            .add(sizeAttenuation);

        this.color = color;
        this.opacity = opacity;
        this.size = size;
        this.position = position;
        this.sizeAttenuation = sizeAttenuation;

        this.update();
    }

    public function update():Void {

        var material = cast this.material;
        var color = this.color;
        var opacity = this.opacity;
        var size = this.size;
        var position = this.position;

        color.setEnabledInputs(!color.getLinkedObject());
        opacity.setEnabledInputs(!opacity.getLinkedObject());

        material.colorNode = color.getLinkedObject();
        material.opacityNode = opacity.getLinkedObject() != null ? opacity.getLinkedObject() : null;

        material.sizeNode = size.getLinkedObject() != null ? size.getLinkedObject() : null;
        material.positionNode = position.getLinkedObject() != null ? position.getLinkedObject() : null;

        material.dispose();

        this.updateTransparent();

        // TODO: Fix on NodeMaterial System
        material.customProgramCacheKey = () -> {
            return THREE.MathUtils.generateUUID();
        };

    }

    public function updateTransparent():Void {

        var material = cast this.material;
        var opacity = this.opacity;

        material.transparent = opacity.getLinkedObject() != null || material.opacity < 1;

        opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');
    }
}
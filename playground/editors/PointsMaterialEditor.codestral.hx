import flow.ColorInput;
import flow.ToggleInput;
import flow.SliderInput;
import flow.LabelElement;
import editors.MaterialEditor;
import three.nodes.PointsNodeMaterial;
import three.THREE;
import DataTypeLib;

class PointsMaterialEditor extends MaterialEditor {

    public var color: LabelElement;
    public var opacity: LabelElement;
    public var size: LabelElement;
    public var position: LabelElement;
    public var sizeAttenuation: LabelElement;

    public function new() {

        var material: PointsNodeMaterial = new PointsNodeMaterial();

        super('Points Material', material);

        color = DataTypeLib.setInputAestheticsFromType(new LabelElement('color'), 'Color');
        opacity = DataTypeLib.setInputAestheticsFromType(new LabelElement('opacity'), 'Number');
        size = DataTypeLib.setInputAestheticsFromType(new LabelElement('size'), 'Number');
        position = DataTypeLib.setInputAestheticsFromType(new LabelElement('position'), 'Vector3');
        sizeAttenuation = DataTypeLib.setInputAestheticsFromType(new LabelElement('Size Attenuation'), 'Number');

        color.add(new ColorInput(material.color.getHex()).onChange((input: ColorInput) -> {
            material.color.setHex(input.getValue());
        }));

        opacity.add(new SliderInput(material.opacity, 0, 1).onChange((input: SliderInput) -> {
            material.opacity = input.getValue();
            this.updateTransparent();
        }));

        sizeAttenuation.add(new ToggleInput(material.sizeAttenuation).onClick((input: ToggleInput) -> {
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

        this.update();
    }

    public function update() {
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

    public function updateTransparent() {
        material.transparent = opacity.getLinkedObject() != null || material.opacity < 1 ? true : false;
        opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');
    }
}
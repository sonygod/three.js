import js.Browser.window;
import js.three.nodes.PointsNodeMaterial;
import js.three.MathUtils;
import js.three.Material;

class PointsMaterialEditor extends MaterialEditor {

    public function new(material:PointsNodeMaterial) {
        super('Points Material', material);

        var color = setInputAestheticsFromType(new LabelElement('color'), 'Color');
        var opacity = setInputAestheticsFromType(new LabelElement('opacity'), 'Number');
        var size = setInputAestheticsFromType(new LabelElement('size'), 'Number');
        var position = setInputAestheticsFromType(new LabelElement('position'), 'Vector3');
        var sizeAttenuation = setInputAestheticsFromType(new LabelElement('Size Attenuation'), 'Number');

        var colorInput = new ColorInput(material.color.getHex());
        colorInput.onChange = function(input) {
            material.color.setHex(input.getValue());
        };
        color.add(colorInput);

        var opacityInput = new SliderInput(material.opacity, 0, 1);
        opacityInput.onChange = function(input) {
            material.opacity = input.getValue();
            updateTransparent();
        };
        opacity.add(opacityInput);

        var sizeAttenuationInput = new ToggleInput(material.sizeAttenuation);
        sizeAttenuationInput.onClick = function(input) {
            material.sizeAttenuation = input.getValue();
            material.dispose();
        };
        sizeAttenuation.add(sizeAttenuationInput);

        color.onConnect = function() {
            update();
        };
        opacity.onConnect = function() {
            update();
        };
        size.onConnect = function() {
            update();
        };
        position.onConnect = function() {
            update();
        };

        add(color);
        add(opacity);
        add(size);
        add(position);
        add(sizeAttenuation);

        this.color = color;
        this.opacity = opacity;
        this.size = size;
        this.position = position;
        this.sizeAttenuation = sizeAttenuation;

        update();
    }

    public function update():Void {
        var material = cast(getMaterial(), PointsNodeMaterial);
        var color = cast(this.color, LabelElement);
        var opacity = cast(this.opacity, LabelElement);

        color.setEnabledInputs(!color.getLinkedObject());
        opacity.setEnabledInputs(!opacity.getLinkedObject());

        material.colorNode = color.getLinkedObject();
        material.opacityNode = opacity.getLinkedObject() != null ? opacity.getLinkedObject() : null;

        material.sizeNode = size.getLinkedObject() != null ? size.getLinkedObject() : null;
        material.positionNode = position.getLinkedObject() != null ? position.getLinkedObject() : null;

        material.dispose();

        updateTransparent();

        // TODO: Fix on NodeMaterial System
        material.customProgramCacheKey = function() {
            return MathUtils.generateUUID();
        };
    }

    public function updateTransparent():Void {
        var material = cast(getMaterial(), PointsNodeMaterial);
        var opacity = cast(this.opacity, LabelElement);

        material.transparent = opacity.getLinkedObject() != null || material.opacity < 1;

        opacity.setIcon(if (material.transparent) 'ti ti-layers-intersect' else 'ti ti-layers-subtract');
    }
}
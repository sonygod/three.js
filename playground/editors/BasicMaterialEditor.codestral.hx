import js.Browser.document;
import js.Browser.window;

class BasicMaterialEditor extends MaterialEditor {

    public var color:LabelElement;
    public var opacity:LabelElement;
    public var position:LabelElement;

    public function new() {
        var material:MeshBasicNodeMaterial = new MeshBasicNodeMaterial();
        super("Basic Material", material);

        color = setInputAestheticsFromType(new LabelElement("color"), "Color");
        opacity = setInputAestheticsFromType(new LabelElement("opacity"), "Number");
        position = setInputAestheticsFromType(new LabelElement("position"), "Vector3");

        color.add(new ColorInput(material.color.getHex()).onChange(function(input) {
            material.color.setHex(input.getValue());
        }));

        opacity.add(new SliderInput(material.opacity, 0, 1).onChange(function(input) {
            material.opacity = input.getValue();
            this.updateTransparent();
        }));

        color.onConnect(() -> {
            this.update();
            return true;
        });

        opacity.onConnect(() -> {
            this.update();
            return true;
        });

        position.onConnect(() -> {
            this.update();
            return true;
        });

        this.add(color)
            .add(opacity)
            .add(position);

        this.update();
    }

    public function update() {
        color.setEnabledInputs(!color.getLinkedObject());
        opacity.setEnabledInputs(!opacity.getLinkedObject());

        material.colorNode = color.getLinkedObject();
        material.opacityNode = opacity.getLinkedObject() != null ? opacity.getLinkedObject() : null;
        material.positionNode = position.getLinkedObject() != null ? position.getLinkedObject() : null;

        material.dispose();
        this.updateTransparent();
    }

    public function updateTransparent() {
        var transparent = opacity.getLinkedObject() != null || material.opacity < 1 ? true : false;
        var needsUpdate = transparent != material.transparent;

        material.transparent = transparent;
        opacity.setIcon(material.transparent ? "ti ti-layers-intersect" : "ti ti-layers-subtract");

        if (needsUpdate) material.dispose();
    }
}
import flow.ColorInput;
import flow.SliderInput;
import flow.LabelElement;
import MaterialEditor.MaterialEditor;
import three.nodes.MeshStandardNodeMaterial;
import DataTypeLib.setInputAestheticsFromType;

class StandardMaterialEditor extends MaterialEditor {

    public var material: MeshStandardNodeMaterial;
    public var color: LabelElement;
    public var opacity: LabelElement;
    public var metalness: LabelElement;
    public var roughness: LabelElement;
    public var emissive: LabelElement;
    public var normal: LabelElement;
    public var position: LabelElement;

    public function new() {
        super("Standard Material", new MeshStandardNodeMaterial());
        this.material = cast this.getMaterial();

        this.color = setInputAestheticsFromType(new LabelElement("color"), "Color");
        this.opacity = setInputAestheticsFromType(new LabelElement("opacity"), "Number");
        this.metalness = setInputAestheticsFromType(new LabelElement("metalness"), "Number");
        this.roughness = setInputAestheticsFromType(new LabelElement("roughness"), "Number");
        this.emissive = setInputAestheticsFromType(new LabelElement("emissive"), "Color");
        this.normal = setInputAestheticsFromType(new LabelElement("normal"), "Vector3");
        this.position = setInputAestheticsFromType(new LabelElement("position"), "Vector3");

        this.color.add(new ColorInput(this.material.color.getHex()));
        this.color.onChange(function(input) {
            this.material.color.setHex(input.getValue());
        });

        this.opacity.add(new SliderInput(this.material.opacity, 0, 1));
        this.opacity.onChange(function(input) {
            this.material.opacity = input.getValue();
            this.updateTransparent();
        });

        this.metalness.add(new SliderInput(this.material.metalness, 0, 1));
        this.metalness.onChange(function(input) {
            this.material.metalness = input.getValue();
        });

        this.roughness.add(new SliderInput(this.material.roughness, 0, 1));
        this.roughness.onChange(function(input) {
            this.material.roughness = input.getValue();
        });

        this.color.onConnect(function() {
            this.update();
        }, true);
        this.opacity.onConnect(function() {
            this.update();
        }, true);
        this.metalness.onConnect(function() {
            this.update();
        }, true);
        this.roughness.onConnect(function() {
            this.update();
        }, true);
        this.emissive.onConnect(function() {
            this.update();
        }, true);
        this.normal.onConnect(function() {
            this.update();
        }, true);
        this.position.onConnect(function() {
            this.update();
        }, true);

        this.add(this.color)
            .add(this.opacity)
            .add(this.metalness)
            .add(this.roughness)
            .add(this.emissive)
            .add(this.normal)
            .add(this.position);

        this.update();
    }

    public function update(): Void {
        this.color.setEnabledInputs(!this.color.getLinkedObject());
        this.opacity.setEnabledInputs(!this.opacity.getLinkedObject());
        this.roughness.setEnabledInputs(!this.roughness.getLinkedObject());
        this.metalness.setEnabledInputs(!this.metalness.getLinkedObject());

        this.material.colorNode = this.color.getLinkedObject();
        this.material.opacityNode = this.opacity.getLinkedObject();
        this.material.metalnessNode = this.metalness.getLinkedObject();
        this.material.roughnessNode = this.roughness.getLinkedObject();
        this.material.emissiveNode = this.emissive.getLinkedObject();
        this.material.normalNode = this.normal.getLinkedObject();
        this.material.positionNode = this.position.getLinkedObject();

        this.material.dispose();

        this.updateTransparent();
    }

    public function updateTransparent(): Void {
        var transparent = this.opacity.getLinkedObject() || this.material.opacity < 1 ? true : false;
        var needsUpdate = transparent !== this.material.transparent;

        this.material.transparent = transparent;

        this.opacity.setIcon(this.material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');

        if (needsUpdate === true) this.material.dispose();
    }
}
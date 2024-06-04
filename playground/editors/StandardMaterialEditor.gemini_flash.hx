import flow.ColorInput;
import flow.SliderInput;
import flow.LabelElement;
import three.nodes.MeshStandardNodeMaterial;
import DataTypeLib;

class StandardMaterialEditor extends MaterialEditor {

	public var material:MeshStandardNodeMaterial;
	public var color:LabelElement;
	public var opacity:LabelElement;
	public var metalness:LabelElement;
	public var roughness:LabelElement;
	public var emissive:LabelElement;
	public var normal:LabelElement;
	public var position:LabelElement;

	public function new() {
		material = new MeshStandardNodeMaterial();
		super('Standard Material', material);

		color = DataTypeLib.setInputAestheticsFromType(new LabelElement('color'), 'Color');
		opacity = DataTypeLib.setInputAestheticsFromType(new LabelElement('opacity'), 'Number');
		metalness = DataTypeLib.setInputAestheticsFromType(new LabelElement('metalness'), 'Number');
		roughness = DataTypeLib.setInputAestheticsFromType(new LabelElement('roughness'), 'Number');
		emissive = DataTypeLib.setInputAestheticsFromType(new LabelElement('emissive'), 'Color');
		normal = DataTypeLib.setInputAestheticsFromType(new LabelElement('normal'), 'Vector3');
		position = DataTypeLib.setInputAestheticsFromType(new LabelElement('position'), 'Vector3');

		color.add(new ColorInput(material.color.getHex()).onChange((input) -> {
			material.color.setHex(input.getValue());
		}));

		opacity.add(new SliderInput(material.opacity, 0, 1).onChange((input) -> {
			material.opacity = input.getValue();
			updateTransparent();
		}));

		metalness.add(new SliderInput(material.metalness, 0, 1).onChange((input) -> {
			material.metalness = input.getValue();
		}));

		roughness.add(new SliderInput(material.roughness, 0, 1).onChange((input) -> {
			material.roughness = input.getValue();
		}));

		color.onConnect(() -> update(), true);
		opacity.onConnect(() -> update(), true);
		metalness.onConnect(() -> update(), true);
		roughness.onConnect(() -> update(), true);
		emissive.onConnect(() -> update(), true);
		normal.onConnect(() -> update(), true);
		position.onConnect(() -> update(), true);

		add(color)
			.add(opacity)
			.add(metalness)
			.add(roughness)
			.add(emissive)
			.add(normal)
			.add(position);

		update();
	}

	public function update() {
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
		var transparent = opacity.getLinkedObject() != null || material.opacity < 1 ? true : false;
		var needsUpdate = transparent != material.transparent;

		material.transparent = transparent;

		opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');

		if (needsUpdate) material.dispose();
	}
}
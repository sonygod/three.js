import ColorInput.ColorInput;
import SliderInput.SliderInput;
import LabelElement.LabelElement;
import MaterialEditor.MaterialEditor;
import MeshStandardNodeMaterial.MeshStandardNodeMaterial;
import DataTypeLib.setInputAestheticsFromType;

class StandardMaterialEditor extends MaterialEditor {

	public function new() {

		var material = new MeshStandardNodeMaterial();

		super('Standard Material', material);

		var color = setInputAestheticsFromType(new LabelElement('color'), 'Color');
		var opacity = setInputAestheticsFromType(new LabelElement('opacity'), 'Number');
		var metalness = setInputAestheticsFromType(new LabelElement('metalness'), 'Number');
		var roughness = setInputAestheticsFromType(new LabelElement('roughness'), 'Number');
		var emissive = setInputAestheticsFromType(new LabelElement('emissive'), 'Color');
		var normal = setInputAestheticsFromType(new LabelElement('normal'), 'Vector3');
		var position = setInputAestheticsFromType(new LabelElement('position'), 'Vector3');

		color.add(new ColorInput(material.color.getHex()).onChange(function(input) {

			material.color.setHex(input.getValue());

		}));

		opacity.add(new SliderInput(material.opacity, 0, 1).onChange(function(input) {

			material.opacity = input.getValue();

			this.updateTransparent();

		}));

		metalness.add(new SliderInput(material.metalness, 0, 1).onChange(function(input) {

			material.metalness = input.getValue();

		}));

		roughness.add(new SliderInput(material.roughness, 0, 1).onChange(function(input) {

			material.roughness = input.getValue();

		}));

		color.onConnect(function() {
			this.update();
		}, true);
		opacity.onConnect(function() {
			this.update();
		}, true);
		metalness.onConnect(function() {
			this.update();
		}, true);
		roughness.onConnect(function() {
			this.update();
		}, true);
		emissive.onConnect(function() {
			this.update();
		}, true);
		normal.onConnect(function() {
			this.update();
		}, true);
		position.onConnect(function() {
			this.update();
		}, true);

		this.add(color)
			.add(opacity)
			.add(metalness)
			.add(roughness)
			.add(emissive)
			.add(normal)
			.add(position);

		this.color = color;
		this.opacity = opacity;
		this.metalness = metalness;
		this.roughness = roughness;
		this.emissive = emissive;
		this.normal = normal;
		this.position = position;

		this.update();

	}

	public function update() {

		var {material, color, opacity, emissive, roughness, metalness, normal, position} = this;

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

		this.updateTransparent();

	}

	public function updateTransparent() {

		var {material, opacity} = this;

		var transparent = opacity.getLinkedObject() || material.opacity < 1 ? true : false;
		var needsUpdate = transparent !== material.transparent;

		material.transparent = transparent;

		opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');

		if (needsUpdate == true) material.dispose();

	}

}
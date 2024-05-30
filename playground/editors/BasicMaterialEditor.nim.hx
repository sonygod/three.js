import ColorInput.ColorInput;
import SliderInput.SliderInput;
import LabelElement.LabelElement;
import MaterialEditor.MaterialEditor;
import MeshBasicNodeMaterial.MeshBasicNodeMaterial;
import DataTypeLib.setInputAestheticsFromType;

class BasicMaterialEditor extends MaterialEditor {

	public function new() {

		var material = new MeshBasicNodeMaterial();

		super('Basic Material', material);

		var color = setInputAestheticsFromType(new LabelElement('color'), 'Color');
		var opacity = setInputAestheticsFromType(new LabelElement('opacity'), 'Number');
		var position = setInputAestheticsFromType(new LabelElement('position'), 'Vector3');

		color.add(new ColorInput(material.color.getHex()).onChange(function(input) {

			material.color.setHex(input.getValue());

		}));

		opacity.add(new SliderInput(material.opacity, 0, 1).onChange(function(input) {

			material.opacity = input.getValue();

			this.updateTransparent();

		}));

		color.onConnect(function() {
			this.update();
		}, true);
		opacity.onConnect(function() {
			this.update();
		}, true);
		position.onConnect(function() {
			this.update();
		}, true);

		this.add(color)
			.add(opacity)
			.add(position);

		this.color = color;
		this.opacity = opacity;
		this.position = position;

		this.update();

	}

	public function update() {

		var material = this.material;
		var color = this.color;
		var opacity = this.opacity;
		var position = this.position;

		color.setEnabledInputs(!color.getLinkedObject());
		opacity.setEnabledInputs(!opacity.getLinkedObject());

		material.colorNode = color.getLinkedObject();
		material.opacityNode = opacity.getLinkedObject() || null;

		material.positionNode = position.getLinkedObject() || null;

		material.dispose();

		this.updateTransparent();

	}

	public function updateTransparent() {

		var material = this.material;
		var opacity = this.opacity;

		var transparent = opacity.getLinkedObject() || material.opacity < 1 ? true : false;
		var needsUpdate = transparent !== material.transparent;

		material.transparent = transparent;

		opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');

		if (needsUpdate == true) material.dispose();

	}

}
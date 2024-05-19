package three.js.playground.editors;

import flow.ColorInput;
import flow.ToggleInput;
import flow.SliderInput;
import flow.LabelElement;
import three.nodes.PointsNodeMaterial;
import three.THREE;

class PointsMaterialEditor extends MaterialEditor {
	
	var material:PointsNodeMaterial;

	public function new() {
		super('Points Material', material = new PointsNodeMaterial());

		var color = setInputAestheticsFromType(new LabelElement('color'), 'Color');
		var opacity = setInputAestheticsFromType(new LabelElement('opacity'), 'Number');
		var size = setInputAestheticsFromType(new LabelElement('size'), 'Number');
		var position = setInputAestheticsFromType(new LabelElement('position'), 'Vector3');
		var sizeAttenuation = setInputAestheticsFromType(new LabelElement('Size Attenuation'), 'Number');

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

		add(color).add(opacity).add(size).add(position).add(sizeAttenuation);

		this.color = color;
		this.opacity = opacity;
		this.size = size;
		this.position = position;
		this.sizeAttenuation = sizeAttenuation;

		update();
	}

	override public function update() {
		var color = this.color;
		var opacity = this.opacity;
		var size = this.size;
		var position = this.position;
		var material = this.material;

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

	function updateTransparent() {
		var opacity = this.opacity;
		var material = this.material;

		material.transparent = opacity.getLinkedObject() || material.opacity < 1 ? true : false;

		opacity.setIcon(material.transparent ? 'ti ti-layers-intersect' : 'ti ti-layers-subtract');
	}
}
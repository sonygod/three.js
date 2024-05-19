import three.js.src.materials.LineBasicMaterial;

class LineDashedMaterial extends LineBasicMaterial {

	public function new(parameters:Dynamic) {

		super();

		this.isLineDashedMaterial = true;

		this.type = 'LineDashedMaterial';

		this.scale = 1;
		this.dashSize = 3;
		this.gapSize = 1;

		this.setValues(parameters);

	}

	public function copy(source:LineDashedMaterial):LineDashedMaterial {

		super.copy(source);

		this.scale = source.scale;
		this.dashSize = source.dashSize;
		this.gapSize = source.gapSize;

		return this;

	}

}
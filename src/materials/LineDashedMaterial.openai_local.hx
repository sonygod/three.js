import three.materials.LineBasicMaterial;

class LineDashedMaterial extends LineBasicMaterial {

	public var isLineDashedMaterial:Bool;
	public var scale:Float;
	public var dashSize:Float;
	public var gapSize:Float;

	public function new(parameters:Dynamic) {
		super();
		
		this.isLineDashedMaterial = true;
		this.type = 'LineDashedMaterial';

		this.scale = 1;
		this.dashSize = 3;
		this.gapSize = 1;

		this.setValues(parameters);
	}

	public override function copy(source:LineDashedMaterial):LineDashedMaterial {
		super.copy(source);

		this.scale = source.scale;
		this.dashSize = source.dashSize;
		this.gapSize = source.gapSize;

		return this;
	}
}
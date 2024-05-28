class LineDashedMaterial extends LineBasicMaterial {
	public var isLineDashedMaterial:Bool = true;
	public var type:String = 'LineDashedMaterial';
	public var scale:Float;
	public var dashSize:Int;
	public var gapSize:Int;

	public function new(parameters:Dynamic) {
		super();
		scale = 1.0;
		dashSize = 3;
		gapSize = 1;
		setValues(parameters);
	}

	public override function copy(source:LineDashedMaterial):LineDashedMaterial {
		super.copy(source);
		scale = source.scale;
		dashSize = source.dashSize;
		gapSize = source.gapSize;
		return this;
	}
}
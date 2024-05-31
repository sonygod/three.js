import three.materials.LineBasicMaterial;

class LineDashedMaterial extends LineBasicMaterial {

	public var isLineDashedMaterial:Bool = true;

	public var type(get, set):String;
	private var _type:String = "LineDashedMaterial";
	function get_type():String {
		return _type;
	}
	function set_type(v:String):String {
		_type = v;
		return v;
	}

	public var scale:Float;
	public var dashSize:Float;
	public var gapSize:Float;

	public function new(parameters:Dynamic = null) {
		super();
		this.scale = 1;
		this.dashSize = 3;
		this.gapSize = 1;
		if (parameters != null) {
			this.setValues(parameters);
		}
	}

	public function copy(source:LineDashedMaterial):LineDashedMaterial {
		super.copy(source);
		this.scale = source.scale;
		this.dashSize = source.dashSize;
		this.gapSize = source.gapSize;
		return this;
	}
}
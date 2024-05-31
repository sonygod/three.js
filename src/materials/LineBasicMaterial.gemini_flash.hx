import three.math.Color;
import three.materials.Material;

class LineBasicMaterial extends Material {

	public var isLineBasicMaterial:Bool = true;

	public var type(default,null):String = "LineBasicMaterial";

	public var color:Color = new Color(0xffffff);

	public var map:Dynamic = null;

	public var linewidth:Float = 1;
	public var linecap:String = "round";
	public var linejoin:String = "round";

	public var fog:Bool = true;

	public function new(parameters:Dynamic = null) {
		super();
		if (parameters != null) {
			setValues(parameters);
		}
	}

	public function copy(source:LineBasicMaterial):LineBasicMaterial {
		super.copy(source);
		color = source.color.clone();
		map = source.map;
		linewidth = source.linewidth;
		linecap = source.linecap;
		linejoin = source.linejoin;
		fog = source.fog;
		return this;
	}

}
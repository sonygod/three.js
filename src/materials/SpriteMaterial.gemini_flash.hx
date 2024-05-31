import three.Material;
import three.math.Color;

class SpriteMaterial extends Material {

	public var isSpriteMaterial:Bool = true;
	public var type:String = "SpriteMaterial";
	public var color:Color = new Color(0xffffff);
	public var map:Dynamic = null;
	public var alphaMap:Dynamic = null;
	public var rotation:Float = 0;
	public var sizeAttenuation:Bool = true;
	public var transparent:Bool = true;
	public var fog:Bool = true;

	public function new(parameters:Dynamic = null) {
		super();
		setValues(parameters);
	}

	public function copy(source:SpriteMaterial):SpriteMaterial {
		super.copy(source);
		color = source.color.clone();
		map = source.map;
		alphaMap = source.alphaMap;
		rotation = source.rotation;
		sizeAttenuation = source.sizeAttenuation;
		fog = source.fog;
		return this;
	}

}
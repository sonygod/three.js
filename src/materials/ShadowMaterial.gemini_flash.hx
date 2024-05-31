import three.materials.Material;
import three.math.Color;

class ShadowMaterial extends Material {

	public var isShadowMaterial:Bool = true;

	public var type(default, null):String = "ShadowMaterial";

	public var color(default, null):Color = new Color(0x000000);
	public var transparent(default, null):Bool = true;
	public var fog(default, null):Bool = true;

	public function new(parameters:Dynamic = null) {
		super();
		if (parameters != null) {
			setValues(parameters);
		}
	}

	public function copy(source:ShadowMaterial):ShadowMaterial {
		super.copy(source);
		color = source.color.clone();
		fog = source.fog;
		return this;
	}
}
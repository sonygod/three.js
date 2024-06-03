import Material from "./Material";
import Color from "../math/Color";

class ShadowMaterial extends Material {

	public var isShadowMaterial:Bool = true;
	public var type:String = "ShadowMaterial";
	public var color:Color = new Color(0x000000);
	public var transparent:Bool = true;
	public var fog:Bool = true;

	public function new(parameters:Dynamic = null) {
		super();
		if (parameters != null) {
			this.setValues(parameters);
		}
	}

	public function copy(source:ShadowMaterial):ShadowMaterial {
		super.copy(source);
		this.color = source.color.clone();
		this.fog = source.fog;
		return this;
	}
}

export class ShadowMaterial {
	static public var prototype:ShadowMaterial = new ShadowMaterial();
}
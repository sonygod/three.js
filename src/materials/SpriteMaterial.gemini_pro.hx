import Material from "./Material";
import Color from "../math/Color";

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

	public function new(parameters:Dynamic) {
		super();
		this.setValues(parameters);
	}

	public function copy(source:SpriteMaterial):SpriteMaterial {
		super.copy(source);
		this.color = source.color.clone();
		this.map = source.map;
		this.alphaMap = source.alphaMap;
		this.rotation = source.rotation;
		this.sizeAttenuation = source.sizeAttenuation;
		this.fog = source.fog;
		return this;
	}

	private function setValues(parameters:Dynamic):Void {
		if (parameters != null) {
			if (parameters.color != null) this.color.set(parameters.color);
			if (parameters.map != null) this.map = parameters.map;
			if (parameters.alphaMap != null) this.alphaMap = parameters.alphaMap;
			if (parameters.rotation != null) this.rotation = parameters.rotation;
			if (parameters.sizeAttenuation != null) this.sizeAttenuation = parameters.sizeAttenuation;
			if (parameters.transparent != null) this.transparent = parameters.transparent;
			if (parameters.fog != null) this.fog = parameters.fog;
		}
	}

}

export class SpriteMaterial {
	static public function new(parameters:Dynamic):SpriteMaterial {
		return new SpriteMaterial(parameters);
	}
}
import three.SpotLight;

class IESSpotLight extends SpotLight {

	public var iesMap:Null<Dynamic>;

	public function new(color:Int, intensity:Float, distance:Float, angle:Float, penumbra:Float, decay:Float) {
		super(color, intensity, distance, angle, penumbra, decay);
		this.iesMap = null;
	}

	public function copy(source:IESSpotLight, recursive:Bool):IESSpotLight {
		super.copy(source, recursive);
		this.iesMap = source.iesMap;
		return this;
	}

}

typedef IESSpotLight_three_js_examples_jsm_lights_IESSpotLight = IESSpotLight;
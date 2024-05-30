package three.examples.jsm.lights;

import three.SpotLight;

class IESSpotLight extends SpotLight {
	public var iesMap:Null<Dynamic>;

	public function new(color:Int, intensity:Float, distance:Float, angle:Float, penumbra:Float, decay:Float) {
		super(color, intensity, distance, angle, penumbra, decay);
		this.iesMap = null;
	}

	override public function copy(source:IESSpotLight, recursive:Bool = false):IESSpotLight {
		super.copy(source, recursive);
		this.iesMap = source.iesMap;
		return this;
	}
}
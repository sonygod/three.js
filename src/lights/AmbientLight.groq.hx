package three.js.src.lights;

import three.js.src.Light;

class AmbientLight extends Light {
	
	public var isAmbientLight:Bool;
	public var type:String;

	public function new(color:Int, intensity:Float) {
		super(color, intensity);
		this.isAmbientLight = true;
		this.type = 'AmbientLight';
	}
}

// Export the AmbientLight class
extern class AmbientLight {}
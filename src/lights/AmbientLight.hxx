import three.js.src.lights.Light;

class AmbientLight extends Light {

	public function new(color:Int, intensity:Float) {
		super(color, intensity);
		this.isAmbientLight = true;
		this.type = 'AmbientLight';
	}

}

typedef AmbientLight = three.js.src.lights.AmbientLight;
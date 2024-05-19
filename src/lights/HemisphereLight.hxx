import three.js.src.lights.Light;
import three.js.src.math.Color;
import three.js.src.core.Object3D;

class HemisphereLight extends Light {

	public function new(skyColor:Color, groundColor:Color, intensity:Float) {
		super(skyColor, intensity);

		this.isHemisphereLight = true;

		this.type = 'HemisphereLight';

		this.position.copy(Object3D.DEFAULT_UP);
		this.updateMatrix();

		this.groundColor = new Color(groundColor);
	}

	public function copy(source:HemisphereLight, recursive:Bool):HemisphereLight {
		super.copy(source, recursive);

		this.groundColor.copy(source.groundColor);

		return this;
	}

}
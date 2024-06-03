import js.html.Three.Light;
import js.html.Three.Color;
import js.html.Three.Object3D;

class HemisphereLight extends Light {

	public var groundColor:Color;

	public function new(skyColor:Int, groundColor:Int, intensity:Float) {
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
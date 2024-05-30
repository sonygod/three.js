import three.lights.Light;
import three.math.Color;
import three.core.Object3D;

class HemisphereLight extends Light {

	public var isHemisphereLight:Bool;
	public var groundColor:Color;

	public function new(skyColor:Dynamic, groundColor:Dynamic, intensity:Float = 1.0) {
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
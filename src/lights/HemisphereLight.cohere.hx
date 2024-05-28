import js.Browser.Window;
import js.three.Light;
import js.three.Color;
import js.three.Object3D;

class HemisphereLight extends Light {

	public var isHemisphereLight:Bool;
	public var type:String;
	public var position:Float32Array;
	public var groundColor:Color;

	public function new(skyColor:Dynamic, groundColor:Dynamic, intensity:Float) {
		super(skyColor, intensity);
		isHemisphereLight = true;
		type = 'HemisphereLight';
		position = Object3D.DEFAULT_UP.slice(0);
		updateMatrix();
		this.groundColor = new Color(groundColor);
	}

	public function copy(source:HemisphereLight, ?recursive:Bool):HemisphereLight {
		super.copy(source, recursive);
		groundColor.copy(source.groundColor);
		return this;
	}

}

class js.three.HemisphereLight = HemisphereLight;
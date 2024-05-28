import Light from Light;
import DirectionalLightShadow from DirectionalLightShadow;
import Object3D from Object3D;

class DirectionalLight extends Light {
	public var isDirectionalLight:Bool;
	public var type:String;
	public var position:Object3D;
	public var target:Object3D;
	public var shadow:DirectionalLightShadow;

	public function new(color:Dynamic, intensity:Flt) {
		super(color, intensity);
		isDirectionalLight = true;
		type = 'DirectionalLight';
		position = Object3D.DEFAULT_UP.clone();
		updateMatrix();
		target = new Object3D();
		shadow = new DirectionalLightShadow();
	}

	public function dispose():Void {
		shadow.dispose();
	}

	public function copy(source:DirectionalLight):DirectionalLight {
		super.copy(source);
		target = source.target.clone();
		shadow = source.shadow.clone();
		return this;
	}
}
import three.lights.Light;
import three.lights.DirectionalLightShadow;
import three.core.Object3D;

class DirectionalLight extends Light {

	public var isDirectionalLight:Bool;
	public var type:String;
	public var target:Object3D;
	public var shadow:DirectionalLightShadow;

	public function new(color:Int, intensity:Float) {
		super(color, intensity);

		this.isDirectionalLight = true;
		this.type = 'DirectionalLight';
		this.position.copy(Object3D.DEFAULT_UP);
		this.updateMatrix();
		this.target = new Object3D();
		this.shadow = new DirectionalLightShadow();
	}

	public function dispose():Void {
		this.shadow.dispose();
	}

	public function copy(source:DirectionalLight):DirectionalLight {
		super.copy(source);
		this.target = source.target.clone();
		this.shadow = source.shadow.clone();
		return this;
	}
}
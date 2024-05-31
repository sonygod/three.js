import three.lights.Light;
import three.lights.DirectionalLightShadow;
import three.core.Object3D;

class DirectionalLight extends Light {
	public var isDirectionalLight:Bool = true;
	public var type:String = "DirectionalLight";
	public var target:Object3D;
	public var shadow:DirectionalLightShadow;

	public function new(color:Dynamic, intensity:Float) {
		super(color, intensity);
		this.position.copy(Object3D.DEFAULT_UP);
		this.updateMatrix();
		this.target = new Object3D();
		this.shadow = new DirectionalLightShadow();
	}

	public function dispose() {
		this.shadow.dispose();
	}

	public function copy(source:DirectionalLight):DirectionalLight {
		super.copy(source);
		this.target = source.target.clone();
		this.shadow = source.shadow.clone();
		return this;
	}
}
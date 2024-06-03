import Light from "./Light";
import DirectionalLightShadow from "./DirectionalLightShadow";
import Object3D from "../core/Object3D";

class DirectionalLight extends Light {

	public var isDirectionalLight:Bool = true;
	public var type:String = "DirectionalLight";
	public var target:Object3D;
	public var shadow:DirectionalLightShadow;

	public function new(color:Int, intensity:Float) {
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

export class DirectionalLight {
}
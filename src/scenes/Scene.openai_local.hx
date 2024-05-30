import three.core.Object3D;
import three.math.Euler;

class Scene extends Object3D {

	public var isScene:Bool;
	public var type:String;
	public var background:Dynamic;
	public var environment:Dynamic;
	public var fog:Dynamic;
	public var backgroundBlurriness:Float;
	public var backgroundIntensity:Float;
	public var backgroundRotation:Euler;
	public var environmentIntensity:Float;
	public var environmentRotation:Euler;
	public var overrideMaterial:Dynamic;

	public function new() {
		super();

		this.isScene = true;
		this.type = 'Scene';

		this.background = null;
		this.environment = null;
		this.fog = null;

		this.backgroundBlurriness = 0;
		this.backgroundIntensity = 1;
		this.backgroundRotation = new Euler();

		this.environmentIntensity = 1;
		this.environmentRotation = new Euler();

		this.overrideMaterial = null;

		#if __THREE_DEVTOOLS__
		__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent('observe', { detail: this }));
		#end
	}

	public function copy(source:Scene, recursive:Bool):Scene {
		super.copy(source, recursive);

		if (source.background != null) this.background = source.background.clone();
		if (source.environment != null) this.environment = source.environment.clone();
		if (source.fog != null) this.fog = source.fog.clone();

		this.backgroundBlurriness = source.backgroundBlurriness;
		this.backgroundIntensity = source.backgroundIntensity;
		this.backgroundRotation.copy(source.backgroundRotation);

		this.environmentIntensity = source.environmentIntensity;
		this.environmentRotation.copy(source.environmentRotation);

		if (source.overrideMaterial != null) this.overrideMaterial = source.overrideMaterial.clone();

		this.matrixAutoUpdate = source.matrixAutoUpdate;

		return this;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var data = super.toJSON(meta);

		if (this.fog != null) data.object.fog = this.fog.toJSON();

		if (this.backgroundBlurriness > 0) data.object.backgroundBlurriness = this.backgroundBlurriness;
		if (this.backgroundIntensity != 1) data.object.backgroundIntensity = this.backgroundIntensity;
		data.object.backgroundRotation = this.backgroundRotation.toArray();

		if (this.environmentIntensity != 1) data.object.environmentIntensity = this.environmentIntensity;
		data.object.environmentRotation = this.environmentRotation.toArray();

		return data;
	}

}
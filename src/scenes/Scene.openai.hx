package three.scenes;

import three.core.Object3D;
import three.math.Euler;

class Scene extends Object3D {

	public var isScene:Bool = true;
	public var type:String = 'Scene';

	public var background:Null<Dynamic> = null;
	public var environment:Null<Dynamic> = null;
	public var fog:Null<Dynamic> = null;

	public var backgroundBlurriness:Float = 0;
	public var backgroundIntensity:Float = 1;
	public var backgroundRotation:Euler;

	public var environmentIntensity:Float = 1;
public var environmentRotation:Euler;

public var overrideMaterial:Null<Dynamic> = null;

public function new() {
	super();
	backgroundRotation = new Euler();
	environmentRotation = new Euler();

	#if (three_devtools)
	if (Uncaught !== null) {
		Uncaught.dispatchEvent(new CustomEvent('observe', { detail: this }));
	}
	#end
}

public function copy(source:Scene, recursive:Bool = false):Scene {
	super.copy(source, recursive);

	if (source.background != null) {
		background = source.background.clone();
	}
	if (source.environment != null) {
		environment = source.environment.clone();
	}
	if (source.fog != null) {
		fog = source.fog.clone();
	}

	backgroundBlurriness = source.backgroundBlurriness;
	backgroundIntensity = source.backgroundIntensity;
	backgroundRotation.copy(source.backgroundRotation);

	environmentIntensity = source.environmentIntensity;
	environmentRotation.copy(source.environmentRotation);

	if (source.overrideMaterial != null) {
		overrideMaterial = source.overrideMaterial.clone();
	}

	matrixAutoUpdate = source.matrixAutoUpdate;

	return this;
}

public function toJSON(meta:Dynamic):Dynamic {
	var data:Dynamic = super.toJSON(meta);

	if (fog != null) {
		data.object.fog = fog.toJSON();
	}

	if (backgroundBlurriness > 0) {
		data.object.backgroundBlurriness = backgroundBlurriness;
	}
	if (backgroundIntensity != 1) {
		data.object.backgroundIntensity = backgroundIntensity;
	}
	data.object.backgroundRotation = backgroundRotation.toArray();

	if (environmentIntensity != 1) {
		data.object.environmentIntensity = environmentIntensity;
	}
	data.object.environmentRotation = environmentRotation.toArray();

	return data;
}
}
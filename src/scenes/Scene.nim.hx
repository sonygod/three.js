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
	public var backgroundRotation:Euler = new Euler();

	public var environmentIntensity:Float = 1;
	public var environmentRotation:Euler = new Euler();

	public var overrideMaterial:Null<Dynamic> = null;

	public function new() {

		super();

		if ( Std.is(typeof(__THREE_DEVTOOLS__), Dynamic )) {

			__THREE_DEVTOOLS__.dispatchEvent( new CustomEvent( 'observe', { detail: this } ) );

		}

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

	public function toJSON(meta:Null<Dynamic>):Dynamic {

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



Please note that Haxe does not have a direct equivalent to JavaScript's `export` statement. Instead, you would typically use a package declaration at the top of your file to indicate where the class should be exported to. For example:


package three.scenes;

import three.core.Object3D;
import three.math.Euler;

class Scene extends Object3D {
    // ...
}
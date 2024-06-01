package;

import three.core.Object3D;
import three.math.Euler;
import three.CustomEvent;

class Scene extends Object3D {

	public var isScene(default, null) : Bool = true;

	public var background : Dynamic = null; // Texture | Color
	public var environment : Dynamic = null; // Texture
	public var fog : Dynamic = null; // Fog | FogExp2

	public var backgroundBlurriness : Float = 0;
	public var backgroundIntensity : Float = 1;
	public var backgroundRotation : Euler;

	public var environmentIntensity : Float = 1;
	public var environmentRotation : Euler;

	public var overrideMaterial : Dynamic = null; // Material

	public function new() {

		super();

		this.type = 'Scene';

		backgroundRotation = new Euler();
		environmentRotation = new Euler();

		#if three_devtools
		__THREE_DEVTOOLS__.dispatchEvent( new CustomEvent( 'observe', { detail: this } ) );
		#end

	}

	override public function copy( source : Scene, recursive : Bool = true ) : Scene {

		super.copy( source, recursive );

		if ( source.background != null ) this.background = source.background.clone();
		if ( source.environment != null ) this.environment = source.environment.clone();
		if ( source.fog != null ) this.fog = source.fog.clone();

		this.backgroundBlurriness = source.backgroundBlurriness;
		this.backgroundIntensity = source.backgroundIntensity;
		this.backgroundRotation.copy( source.backgroundRotation );

		this.environmentIntensity = source.environmentIntensity;
		this.environmentRotation.copy( source.environmentRotation );

		if ( source.overrideMaterial != null ) this.overrideMaterial = source.overrideMaterial.clone();

		this.matrixAutoUpdate = source.matrixAutoUpdate;

		return this;

	}

	override public function toJSON( meta : Dynamic ) : Dynamic {

		var data = super.toJSON( meta );

		if ( this.fog != null ) data.object.fog = this.fog.toJSON();

		if ( this.backgroundBlurriness > 0 ) data.object.backgroundBlurriness = this.backgroundBlurriness;
		if ( this.backgroundIntensity != 1 ) data.object.backgroundIntensity = this.backgroundIntensity;
		data.object.backgroundRotation = this.backgroundRotation.toArray();

		if ( this.environmentIntensity != 1 ) data.object.environmentIntensity = this.environmentIntensity;
		data.object.environmentRotation = this.environmentRotation.toArray();

		return data;

	}

}
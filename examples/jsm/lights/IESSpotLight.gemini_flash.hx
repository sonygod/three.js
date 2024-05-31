import three.lights.SpotLight;
import three.textures.Texture;

class IESSpotLight extends SpotLight {

	public var iesMap:Texture;

	public function new( color:Int = 0xffffff, intensity:Float = 1, distance:Float = 0, angle:Float = Math.PI / 3, penumbra:Float = 0, decay:Float = 1 ) {

		super( color, intensity, distance, angle, penumbra, decay );
		this.iesMap = null;
	}

	override public function copy( source:Dynamic, ?recursive:Bool ):Dynamic {

		super.copy( source, recursive );

		if ( Std.is(source, IESSpotLight) ) {
			this.iesMap = cast(source, IESSpotLight).iesMap;
		}

		return this;

	}

}
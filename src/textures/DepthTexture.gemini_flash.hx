import three.Textures.Texture;
import three.Constants;

class DepthTexture extends Texture {

	public function new( width : Int, height : Int, type : Int = -1, mapping : Int = 0, wrapS : Int = 0, wrapT : Int = 0, magFilter : Int = 0, minFilter : Int = 0, anisotropy : Int = 0, format : Int = Constants.DepthFormat ) {

		if ( format != Constants.DepthFormat && format != Constants.DepthStencilFormat ) {

			throw "DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat";

		}

		if ( type == -1 && format == Constants.DepthFormat ) type = Constants.UnsignedIntType;
		if ( type == -1 && format == Constants.DepthStencilFormat ) type = Constants.UnsignedInt248Type;

		super( null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy );

		this.isDepthTexture = true;

		this.image = { width: width, height: height };

		this.magFilter = ( magFilter != -1 ) ? magFilter : Constants.NearestFilter;
		this.minFilter = ( minFilter != -1 ) ? minFilter : Constants.NearestFilter;

		this.flipY = false;
		this.generateMipmaps = false;

		this.compareFunction = null;

	}


	public override function copy( source : DepthTexture ) : DepthTexture {

		super.copy( source );

		this.compareFunction = source.compareFunction;

		return this;

	}

	public override function toJSON( meta : Dynamic ) : Dynamic {

		var data = super.toJSON( meta );

		if ( this.compareFunction != null ) data.compareFunction = this.compareFunction;

		return data;

	}

}
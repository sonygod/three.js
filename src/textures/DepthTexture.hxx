import three.js.src.textures.Texture;
import three.js.src.constants.NearestFilter;
import three.js.src.constants.UnsignedIntType;
import three.js.src.constants.UnsignedInt248Type;
import three.js.src.constants.DepthFormat;
import three.js.src.constants.DepthStencilFormat;

class DepthTexture extends Texture {

	public function new(width:Int, height:Int, type:Int, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, anisotropy:Int, format:Int = DepthFormat) {

		if (format != DepthFormat && format != DepthStencilFormat) {

			throw 'DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat';

		}

		if (type == null && format == DepthFormat) type = UnsignedIntType;
		if (type == null && format == DepthStencilFormat) type = UnsignedInt248Type;

		super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

		this.isDepthTexture = true;

		this.image = { width: width, height: height };

		this.magFilter = if (magFilter != null) magFilter else NearestFilter;
		this.minFilter = if (minFilter != null) minFilter else NearestFilter;

		this.flipY = false;
		this.generateMipmaps = false;

		this.compareFunction = null;

	}

	public function copy(source:DepthTexture):DepthTexture {

		super.copy(source);

		this.compareFunction = source.compareFunction;

		return this;

	}

	public function toJSON(meta:Dynamic):Dynamic {

		var data = super.toJSON(meta);

		if (this.compareFunction != null) data.compareFunction = this.compareFunction;

		return data;

	}

}
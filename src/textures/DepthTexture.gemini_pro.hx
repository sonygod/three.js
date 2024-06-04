import Texture from "./Texture";
import {NearestFilter, UnsignedIntType, UnsignedInt248Type, DepthFormat, DepthStencilFormat} from "../constants";

class DepthTexture extends Texture {
	public var isDepthTexture:Bool = true;
	public var image:Dynamic;
	public var compareFunction:Dynamic;

	public function new(width:Int, height:Int, type:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:Dynamic, minFilter:Dynamic, anisotropy:Dynamic, format:Dynamic = DepthFormat) {
		if (format != DepthFormat && format != DepthStencilFormat) {
			throw new Error("DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat");
		}

		if (type == null && format == DepthFormat) type = UnsignedIntType;
		if (type == null && format == DepthStencilFormat) type = UnsignedInt248Type;

		super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

		this.image = {width: width, height: height};

		this.magFilter = magFilter != null ? magFilter : NearestFilter;
		this.minFilter = minFilter != null ? minFilter : NearestFilter;

		this.flipY = false;
		this.generateMipmaps = false;
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

export class DepthTexture {
}
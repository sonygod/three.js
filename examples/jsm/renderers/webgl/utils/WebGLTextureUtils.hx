import three.LinearFilter;
import three.LinearMipmapLinearFilter;
import three.LinearMipmapNearestFilter;
import three.NearestFilter;
import three.NearestMipmapLinearFilter;
import three.NearestMipmapNearestFilter;
import three.FloatType;
import three.MirroredRepeatWrapping;
import three.ClampToEdgeWrapping;
import three.RepeatWrapping;
import three.SRGBColorSpace;
import three.NeverCompare;
import three.AlwaysCompare;
import three.LessCompare;
import three.LessEqualCompare;
import three.EqualCompare;
import three.GreaterEqualCompare;
import three.GreaterCompare;
import three.NotEqualCompare;

class WebGLTextureUtils {

	private static initialized:Bool;
	private static wrappingToGL:Dynamic<Int>;
	private static filterToGL:Dynamic<Int>;
	private static compareToGL:Dynamic<Int>;

	public var backend:Dynamic;
	public var gl:WebGLRenderingContext;
	public var extensions:Dynamic;
	public var defaultTextures:Dynamic<Dynamic>;

	public function new(backend:Dynamic) {
		this.backend = backend;
		this.gl = backend.gl;
		this.extensions = backend.extensions;
		this.defaultTextures = {};

		if (WebGLTextureUtils.initialized === false) {
			this._init(this.gl);
			WebGLTextureUtils.initialized = true;
		}
	}

	private function _init(gl:WebGLRenderingContext) {
		WebGLTextureUtils.wrappingToGL = {
			[RepeatWrapping]: gl.REPEAT,
			[ClampToEdgeWrapping]: gl.CLAMP_TO_EDGE,
			[MirroredRepeatWrapping]: gl.MIRRORED_REPEAT
		};

		WebGLTextureUtils.filterToGL = {
			[NearestFilter]: gl.NEAREST,
			[NearestMipmapNearestFilter]: gl.NEAREST_MIPMAP_NEAREST,
			[NearestMipmapLinearFilter]: gl.NEAREST_MIPMAP_LINEAR,

			[LinearFilter]: gl.LINEAR,
			[LinearMipmapNearestFilter]: gl.LINEAR_MIPMAP_NEAREST,
			[LinearMipmapLinearFilter]: gl.LINEAR_MIPMAP_LINEAR
		};

		WebGLTextureUtils.compareToGL = {
			[NeverCompare]: gl.NEVER,
			[AlwaysCompare]: gl.ALWAYS,
			[LessCompare]: gl.LESS,
			[LessEqualCompare]: gl.LEQUAL,
			[EqualCompare]: gl.EQUAL,
			[GreaterEqualCompare]: gl.GEQUAL,
			[GreaterCompare]: gl.GREATER,
			[NotEqualCompare]: gl.NOTEQUAL
		};
	}

	public function filterFallback(f:Int):Int {
		const { gl } = this;

		if (f === NearestFilter || f === NearestMipmapNearestFilter || f === NearestMipmapLinearFilter) {
			return gl.NEAREST;
		}

		return gl.LINEAR;
	}

	public function getGLTextureType(texture:Dynamic):Int {
		const { gl } = this;

		let glTextureType:Int;

		if (UnsignedByteType.is(texture.type)) {
			glTextureType = gl.UNSIGNED_BYTE;
		} else if (UnsignedShortType.is(texture.type)) {
			glTextureType = gl.UNSIGNED_SHORT;
		} else if (UnsignedIntType.is(texture.type)) {
			glTextureType = gl.UNSIGNED_INT;
		} else if (HalfFloatType.is(texture.type)) {
			glTextureType = gl.HALF_FLOAT;
		} else if (FloatType.is(texture.type)) {
			glTextureType = gl.FLOAT;
		} else {
			throw new Error("Invalid texture type: " + texture.type);
		}

		if (texture.isCubeTexture === true) {
			glTextureType = gl.TEXTURE_CUBE_MAP;
		} else if (texture.isDataArrayTexture === true) {
			glTextureType = gl.TEXTURE_2D_ARRAY;
		} else {
			glTextureType = gl.TEXTURE_2D;
		}

		return glTextureType;
	}

	public function getInternalFormat(internalFormatName:String, glFormat:Int, glType:Int, colorSpace:Dynamic, forceLinearTransfer:Bool = false):Int {
		const { gl, extensions } = this;

		if (internalFormatName !== null) {
			if (gl[internalFormatName] !== undefined) return gl[internalFormatName];

			console.warn("THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format '" + internalFormatName + "'");
		}

		let internalFormat = glFormat;

		if (glFormat === gl.RED) {
			if (glType === gl.FLOAT) internalFormat = gl.R32F;
			if (glType === gl.HALF_FLOAT) internalFormat = gl.R16F;
			if (glType === gl.UNSIGNED_BYTE) internalFormat = gl.R8;
		}

		if (glFormat === gl.RED_INTEGER) {
			if (glType === gl.UNSIGNED_BYTE) internalFormat = gl.R8UI;
			if (glType === gl.UNSIGNED_SHORT) internalFormat = gl.R16UI;
			if (glType === gl.UNSIGNED_INT) internalFormat = gl.R32UI;
			if (glType === gl.BYTE) internalFormat = gl.R8I;
			if (glType === gl.SHORT) internalFormat = gl.R16I;
			if (glType === gl.INT) internalFormat = gl.R32I;
		}

		if (glFormat === gl.RG) {
			if (glType === gl.FLOAT) internalFormat = gl.RG32F;
			if (glType === gl.HALF_FLOAT) internalFormat = gl.RG16F;
			if (glType === gl.UNSIGNED_BYTE) internalFormat = gl.RG8;
		}

		if (glFormat === gl.RGB) {
			if (glType === gl.FLOAT) internalFormat = gl.RGB32F;
			if (glType === gl.HALF_FLOAT) internalFormat = gl.RGB16F;
			if (glType === gl.UNSIGNED_BYTE) internalFormat = gl.RGB8;
			if (glType === gl.UNSIGNED_SHORT_5_6_5) internalFormat = gl.RGB565;
			if (glType === gl.UNSIGNED_SHORT_5_5_5_1) internalFormat = gl.RGB5_A1;
			if (glType === gl.UNSIGNED_SHORT_4_4_4_4) internalFormat = gl.RGB4;
			if (glType === gl.UNSIGNED_INT_5_9_9_9_REV) internalFormat = gl.RGB9_E5;
		}

		if (glFormat === gl.RGBA) {
			if (glType === gl.FLOAT) internalFormat = gl.RGBA32F;
			if (glType === gl.HALF_FLOAT) internalFormat = gl.RGBA16F;
			if (glType === gl.UNSIGNED_BYTE) internalFormat = (colorSpace === SRGBColorSpace && forceLinearTransfer === false) ? gl.SRGB8_ALPHA8 : gl.RGBA8;
			if (glType === gl.UNSIGNED_SHORT_4_4_4_4) internalFormat = gl.RGBA4;
			if (glType === gl.UNSIGNED_SHORT_5_5_5_1) internalFormat = gl.RGB5_A1;
		}

		if (glFormat === gl.DEPTH_COMPONENT) {
			if (glType === gl.UNSIGNED_INT) internalFormat = gl.DEPTH24_STENCIL8;
			if (glType === gl.FLOAT) internalFormat = gl.DEPTH_COMPONENT32F;
		}

		if (glFormat === gl.DEPTH_STENCIL) {
			if (glType === gl.UNSIGNED_INT_24_8) internalFormat = gl.DEPTH24_STENCIL8;
		}

		if (internalFormat === gl.R16F || internalFormat === gl.R32F || internalFormat === gl.RG16F || internalFormat === gl.RG32F || internalFormat === gl.RGBA16F || internalFormat === gl.RGBA32F) {
			extensions.get("EXT_color_buffer_float");
		}

		return internalFormat;
	}

	public function setTextureParameters(textureType:Int, texture:Dynamic) {
		const { gl, extensions, backend } = this;

		const { currentAnisotropy } = backend.get(texture);

		gl.texParameteri(textureType, gl.TEXTURE_WRAP_S, WebGLTextureUtils.wrappingToGL[texture.wrapS]);
		gl.texParameteri(textureType, gl.TEXTURE_WRAP_T, WebGLTextureUtils.wrappingToGL[texture.wrapT]);

		if (textureType === gl.TEXTURE_3D || textureType === gl.TEXTURE_2D_ARRAY) {
			gl.texParameteri(textureType, gl.TEXTURE_WRAP_R, WebGLTextureUtils.wrappingToGL[texture.wrapR]);
		}

		gl.texParameteri(textureType, gl.TEXTURE_MAG_FILTER, WebGLTextureUtils.filterToGL[texture.magFilter]);

		const minFilter = !texture.isVideoTexture && texture.minFilter === LinearFilter ? LinearMipmapLinearFilter : texture.minFilter;

		gl.texParameteri(textureType, gl.TEXTURE_MIN_FILTER, WebGLTextureUtils.filterToGL[minFilter]);

		if (texture.compareFunction) {
			gl.texParameteri(textureType, gl.TEXTURE_COMPARE_MODE, gl.COMPARE_REF_TO_TEXTURE);
			gl.texParameteri(textureType, gl.TEXTURE_COMPARE_FUNC, WebGLTextureUtils.compareToGL[texture.compareFunction]);
		}

		if (extensions.has("EXT_texture_filter_anisotropic") === true) {
			if (texture.magFilter === NearestFilter) return;
			if (texture.minFilter !== NearestMipmapLinearFilter && texture.minFilter !== LinearMipmapLinearFilter) return;
			if (texture.type === FloatType && extensions.has("OES_texture_float_linear") === false) return;

			if (texture.anisotropy > 1 || currentAnisotropy !== texture.anisotropy) {
				const extension = extensions.get("EXT_texture_filter_anisotropic");
				gl.texParameterf(textureType, extension.TEXTURE_MAX_ANISOTROPY_EXT, Math.min(texture.anisotropy, backend.getMaxAnisotropy()));
				backend.get(texture).currentAnisotropy = texture.anisotropy;
			}
		}
	}

	public function createDefaultTexture(texture:Dynamic) {
		const { gl, backend, defaultTextures } = this;

		const glTextureType = this.getGLTextureType(texture);

		let textureGPU = defaultTextures[glTextureType];

		if (textureGPU === undefined) {
			textureGPU = gl.createTexture();

			backend.state.bindTexture(glTextureType, textureGPU);
			gl.texParameteri(glTextureType, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
			gl.texParameteri(glTextureType, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

			defaultTextures[glTextureType] = textureGPU;
		}

		backend.set(texture, {
			textureGPU,
			glTextureType,
			isDefault: true
		});
	}

	public function createTexture(texture:Dynamic, options:Dynamic) {
		const { gl, backend } = this;
		const { levels, width, height, depth } = options;

		const glFormat = backend.utils.convert(texture.format, texture.colorSpace);
		const glType = backend.utils.convert(texture.type);
		const glInternalFormat = this.getInternalFormat(texture.internalFormat, glFormat, glType, texture.colorSpace, texture.isVideoTexture);

		const textureGPU = gl.createTexture();
		const glTextureType = this.getGLTextureType(texture);

		backend.state.bindTexture(glTextureType, textureGPU);

		gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, texture.flipY);
		gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, texture.premultiplyAlpha);
		gl.pixelStorei(gl.UNPACK_ALIGNMENT, texture.unpackAlignment);
		gl.pixelStorei(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL, gl.NONE);

		this.setTextureParameters(glTextureType, texture);

		if (texture.isDataArrayTexture) {
			gl.texStorage3D(gl.TEXTURE_2D_ARRAY, levels, glInternalFormat, width, height, depth);
		} else if (!texture.isVideoTexture) {
			gl.texStorage2D(glTextureType, levels, glInternalFormat, width, height);
		}

		backend.set(texture, {
			textureGPU,
			glTextureType,
			glFormat,
			glType,
			glInternalFormat
		});
	}

	// ... (other functions omitted for brevity)

}
import haxe.ds.StringMap;
import haxe.ds.StringIntMap;
import haxe.ds.Null<T>;
import haxe.ds.Option;
import js.html.CanvasElement;
import js.html.ImageBitmap;
import js.html.VideoFrame;
import js.html.HTMLImageElement;
import js.html.HTMLCanvasElement;
import js.html.HTMLVideoElement;
import js.webgl.WebGLRenderingContext;
import js.webgl.WebGLProgram;
import js.webgl.WebGLBuffer;
import js.webgl.WebGLFramebuffer;
import js.webgl.WebGLTexture;
import js.webgl.WebGLRenderbuffer;
import js.webgl.WebGLShader;
import js.webgl.WebGLUniformLocation;
import js.webgl.WebGLActiveInfo;
import js.webgl.WebGLShaderPrecisionFormat;
import js.webgl.WebGLShaderSource;
import js.webgl.WebGLContextAttributes;
import js.webgl.WebGLQuery;
import js.webgl.WebGLVertexArrayObject;
import js.webgl.WebGLSync;
import js.webgl.WebGLSampler;
import js.webgl.WebGLTextureInternalFormat;
import js.webgl.WebGLTextureFormat;
import js.webgl.WebGLTextureType;
import js.webgl.WebGLCompareFunc;
import js.webgl.WebGLStencilFunc;
import js.webgl.WebGLBlendFunc;
import js.webgl.WebGLBlendEquation;
import js.webgl.WebGLBlendEquationSeparate;
import js.webgl.WebGLDrawElementsType;
import js.webgl.WebGLCullFaceMode;
import js.webgl.WebGLFrontFace;
import js.webgl.WebGLPolygonMode;
import js.webgl.WebGLPrimitiveRestartIndex;
import js.webgl.WebGLContextEvent;
import js.webgl.WebGLFramebufferAttachment;
import js.webgl.WebGLFramebufferStatus;
import js.webgl.WebGLRenderbufferStorageMultisampleEXT;
import js.webgl.WebGLFramebufferTexture2DMultisampleEXT;
import js.webgl.WebGLTextureCubeMap;
import js.webgl.WebGLTextureCubeMapTarget;
import js.webgl.WebGLTextureTarget;
import js.webgl.WebGLCompressedTextureFormat;
import js.webgl.WebGLCompressedTextureS3TC;
import js.webgl.WebGLCompressedTextureETC;
import js.webgl.WebGLCompressedTextureBPTC;
import js.webgl.WebGLCompressedTexturePVRTC;
import js.webgl.WebGLCompressedTextureASTC;
import js.webgl.WebGLCompressedTextureATC;
import js.webgl.WebGLCompressedTextureS3TC_DXT1;
import js.webgl.WebGLCompressedTextureS3TC_DXT3;
import js.webgl.WebGLCompressedTextureS3TC_DXT5;
import js.webgl.WebGLCompressedTextureETC1;
import js.webgl.WebGLCompressedTextureETC2;
import js.webgl.WebGLCompressedTextureBPTC_RGBA;
import js.webgl.WebGLCompressedTextureBPTC_SRGB;
import js.webgl.WebGLCompressedTexturePVRTC_RGB;
import js.webgl.WebGLCompressedTexturePVRTC_RGBA;
import js.webgl.WebGLCompressedTexturePVRTC_4BPPV1;
import js.webgl.WebGLCompressedTexturePVRTC_2BPPV1;
import js.webgl.WebGLCompressedTextureASTC_LDR;
import js.webgl.WebGLCompressedTextureASTC_HDR;
import js.webgl.WebGLCompressedTextureATC_RGB_AMD;
import js.webgl.WebGLCompressedTextureATC_RGBA_AMD;
import js.webgl.WebGLCompressedTextureS3TC_DXT1_EXT;
import js.webgl.WebGLCompressedTextureS3TC_DXT3_EXT;
import js.webgl.WebGLCompressedTextureS3TC_DXT5_EXT;
import js.webgl.WebGLCompressedTextureETC1_EXT;
import js.webgl.WebGLCompressedTextureETC2_EXT;
import js.webgl.WebGLCompressedTextureBPTC_RGBA_EXT;
import js.webgl.WebGLCompressedTextureBPTC_SRGB_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_RGB_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_RGBA_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_4BPPV1_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_2BPPV1_EXT;
import js.webgl.WebGLCompressedTextureASTC_LDR_EXT;
import js.webgl.WebGLCompressedTextureASTC_HDR_EXT;
import js.webgl.WebGLCompressedTextureATC_RGB_AMD_EXT;
import js.webgl.WebGLCompressedTextureATC_RGBA_AMD_EXT;
import js.webgl.WebGLCompressedTextureS3TC_DXT1_OES;
import js.webgl.WebGLCompressedTextureS3TC_DXT3_OES;
import js.webgl.WebGLCompressedTextureS3TC_DXT5_OES;
import js.webgl.WebGLCompressedTextureETC1_OES;
import js.webgl.WebGLCompressedTextureETC2_OES;
import js.webgl.WebGLCompressedTextureBPTC_RGBA_EXT;
import js.webgl.WebGLCompressedTextureBPTC_SRGB_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_RGB_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_RGBA_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_4BPPV1_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_2BPPV1_EXT;
import js.webgl.WebGLCompressedTextureASTC_LDR_EXT;
import js.webgl.WebGLCompressedTextureASTC_HDR_EXT;
import js.webgl.WebGLCompressedTextureATC_RGB_AMD_EXT;
import js.webgl.WebGLCompressedTextureATC_RGBA_AMD_EXT;
import js.webgl.WebGLContextEvent;
import js.webgl.WebGLFramebufferStatus;
import js.webgl.WebGLFramebufferAttachment;
import js.webgl.WebGLRenderbufferStorageMultisampleEXT;
import js.webgl.WebGLFramebufferTexture2DMultisampleEXT;
import js.webgl.WebGLTextureCubeMap;
import js.webgl.WebGLTextureCubeMapTarget;
import js.webgl.WebGLTextureTarget;
import js.webgl.WebGLCompressedTextureFormat;
import js.webgl.WebGLCompressedTextureS3TC;
import js.webgl.WebGLCompressedTextureETC;
import js.webgl.WebGLCompressedTextureBPTC;
import js.webgl.WebGLCompressedTexturePVRTC;
import js.webgl.WebGLCompressedTextureASTC;
import js.webgl.WebGLCompressedTextureATC;
import js.webgl.WebGLCompressedTextureS3TC_DXT1;
import js.webgl.WebGLCompressedTextureS3TC_DXT3;
import js.webgl.WebGLCompressedTextureS3TC_DXT5;
import js.webgl.WebGLCompressedTextureETC1;
import js.webgl.WebGLCompressedTextureETC2;
import js.webgl.WebGLCompressedTextureBPTC_RGBA;
import js.webgl.WebGLCompressedTextureBPTC_SRGB;
import js.webgl.WebGLCompressedTexturePVRTC_RGB;
import js.webgl.WebGLCompressedTexturePVRTC_RGBA;
import js.webgl.WebGLCompressedTexturePVRTC_4BPPV1;
import js.webgl.WebGLCompressedTexturePVRTC_2BPPV1;
import js.webgl.WebGLCompressedTextureASTC_LDR;
import js.webgl.WebGLCompressedTextureASTC_HDR;
import js.webgl.WebGLCompressedTextureATC_RGB_AMD;
import js.webgl.WebGLCompressedTextureATC_RGBA_AMD;
import js.webgl.WebGLCompressedTextureS3TC_DXT1_EXT;
import js.webgl.WebGLCompressedTextureS3TC_DXT3_EXT;
import js.webgl.WebGLCompressedTextureS3TC_DXT5_EXT;
import js.webgl.WebGLCompressedTextureETC1_EXT;
import js.webgl.WebGLCompressedTextureETC2_EXT;
import js.webgl.WebGLCompressedTextureBPTC_RGBA_EXT;
import js.webgl.WebGLCompressedTextureBPTC_SRGB_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_RGB_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_RGBA_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_4BPPV1_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_2BPPV1_EXT;
import js.webgl.WebGLCompressedTextureASTC_LDR_EXT;
import js.webgl.WebGLCompressedTextureASTC_HDR_EXT;
import js.webgl.WebGLCompressedTextureATC_RGB_AMD_EXT;
import js.webgl.WebGLCompressedTextureATC_RGBA_AMD_EXT;
import js.webgl.WebGLContextEvent;
import js.webgl.WebGLFramebufferStatus;
import js.webgl.WebGLFramebufferAttachment;
import js.webgl.WebGLRenderbufferStorageMultisampleEXT;
import js.webgl.WebGLFramebufferTexture2DMultisampleEXT;
import js.webgl.WebGLTextureCubeMap;
import js.webgl.WebGLTextureCubeMapTarget;
import js.webgl.WebGLTextureTarget;
import js.webgl.WebGLCompressedTextureFormat;
import js.webgl.WebGLCompressedTextureS3TC;
import js.webgl.WebGLCompressedTextureETC;
import js.webgl.WebGLCompressedTextureBPTC;
import js.webgl.WebGLCompressedTexturePVRTC;
import js.webgl.WebGLCompressedTextureASTC;
import js.webgl.WebGLCompressedTextureATC;
import js.webgl.WebGLCompressedTextureS3TC_DXT1;
import js.webgl.WebGLCompressedTextureS3TC_DXT3;
import js.webgl.WebGLCompressedTextureS3TC_DXT5;
import js.webgl.WebGLCompressedTextureETC1;
import js.webgl.WebGLCompressedTextureETC2;
import js.webgl.WebGLCompressedTextureBPTC_RGBA;
import js.webgl.WebGLCompressedTextureBPTC_SRGB;
import js.webgl.WebGLCompressedTexturePVRTC_RGB;
import js.webgl.WebGLCompressedTexturePVRTC_RGBA;
import js.webgl.WebGLCompressedTexturePVRTC_4BPPV1;
import js.webgl.WebGLCompressedTexturePVRTC_2BPPV1;
import js.webgl.WebGLCompressedTextureASTC_LDR;
import js.webgl.WebGLCompressedTextureASTC_HDR;
import js.webgl.WebGLCompressedTextureATC_RGB_AMD;
import js.webgl.WebGLCompressedTextureATC_RGBA_AMD;
import js.webgl.WebGLCompressedTextureS3TC_DXT1_EXT;
import js.webgl.WebGLCompressedTextureS3TC_DXT3_EXT;
import js.webgl.WebGLCompressedTextureS3TC_DXT5_EXT;
import js.webgl.WebGLCompressedTextureETC1_EXT;
import js.webgl.WebGLCompressedTextureETC2_EXT;
import js.webgl.WebGLCompressedTextureBPTC_RGBA_EXT;
import js.webgl.WebGLCompressedTextureBPTC_SRGB_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_RGB_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_RGBA_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_4BPPV1_EXT;
import js.webgl.WebGLCompressedTexturePVRTC_2BPPV1_EXT;
import js.webgl.WebGLCompressedTextureASTC_LDR_EXT;
import js.webgl.WebGLCompressedTextureASTC_HDR_EXT;
import js.webgl.WebGLCompressedTextureATC_RGB_AMD_EXT;
import js.webgl.WebGLCompressedTextureATC_RGBA_AMD_EXT;
import haxe.ds.EnumValueMap;
import haxe.ds.Option;
import haxe.ds.StringMap;
import haxe.ds.StringIntMap;
import haxe.ds.Null<T>;
import haxe.ds.Option;
import haxe.rtti.EnumType;
import haxe.rtti.Type;
import haxe.rtti.Reflect;
import haxe.rtti.DynamicAccess;
import haxe.rtti.EnumValue;
import haxe.ds.ObjectMap;
import haxe.ds.StringSet;
import haxe.io.Bytes;
import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Output;
import js.html.CanvasRenderingContext2D;
import js.html.ImageData;
import js.typedarrays.ArrayBuffer;
import js.typedarrays.ArrayBufferView;
import js.typedarrays.DataView;
import js.typedarrays.ArrayBufferView;
import js.typedarrays.Uint8Array;
import js.typedarrays.Int8Array;
import js.typedarrays.Uint16Array;
import js.typedarrays.Int16Array;
import js.typedarrays.Uint32Array;
import js.typedarrays.Int32Array;
import js.typedarrays.Float32Array;
import js.typedarrays.Float64Array;
import js.typedarrays.Uint8ClampedArray;
import js.typedarrays.DataView;

class WebGLTextures {

	private static function resizeImage(image:Dynamic, needsNewCanvas:Bool, maxSize:Int):Dynamic {
		var scale:Float = 1;
		var dimensions:Dynamic = getDimensions(image);
		if (dimensions.width > maxSize || dimensions.height > maxSize) {
			scale = maxSize / Math.max(dimensions.width, dimensions.height);
		}
		if (scale < 1) {
			if (
				(Type.getClassName(image) == "HTMLImageElement") ||
				(Type.getClassName(image) == "HTMLCanvasElement") ||
				(Type.getClassName(image) == "ImageBitmap") ||
				(Type.getClassName(image) == "VideoFrame")
			) {
				var width:Int = Math.floor(scale * dimensions.width);
				var height:Int = Math.floor(scale * dimensions.height);
				if (_canvas === undefined) _canvas = createCanvas(width, height);
				var canvas:CanvasElement = needsNewCanvas ? createCanvas(width, height) : _canvas;
				canvas.width = width;
				canvas.height = height;
				var context:CanvasRenderingContext2D = canvas.getContext("2d");
				context.drawImage(image, 0, 0, width, height);
				return canvas;
			} else {
				if ("data" in image) {
					console.warn("THREE.WebGLRenderer: Image in DataTexture is too big (" + dimensions.width + "x" + dimensions.height + ").");
				}
				return image;
			}
		}
		return image;
	}

	private static function getDimensions(image:Dynamic):Dynamic {
		if (Type.getClassName(image) == "HTMLImageElement") {
			// if intrinsic data are not available, fallback to width/height
			return {width: image.naturalWidth || image.width, height: image.naturalHeight || image.height};
		} else if (Type.getClassName(image) == "VideoFrame") {
			return {width: image.displayWidth, height: image.displayHeight};
		} else {
			return {width: image.width, height: image.height};
		}
	}

	// ...

}
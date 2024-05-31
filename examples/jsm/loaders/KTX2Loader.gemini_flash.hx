package;

import three.Textures.CompressedTexture;
import three.Textures.CompressedArrayTexture;
import three.Textures.CompressedCubeTexture;
import three.Textures.Data3DTexture;
import three.Textures.DataTexture;
import three.Textures.PixelFormat;
import three.Textures.TextureDataType;
import three.Loaders.Loader;
import three.Loaders.FileLoader;
import three.Core.ColorSpace;
import three.Constants.TextureFilter;
import three.Three;
import js.lib.Promise;
import js.html.Uint8Array;
import js.html.ArrayBuffer;
import js.html.URL;
import js.html.Blob;
import js.html.Worker;

#if three_jsm_utils_workerpool
import three.jsm.utils.WorkerPool;
#end

#if three_jsm_libs_ktx_parse
import three.jsm.libs.KTXParse.KHR_DF_FLAG_ALPHA_PREMULTIPLIED;
import three.jsm.libs.KTXParse.KHR_DF_TRANSFER_SRGB;
import three.jsm.libs.KTXParse.KHR_SUPERCOMPRESSION_NONE;
import three.jsm.libs.KTXParse.KHR_SUPERCOMPRESSION_ZSTD;
import three.jsm.libs.KTXParse.VK_FORMAT_UNDEFINED;
import three.jsm.libs.KTXParse.VK_FORMAT_R16_SFLOAT;
import three.jsm.libs.KTXParse.VK_FORMAT_R16G16_SFLOAT;
import three.jsm.libs.KTXParse.VK_FORMAT_R16G16B16A16_SFLOAT;
import three.jsm.libs.KTXParse.VK_FORMAT_R32_SFLOAT;
import three.jsm.libs.KTXParse.VK_FORMAT_R32G32_SFLOAT;
import three.jsm.libs.KTXParse.VK_FORMAT_R32G32B32A32_SFLOAT;
import three.jsm.libs.KTXParse.VK_FORMAT_R8_SRGB;
import three.jsm.libs.KTXParse.VK_FORMAT_R8_UNORM;
import three.jsm.libs.KTXParse.VK_FORMAT_R8G8_SRGB;
import three.jsm.libs.KTXParse.VK_FORMAT_R8G8_UNORM;
import three.jsm.libs.KTXParse.VK_FORMAT_R8G8B8A8_SRGB;
import three.jsm.libs.KTXParse.VK_FORMAT_R8G8B8A8_UNORM;
import three.jsm.libs.KTXParse.VK_FORMAT_ASTC_6x6_SRGB_BLOCK;
import three.jsm.libs.KTXParse.VK_FORMAT_ASTC_6x6_UNORM_BLOCK;
import three.jsm.libs.KTXParse.KHR_DF_PRIMARIES_UNSPECIFIED;
import three.jsm.libs.KTXParse.KHR_DF_PRIMARIES_BT709;
import three.jsm.libs.KTXParse.KHR_DF_PRIMARIES_DISPLAYP3;
import three.jsm.libs.KTXParse.read;
#end

#if three_jsm_libs_zstddec
import three.jsm.libs.ZSTDDec.ZSTDDecoder;
#end

@:jsRequire("three/examples/jsm/loaders/KTX2Loader")
extern class KTX2Loader extends Loader {
	function new(?manager:Dynamic);

	function setTranscoderPath(path:String):KTX2Loader;

	#if three_jsm_utils_workerpool
	function setWorkerLimit(num:Int):KTX2Loader;
	#end

	function detectSupportAsync(renderer:Three.WebGLRenderer):Promise<KTX2Loader>;

	function detectSupport(renderer:Three.WebGLRenderer):KTX2Loader;

	function init():Promise<Void>;

	function load(url:String, ?onLoad:CompressedTexture->Void, ?onProgress:Dynamic->Void, ?onError:Dynamic->Void):Void;

	function dispose():KTX2Loader;

	static var BasisFormat(default, null):{
		var ETC1S:Int;
		var UASTC_4x4:Int;
	};

	static var TranscoderFormat(default, null):{
		var ETC1:Int;
		var ETC2:Int;
		var BC1:Int;
		var BC3:Int;
		var BC4:Int;
		var BC5:Int;
		var BC7_M6_OPAQUE_ONLY:Int;
		var BC7_M5:Int;
		var PVRTC1_4_RGB:Int;
		var PVRTC1_4_RGBA:Int;
		var ASTC_4x4:Int;
		var ATC_RGB:Int;
		var ATC_RGBA_INTERPOLATED_ALPHA:Int;
		var RGBA32:Int;
		var RGB565:Int;
		var BGR565:Int;
		var RGBA4444:Int;
	};

	static var EngineFormat(default, null):{
		var RGBAFormat:PixelFormat;
		var RGBA_ASTC_4x4_Format:PixelFormat;
		var RGBA_BPTC_Format:PixelFormat;
		var RGBA_ETC2_EAC_Format:PixelFormat;
		var RGBA_PVRTC_4BPPV1_Format:PixelFormat;
		var RGBA_S3TC_DXT5_Format:PixelFormat;
		var RGB_ETC1_Format:PixelFormat;
		var RGB_ETC2_Format:PixelFormat;
		var RGB_PVRTC_4BPPV1_Format:PixelFormat;
		var RGBA_S3TC_DXT1_Format:PixelFormat;
	};
}
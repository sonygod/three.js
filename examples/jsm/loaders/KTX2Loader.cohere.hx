/**
 * Loader for KTX 2.0 GPU Texture containers.
 *
 * KTX 2.0 is a container format for various GPU texture formats. The loader
 * supports Basis Universal GPU textures, which can be quickly transcoded to
 * a wide variety of GPU texture compression formats, as well as some
 * uncompressed DataTexture and Data3DTexture formats.
 *
 * References:
 * - KTX: http://github.khronos.org/KTX-Specification/
 * - DFD: https://www.khronos.org/registry/DataFormat/specs/1.3/dataformat.1.3.html#basicdescriptor
 */

import js.three.*;
import js.three.loaders.FileLoader;
import js.three.loaders.Loader;
import js.three.textures.CompressedTexture;
import js.three.textures.CompressedArrayTexture;
import js.three.textures.CompressedCubeTexture;
import js.three.textures.Data3DTexture;
import js.three.textures.DataTexture;
import js.three.textures.DisplayP3ColorSpace;
import js.three.textures.Filter;
import js.three.textures.FloatType;
import js.three.textures.HalfFloatType;
import js.three.textures.LinearDisplayP3ColorSpace;
import js.three.textures.LinearFilter;
import js.three.textures.LinearMipmapLinearFilter;
import js.three.textures.LinearSRGBColorSpace;
import js.three.textures.NoColorSpace;
import js.three.textures.RedFormat;
import js.three.textures.RGB_ETC1_Format;
import js.three.textures.RGB_ETC2_Format;
import js.three.textures.RGB_PVRTC_4BPPV1_Format;
import js.three.textures.RGBA_ASTC_4x4_Format;
import js.three.textures.RGBA_ASTC_6x6_Format;
import js.three.textures.RGBA_BPTC_Format;
import js.three.textures.RGBA_ETC2_EAC_Format;
import js.three.textures.RGBA_PVRTC_4BPPV1_Format;
import js.three.textures.RGBA_S3TC_DXT1_Format;
import js.three.textures.RGBA_S3TC_DXT5_Format;
import js.three.textures.RGBAFormat;
import js.three.textures.RGFormat;
import js.three.textures.SRGBColorSpace;
import js.three.textures.UnsignedByteType;

import js.three.utils.WorkerPool;

import js.libs.ktx_parse.*;
import js.libs.zstddec.ZSTDDecoder;

class KTX2Loader extends Loader {

	var _taskCache:WeakMap<ArrayBuffer, { promise:Promise<CompressedTexture|CompressedArrayTexture|DataTexture|Data3DTexture> }>;
	static var _activeLoaders:Int;
	static var _zstd:ZSTDDecoder;

	public function new(manager:LoaderManager) {
		super(manager);
		_taskCache = new WeakMap();
		this.transcoderPath = '';
		this.transcoderBinary = null;
		this.transcoderPending = null;
		this.workerPool = new WorkerPool();
		this.workerSourceURL = '';
		this.workerConfig = null;
	}

	public function setTranscoderPath(path:String):KTX2Loader {
		this.transcoderPath = path;
		return this;
	}

	public function setWorkerLimit(num:Int):KTX2Loader {
		this.workerPool.setWorkerLimit(num);
		return this;
	}

	public async function detectSupportAsync(renderer:WebGLRenderer):KTX2Loader {
		this.workerConfig = {
			astcSupported: await renderer.hasFeatureAsync('texture-compression-astc'),
			etc1Supported: await renderer.hasFeatureAsync('texture-compression-etc1'),
			etc2Supported: await renderer.hasFeatureAsync('texture-compression-etc2'),
			dxtSupported: await renderer.hasFeatureAsync('texture-compression-bc'),
			bptcSupported: await renderer.hasFeatureAsync('texture-compression-bptc'),
			pvrtcSupported: await renderer.hasFeatureAsync('texture-compression-pvrtc')
		};
		return this;
	}

	public function detectSupport(renderer:WebGLRenderer):KTX2Loader {
		if (renderer.isWebGPURenderer) {
			this.workerConfig = {
				astcSupported: renderer.hasFeature('texture-compression-astc'),
				etc1Supported: renderer.hasFeature('texture-compression-etc1'),
				etc2Supported: renderer.hasFeature('texture-compression-etc2'),
				dxtSupported: renderer.hasFeature('texture-compression-bc'),
				bptcSupported: renderer.hasFeature('texture-compression-bptc'),
				pvrtcSupported: renderer.hasFeature('texture-compression-pvrtc')
			};
		} else {
			this.workerConfig = {
				astcSupported: renderer.extensions.has('WEBGL_compressed_texture_astc'),
				etc1Supported: renderer.extensions.has('WEBGL_compressed_texture_etc1'),
				etc2Supported: renderer.extensions.has('WEBGL_compressed_texture_etc'),
				dxtSupported: renderer.extensions.has('WEBGL_compressed_texture_s3tc'),
				bptcSupported: renderer.extensions.has('EXT_texture_compression_bptc'),
				pvrtcSupported: renderer.extensions.has('WEBGL_compressed_texture_pvrtc')
					|| renderer.extensions.has('WEBKIT_WEBGL_compressed_texture_pvrtc')
			};
		}
		return this;
	}

	public function init():Promise<Void> {
		if (!this.transcoderPending) {
			// Load transcoder wrapper.
			var jsLoader = new FileLoader(this.manager);
			jsLoader.setPath(this.transcoderPath);
			jsLoader.setWithCredentials(this.withCredentials);
			var jsContent = jsLoader.loadAsync('basis_transcoder.js');

			// Load transcoder WASM binary.
			var binaryLoader = new FileLoader(this.manager);
			binaryLoader.setPath(this.transcoderPath);
			binaryLoader.setResponseType('arraybuffer');
			binaryLoader.setWithCredentials(this.withCredentials);
			var binaryContent = binaryLoader.loadAsync('basis_transcoder.wasm');

			this.transcoderPending = Promise.all([jsContent, binaryContent])
				.then(function(results) {
					var [jsContent, binaryContent] = results;
					var fn = KTX2Loader.BasisWorker.toString();
					var body = [
						'/* constants */',
						'let _EngineFormat = ' + Std.string(KTX2Loader.EngineFormat) + ';',
						'let _TranscoderFormat = ' + Std.string(KTX2Loader.TranscoderFormat) + ';',
						'let _BasisFormat = ' + Std.string(KTX2Loader.BasisFormat) + ';',
						'/* basis_transcoder.js */',
						jsContent,
						'/* worker */',
						fn.substring(fn.indexOf('{') + 1, fn.lastIndexOf('}'))
					].join('\n');

					var blob = new Blob([body]);
					this.workerSourceURL = URL.createObjectURL(blob);
					this.transcoderBinary = binaryContent;

					this.workerPool.setWorkerCreator(function() {
						var worker = new Worker(this.workerSourceURL);
						var transcoderBinary = this.transcoderBinary.slice(0);

						worker.postMessage({
							type: 'init',
							config: this.workerConfig,
							transcoderBinary
						}, [transcoderBinary]);

						return worker;
					});
				});

			if (_activeLoaders > 0) {
				// Each instance loads a transcoder and allocates workers, increasing network and memory cost.
				trace(
					'THREE.KTX2Loader: Multiple active KTX2 loaders may cause performance issues.'
					+ ' Use a single KTX2Loader instance, or call .dispose() on old instances.'
				);
			}

			_activeLoaders++;
		}

		return this.transcoderPending;
	}

	public function load(
		url:String,
		onLoad:(texture:CompressedTexture|CompressedArrayTexture|DataTexture|Data3DTexture)->Void,
		onProgress:Float->Void,
		onError:Dynamic->Void
	):Void {
		if (this.workerConfig == null) {
			throw new Error('THREE.KTX2Loader: Missing initialization with `.detectSupport( renderer )`.');
		}

		var loader = new FileLoader(this.manager);
		loader.setResponseType('arraybuffer');
		loader.setWithCredentials(this.withCredentials);

		loader.load(url, function(buffer) {
			// Check for an existing task using this buffer. A transferred buffer cannot be transferred
			// again from this thread.
			if (_taskCache.has(buffer)) {
				var cachedTask = _taskCache.get(buffer);
				return cachedTask.promise.then(onLoad).catch(onError);
			}

			this._createTexture(buffer)
				.then(function(texture) {
					if (onLoad != null) {
						onLoad(texture);
					}
				})
				.catch(onError);
		}, onProgress, onError);
	}

	function _createTextureFrom(
		transcodeResult:{
			faces:Array<{}>,
			width:Int,
			height:Int,
			format:Int,
			type:String,
			error:String,
			dfdFlags:Int
		},
		container:KTX2Container
	):Promise<CompressedTexture|CompressedArrayTexture|DataTexture|Data3DTexture> {
		var { faces, width, height, format, type, error, dfdFlags } = transcodeResult;

		if (type == 'error') {
			return Promise.reject(error);
		}

		var texture:CompressedTexture|CompressedArrayTexture|DataTexture|Data3DTexture;

		if (container.faceCount == 6) {
			texture = new CompressedCubeTexture(faces, format, UnsignedByteType);
		} else {
			var mipmaps = faces[0].mipmaps;

			texture = container.layerCount > 1
				? new CompressedArrayTexture(mipmaps, width, height, container.layerCount, format, UnsignedByteType)
				: new CompressedTexture(mipmaps, width, height, format, UnsignedByteType);
		}

		texture.minFilter = faces[0].mipmaps.length == 1 ? LinearFilter : LinearMipmapLinearFilter;
		texture.magFilter = LinearFilter;
		texture.generateMipmaps = false;

		texture.needsUpdate = true;
		texture.colorSpace = parseColorSpace(container);
		texture.premultiplyAlpha = (dfdFlags & KHR_DF_FLAG_ALPHA_PREMULTIPLIED) != 0;

		return Promise.resolve(texture);
	}

	/**
	 * @param {ArrayBuffer} buffer
	 * @param {object?} config
	 * @return {Promise<CompressedTexture|CompressedArrayTexture|DataTexture|Data3DTexture>}
	 */
	async function _createTexture(
		buffer:ArrayBuffer,
		config:Map<String, Dynamic> = {}
	):Promise<CompressedTexture|CompressedArrayTexture|DataTexture|Data3DTexture> {
		var container = read(new Uint8Array(buffer));

		if (container.vkFormat != VK_FORMAT_UNDEFINED) {
			return createRawTexture(container);
		}

		//
		var taskConfig = config;
		var texturePending = this.init().then(function() {
			return this.workerPool.postMessage({
				type: 'transcode',
				buffer: buffer,
				taskConfig: taskConfig
			}, [buffer]);
		}).then(function(e) {
			return this._createTextureFrom(e.data, container);
		});

		// Cache the task result.
		_taskCache.set(buffer, { promise: texturePending });

		return texturePending;
	}

	function dispose():KTX2Loader {
		this.workerPool.dispose();
		if (this.workerSourceURL != '') {
			URL.revokeObjectURL(this.workerSourceURL);
		}

		_activeLoaders--;

		return this;
	}

	static var BasisFormat:Map<String, Int> = {
		ETC1S: 0,
		UASTC_4x4: 1,
	};

	static var TranscoderFormat:Map<String, Int> = {
		ETC1: 0,
		ETC2: 1,
		BC1: 2,
		BC3: 3,
		BC4: 4,
		BC5: 5,
		BC7_M6_OPAQUE_ONLY: 6,
		BC7_M5: 7,
		PVRTC1_4_RGB: 8,
		PVRTC1_4_RGBA: 9,
		ASTC_4x4: 10,
		ATC_RGB: 11,
		ATC_RGBA_INTERPOLATED_ALPHA: 12,
		RGBA32: 13,
		RGB565: 14,
		BGR565: 15,
		RGBA4444: 16,
	};

	static var EngineFormat:Map<String, Int> = {
		RGBAFormat: RGBAFormat,
		RGBA_ASTC_4x4_Format: RGBA_ASTC_4x4_Format,
		RGBA_BPTC_Format: RGBA_BPTC_Format,
		RGBA_ETC2_EAC_Format: RGBA_ETC2_EAC_Format,
		RGBA_PVRTC_4BPPV1_Format: RGBA_PVRTC_4BPPV1_Format,
		RGBA_S3TC_DXT5_Format: RGBA_S3TC_DXT5_Format,
		RGB_ETC1_Format: RGB_ETC1_Format,
		RGB_ETC2_Format: RGB_ETC2_Format,
		RGB_PVRTC_4BPPV1_Format: RGB_PVRTC_4BPPV1_Format,
		RGBA_S3TC_DXT1_Format: RGBA_S3TC_DXT1_Format,
	};

	static function BasisWorker():Void {
		var config:Map<String, Bool>;
		var transcoderPending:Promise<Void>;
		var BasisModule:Dynamic;

		self.addEventListener('message', function(e) {
			var message = e.data;

			switch (message.type) {
				case 'init':
					config = message.config;
					init(message.transcoderBinary);
					break;

				case 'transcode':
					transcoderPending.then(function() {
						try {
							var {
								faces,
								buffers,
								width,
								height,
								hasAlpha,
								format,
								dfdFlags
							} = transcode(message.buffer);

							self.postMessage({
								type: 'transcode',
								id: message.id,
								faces: faces,
								width: width,
								height: height,
								hasAlpha: hasAlpha,
								format: format,
								dfdFlags: dfdFlags
							}, buffers);
						} catch (error) {
							self.postMessage({
								type: 'error',
								id: message.id,
								error: error.message
							});
						}
					});
					break;
			}
		});

		function init(wasmBinary:ArrayBuffer):Void {
			transcoderPending = new Promise(function(resolve) {
				BasisModule = {
					wasmBinary: wasmBinary,
					onRuntimeInitialized: resolve
				};
				BASIS(BasisModule);
			}).then(function() {
				BasisModule.initializeBasis();

				if (BasisModule.KTX2File == null) {
					trace('THREE.KTX2Loader: Please update Basis Universal transcoder.');
				}
			});
		}

		function transcode(buffer:ArrayBuffer):Map<String, Dynamic> {
			var ktx2File = new BasisModule.KTX2File(new Uint8Array(buffer));

			function cleanup():Void {
				ktx2File.close();
				ktx2File.delete();
			}

			if (!ktx2File.isValid()) {
				cleanup();
				throw new Error('THREE.KTX2Loader:	Invalid or unsupported .ktx2 file');
			}

			var basisFormat = ktx2File.isUASTC() ? BasisFormat.UASTC_4x4 : BasisFormat.ETC1S;
			var width = ktx2File.getWidth();
			var height = ktx2File.getHeight();
			var layerCount = ktx2File.getLayers
	var layerCount = ktx2File.getLayers() || 1;
	var levelCount = ktx2File.getLevels();
	var faceCount = ktx2File.getFaces();
	var hasAlpha = ktx2File.getHasAlpha();
	var dfdFlags = ktx2File.getDFDFlags();

	if (width == 0 || height == 0 || levelCount == 0) {
		cleanup();
		throw new Error('THREE.KTX2Loader:	Invalid texture');
	}

	if (!ktx2File.startTranscoding()) {
		cleanup();
		throw new Error('THREE.KTX2Loader: .startTranscoding failed');
	}

	var faces = [];
	var buffers = [];

	for (var face = 0; face < faceCount; face++) {
		var mipmaps = [];

		for (var mip = 0; mip < levelCount; mip++) {
			var layerMips = [];

			var mipWidth, mipHeight;

			for (var layer = 0; layer < layerCount; layer++) {
				var levelInfo = ktx2File.getImageLevelInfo(mip, layer, face);

				if (face == 0 && mip == 0 && layer == 0 && (levelInfo.origWidth % 4 != 0 || levelInfo.origHeight % 4 != 0)) {
					trace('THREE.KTX2Loader: ETC1S and UASTC textures should use multiple-of-four dimensions.');
				}

				if (levelCount > 1) {
					mipWidth = levelInfo.origWidth;
					mipHeight = levelInfo.origHeight;
				} else {
					// Handles non-multiple-of-four dimensions in textures without mipmaps. Textures with
					// mipmaps must use multiple-of-four dimensions, for some texture formats and APIs.
					// See mrdoob/three.js#25908.
					mipWidth = levelInfo.width;
					mipHeight = levelInfo.height;
				}

				var dst = new Uint8Array(ktx2File.getImageTranscodedSizeInBytes(mip, layer, 0, transcoderFormat));
				var status = ktx2File.transcodeImage(dst, mip, layer, face, transcoderFormat, 0, -1, -1);

				if (!status) {
					cleanup();
					throw new Error('THREE.KTX2Loader: .transcodeImage failed.');
				}

				layerMips.push(dst);
			}

			var mipData = concat(layerMips);

			mipmaps.push({
				data: mipData,
				width: mipWidth,
				height: mipHeight
			});
			buffers.push(mipData.buffer);
		}

		faces.push({
			mipmaps: mipmaps,
			width: width,
			height: height,
			format: engineFormat
		});
	}

	cleanup();

	return {
		faces: faces,
		buffers: buffers,
		width: width,
		height: height,
		hasAlpha: hasAlpha,
		format: engineFormat,
		dfdFlags: dfdFlags
	};
}

//

// Optimal choice of a transcoder target format depends on the Basis format (ETC1S or UASTC),
// device capabilities, and texture dimensions. The list below ranks the formats separately
// for ETC1S and UASTC.
//
// In some cases, transcoding UASTC to RGBA32 might be preferred for higher quality (at
// significant memory cost) compared to ETC1/2, BC1/3, and PVRTC. The transcoder currently
// chooses RGBA32 only as a last resort and does not expose that option to the caller.
var FORMAT_OPTIONS = [
	{
		if: 'astcSupported',
		basisFormat: [BasisFormat.UASTC_4x4],
		transcoderFormat: [TranscoderFormat.ASTC_4x4, TranscoderFormat.ASTC_4x4],
		engineFormat: [EngineFormat.RGBA_ASTC_4x4_Format, EngineFormat.RGBA_ASTC_4x4_Format],
		priorityETC1S: Infinity,
		priorityUASTC: 1,
		needsPowerOfTwo: false,
	},
	{
		if: 'bptcSupported',
		basisFormat: [BasisFormat.ETC1S, BasisFormat.UASTC_4x4],
		transcoderFormat: [TranscoderFormat.BC7_M5, TranscoderFormat.BC7_M5],
		engineFormat: [EngineFormat.RGBA_BPTC_Format, EngineFormat.RGBA_BPTC_Format],
		priorityETC1S: 3,
		priorityUASTC: 2,
		needsPowerOfTwo: false,
	},
	{
		if: 'dxtSupported',
		basisFormat: [BasisFormat.ETC1S, BasisFormat.UASTC_4x4],
		transcoderFormat: [TranscoderFormat.BC1, TranscoderFormat.BC3],
		engineFormat: [EngineFormat.RGBA_S3TC_DXT1_Format, EngineFormat.RGBA_S3TC_DXT5_Format],
		priorityETC1S: 4,
		priorityUASTC: 5,
		needsPowerOfTwo: false,
	},
	{
		if: 'etc2Supported',
		basisFormat: [BasisFormat.ETC1S, BasisFormat.UASTC_4x4],
		transcoderFormat: [TranscoderFormat.ETC1, TranscoderFormat.ETC2],
		engineFormat: [EngineFormat.RGB_ETC2_Format, EngineFormat.RGBA_ETC2_EAC_Format],
		priorityETC1S: 1,
		priorityUASTC: 3,
		needsPowerOfTwo: false,
	},
	{
		if: 'etc1Supported',
		basisFormat: [BasisFormat.ETC1S, BasisFormat.UASTC_4x4],
		transcoderFormat: [TranscoderFormat.ETC1],
		engineFormat: [EngineFormat.RGB_ETC1_Format],
		priorityETC1S: 2,
		priorityUASTC: 4,
		needsPowerOfTwo: false,
	},
	{
		if: 'pvrtcSupported',
		basisFormat: [BasisFormat.ETC1S, BasisFormat.UASTC_4x4],
		transcoderFormat: [TranscoderFormat.PVRTC1_4_RGB, TranscoderFormat.PVRTC1_4_RGBA],
		engineFormat: [EngineFormat.RGB_PVRTC_4BPPV1_Format, EngineFormat.RGBA_PVRTC_4BPPV1_Format],
		priorityETC1S: 5,
		priorityUASTC: 6,
		needsPowerOfTwo: true,
	},
];

var ETC1S_OPTIONS = FORMAT_OPTIONS.sort(function(a, b) {
	return a.priorityETC1S - b.priorityETC1S;
});
var UASTC_OPTIONS = FORMAT_OPTIONS.sort(function(a, b) {
	return a.priorityUASTC - b.priorityUASTC;
});

function getTranscoderFormat(
	basisFormat:Int,
	width:Int,
	height:Int,
	hasAlpha:Bool
):Map<String, Int> {
	var transcoderFormat, engineFormat;

	var options = basisFormat == BasisFormat.ETC1S ? ETC1S_OPTIONS : UASTC_OPTIONS;

	for (var i = 0; i < options.length; i++) {
		var opt = options[i];

		if (!config.exists(opt.if)) continue;
		if (!opt.basisFormat.includes(basisFormat)) continue;
		if (hasAlpha && opt.transcoderFormat.length < 2) continue;
		if (opt.needsPowerOfTwo && !(isPowerOfTwo(width) && isPowerOfTwo(height))) continue;

		transcoderFormat = opt.transcoderFormat[hasAlpha ? 1 : 0];
		engineFormat = opt.engineFormat[hasAlpha ? 1 : 0];

		return {
			transcoderFormat: transcoderFormat,
			engineFormat: engineFormat
		};
	}

	trace('THREE.KTX2Loader: No suitable compressed texture format found. Decoding to RGBA32.');

	transcoderFormat = TranscoderFormat.RGBA32;
	engineFormat = EngineFormat.RGBAFormat;

	return {
		transcoderFormat: transcoderFormat,
		engineFormat: engineFormat
	};
}

function isPowerOfTwo(value:Int):Bool {
	if (value <= 2) return true;

	return (value & (value - 1)) == 0 && value != 0;
}

/** Concatenates N byte arrays. */
function concat(arrays:Array<Uint8Array>):Uint8Array {
	if (arrays.length == 1) return arrays[0];

	var totalByteLength = 0;

	for (var i = 0; i < arrays.length; i++) {
		var array = arrays[i];
		totalByteLength += array.byteLength;
	}

	var result = new Uint8Array(totalByteLength);

	var byteOffset = 0;

	for (var i = 0; i < arrays.length; i++) {
		var array = arrays[i];
		result.set(array, byteOffset);

		byteOffset += array.byteLength;
	}

	return result;
}
}

//
// Parsing for non-Basis textures. These textures are may have supercompression
// like Zstd, but they do not require transcoding.

var UNCOMPRESSED_FORMATS = new Set([RGBAFormat, RGFormat, RedFormat]);

var FORMAT_MAP = {
	[VK_FORMAT_R32G32B32A32_SFLOAT]: RGBAFormat,
	[VK_FORMAT_R16G16B16A16_SFLOAT]: RGBAFormat,
	[VK_FORMAT_R8G8B8A8_UNORM]: RGBAFormat,
	[VK_FORMAT_R8G8B8A8_SRGB]: RGBAFormat,

	[VK_FORMAT_R32G32_SFLOAT]: RGFormat,
	[VK_FORMAT_R16G16_SFLOAT]: RGFormat,
	[VK_FORMAT_R8G8_UNORM]: RGFormat,
	[VK_FORMAT_R8G8_SRGB]: RGFormat,

	[VK_FORMAT_R32_SFLOAT]: RedFormat,
	[VK_FORMAT_R16_SFLOAT]: RedFormat,
	[VK_FORMAT_R8_SRGB]: RedFormat,
	[VK_FORMAT_R8_UNORM]: RedFormat,

	[VK_FORMAT_ASTC_6x6_SRGB_BLOCK]: RGBA_ASTC_6x6_Format,
	[VK_FORMAT_ASTC_6x6_UNORM_BLOCK]: RGBA_ASTC_6x6_Format,

};

var TYPE_MAP = {
	[VK_FORMAT_R32G32B32A32_SFLOAT]: FloatType,
	[VK_FORMAT_R16G16B16A16_SFLOAT]: HalfFloatType,
	[VK_FORMAT_R8G8B8A8_UNORM]: UnsignedByteType,
	[VK_FORMAT_R8G8B8A8_SRGB]: UnsignedByteType,

	[VK_FORMAT_R32G32_SFLOAT]: FloatType,
	[VK_FORMAT_R16G16_SFLOAT]: HalfFloatType,
	[VK_FORMAT_R8G8_UNORM]: UnsignedByteType,
	[VK_FORMAT_R8G8_SRGB]: UnsignedByteType,

	[VK_FORMAT_R32_SFLOAT]: FloatType,
	[VK_FORMAT_R16_SFLOAT]: HalfFloatType,
	[VK_FORMAT_R8_SRGB]: UnsignedByteType,
	[VK_FORMAT_R8_UNORM]: UnsignedByteType,

	[VK_FORMAT_ASTC_6x6_SRGB_BLOCK]: UnsignedByteType,
	[VK_FORMAT_ASTC_6x6_UNORM_BLOCK]: UnsignedByteType,

};

async function createRawTexture(container:KTX2Container):Promise<CompressedTexture|CompressedArrayTexture|DataTexture|Data3DTexture> {
	var { vkFormat } = container;

	if (!FORMAT_MAP.exists(vkFormat)) {
		throw new Error('THREE.KTX2Loader: Unsupported vkFormat.');
	}

	//

	var zstd:ZSTDDecoder;

	if (container.supercompressionScheme == KHR_SUPERCOMPRESSION_ZSTD) {
		if (_zstd == null) {
			_zstd = new Promise(async function(resolve) {
				var zstd = new ZSTDDecoder();
				await zstd.init();
				resolve(zstd);
			});
		}

		zstd = await _zstd;
	}

	//

	var mipmaps = [];

	for (var levelIndex = 0; levelIndex < container.levels.length; levelIndex++) {
		var levelWidth = Math.max(1, container.pixelWidth >> levelIndex);
		var levelHeight = Math.max(1, container.pixelHeight >> levelIndex);
		var levelDepth = container.pixelDepth != 0 ? Math.max(1, container.pixelDepth >> levelIndex) : 0;

		var level = container.levels[levelIndex];

		var levelData;

		if (container.supercompressionScheme == KHR_SUPERCOMPRESSION_NONE) {
			levelData = level.levelData;
		} else if (container.supercompressionScheme == KHR_SUPERCOMPRESSION_ZSTD) {
			levelData = zstd.decode(level.levelData, level.uncompressedByteLength);
		} else {
			throw new Error('THREE.KTX2Loader: Unsupported supercompressionScheme.');
		}

		var data;

		if (TYPE_MAP[vkFormat] == FloatType) {
			data = new Float32Array(
				levelData.buffer,
				levelData.byteOffset,
				levelData.byteLength / Float32Array.BYTES_PER_ELEMENT
			);
		} else if (TYPE_MAP[vkFormat] == HalfFloatType) {
			data = new Uint16Array(
				levelData.buffer,
				levelData.byteOffset,
				levelData.byteLength / Uint16Array.BYTES_PER_ELEMENT
			);
		} else {
			data = levelData;
		}

		mipmaps.push({
			data: data,
			width: levelWidth,
			height: levelHeight,
			depth: levelDepth,
		});
	}

	var texture;

	if (UNCOMPRESSED_FORMATS.has(FORMAT_MAP[vkFormat])) {
		texture = container.pixelDepth == 0
			? new DataTexture(mipmaps[0].data, container.pixelWidth, container.pixelHeight)
			: new Data3DTexture(mipmaps[0].data, container.pixelWidth, container.pixelHeight, container.pixelDepth);
	} else {
		if (container.pixelDepth != 0) {
			throw new Error('THREE.KTX2Loader: Unsupported pixelDepth.');
		}

		texture = new CompressedTexture(mipmaps, container.pixelWidth, container.pixelHeight);
	}

	texture.mipmaps = mipmaps;

	texture.type = TYPE_MAP[vkFormat];
	texture.format = FORMAT_MAP[vkFormat];
	texture.colorSpace = parseColorSpace(container);
	texture.needsUpdate = true;

	//

	return Promise.resolve(texture);
}

function parseColorSpace(container:KTX2Container):ColorSpace {
	var dfd = container.dataFormatDescriptor[0];

	if (dfd.colorPrimaries == KHR_DF_PRIMARIES_BT709) {
		return dfd.transferFunction == KHR_DF_TRANSFER_SRGB ? SRGBColorSpace : LinearSRGBColorSpace;
	} else if (dfd.colorPrimaries == KHR_DF_PRIMARIES_DISPLAYP3) {
		return dfd.transferFunction == KHR_DF_TRANSFER_SRGB ? DisplayP3ColorSpace : LinearDisplayP3ColorSpace;
	} else if (dfd.colorPrimaries == KHR_DF_PRIMARIES_UNSPECIFIED) {
		return NoColorSpace;
	} else {
		trace(`THREE.KTX2Loader: Unsupported color primaries, "${dfd.colorPrimaries}"`);
		return NoColorSpace;
	}
}
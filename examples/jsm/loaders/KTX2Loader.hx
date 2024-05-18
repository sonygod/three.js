import three.textures.CompressedTexture;
import three.textures.CompressedArrayTexture;
import three.textures.CompressedCubeTexture;
import three.textures.Data3DTexture;
import three.textures.DataTexture;
import three.textures.DisplayP3ColorSpace;
import three.textures.FileLoader;
import three.textures.FloatType;
import three.textures.HalfFloatType;
import three.textures.NoColorSpace;
import three.textures.LinearFilter;
import three.textures.LinearMipmapLinearFilter;
import three.textures.LinearDisplayP3ColorSpace;
import three.textures.LinearSRGBColorSpace;
import three.textures.Loader;
import three.textures.RedFormat;
import three.textures.RGB_ETC1_Format;
import three.textures.RGB_ETC2_Format;
import three.textures.RGB_PVRTC_4BPPV1_Format;
import three.textures.RGBA_ASTC_4x4_Format;
import three.textures.RGBA_ASTC_6x6_Format;
import three.textures.RGBA_BPTC_Format;
import three.textures.RGBA_ETC2_EAC_Format;
import three.textures.RGBA_PVRTC_4BPPV1_Format;
import three.textures.RGBA_S3TC_DXT5_Format;
import three.textures.RGBA_S3TC_DXT1_Format;
import three.textures.RGBAFormat;
import three.textures.RGFormat;
import three.textures.SRGBColorSpace;
import three.textures.UnsignedByteType;
import utils.WorkerPool;
import ktx.KHR_DF_FLAG_ALPHA_PREMULTIPLIED;
import ktx.KHR_DF_TRANSFER_SRGB;
import ktx.KHR_SUPERCOMPRESSION_NONE;
import ktx.KHR_SUPERCOMPRESSION_ZSTD;
import ktx.VK_FORMAT_UNDEFINED;
import ktx.VK_FORMAT_R16_SFLOAT;
import ktx.VK_FORMAT_R16G16_SFLOAT;
import ktx.VK_FORMAT_R16G16B16A16_SFLOAT;
import ktx.VK_FORMAT_R32_SFLOAT;
import ktx.VK_FORMAT_R32G32_SFLOAT;
import ktx.VK_FORMAT_R32G32B32A32_SFLOAT;
import ktx.VK_FORMAT_R8_SRGB;
import ktx.VK_FORMAT_R8_UNORM;
import ktx.VK_FORMAT_R8G8_SRGB;
import ktx.VK_FORMAT_R8G8_UNORM;
import ktx.VK_FORMAT_R8G8B8A8_SRGB;
import ktx.VK_FORMAT_R8G8B8A8_UNORM;
import ktx.VK_FORMAT_ASTC_6x6_SRGB_BLOCK;
import ktx.VK_FORMAT_ASTC_6x6_UNORM_BLOCK;
import ktx.KHR_DF_PRIMARIES_UNSPECIFIED;
import ktx.KHR_DF_PRIMARIES_BT709;
import ktx.KHR_DF_PRIMARIES_DISPLAYP3;

class KTX2Loader extends Loader {
	transcoderPath:String;
	transcoderBinary:ArrayBuffer;
	transcoderPending:Future<Dynamic>;
	workerPool:WorkerPool;
	workerSourceURL:String;
	workerConfig:Dynamic;

	public function new(manager:Loader) {
		super(manager);
		this.transcoderPath = '';
		this.transcoderBinary = null;
		this.transcoderPending = null;
		this.workerPool = new WorkerPool();
		this.workerSourceURL = '';
		this.workerConfig = null;
		if (typeof MSC_TRANSCODER !== 'undefined') {
			console.warn(
				'THREE.KTX2Loader: Please update to latest "basis_transcoder".'
				+ '"msc_basis_transcoder" is no longer supported in three.js r125+.'
			);
		}
	}

	public function setTranscoderPath(path:String):KTX2Loader {
		this.transcoderPath = path;
		return this;
	}

	public function setWorkerLimit(num:Int):KTX2Loader {
		this.workerPool.setWorkerLimit(num);
		return this;
	}

	public function detectSupportAsync(renderer:Renderer):Future<Dynamic> {
		this.workerConfig = {
			astcSupported: Std.async(cb) => {
				renderer.hasFeatureAsync('texture-compression-astc').then(value => cb(value));
			},
			etc1Supported: Std.async(cb) => {
				renderer.hasFeatureAsync('texture-compression-etc1').then(value => cb(value));
			},
			etc2Supported: Std.async(cb) => {
				renderer.hasFeatureAsync('texture-compression-etc2').then(value => cb(value));
			},
			dxtSupported: Std.async(cb) => {
				renderer.hasFeatureAsync('texture-compression-bc').then(value => cb(value));
			},
			bptcSupported: Std.async(cb) => {
				renderer.hasFeatureAsync('texture-compression-bptc').then(value => cb(value));
			},
			pvrtcSupported: Std.async(cb) => {
				renderer.hasFeatureAsync('texture-compression-pvrtc').then(value => cb(value));
			}
		};
		return Promise.all(Type.getKeys(this.workerConfig).map(key => this.workerConfig[key]));
	}

	public function detectSupport(renderer:Renderer):KTX2Loader {
		if (renderer.isWebGPURenderer === true) {
			this.workerConfig = {
				astcSupported: renderer.hasFeature('texture-compression-astc'),
				etc1Supported: renderer.hasFeature('texture-compression-etc1'),
				etc2Supported: renderer.hasFeature('texture-compression-etc2'),
				dxtSupported: renderer.hasFeature('texture-compression-bc'),
				bptcSupported: renderer.hasFeature('texture-compression-bptc'),
				pvrtcSupported: renderer.hasFeature('texture-compression-pvrtc') ||
					renderer.hasFeature('WEBKIT_WEBGL_compressed_texture_pvrtc')
			};
		} else {
			this.workerConfig = {
				astcSupported: renderer.extensions.has('WEBGL_compressed_texture_astc'),
				etc1Supported: renderer.extensions.has('WEBGL_compressed_texture_etc1'),
				etc2Supported: renderer.extensions.has('WEBGL_compressed_texture_etc'),
				dxtSupported: renderer.extensions.has('WEBGL_compressed_texture_s3tc'),
				bptcSupported: renderer.extensions.has('EXT_texture_compression_bptc'),
				pvrtcSupported: renderer.extensions.has('WEBGL_compressed_texture_pvrtc') ||
					renderer.extensions.has('WEBKIT_WEBGL_compressed_texture_pvrtc')
			};
		}
		return this;
	}

	public function init():Future<Dynamic> {
		if (this.transcoderPending === null) {
			const jsLoader = new FileLoader(this.manager);
			jsLoader.setPath(this.transcoderPath);
			const jsContent = jsLoader.loadAsync('basis_transcoder.js');
			const binaryLoader = new FileLoader(this.manager);
			binaryLoader.setPath(this.transcoderPath);
			binaryLoader.setResponseType(ResponseType.ArrayBuffer);
			binaryLoader.setWithCredentials(this.withCredentials);
			const binaryContent = binaryLoader.loadAsync('basis_transcoder.wasm');
			this.transcoderPending = Promise.all([jsContent, binaryContent]).then(([jsContent, binaryContent]) => {
				const fn = KTX2Loader.BasisWorker.toString();
				const body = [
					'/* constants */',
					'let _EngineFormat = ' + JS.eval(jsContent).EngineFormat.toString(),
					'let _TranscoderFormat = ' + JS.eval(jsContent).TranscoderFormat.toString(),
					'let _BasisFormat = ' + JS.eval(jsContent).BasisFormat.toString(),
					'/* basis_transcoder.js */',
					jsContent,
					'/* worker */',
					fn.substring(fn.indexOf('{') + 1, fn.lastIndexOf('}'))
				].join('\n');
				this.workerSourceURL = URL.createObjectURL(new Blob([body]));
				this.transcoderBinary = binaryContent;
				this.workerPool.setWorkerCreator(() => {
					const worker = new Worker(this.workerSourceURL);
					const transcoderBinary = this.transcoderBinary.slice(0);
					worker.postMessage({ type: 'init', config: this.workerConfig, transcoderBinary }, [transcoderBinary]);
					return worker;
				});
			});
			if (_activeLoaders > 0) {
				console.warn(
					'THREE.KTX2Loader: Multiple active KTX2 loaders may cause performance issues.'
					+ ' Use a single KTX2Loader instance, or call .dispose() on old instances.'
				);
			}
			_activeLoaders++;
		}
		return this.transcoderPending;
	}

	public function load(url:String, onLoad:(texture:Dynamic)
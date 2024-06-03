import js.html.Worker;
import js.html.File;
import js.html.FileReader;
import js.html.Blob;

import three.CompressedTexture;
import three.CompressedArrayTexture;
import three.CompressedCubeTexture;
import three.Data3DTexture;
import three.DataTexture;
import three.DisplayP3ColorSpace;
import three.FileLoader;
import three.FloatType;
import three.HalfFloatType;
import three.NoColorSpace;
import three.LinearFilter;
import three.LinearMipmapLinearFilter;
import three.LinearDisplayP3ColorSpace;
import three.LinearSRGBColorSpace;
import three.Loader;
import three.RedFormat;
import three.RGB_ETC1_Format;
import three.RGB_ETC2_Format;
import three.RGB_PVRTC_4BPPV1_Format;
import three.RGBA_ASTC_4x4_Format;
import three.RGBA_ASTC_6x6_Format;
import three.RGBA_BPTC_Format;
import three.RGBA_ETC2_EAC_Format;
import three.RGBA_PVRTC_4BPPV1_Format;
import three.RGBA_S3TC_DXT5_Format;
import three.RGBA_S3TC_DXT1_Format;
import three.RGBAFormat;
import three.RGFormat;
import three.SRGBColorSpace;
import three.UnsignedByteType;

import WorkerPool from '../utils/WorkerPool';
import {
	read,
	KHR_DF_FLAG_ALPHA_PREMULTIPLIED,
	KHR_DF_TRANSFER_SRGB,
	KHR_SUPERCOMPRESSION_NONE,
	KHR_SUPERCOMPRESSION_ZSTD,
	VK_FORMAT_UNDEFINED,
	VK_FORMAT_R16_SFLOAT,
	VK_FORMAT_R16G16_SFLOAT,
	VK_FORMAT_R16G16B16A16_SFLOAT,
	VK_FORMAT_R32_SFLOAT,
	VK_FORMAT_R32G32_SFLOAT,
	VK_FORMAT_R32G32B32A32_SFLOAT,
	VK_FORMAT_R8_SRGB,
	VK_FORMAT_R8_UNORM,
	VK_FORMAT_R8G8_SRGB,
	VK_FORMAT_R8G8_UNORM,
	VK_FORMAT_R8G8B8A8_SRGB,
	VK_FORMAT_R8G8B8A8_UNORM,
	VK_FORMAT_ASTC_6x6_SRGB_BLOCK,
	VK_FORMAT_ASTC_6x6_UNORM_BLOCK,
	KHR_DF_PRIMARIES_UNSPECIFIED,
	KHR_DF_PRIMARIES_BT709,
	KHR_DF_PRIMARIES_DISPLAYP3
} from '../libs/ktx-parse.module.js';
import { ZSTDDecoder } from '../libs/zstddec.module.js';

class KTX2Loader extends Loader {
	public var transcoderPath:String = '';
	public var transcoderBinary:js.html.ArrayBuffer = null;
	public var transcoderPending:Promise<Void> = null;

	public var workerPool:WorkerPool = new WorkerPool();
	public var workerSourceURL:String = '';
	public var workerConfig:Dynamic = null;

	public function new() {
		super();
	}

	public function setTranscoderPath(path:String):KTX2Loader {
		this.transcoderPath = path;
		return this;
	}

	public function setWorkerLimit(num:Int):KTX2Loader {
		this.workerPool.setWorkerLimit(num);
		return this;
	}

	public async function detectSupportAsync(renderer:Dynamic):Promise<KTX2Loader> {
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

	public function detectSupport(renderer:Dynamic):KTX2Loader {
		if (renderer.isWebGPURenderer === true) {
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
				pvrtcSupported: renderer.extensions.has('WEBGL_compressed_texture_pvrtc') || renderer.extensions.has('WEBKIT_WEBGL_compressed_texture_pvrtc')
			};
		}

		return this;
	}

	public function init():Promise<Void> {
		if (this.transcoderPending == null) {
			// Load transcoder wrapper.
			let jsLoader:FileLoader = new FileLoader(this.manager);
			jsLoader.setPath(this.transcoderPath);
			jsLoader.setWithCredentials(this.withCredentials);
			let jsContent:Promise<String> = jsLoader.loadAsync('basis_transcoder.js');

			// Load transcoder WASM binary.
			let binaryLoader:FileLoader = new FileLoader(this.manager);
			binaryLoader.setPath(this.transcoderPath);
			binaryLoader.setResponseType('arraybuffer');
			binaryLoader.setWithCredentials(this.withCredentials);
			let binaryContent:Promise<js.html.ArrayBuffer> = binaryLoader.loadAsync('basis_transcoder.wasm');

			this.transcoderPending = Promise.all([jsContent, binaryContent]).then(([jsContent, binaryContent]) => {
				let fn:String = KTX2Loader.BasisWorker.toString();

				let body:String = [
					'/* constants */',
					'let _EngineFormat = ' + JSON.stringify(KTX2Loader.EngineFormat),
					'let _TranscoderFormat = ' + JSON.stringify(KTX2Loader.TranscoderFormat),
					'let _BasisFormat = ' + JSON.stringify(KTX2Loader.BasisFormat),
					'/* basis_transcoder.js */',
					jsContent,
					'/* worker */',
					fn.substring(fn.indexOf('{') + 1, fn.lastIndexOf('}'))
				].join('\n');

				this.workerSourceURL = URL.createObjectURL(new Blob([body]));
				this.transcoderBinary = binaryContent;

				this.workerPool.setWorkerCreator(() => {
					let worker:Worker = new Worker(this.workerSourceURL);
					let transcoderBinary:js.html.ArrayBuffer = this.transcoderBinary.slice(0);

					worker.postMessage({ type: 'init', config: this.workerConfig, transcoderBinary }, [transcoderBinary]);

					return worker;
				});
			});
		}

		return this.transcoderPending;
	}

	public function load(url:String, onLoad:Dynamic = null, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		if (this.workerConfig == null) {
			throw new Error('THREE.KTX2Loader: Missing initialization with `.detectSupport( renderer )`.');
		}

		let loader:FileLoader = new FileLoader(this.manager);

		loader.setResponseType('arraybuffer');
		loader.setWithCredentials(this.withCredentials);

		loader.load(url, (buffer) => {
			this._createTexture(buffer)
				.then((texture) => {
					if (onLoad != null) {
						onLoad(texture);
					}
				})
				.catch((error) => {
					if (onError != null) {
						onError(error);
					}
				});
		}, onProgress, onError);
	}

	// ... continue converting the rest of the code ...
}
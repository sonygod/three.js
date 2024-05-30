import three.js.examples.jsm.loaders.KTX2Loader;
import three.js.examples.jsm.utils.WorkerPool;
import three.js.examples.jsm.libs.ktx-parse.module.KHR_DF_FLAG_ALPHA_PREMULTIPLIED;
import three.js.examples.jsm.libs.ktx-parse.module.KHR_DF_TRANSFER_SRGB;
import three.js.examples.jsm.libs.ktx-parse.module.KHR_SUPERCOMPRESSION_NONE;
import three.js.examples.jsm.libs.ktx-parse.module.KHR_SUPERCOMPRESSION_ZSTD;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_UNDEFINED;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R16_SFLOAT;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R16G16_SFLOAT;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R16G16B16A16_SFLOAT;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R32_SFLOAT;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R32G32_SFLOAT;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R32G32B32A32_SFLOAT;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R8_SRGB;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R8_UNORM;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R8G8_SRGB;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R8G8_UNORM;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R8G8B8A8_SRGB;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_R8G8B8A8_UNORM;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_ASTC_6x6_SRGB_BLOCK;
import three.js.examples.jsm.libs.ktx-parse.module.VK_FORMAT_ASTC_6x6_UNORM_BLOCK;
import three.js.examples.jsm.libs.ktx-parse.module.KHR_DF_PRIMARIES_UNSPECIFIED;
import three.js.examples.jsm.libs.ktx-parse.module.KHR_DF_PRIMARIES_BT709;
import three.js.examples.jsm.libs.ktx-parse.module.KHR_DF_PRIMARIES_DISPLAYP3;
import three.js.examples.jsm.libs.zstddec.module.ZSTDDecoder;

class KTX2LoaderHaxe extends KTX2Loader {

  public function new(manager:LoaderManager) {
    super(manager);
    this.transcoderPath = '';
    this.transcoderBinary = null;
    this.transcoderPending = null;
    this.workerPool = new WorkerPool();
    this.workerSourceURL = '';
    this.workerConfig = null;
  }

  public function setTranscoderPath(path:String):KTX2LoaderHaxe {
    this.transcoderPath = path;
    return this;
  }

  public function setWorkerLimit(num:Int):KTX2LoaderHaxe {
    this.workerPool.setWorkerLimit(num);
    return this;
  }

  public function detectSupportAsync(renderer:WebGLRenderer):KTX2LoaderHaxe {
    this.workerConfig = {
      astcSupported: renderer.hasFeatureAsync('texture-compression-astc'),
      etc1Supported: renderer.hasFeatureAsync('texture-compression-etc1'),
      etc2Supported: renderer.hasFeatureAsync('texture-compression-etc2'),
      dxtSupported: renderer.hasFeatureAsync('texture-compression-bc'),
      bptcSupported: renderer.hasFeatureAsync('texture-compression-bptc'),
      pvrtcSupported: renderer.hasFeatureAsync('texture-compression-pvrtc')
    };
    return this;
  }

  public function detectSupport(renderer:WebGLRenderer):KTX2LoaderHaxe {
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

  public function init():KTX2LoaderHaxe {
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

      this.transcoderPending = Promise.all([jsContent, binaryContent]).then(([jsContent, binaryContent]) => {
        var fn = KTX2Loader.BasisWorker.toString();

        var body = [
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
          var worker = new Worker(this.workerSourceURL);
          var transcoderBinary = this.transcoderBinary.slice(0);

          worker.postMessage({type: 'init', config: this.workerConfig, transcoderBinary}, [transcoderBinary]);

          return worker;
        });
      });

      if (_activeLoaders > 0) {
        // Each instance loads a transcoder and allocates workers, increasing network and memory cost.
        console.warn(
          'THREE.KTX2Loader: Multiple active KTX2 loaders may cause performance issues.' +
          ' Use a single KTX2Loader instance, or call .dispose() on old instances.'
        );
      }

      _activeLoaders++;
    }

    return this.transcoderPending;
  }

  public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):KTX2LoaderHaxe {
    if (this.workerConfig === null) {
      throw new Error('THREE.KTX2Loader: Missing initialization with `.detectSupport( renderer )`.');
    }

    var loader = new FileLoader(this.manager);

    loader.setResponseType('arraybuffer');
    loader.setWithCredentials(this.withCredentials);

    loader.load(url, (buffer) => {
      // Check for an existing task using this buffer. A transferred buffer cannot be transferred
      // again from this thread.
      if (_taskCache.has(buffer)) {
        var cachedTask = _taskCache.get(buffer);

        return cachedTask.promise.then(onLoad).catch(onError);
      }

      this._createTexture(buffer)
        .then((texture) => onLoad ? onLoad(texture) : null)
        .catch(onError);
    }, onProgress, onError);
  }

  public function _createTextureFrom(transcodeResult:Dynamic, container:Dynamic):KTX2LoaderHaxe {
    var {faces, width, height, format, type, error, dfdFlags} = transcodeResult;

    if (type === 'error') return Promise.reject(error);

    var texture;

    if (container.faceCount === 6) {
      texture = new CompressedCubeTexture(faces, format, UnsignedByteType);
    } else {
      texture = container.layerCount > 1
        ? new CompressedArrayTexture(faces[0].mipmaps, width, height, container.layerCount, format, UnsignedByteType)
        : new CompressedTexture(faces[0].mipmaps, width, height, format, UnsignedByteType);
    }

    texture.minFilter = faces[0].mipmaps.length === 1 ? LinearFilter : LinearMipmapLinearFilter;
    texture.magFilter = LinearFilter;
    texture.generateMipmaps = false;

    texture.needsUpdate = true;
    texture.colorSpace = parseColorSpace(container);
    texture.premultiplyAlpha = !! (dfdFlags & KHR_DF_FLAG_ALPHA_PREMULTIPLIED);

    return texture;
  }

  public function _createTexture(buffer:ArrayBuffer, config:Dynamic = {}):Promise<Dynamic> {
    var container = read(new Uint8Array(buffer));

    if (container.vkFormat !== VK_FORMAT_UNDEFINED) {
      return createRawTexture(container);
    }

    //
    var taskConfig = config;
    var texturePending = this.init().then(() => {
      return this.workerPool.postMessage({type: 'transcode', buffer, taskConfig: taskConfig}, [buffer]);
    }).then((e) => this._createTextureFrom(e.data, container));

    // Cache the task result.
    _taskCache.set(buffer, {promise: texturePending});

    return texturePending;
  }

  public function dispose():KTX2LoaderHaxe {
    this.workerPool.dispose();
    if (this.workerSourceURL) URL.revokeObjectURL(this.workerSourceURL);

    _activeLoaders--;

    return this;
  }
}
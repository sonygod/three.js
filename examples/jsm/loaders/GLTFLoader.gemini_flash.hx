import three.AnimationClip;
import three.Bone;
import three.Box3;
import three.BufferAttribute;
import three.BufferGeometry;
import three.ClampToEdgeWrapping;
import three.Color;
// import three.ColorManagement; // Not needed in Haxe
import three.DirectionalLight;
import three.DoubleSide;
import three.FileLoader;
import three.FrontSide;
import three.Group;
import three.ImageBitmapLoader;
import three.InstancedMesh;
import three.InterleavedBuffer;
import three.InterleavedBufferAttribute;
import three.Interpolant;
import three.InterpolateDiscrete;
import three.InterpolateLinear;
import three.Line;
import three.LineBasicMaterial;
import three.LineLoop;
import three.LineSegments;
import three.LinearFilter;
import three.LinearMipmapLinearFilter;
// import three.LinearMipmapNearestFilter; // Not needed in Haxe
import three.LinearSRGBColorSpace;
import three.Loader;
import three.LoaderUtils;
import three.Material;
import three.MathUtils;
import three.Matrix4;
import three.Mesh;
import three.MeshBasicMaterial;
import three.MeshPhysicalMaterial;
import three.MeshStandardMaterial;
import three.MirroredRepeatWrapping;
import three.NearestFilter;
import three.NearestMipmapLinearFilter;
// import three.NearestMipmapNearestFilter; // Not needed in Haxe
import three.NumberKeyframeTrack;
import three.Object3D;
import three.OrthographicCamera;
import three.PerspectiveCamera;
import three.PointLight;
import three.Points;
import three.PointsMaterial;
import three.PropertyBinding;
import three.Quaternion;
import three.QuaternionKeyframeTrack;
import three.RepeatWrapping;
import three.Skeleton;
import three.SkinnedMesh;
import three.Sphere;
import three.SpotLight;
import three.Texture;
import three.TextureLoader;
import three.TriangleFanDrawMode;
import three.TriangleStripDrawMode;
import three.Vector2;
import three.Vector3;
import three.VectorKeyframeTrack;
import three.SRGBColorSpace;
import three.InstancedBufferAttribute;

// Import from local utils
import utils.BufferGeometryUtils.toTrianglesDrawMode;

// Using typedef instead of class for interface
typedef IGLTFParserPlugin = {
  name: String;
  beforeRoot: Void->Void->Promise<Dynamic>;
  afterRoot: Dynamic->Void->Promise<Dynamic>;
  _markDefs: Void->Void;
  loadNode: Int->Promise<Dynamic>;
  loadMesh: Int->Promise<Dynamic>;
  loadBufferView: Int->Promise<Dynamic>;
  loadTexture: Int->Promise<Dynamic>;
  loadAnimation: Int->Promise<Dynamic>;
  getDependency: String->Int->Promise<Dynamic>;
  createNodeMesh: Int->Promise<Dynamic>;
  createNodeAttachment: Int->Promise<Dynamic>;
  getMaterialType: Int->Class<Dynamic>;
  extendMaterialParams: Int->Dynamic->Promise<Dynamic>;
};

class GLTFLoader extends Loader {
  public var dracoLoader:Dynamic = null; // Placeholder for DracoLoader
  public var ktx2Loader:Dynamic = null; // Placeholder for KTX2Loader
  public var meshoptDecoder:Dynamic = null; // Placeholder for MeshoptDecoder

  public var pluginCallbacks:Array<IGLTFPluginCallback> = [];

  public function new(manager:LoadingManager = null) {
    super(manager);

    // Example of registering a plugin
    register( (parser) -> new GLTFMaterialsClearcoatExtension(parser));
  }

  public function load(url:String, onLoad:Dynamic->Void, ?onProgress:ProgressEvent->Void, ?onError:Dynamic->Void):Void {
    var scope = this;
    var resourcePath = LoaderUtils.extractUrlBase(url); // Simplified resource path logic

    // Track the loading progress
    manager.itemStart(url);

    var _onError = function(e:Dynamic) {
      if (onError != null) {
        onError(e);
      } else {
        trace('Error loading GLTF: $e');
      }
      manager.itemError(url);
      manager.itemEnd(url);
    };

    var loader = new FileLoader(manager);
    loader.setPath(path);
    loader.setResponseType("arraybuffer");
    loader.setRequestHeader(requestHeader);
    loader.setWithCredentials(withCredentials);

    loader.load(url,
      function(data:ArrayBuffer) {
        try {
          scope.parse(data, resourcePath, onLoad, _onError);
        } catch (e:Dynamic) {
          _onError(e);
        }
      },
      onProgress,
      _onError
    );
  }

  public function setDRACOLoader(dracoLoader:Dynamic):GLTFLoader {
    this.dracoLoader = dracoLoader;
    return this;
  }

  public function setKTX2Loader(ktx2Loader:Dynamic):GLTFLoader {
    this.ktx2Loader = ktx2Loader;
    return this;
  }

  public function setMeshoptDecoder(meshoptDecoder:Dynamic):GLTFLoader {
    this.meshoptDecoder = meshoptDecoder;
    return this;
  }

  public function register(callback:GLTFParser->IGLTFParserPlugin):GLTFLoader {
    pluginCallbacks.push(callback);
    return this;
  }

  public function unregister(callback:GLTFParser->IGLTFParserPlugin):GLTFLoader {
    pluginCallbacks.remove(callback);
    return this;
  }
  

  function parse(data:ArrayBuffer, path:String, onLoad:Dynamic->Void, onError:Dynamic->Void) {
    var json:Dynamic = null;
    var extensions:Map<String, Dynamic> = new Map();
    var plugins:Map<String, IGLTFParserPlugin> = new Map();
    var textDecoder = new TextDecoder();

    // Detect if data is GLB or GLTF
    if (new String(data.slice(0, 4)) == BINARY_EXTENSION_HEADER_MAGIC) {
      extensions.set(EXTENSIONS.KHR_BINARY_GLTF, new GLTFBinaryExtension(data));
      json = extensions.get(EXTENSIONS.KHR_BINARY_GLTF).content;
    } else {
      json = try {
        JSON.parse(textDecoder.decode(data));
      } catch (e:Dynamic) {
        onError(e);
        return;
      }
    }

    if (json.asset == null || json.asset.version[0] < 2) {
      onError(new Error("Unsupported asset. glTF versions >=2.0 are supported."));
      return;
    }

    var parser = new GLTFParser(json, {
      path: path,
      crossOrigin: crossOrigin,
      requestHeader: requestHeader,
      manager: manager,
      ktx2Loader: ktx2Loader,
      meshoptDecoder: meshoptDecoder,
    });

    parser.fileLoader.setRequestHeader(requestHeader);

    // Initialize plugins
    for (callback in pluginCallbacks) {
      var plugin = callback(parser);
      if (plugin.name == null) {
        trace('Invalid plugin found: missing name');
      } else {
        plugins.set(plugin.name, plugin);
        extensions.set(plugin.name, true); // Workaround for unknown extensions
      }
    }

    // Add extensions based on glTF file
    if (json.extensionsUsed != null) {
      for (extensionName in json.extensionsUsed) {
        var extensionsRequired = json.extensionsRequired;

        switch (extensionName) {
          case EXTENSIONS.KHR_MATERIALS_UNLIT:
            extensions.set(extensionName, new GLTFMaterialsUnlitExtension());
          case EXTENSIONS.KHR_DRACO_MESH_COMPRESSION:
            extensions.set(extensionName, new GLTFDracoMeshCompressionExtension(json, dracoLoader));
          case EXTENSIONS.KHR_TEXTURE_TRANSFORM:
            extensions.set(extensionName, new GLTFTextureTransformExtension());
          case EXTENSIONS.KHR_MESH_QUANTIZATION:
            extensions.set(extensionName, new GLTFMeshQuantizationExtension());
          default:
            if (extensionsRequired != null && extensionsRequired.indexOf(extensionName) >= 0 && !plugins.exists(extensionName)) {
              trace('Unknown extension "$extensionName".');
            }
        }
      }
    }

    parser.setExtensions(extensions);
    parser.setPlugins(plugins);
    parser.parse(onLoad, onError);
  }
  
  public function parseAsync(data:ArrayBuffer, path:String):Promise<Dynamic> {
    return new Promise(function(resolve, reject) {
      parse(data, path, resolve, reject);
    });
  }
}

// ... (Rest of the code remains largely the same, with minor syntax adjustments for Haxe)
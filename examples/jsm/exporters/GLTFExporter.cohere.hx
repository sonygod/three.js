import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Output;
import haxe.io.Path;
import haxe.io.Path.File;
import haxe.io.Path.FilePath;
import haxe.io.Path.Tools;
import haxe.io.StringInput;
import haxe.zip.Reader;
import js.Browser;
import js.html.ArrayBufferView;
import js.html.Blob;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.DataView;
import js.html.Document;
import js.html.FileReader;
import js.html.HTMLCanvasElement;
import js.html.HTMLImageElement;
import js.html.HTMLInputElement;
import js.html.Image;
import js.html.ImageData;
import js.html.OffscreenCanvas;
import js.html.OffscreenCanvasRenderingContext2D;
import js.html.Uint8ClampedArray;
import js.html._DataView;
import js.html._Uint8ClampedArray;
import js.html._Uint8Array;
import js.html._Uint8Array.UInt8Array_Impl_;
import js.node.Fs;
import js.node.buffer.Buffer;
import js.node.buffer.BufferView;
import js.node.buffer.SlowBuffer;
import js.node.buffer.SlowBufferView;
import js.node.child_process.exec;
import js.node.child_process.execSync;
import js.node.child_process.spawn;
import js.node.child_process.spawnSync;
import js.node.child_process.ChildProcess;
import js.node.child_process.ExecOptions;
import js.node.child_process.SpawnOptions;
import js.node.child_process.SpawnSyncOptions;
import js.node.events.EventEmitter;
import js.node.events.Listener;
import js.node.fs.Stats;
import js.node.http.ClientRequest;
import js.node.http.IncomingMessage;
import js.node.http.Server;
import js.node.http.ServerResponse;
import js.node.http.IncomingMessage as NodeIncomingMessage;
import js.node.http.Server as NodeHttpServer;
import js.node.http.ServerResponse as NodeHttpServerResponse;
import js.node.net.Socket;
import js.node.os.tmpDir;
import js.node.process;
import js.node.process.Process;
import js.node.stream.Readable;
import js.node.stream.Writable;
import js.node.stream.WritableStream;
import js.node.tty.ReadStream;
import js.node.tty.WriteStream;
import js.node.url.Url;
import js.node.util.Inspection;
import js.node.util.Modular;
import js.node.util.Util;
import js.node.vm.Context;
import js.node.vm.Script;
import js.node.vm.VMScript;
import js.node.zlib.DeflateOptions;
import js.node.zlib.DeflateRawOptions;
import js.node.zlib.GunzipOptions;
import js.node.zlib.GzipOptions;
import js.node.zlib.InflateOptions;
import js.node.zlib.InflateRawOptions;
import js.node.zlib.UnzipOptions;
import js.node.zlib.ZipOptions;
import js.node.zlib.Zlib;
import js.node.zlib.ZlibOptions;
import js.node.zlib.deflate;
import js.node.zlib.deflateRaw;
import js.node.zlib.gunzip;
import js.node.zlib.gzip;
import js.node.zlib.inflate;
import js.node.zlib.inflateRaw;
import js.node.zlib.unzip;
import js.node.zlib.zip;
import js.Promise;
import js.html.Image as HtmlImage;
import js.html.Window;

class GLTFExporter {
	public var pluginCallbacks: Array<Function>;
	public function new() {
		this.pluginCallbacks = [];
		this.register(function(writer) {
			return new GLTFLightExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsUnlitExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsTransmissionExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsVolumeExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsIorExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsSpecularExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsClearcoatExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsDispersionExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsIridescenceExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsSheenExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsAnisotropyExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsEmissiveStrengthExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMaterialsBumpExtension(writer);
		});
		this.register(function(writer) {
			return new GLTFMeshGpuInstancing(writer);
		});
	}

	public function register(callback: Function) {
		if (this.pluginCallbacks.indexOf(callback) == -1) {
			this.pluginCallbacks.push(callback);
		}
		return this;
	}

	public function unregister(callback: Function) {
		if (this.pluginCallbacks.indexOf(callback) != -1) {
			this.pluginCallbacks.splice(this.pluginCallbacks.indexOf(callback), 1);
		}
		return this;
	}

	public function parse(input: Dynamic, onDone: Function, onError: Function, ?options: Dynamic) {
		var writer = new GLTFWriter();
		var plugins = [];
		var _g = 0;
		while (_g < this.pluginCallbacks.length) {
			var i = _g++;
			plugins.push(this.pluginCallbacks[i](writer));
		}
		writer.setPlugins(plugins);
		writer.write(input, onDone, options).catch(onError);
	}

	public function parseAsync(input: Dynamic, ?options: Dynamic) {
		var scope = this;
		return new Promise(function(resolve, reject) {
			scope.parse(input, resolve, reject, options);
		});
	}

	public static var WEBGL_CONSTANTS = {
		POINTS: 0,
		LINES: 1,
		LINE_LOOP: 2,
		LINE_STRIP: 3,
		TRIANGLES: 4,
		TRIANGLE_STRIP: 5,
		TRIANGLE_FAN: 6,
		BYTE: 5120,
		UNSIGNED_BYTE: 5121,
		SHORT: 5122,
		UNSIGNED_SHORT: 5123,
		INT: 5124,
		UNSIGNED_INT: 5125,
		FLOAT: 5126,
		ARRAY_BUFFER: 34962,
		ELEMENT_ARRAY_BUFFER: 34963,
		NEAREST: 9728,
		LINEAR: 9729,
		NEAREST_MIPMAP_NEAREST: 9984,
		LINEAR_MIPMAP_NEAREST: 9985,
		NEAREST_MIPMAP_LINEAR: 9986,
		LINEAR_MIPMAP_LINEAR: 9987,
		CLAMP_TO_EDGE: 33071,
		MIRRORED_REPEAT: 33648,
		REPEAT: 10497
	};

	public static var KHR_MESH_QUANTIZATION = "KHR_mesh_quantization";

	public static var THREE_TO_WEBGL = { };

	public static function __hx_static_init() {
		var _g = 0;
		var _g1 = [NearestFilter,NearestMipmapNearestFilter,NearestMipmapLinearFilter,LinearFilter,LinearMipmapNearestFilter,LinearMipmapLinearFilter];
		while (_g < _g1.length) {
			var i = _g1[_g];
			++_g;
			THREE_TO_WEBGL[i] = WEBGL_CONSTANTS.NEAREST;
		}
		var _g11 = [ClampToEdgeWrapping,RepeatWrapping,MirroredRepeatWrapping];
		_g = 0;
		while (_g < _g11.length) {
			var i1 = _g11[_g];
			++_g;
			THREE_TO_WEBGL[i1] = WEBGL_CONSTANTS.CLAMP_TO_EDGE;
		}
	}

	public static var PATH_PROPERTIES = {
		scale: "scale",
		position: "translation",
		quaternion: "rotation",
		morphTargetInfluences: "weights"
	};

	public static var DEFAULT_SPECULAR_COLOR = new Color();

	public static var GLB_HEADER_BYTES = 12;

	public static var GLB_HEADER_MAGIC = 1021932735;

	public static var GLB_VERSION = 2;

	public static var GLB_CHUNK_PREFIX_BYTES = 8;

	public static var GLB_CHUNK_TYPE_JSON = 2079131347;

	public static var GLB_CHUNK_TYPE_BIN = 2113515570;

	public static function equalArray(array1: Array<Float>, array2: Array<Float>) {
		return (array1.length == array2.length) && array1.every(((function(index, element) {
			return element == array2[index];
		})));
	}

	public static function stringToArrayBuffer(text: String) {
		return new TextEncoder().encode(text).buffer;
	}

	public static function isIdentityMatrix(matrix: Matrix4) {
		return equalArray(matrix.elements, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
	}

	public static function getMinMax(attribute: BufferAttribute, start: Int, count: Int) {
		var output = { min : [], max : []};
		var _g = 0;
		while (_g < attribute.itemSize) {
			var a = _g++;
			output.min[a] = Float.POSITIVE_INFINITY;
			output.max[a] = Float.NEGATIVE_INFINITY;
		}
		var _g1 = start;
		var _g2 = start + count;
		while (_g1 < _g2) {
			var i = _g1++;
			var _g3 = 0;
			while (_g3 < attribute.itemSize) {
				var a1 = _g3++;
				var value = attribute.getX(i);
				if (attribute.itemSize > 4) {
					value = attribute.array[i * attribute.itemSize + a1];
				} else if (a1 == 0) {
					value = attribute.getX(i);
				} else if (a1 == 1) {
					value = attribute.getY(i);
				} else if (a1 == 2) {
					value = attribute.getZ(i);
				} else if (a1 == 3) {
					value = attribute.getW(i);
				}
				if (attribute.normalized == true) {
					value = MathUtils.normalize(value, attribute.array);
				}
				output.min[a1] = Math.min(output.min[a1], value);
				output.max[a1] = Math.max(output.max[a1], value);
			}
		}
		return output;
	}

	public static function getPaddedBufferSize(bufferSize: Int) {
		return Math.ceil(bufferSize / 4) * 4;
	}

	public static function getPaddedArrayBuffer(arrayBuffer: ArrayBuffer, ?paddingByte: Int) {
		var paddedLength = getPaddedBufferSize(arrayBuffer.byteLength);
		if (paddedLength != arrayBuffer.byteLength) {
			var array = new Uint8Array(paddedLength);
			array.set(new Uint8Array(arrayBuffer));
			if (paddingByte != null) {
				var _g = 0;
				while (_g < (paddedLength - arrayBuffer.byteLength)) {
					++_g;
					array[arrayBuffer.byteLength + _g] = paddingByte;
				}
			}
			return array.buffer;
		} else {
			return arrayBuffer;
		}
	}

	public static function getCanvas() {
		if (typeof document != "undefined" && typeof OffscreenCanvas != "undefined") {
			return new OffscreenCanvas(1, 1);
		} else {
			return document.createElement("canvas");
		}
	}

	public static function getToBlobPromise(canvas: HTMLCanvasElement, mimeType: String) {
		if (canvas.toBlob != null) {
			return new Promise(function(resolve) {
				canvas.toBlob(resolve, mimeType);
			});
		}
		var quality;
		if (mimeType == "image/jpeg") {
			quality = 0.92;
		} else if (mimeType == "image/webp") {
			quality = 0.8;
		}
		return canvas.convertToBlob({ type : mimeType, quality : quality});
	}

	public var plugins: Array<Dynamic>;

	public var options: Dynamic;

	public var pending: Array<Dynamic>;

	public var buffers: Array<ArrayBuffer>;

	public var byteOffset: Int;

	public var buffers: Array<Dynamic>;

	public var nodeMap: Map<Dynamic, Dynamic>;

	public var skins: Array<Dynamic>;

	public var extensionsUsed: Dynamic;

	public var extensionsRequired: Dynamic;

	public var uids: Map<Dynamic, Dynamic>;

	public var uid: Int;

	public var json: Dynamic;

	public var cache: Dynamic;

	public function new() {
		this.plugins = [];
		this.options = { };
		this.pending = [];
		this.buffers = [];
		this.byteOffset = 0;
		this.buffers = [];
		this.nodeMap = new Map();
		this.skins = [];
		this.extensionsUsed = { };
		this.extensionsRequired = { };
		this.uids = new Map();
		this.uid = 0;
		this.json = { };
		this.json.asset = { };
		this.json.asset.version = "2.0";
		this.json.asset.generator = "THREE.GLTFExporter r" + REVISION;
		this.cache = { };
		this.cache.meshes = new Map();
		this.cache.attributes = new Map();
		this.cache.attributesNormalized = new Map();
		this.cache.materials = new Map();
		this.cache.textures = new Map();
		this.cache.images = new Map();
	}

	public function setPlugins(plugins: Array<Dynamic>) {
		this.plugins = plugins;
	}

	public async function write(input: Dynamic, onDone: Function, ?options: Dynamic) {
		this.options = { };
		this.options.binary = false;
		this.options.trs = false;
		this.options.onlyVisible = true;
		this.options.maxTextureSize = Float.POSITIVE_INFINITY;
		this.options.animations = [];
		this.options.includeCustomExtensions = false;
		if (this.options.animations.length > 0) {
			this.options.trs = true;
		}
		this.processInput(input);
		await Promise.all(this.pending);
		var writer = this;
		var buffers = writer.buffers;
		var json = writer.json;
		var options = writer.options;
		var
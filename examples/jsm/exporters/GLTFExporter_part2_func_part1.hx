package three.js.examples.jsm.exporters;

import haxe.io.Bytes;
import haxe.io.UInt8Array;
import js.Blob;
import js.FileReader;
import js.Map;
import js.Promise;
import three.js.Buffer;
import three.js.CompressedTexture;
import three.js.ImageData;
import three.js.Source;
import three.js.Texture;
import three.js.Vector3;

class GLTFWriter {
	// ...

	var plugins:Array<Dynamic>;
	var options:Dynamic;
	var pending:Array<Promise<Dynamic>>;
	var buffers:Array<Bytes>;
	var nodeMap:Map<String, Dynamic>;
	var skins:Array<Dynamic>;
	var extensionsUsed:Map<String, Bool>;
	var extensionsRequired:Map<String, Bool>;
	var uids:Map<String, Map<Bool, Int>>;
	var uid:Int;
	var json:Dynamic;
	var cache:Dynamic;

	public function new() {
		plugins = [];
		options = {};
		pending = [];
		buffers = [];
		nodeMap = new Map<String, Dynamic>();
		skins = [];
		extensionsUsed = new Map<String, Bool>();
		extensionsRequired = new Map<String, Bool>();
		uids = new Map<String, Map<Bool, Int>>();
		uid = 0;
		json = {
			asset: {
				version: '2.0',
				generator: 'THREE.GLTFExporter r' + REVISION
			}
		};
		cache = {
			meshes: new Map(),
			attributes: new Map(),
			attributesNormalized: new Map(),
			materials: new Map(),
			textures: new Map(),
			images: new Map()
		};
	}

	public function setPlugins(plugins:Array<Dynamic>) {
		this.plugins = plugins;
	}

	public function write(input:Dynamic, onDone:Dynamic -> Void, options:Dynamic = {}) {
		this.options = Object.assign({
			binary: false,
			trs: false,
			onlyVisible: true,
			maxTextureSize: Math.POSITIVE_INFINITY,
			animations: [],
			includeCustomExtensions: false
		}, options);

		if (options.animations.length > 0) {
			this.options.trs = true;
		}

		processInput(input);

		Promise.all(pending).then(function(_) {
			var writer:GLTFWriter = this;
			var buffers:Array<Bytes> = writer.buffers;
			var json:Dynamic = writer.json;
			var options:Dynamic = writer.options;

			var extensionsUsed:Map<String, Bool> = writer.extensionsUsed;
			var extensionsRequired:Map<String, Bool> = writer.extensionsRequired;

			var blob:Blob = new Blob(buffers, {type: 'application/octet-stream'});

			var extensionsUsedList:Array<String> = Lambda.array(extensionsUsed.keys());
			var extensionsRequiredList:Array<String> = Lambda.array(extensionsRequired.keys());

			if (extensionsUsedList.length > 0) json.extensionsUsed = extensionsUsedList;
			if (extensionsRequiredList.length > 0) json.extensionsRequired = extensionsRequiredList;

			if (json.buffers && json.buffers.length > 0) json.buffers[0].byteLength = blob.size;

			if (options.binary) {
				// ...
			} else {
				// ...
			}
		});
	}

	public function serializeUserData(object:Dynamic, objectDef:Dynamic) {
		// ...
	}

	public function getUID(attribute:Dynamic, isRelativeCopy:Bool = false):Int {
		// ...
	}

	public function isNormalizedNormalAttribute(normal:Dynamic):Bool {
		// ...
	}

	public function createNormalizedNormalAttribute(normal:Dynamic):Dynamic {
		// ...
	}

	public function applyTextureTransform(mapDef:Dynamic, texture:Dynamic) {
		// ...
	}

	public function buildMetalRoughTexture(metalnessMap:Dynamic, roughnessMap:Dynamic):Dynamic {
		// ...
	}

	public function processBuffer(buffer:Bytes):Int {
		// ...
	}
}
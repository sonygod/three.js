import three.BufferAttribute;
import three.ClampToEdgeWrapping;
import three.Color;
import three.DoubleSide;
import three.InterpolateDiscrete;
import three.InterpolateLinear;
import three.LinearFilter;
import three.LinearMipmapLinearFilter;
import three.LinearMipmapNearestFilter;
import three.MathUtils;
import three.Matrix4;
import three.MirroredRepeatWrapping;
import three.NearestFilter;
import three.NearestMipmapLinearFilter;
import three.NearestMipmapNearestFilter;
import three.PropertyBinding;
import three.RGBAFormat;
import three.RepeatWrapping;
import three.Scene;
import three.CompressedTexture;
import three.Vector3;
import three.Quaternion;
import three.REVISION;
import utils.TextureUtils;
import haxe.io.Bytes;
import haxe.io.Output;
import haxe.io.EofException;
import js.html.CanvasRenderingContext2D;
import js.html.HTMLCanvasElement;
import js.html.HTMLImageElement;
import js.html.ImageBitmap;
import js.html.OffscreenCanvas;
import js.html.FileReader;
import js.lib.Promise;

/**
 * The KHR_mesh_quantization extension allows these extra attribute component types
 *
 * @see https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_mesh_quantization/README.md#extending-mesh-attributes
 */
enum KHR_mesh_quantization_ExtraAttrTypes {
	POSITION;
	NORMAL;
	TANGENT;
	TEXCOORD;
}

class GLTFExporter {

	private pluginCallbacks:Array<Dynamic> = [];

	public function new() {
		register(function(writer:GLTFWriter) return new GLTFLightExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsUnlitExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsTransmissionExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsVolumeExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsIorExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsSpecularExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsClearcoatExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsDispersionExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsIridescenceExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsSheenExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsAnisotropyExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsEmissiveStrengthExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsBumpExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMeshGpuInstancing(writer));
	}

	public function register(callback:Dynamic):GLTFExporter {
		if (pluginCallbacks.indexOf(callback) == -1) {
			pluginCallbacks.push(callback);
		}
		return this;
	}

	public function unregister(callback:Dynamic):GLTFExporter {
		if (pluginCallbacks.indexOf(callback) != -1) {
			pluginCallbacks.splice(pluginCallbacks.indexOf(callback), 1);
		}
		return this;
	}

	/**
	 * Parse scenes and generate GLTF output
	 * @param  {Scene or [THREE.Scenes]} input   Scene or Array of THREE.Scenes
	 * @param  {Function} onDone  Callback on completed
	 * @param  {Function} onError  Callback on errors
	 * @param  {Object} options options
	 */
	public function parse(input:Scene, onDone:Dynamic, onError:Dynamic, options:Dynamic = null) {
		final writer = new GLTFWriter();
		final plugins:Array<Dynamic> = [];

		for (i in 0...pluginCallbacks.length) {
			plugins.push(pluginCallbacks[i](writer));
		}

		writer.setPlugins(plugins);
		writer.write(input, onDone, options).catch(onError);
	}

	public function parseAsync(input:Scene, options:Dynamic = null):Promise<Dynamic> {
		final scope = this;
		return new Promise(function(resolve:Dynamic, reject:Dynamic) {
			scope.parse(input, resolve, reject, options);
		});
	}

}

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

enum WEBGL_CONSTANTS {
	POINTS = 0x0000;
	LINES = 0x0001;
	LINE_LOOP = 0x0002;
	LINE_STRIP = 0x0003;
	TRIANGLES = 0x0004;
	TRIANGLE_STRIP = 0x0005;
	TRIANGLE_FAN = 0x0006;

	BYTE = 0x1400;
	UNSIGNED_BYTE = 0x1401;
	SHORT = 0x1402;
	UNSIGNED_SHORT = 0x1403;
	INT = 0x1404;
	UNSIGNED_INT = 0x1405;
	FLOAT = 0x1406;

	ARRAY_BUFFER = 0x8892;
	ELEMENT_ARRAY_BUFFER = 0x8893;

	NEAREST = 0x2600;
	LINEAR = 0x2601;
	NEAREST_MIPMAP_NEAREST = 0x2700;
	LINEAR_MIPMAP_NEAREST = 0x2701;
	NEAREST_MIPMAP_LINEAR = 0x2702;
	LINEAR_MIPMAP_LINEAR = 0x2703;

	CLAMP_TO_EDGE = 33071;
	MIRRORED_REPEAT = 33648;
	REPEAT = 10497;
}

private enum KHR_MESH_QUANTIZATION {
	KHR_mesh_quantization = "KHR_mesh_quantization";
}

private var THREE_TO_WEBGL:Map<Int,Int> = new Map();

THREE_TO_WEBGL.set(NearestFilter, WEBGL_CONSTANTS.NEAREST);
THREE_TO_WEBGL.set(NearestMipmapNearestFilter, WEBGL_CONSTANTS.NEAREST_MIPMAP_NEAREST);
THREE_TO_WEBGL.set(NearestMipmapLinearFilter, WEBGL_CONSTANTS.NEAREST_MIPMAP_LINEAR);
THREE_TO_WEBGL.set(LinearFilter, WEBGL_CONSTANTS.LINEAR);
THREE_TO_WEBGL.set(LinearMipmapNearestFilter, WEBGL_CONSTANTS.LINEAR_MIPMAP_NEAREST);
THREE_TO_WEBGL.set(LinearMipmapLinearFilter, WEBGL_CONSTANTS.LINEAR_MIPMAP_LINEAR);

THREE_TO_WEBGL.set(ClampToEdgeWrapping, WEBGL_CONSTANTS.CLAMP_TO_EDGE);
THREE_TO_WEBGL.set(RepeatWrapping, WEBGL_CONSTANTS.REPEAT);
THREE_TO_WEBGL.set(MirroredRepeatWrapping, WEBGL_CONSTANTS.MIRRORED_REPEAT);

private var PATH_PROPERTIES:Map<String,String> = new Map();

PATH_PROPERTIES.set("scale", "scale");
PATH_PROPERTIES.set("position", "translation");
PATH_PROPERTIES.set("quaternion", "rotation");
PATH_PROPERTIES.set("morphTargetInfluences", "weights");

private var DEFAULT_SPECULAR_COLOR = new Color();

// GLB constants
// https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#glb-file-format-specification

private const GLB_HEADER_BYTES = 12;
private const GLB_HEADER_MAGIC = 0x46546C67;
private const GLB_VERSION = 2;

private const GLB_CHUNK_PREFIX_BYTES = 8;
private const GLB_CHUNK_TYPE_JSON = 0x4E4F534A;
private const GLB_CHUNK_TYPE_BIN = 0x004E4942;

//------------------------------------------------------------------------------
// Utility functions
//------------------------------------------------------------------------------

/**
 * Compare two arrays
 * @param  {Array} array1 Array 1 to compare
 * @param  {Array} array2 Array 2 to compare
 * @return {Boolean}        Returns true if both arrays are equal
 */
private function equalArray(array1:Array<Float>, array2:Array<Float>):Bool {
	return (array1.length == array2.length) && array1.every(function(element, index) {
		return element == array2[index];
	});
}

/**
 * Converts a string to an ArrayBuffer.
 * @param  {string} text
 * @return {ArrayBuffer}
 */
private function stringToArrayBuffer(text:String):ArrayBuffer {
	return new TextEncoder().encode(text).buffer;
}

/**
 * Is identity matrix
 *
 * @param {Matrix4} matrix
 * @returns {Boolean} Returns true, if parameter is identity matrix
 */
private function isIdentityMatrix(matrix:Matrix4):Bool {
	return equalArray(matrix.elements, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
}

/**
 * Get the min and max vectors from the given attribute
 * @param  {BufferAttribute} attribute Attribute to find the min/max in range from start to start + count
 * @param  {Integer} start
 * @param  {Integer} count
 * @return {Object} Object containing the `min` and `max` values (As an array of attribute.itemSize components)
 */
private function getMinMax(attribute:BufferAttribute, start:Int, count:Int):{min:Array<Float>, max:Array<Float>} {
	final output = {
		min: new Array<Float>(attribute.itemSize).fill(Float.POSITIVE_INFINITY),
		max: new Array<Float>(attribute.itemSize).fill(Float.NEGATIVE_INFINITY)
	};

	for (i in start...start + count) {
		for (a in 0...attribute.itemSize) {
			var value:Float;
			if (attribute.itemSize > 4) {
				// no support for interleaved data for itemSize > 4
				value = attribute.array[i * attribute.itemSize + a];
			} else {
				if (a == 0) value = attribute.getX(i);
				else if (a == 1) value = attribute.getY(i);
				else if (a == 2) value = attribute.getZ(i);
				else if (a == 3) value = attribute.getW(i);
				if (attribute.normalized == true) {
					value = MathUtils.normalize(value, attribute.array);
				}
			}
			output.min[a] = Math.min(output.min[a], value);
			output.max[a] = Math.max(output.max[a], value);
		}
	}
	return output;
}

/**
 * Get the required size + padding for a buffer, rounded to the next 4-byte boundary.
 * https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#data-alignment
 *
 * @param {Integer} bufferSize The size the original buffer.
 * @returns {Integer} new buffer size with required padding.
 *
 */
private function getPaddedBufferSize(bufferSize:Int):Int {
	return Math.ceil(bufferSize / 4) * 4;
}

/**
 * Returns a buffer aligned to 4-byte boundary.
 *
 * @param {ArrayBuffer} arrayBuffer Buffer to pad
 * @param {Integer} paddingByte (Optional)
 * @returns {ArrayBuffer} The same buffer if it's already aligned to 4-byte boundary or a new buffer
 */
private function getPaddedArrayBuffer(arrayBuffer:ArrayBuffer, paddingByte:Int = 0):ArrayBuffer {
	final paddedLength = getPaddedBufferSize(arrayBuffer.byteLength);
	if (paddedLength != arrayBuffer.byteLength) {
		final array = new Uint8Array(paddedLength);
		array.set(new Uint8Array(arrayBuffer));
		if (paddingByte != 0) {
			for (i in arrayBuffer.byteLength...paddedLength) {
				array[i] = paddingByte;
			}
		}
		return array.buffer;
	}
	return arrayBuffer;
}

private function getCanvas():HTMLCanvasElement {
	if (typeof document == "undefined" && typeof OffscreenCanvas != "undefined") {
		return new OffscreenCanvas(1, 1);
	}
	return document.createElement("canvas");
}

private function getToBlobPromise(canvas:HTMLCanvasElement, mimeType:String):Promise<Dynamic> {
	if (canvas.toBlob != null) {
		return new Promise(function(resolve:Dynamic) {
			canvas.toBlob(resolve, mimeType);
		});
	}
	var quality:Float;
	// Blink's implementation of convertToBlob seems to default to a quality level of 100%
	// Use the Blink default quality levels of toBlob instead so that file sizes are comparable.
	if (mimeType == "image/jpeg") {
		quality = 0.92;
	} else if (mimeType == "image/webp") {
		quality = 0.8;
	}
	return canvas.convertToBlob({
		type: mimeType,
		quality: quality
	});
}

/**
 * Writer
 */
class GLTFWriter {

	private plugins:Array<Dynamic> = [];
	private options:Dynamic = null;
	private pending:Array<Promise<Dynamic>> = [];
	private buffers:Array<ArrayBuffer> = [];
	private byteOffset:Int = 0;
	private nodeMap:Map<Dynamic,Int> = new Map();
	private skins:Array<Dynamic> = [];
	private extensionsUsed:Map<String,Bool> = new Map();
	private extensionsRequired:Map<String,Bool> = new Map();
	private uids:Map<Dynamic,Map<Bool,Int>> = new Map();
	private uid:Int = 0;
	private json:Dynamic = {
		asset: {
			version: "2.0",
			generator: "THREE.GLTFExporter r" + REVISION
		}
	};
	private cache:{meshes:Map<String,Int>, attributes:Map<Int,Int>, attributesNormalized:Map<Dynamic,BufferAttribute>, materials:Map<Dynamic,Int>, textures:Map<Dynamic,Int>, images:Map<Dynamic,Dynamic>} = {
		meshes: new Map(),
		attributes: new Map(),
		attributesNormalized: new Map(),
		materials: new Map(),
		textures: new Map(),
		images: new Map()
	};

	public function new() {}

	public function setPlugins(plugins:Array<Dynamic>):Void {
		this.plugins = plugins;
	}

	/**
	 * Parse scenes and generate GLTF output
	 * @param  {Scene or [THREE.Scenes]} input   Scene or Array of THREE.Scenes
	 * @param  {Function} onDone  Callback on completed
	 * @param  {Object} options options
	 */
	public function write(input:Scene, onDone:Dynamic, options:Dynamic = null):Promise<Dynamic> {
		this.options = {
			// default options
			binary: false,
			trs: false,
			onlyVisible: true,
			maxTextureSize: Float.POSITIVE_INFINITY,
			animations: [],
			includeCustomExtensions: false
		}.merge(options);

		if (this.options.animations.length > 0) {
			// Only TRS properties, and not matrices, may be targeted by animation.
			this.options.trs = true;
		}

		processInput(input);
		return Promise.all(pending).then(function(_) {
			final writer = this;
			final buffers = writer.buffers;
			final json = writer.json;
			options = writer.options;
			final extensionsUsed = writer.extensionsUsed;
			final extensionsRequired = writer.extensionsRequired;
			// Merge buffers.
			final blob = new Blob(buffers, { type: "application/octet-stream" });
			// Declare extensions.
			final extensionsUsedList = extensionsUsed.keys();
			final extensionsRequiredList = extensionsRequired.keys();
			if (extensionsUsedList.length > 0) json.extensionsUsed = extensionsUsedList;
			if (extensionsRequiredList.length > 0) json.extensionsRequired = extensionsRequiredList;
			// Update bytelength of the single buffer.
			if (json.buffers && json.buffers.length > 0) json.buffers[0].byteLength = blob.size;
			if (options.binary == true) {
				// https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#glb-file-format-specification
				final reader = new FileReader();
				reader.readAsArrayBuffer(blob);
				reader.onloadend = function() {
					// Binary chunk.
					final binaryChunk = getPaddedArrayBuffer(reader.result);
					final binaryChunkPrefix = new DataView(new ArrayBuffer(GLB_CHUNK_PREFIX_BYTES));
					binaryChunkPrefix.setUint32(0, binaryChunk.byteLength, true);
					binaryChunkPrefix.setUint32(4, GLB_CHUNK_TYPE_BIN, true);
					// JSON chunk.
					final jsonChunk = getPaddedArrayBuffer(stringToArrayBuffer(JSON.stringify(json)), 0x20);
					final jsonChunkPrefix = new DataView(new ArrayBuffer(GLB_CHUNK_PREFIX_BYTES));
					jsonChunkPrefix.setUint32(0, jsonChunk.byteLength, true);
					jsonChunkPrefix.setUint32(4, GLB_CHUNK_TYPE_JSON, true);
					// GLB header.
					final header = new ArrayBuffer(GLB_HEADER_BYTES);
					final headerView = new DataView(header);
					headerView.setUint32(0, GLB_HEADER_MAGIC, true);
					headerView.setUint32(4, GLB_VERSION, true);
					final totalByteLength = GLB_HEADER_BYTES + jsonChunkPrefix.byteLength + jsonChunk.byteLength + binaryChunkPrefix.byteLength + binaryChunk.byteLength;
					headerView.setUint32(8, totalByteLength, true);
					final glbBlob = new Blob([header, jsonChunkPrefix, jsonChunk, binaryChunkPrefix, binaryChunk], { type: "application/octet-stream" });
					final glbReader = new FileReader();
					glbReader.readAsArrayBuffer(glbBlob);
					glbReader.onloadend = function() {
						onDone(glbReader.result);
					};
				};
			} else {
				if (json.buffers && json.buffers.length > 0) {
					final reader = new FileReader();
					reader.readAsDataURL(blob);
					reader.onloadend = function() {
						final base64data = reader.result;
						json.buffers[0].uri = base64data;
						onDone(json);
					};
				} else {
					onDone(json);
				}
			}
		});
	}

	/**
	 * Serializes a userData.
	 *
	 * @param {THREE.Object3D|THREE.Material} object
	 * @param {Object} objectDef
	 */
	public function serializeUserData(object:Dynamic, objectDef:Dynamic):Void {
		if (Reflect.fields(object.userData).length == 0) return;
		final options = this.options;
		final extensionsUsed = this.extensionsUsed;
		try {
			final json = JSON.parse(JSON.stringify(object.userData));
			if (options.includeCustomExtensions && json.gltfExtensions) {
				if (objectDef.extensions == null) objectDef.extensions = {};
				for (extensionName in json.gltfExtensions) {
					objectDef.extensions[extensionName] = json.gltfExtensions[extensionName];
					extensionsUsed.set(extensionName, true);
				}
				delete json.gltfExtensions;
			}
			if (Reflect.fields(json).length > 0) objectDef.extras = json;
		} catch(error:Dynamic) {
			console.warn("THREE.GLTFExporter: userData of '" + object.name + "' won't be serialized because of JSON.stringify error - " + error.message);
		}
	}

	/**
	 * Returns ids for buffer attributes.
	 * @param  {Object} object
	 * @return {Integer}
	 */
	private function getUID(attribute:BufferAttribute, isRelativeCopy:Bool = false):Int {
		if (!uids.has(attribute)) {
			final uids = new Map();
			uids.set(true, uid++);
			uids.set(false, uid++);
			this.uids.set(attribute, uids);
		}
		final uids = this.uids.get(attribute);
		return uids.get(isRelativeCopy);
	}

	/**
	 * Checks if normal attribute values are normalized.
	 *
	 * @param {BufferAttribute} normal
	 * @returns {Boolean}
	 */
	private function isNormalizedNormalAttribute(normal:BufferAttribute):Bool {
		final cache = this.cache;
		if (cache.attributesNormalized.has(normal)) return false;
		final v = new Vector3();
		for (i in 0...normal.count) {
			// 0.0005 is from glTF-validator
			if (Math.abs(v.fromBufferAttribute(normal, i).length() - 1.0) > 0.0005) return false;
		}
		return true;
	}

	/**
	 * Creates normalized normal buffer attribute.
	 *
	 * @param {BufferAttribute} normal
	 * @returns {BufferAttribute}
	 *
	 */
	private function createNormalizedNormalAttribute(normal:BufferAttribute):BufferAttribute {
		final cache = this.cache;
		if (cache.attributesNormalized.has(normal)) return cache.attributesNormalized.get(normal);
		final attribute = normal.clone();
		final v = new Vector3();
		for (i in 0...attribute.count) {
			v.fromBufferAttribute(attribute, i);
			if (v.x == 0 && v.y == 0 && v.z == 0) {
				// if values can't be normalized set (1, 0, 0)
				v.setX(1.0);
			} else {
				v.normalize();
			}
			attribute.setXYZ(i, v.x, v.y, v.z);
		}
		cache.attributesNormalized.set(normal, attribute);
		return attribute;
	}

	/**
	 * Applies a texture transform, if present, to the map definition. Requires
	 * the KHR_texture_transform extension.
	 *
	 * @param {Object} mapDef
	 * @param {THREE.Texture} texture
	 */
	private function applyTextureTransform(mapDef:Dynamic, texture:Dynamic):Void {
		var didTransform = false;
		final transformDef:Dynamic = {};
		if (texture.offset.x != 0 || texture.offset.y != 0) {
			transformDef.offset = texture.offset.toArray();
			didTransform = true;
		}
		if (texture.rotation != 0) {
			transformDef.rotation = texture.rotation;
			didTransform = true;
		}
		if (texture.repeat.x != 1 || texture.repeat.y != 1) {
			transformDef.scale = texture.repeat.toArray();
			didTransform = true;
		}
		if (didTransform) {
			mapDef.extensions = mapDef.extensions || {};
			mapDef.extensions[KHR_MESH_QUANTIZATION.KHR_mesh_quantization] = transformDef;
			extensionsUsed.set(KHR_MESH_QUANTIZATION.KHR_mesh_quantization, true);
		}
	}

	private function buildMetalRoughTexture(metalnessMap:Dynamic, roughnessMap:Dynamic):Dynamic {
		if (metalnessMap == roughnessMap) return metalnessMap;
		function getEncodingConversion(map:Dynamic) {
			if (map.colorSpace == SRGBColorSpace) {
				return function(c:Float) {
					return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
				};
			}
			return function(c:Float) {
				return c;
			};
		}
		console.warn("THREE.GLTFExporter: Merged metalnessMap and roughnessMap textures.");
		if (metalnessMap is CompressedTexture) {
			metalnessMap = TextureUtils.decompress(metalnessMap);
		}
		if (roughnessMap is CompressedTexture) {
			roughnessMap = TextureUtils.decompress(roughnessMap);
		}
		final metalness = metalnessMap ? metalnessMap.image : null;
		final roughness = roughnessMap ? roughnessMap.image : null;
		final width = Math.max(metalness ? metalness.width : 0, roughness ? roughness.width : 0);
		final height = Math.max(metalness ? metalness.height : 0, roughness ? roughness.height : 0);
		final canvas = getCanvas();
		canvas.width = width;
		canvas.height = height;
		final context = canvas.getContext("2d");
		context.fillStyle = "#00ffff";
		context.fillRect(0, 0, width, height);
		final composite = context.getImageData(0, 0, width, height);
		if (metalness) {
			context.drawImage(metalness, 0, 0, width, height);
			final convert = getEncodingConversion(metalnessMap);
			final data = context.getImageData(0, 0, width, height).data;
			for (i in 2...data.length) {
				composite.data[i] = convert(data[i] / 256) * 256;
			}
		}
		if (roughness) {
			context.drawImage(roughness, 0, 0, width, height);
			final convert = getEncodingConversion(roughnessMap);
			final data = context.getImageData(0, 0, width, height).data;
			for (i in 1...data.length) {
				composite.data[i] = convert(data[i] / 256) * 256;
			}
		}
		context.putImageData(composite, 0, 0);
		//
		final reference = metalnessMap || roughnessMap;
		final texture = reference.clone();
		texture.source = new three.Source(canvas);
		texture.colorSpace = NoColorSpace;
		texture.channel = (metalnessMap || roughnessMap).channel;
		if (metalnessMap && roughnessMap && metalnessMap.channel != roughnessMap.channel) {
			console.warn("THREE.GLTFExporter: UV channels for metalnessMap and roughnessMap textures must match.");
		}
		return texture;
	}

	/**
	 * Process a buffer to append to the default one.
	 * @param  {ArrayBuffer} buffer
	 * @return {Integer}
	 */
	private function processBuffer(buffer:ArrayBuffer):Int {
		final json = this.json;
		final buffers = this.buffers;
		if (!json.buffers) json.buffers = [{ byteLength: 0 }];
		// All buffers are merged before export.
		buffers.push(buffer);
		return 0;
	}

	/**
	 * Process and generate a BufferView
	 * @param  {BufferAttribute} attribute
	 * @param  {number} componentType
	 * @param  {number} start
	 * @param  {number} count
	 * @param  {number} target (Optional) Target usage of the BufferView
	 * @return {Object}
	 */
	private function processBufferView(attribute:BufferAttribute, componentType:Int, start:Int, count:Int, target:Int = null):{id:Int, byteLength:Int} {
		final json = this.json;
		if (!json.bufferViews) json.bufferViews = [];
		// Create a new dataview and dump the attribute's array into it
		var componentSize:Int;
		switch (componentType) {
			case WEBGL_CONSTANTS.BYTE:
			case WEBGL_CONSTANTS.UNSIGNED_BYTE:
				componentSize = 1;
				break;
			case WEBGL_CONSTANTS.SHORT:
			case WEBGL_CONSTANTS.UNSIGNED_SHORT:
				componentSize = 2;
				break;
			default:
				componentSize = 4;
		}
		var byteStride = attribute.itemSize * componentSize;
		if (target == WEBGL_CONSTANTS.ARRAY_BUFFER) {
			// Each element of a vertex attribute MUST be aligned to 4-byte boundaries
			// inside a bufferView
			byteStride = Math.ceil(byteStride / 4) * 4;
		}
		final byteLength = getPaddedBufferSize(count * byteStride);
		final dataView = new DataView(new ArrayBuffer(byteLength));
		var offset = 0;
		for (i in start...start + count) {
			for (a in 0...attribute.itemSize) {
				var value:Float;
				if (attribute.itemSize > 4) {
					// no support for interleaved data for itemSize > 4
					value = attribute.array[i * attribute.itemSize + a];
				} else {
					if (a == 0) value = attribute.getX(i);
					else if (a == 1) value = attribute.getY(i);
					else if (a == 2) value = attribute.getZ(i);
					else if (a == 3) value = attribute.getW(i);
					if (attribute.normalized == true) {
						value = MathUtils.normalize(value, attribute.array);
					}
				}
				if (componentType == WEBGL_CONSTANTS.FLOAT) {
					dataView.setFloat32(offset, value, true);
				} else if (componentType == WEBGL_CONSTANTS.INT) {
					dataView.setInt32(offset, value, true);
				} else if (componentType == WEBGL_CONSTANTS.UNSIGNED_INT) {
					dataView.setUint32(offset, value, true);
				} else if (componentType == WEBGL_CONSTANTS.SHORT) {
					dataView.setInt16(offset, value, true);
				} else if (componentType == WEBGL_CONSTANTS.UNSIGNED_SHORT) {
					dataView.setUint16(offset, value, true);
				} else if (componentType == WEBGL_CONSTANTS.BYTE) {
					dataView.setInt8(offset, value);
				} else if (componentType == WEBGL_CONSTANTS.UNSIGNED_BYTE) {
					dataView.setUint8(offset, value);
				}
				offset += componentSize;
			}
			if ((offset % byteStride) != 0) {
				offset += byteStride - (offset % byteStride);
			}
		}
		final bufferViewDef = {
			buffer: processBuffer(dataView.buffer),
			byteOffset: byteOffset,
			byteLength: byteLength
		};
		if (target != null) bufferViewDef.target = target;
		if (target == WEBGL_CONSTANTS.ARRAY_BUFFER) {
			// Only define byteStride for vertex attributes.
			bufferViewDef.byteStride = byteStride;
		}
		byteOffset += byteLength;
		json.bufferViews.push(bufferViewDef);
		// @TODO Merge bufferViews where possible.
		final output = {
			id: json.bufferViews.length - 1,
			byteLength: 0
		};
		return output;
	}

	/**
	 * Process and generate a BufferView from an image Blob.
	 * @param {Blob} blob
	 * @return {Promise<Integer>}
	 */
	private function processBufferViewImage(blob:Dynamic):Promise<Int> {
		final writer = this;
		final json = writer.json;
		if (!json.bufferViews) json.bufferViews = [];
		return new Promise(function(resolve:Dynamic) {
			final reader = new FileReader();
			reader.readAsArrayBuffer(blob);
			reader.onloadend = function() {
				final buffer = getPaddedArrayBuffer(reader.result);
				final bufferViewDef = {
					buffer: writer.processBuffer(buffer),
					byteOffset: writer.byteOffset,
					byteLength: buffer.byteLength
				};
				writer.byteOffset += buffer.byteLength;
				resolve(json.bufferViews.push(bufferViewDef) - 1);
			};
		});
	}

	/**
	 * Process attribute to generate an accessor
	 * @param  {BufferAttribute} attribute Attribute to process
	 * @param  {THREE.BufferGeometry} geometry (Optional) Geometry used for truncated draw range
	 * @param  {Integer} start (Optional)
	 * @param  {Integer} count (Optional)
	 * @return {Integer|null} Index of the processed accessor on the "accessors" array
	 */
	private function processAccessor(attribute:BufferAttribute, geometry:Dynamic = null, start:Int = 0, count:Int = null):Int {
		final json = this.json;
		final types = {
			1: "SCALAR",
			2: "VEC2",
			3: "VEC3",
			4: "VEC4",
			9: "MAT3",
			16: "MAT4"
		};
		var componentType:Int;
		// Detect the component type of the attribute array
		if (attribute
			1: "SCALAR",
			2: "VEC2",
			3: "VEC3",
			4: "VEC4",
			9: "MAT3",
			16: "MAT4"
		};
		var componentType:Int;
		// Detect the component type of the attribute array
		if (attribute.array.constructor == Float32Array) {
			componentType = WEBGL_CONSTANTS.FLOAT;
		} else if (attribute.array.constructor == Int32Array) {
			componentType = WEBGL_CONSTANTS.INT;
		} else if (attribute.array.constructor == Uint32Array) {
			componentType = WEBGL_CONSTANTS.UNSIGNED_INT;
		} else if (attribute.array.constructor == Int16Array) {
			componentType = WEBGL_CONSTANTS.SHORT;
		} else if (attribute.array.constructor == Uint16Array) {
			componentType = WEBGL_CONSTANTS.UNSIGNED_SHORT;
		} else if (attribute.array.constructor == Int8Array) {
			componentType = WEBGL_CONSTANTS.BYTE;
		} else if (attribute.array.constructor == Uint8Array) {
			componentType = WEBGL_CONSTANTS.UNSIGNED_BYTE;
		} else {
			throw new Error("THREE.GLTFExporter: Unsupported bufferAttribute component type: " + attribute.array.constructor.name);
		}
		if (start == null) start = 0;
		if (count == null || count == Float.POSITIVE_INFINITY) count = attribute.count;
		// Skip creating an accessor if the attribute doesn't have data to export
		if (count == 0) return null;
		final minMax = getMinMax(attribute, start, count);
		var bufferViewTarget:Int;
		// If geometry isn't provided, don't infer the target usage of the bufferView. For
		// animation samplers, target must not be set.
		if (geometry != null) {
			bufferViewTarget = attribute == geometry.index ? WEBGL_CONSTANTS.ELEMENT_ARRAY_BUFFER : WEBGL_CONSTANTS.ARRAY_BUFFER;
		}
		final bufferView = processBufferView(attribute, componentType, start, count, bufferViewTarget);
		final accessorDef = {
			bufferView: bufferView.id,
			byteOffset: bufferView.byteOffset,
			componentType: componentType,
			count: count,
			max: minMax.max,
			min: minMax.min,
			type: types[attribute.itemSize]
		};
		if (attribute.normalized == true) accessorDef.normalized = true;
		if (!json.accessors) json.accessors = [];
		return json.accessors.push(accessorDef) - 1;
	}

	/**
	 * Process image
	 * @param  {Image} image to process
	 * @param  {Integer} format of the image (RGBAFormat)
	 * @param  {Boolean} flipY before writing out the image
	 * @param  {String} mimeType export format
	 * @return {Integer}     Index of the processed texture in the "images" array
	 */
	private function processImage(image:Dynamic, format:Int, flipY:Bool, mimeType:String = "image/png"):Int {
		if (image != null) {
			final writer = this;
			final cache = writer.cache;
			final json = writer.json;
			final options = writer.options;
			final pending = writer.pending;
			if (!cache.images.has(image)) cache.images.set(image, {});
			final cachedImages = cache.images.get(image);
			final key = mimeType + ":flipY/" + flipY.toString();
			if (cachedImages[key] != null) return cachedImages[key];
			if (!json.images) json.images = [];
			final imageDef = { mimeType: mimeType };
			final canvas = getCanvas();
			canvas.width = Math.min(image.width, options.maxTextureSize);
			canvas.height = Math.min(image.height, options.maxTextureSize);
			final ctx = canvas.getContext("2d");
			if (flipY == true) {
				ctx.translate(0, canvas.height);
				ctx.scale(1, -1);
			}
			if (image.data != null) { // THREE.DataTexture
				if (format != RGBAFormat) {
					console.error("GLTFExporter: Only RGBAFormat is supported.", format);
				}
				if (image.width > options.maxTextureSize || image.height > options.maxTextureSize) {
					console.warn("GLTFExporter: Image size is bigger than maxTextureSize", image);
				}
				final data = new Uint8ClampedArray(image.height * image.width * 4);
				for (i in 0...data.length) {
					data[i + 0] = image.data[i + 0];
					data[i + 1] = image.data[i + 1];
					data[i + 2] = image.data[i + 2];
					data[i + 3] = image.data[i + 3];
				}
				ctx.putImageData(new ImageData(data, image.width, image.height), 0, 0);
			} else {
				if ((typeof HTMLImageElement != "undefined" && image is HTMLImageElement) ||
					(typeof HTMLCanvasElement != "undefined" && image is HTMLCanvasElement) ||
					(typeof ImageBitmap != "undefined" && image is ImageBitmap) ||
					(typeof OffscreenCanvas != "undefined" && image is OffscreenCanvas)) {
					ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
				} else {
					throw new Error("THREE.GLTFExporter: Invalid image type. Use HTMLImageElement, HTMLCanvasElement, ImageBitmap or OffscreenCanvas.");
				}
			}
			if (options.binary == true) {
				pending.push(
					getToBlobPromise(canvas, mimeType).then(function(blob:Dynamic) {
						return writer.processBufferViewImage(blob);
					}).then(function(bufferViewIndex:Int) {
						imageDef.bufferView = bufferViewIndex;
					})
				);
			} else {
				if (canvas.toDataURL != null) {
					imageDef.uri = canvas.toDataURL(mimeType);
				} else {
					pending.push(
						getToBlobPromise(canvas, mimeType).then(function(blob:Dynamic) {
							return new FileReader().readAsDataURL(blob);
						}).then(function(dataURL:String) {
							imageDef.uri = dataURL;
						})
					);
				}
			}
			final index = json.images.push(imageDef) - 1;
			cachedImages[key] = index;
			return index;
		} else {
			throw new Error("THREE.GLTFExporter: No valid image data found. Unable to process texture.");
		}
	}

	/**
	 * Process sampler
	 * @param  {Texture} map Texture to process
	 * @return {Integer}     Index of the processed texture in the "samplers" array
	 */
	private function processSampler(map:Dynamic):Int {
		final json = this.json;
		if (!json.samplers) json.samplers = [];
		final samplerDef = {
			magFilter: THREE_TO_WEBGL[map.magFilter],
			minFilter: THREE_TO_WEBGL[map.minFilter],
			wrapS: THREE_TO_WEBGL[map.wrapS],
			wrapT: THREE_TO_WEBGL[map.wrapT]
		};
		return json.samplers.push(samplerDef) - 1;
	}

	/**
	 * Process texture
	 * @param  {Texture} map Map to process
	 * @return {Integer} Index of the processed texture in the "textures" array
	 */
	private function processTexture(map:Dynamic):Int {
		final writer = this;
		final options = writer.options;
		final cache = this.cache;
		final json = this.json;
		if (cache.textures.has(map)) return cache.textures.get(map);
		if (!json.textures) json.textures = [];
		// make non-readable textures (e.g. CompressedTexture) readable by blitting them into a new texture
		if (map is CompressedTexture) {
			map = TextureUtils.decompress(map, options.maxTextureSize);
		}
		var mimeType = map.userData.mimeType;
		if (mimeType == "image/webp") mimeType = "image/png";
		final textureDef = {
			sampler: processSampler(map),
			source: processImage(map.image, map.format, map.flipY, mimeType)
		};
		if (map.name) textureDef.name = map.name;
		this._invokeAll(function(ext:Dynamic) {
			ext.writeTexture && ext.writeTexture(map, textureDef);
		});
		final index = json.textures.push(textureDef) - 1;
		cache.textures.set(map, index);
		return index;
	}

	/**
	 * Process material
	 * @param  {THREE.Material} material Material to process
	 * @return {Integer|null} Index of the processed material in the "materials" array
	 */
	private function processMaterial(material:Dynamic):Int {
		final cache = this.cache;
		final json = this.json;
		if (cache.materials.has(material)) return cache.materials.get(material);
		if (material.isShaderMaterial) {
			console.warn("GLTFExporter: THREE.ShaderMaterial not supported.");
			return null;
		}
		if (!json.materials) json.materials = [];
		// @QUESTION Should we avoid including any attribute that has the default value?
		final materialDef:Dynamic = {	pbrMetallicRoughness: {} };
		if (material.isMeshStandardMaterial != true && material.isMeshBasicMaterial != true) {
			console.warn("GLTFExporter: Use MeshStandardMaterial or MeshBasicMaterial for best results.");
		}
		// pbrMetallicRoughness.baseColorFactor
		final color = material.color.toArray().concat([material.opacity]);
		if (!equalArray(color, [1, 1, 1, 1])) {
			materialDef.pbrMetallicRoughness.baseColorFactor = color;
		}
		if (material.isMeshStandardMaterial) {
			materialDef.pbrMetallicRoughness.metallicFactor = material.metalness;
			materialDef.pbrMetallicRoughness.roughnessFactor = material.roughness;
		} else {
			materialDef.pbrMetallicRoughness.metallicFactor = 0.5;
			materialDef.pbrMetallicRoughness.roughnessFactor = 0.5;
		}
		// pbrMetallicRoughness.metallicRoughnessTexture
		if (material.metalnessMap || material.roughnessMap) {
			final metalRoughTexture = buildMetalRoughTexture(material.metalnessMap, material.roughnessMap);
			final metalRoughMapDef = {
				index: processTexture(metalRoughTexture),
				channel: metalRoughTexture.channel
			};
			applyTextureTransform(metalRoughMapDef, metalRoughTexture);
			materialDef.pbrMetallicRoughness.metallicRoughnessTexture = metalRoughMapDef;
		}
		// pbrMetallicRoughness.baseColorTexture
		if (material.map) {
			final baseColorMapDef = {
				index: processTexture(material.map),
				texCoord: material.map.channel
			};
			applyTextureTransform(baseColorMapDef, material.map);
			materialDef.pbrMetallicRoughness.baseColorTexture = baseColorMapDef;
		}
		if (material.emissive) {
			final emissive = material.emissive;
			final maxEmissiveComponent = Math.max(emissive.r, emissive.g, emissive.b);
			if (maxEmissiveComponent > 0) {
				materialDef.emissiveFactor = material.emissive.toArray();
			}
			// emissiveTexture
			if (material.emissiveMap) {
				final emissiveMapDef = {
					index: processTexture(material.emissiveMap),
					texCoord: material.emissiveMap.channel
				};
				applyTextureTransform(emissiveMapDef, material.emissiveMap);
				materialDef.emissiveTexture = emissiveMapDef;
			}
		}
		// normalTexture
		if (material.normalMap) {
			final normalMapDef = {
				index: processTexture(material.normalMap),
				texCoord: material.normalMap.channel
			};
			if (material.normalScale && material.normalScale.x != 1) {
				// glTF normal scale is univariate. Ignore `y`, which may be flipped.
				// Context: https://github.com/mrdoob/three.js/issues/11438#issuecomment-507003995
				normalMapDef.scale = material.normalScale.x;
			}
			applyTextureTransform(normalMapDef, material.normalMap);
			materialDef.normalTexture = normalMapDef;
		}
		// occlusionTexture
		if (material.aoMap) {
			final occlusionMapDef = {
				index: processTexture(material.aoMap),
				texCoord: material.aoMap.channel
			};
			if (material.aoMapIntensity != 1.0) {
				occlusionMapDef.strength = material.aoMapIntensity;
			}
			applyTextureTransform(occlusionMapDef, material.aoMap);
			materialDef.occlusionTexture = occlusionMapDef;
		}
		// alphaMode
		if (material.transparent) {
			materialDef.alphaMode = "BLEND";
		} else {
			if (material.alphaTest > 0.0) {
				materialDef.alphaMode = "MASK";
				materialDef.alphaCutoff = material.alphaTest;
			}
		}
		// doubleSided
		if (material.side == DoubleSide) materialDef.doubleSided = true;
		if (material.name != "") materialDef.name = material.name;
		serializeUserData(material, materialDef);
		this._invokeAll(function(ext:Dynamic) {
			ext.writeMaterial && ext.writeMaterial(material, materialDef);
		});
		final index = json.materials.push(materialDef) - 1;
		cache.materials.set(material, index);
		return index;
	}

	/**
	 * Process mesh
	 * @param  {THREE.Mesh} mesh Mesh to process
	 * @return {Integer|null} Index of the processed mesh in the "meshes" array
	 */
	private function processMesh(mesh:Dynamic):Int {
		final cache = this.cache;
		final json = this.json;
		final meshCacheKeyParts:Array<String> = [mesh.geometry.uuid];
		if (Array.isArray(mesh.material)) {
			for (i in 0...mesh.material.length) {
				meshCacheKeyParts.push(mesh.material[i].uuid);
			}
		} else {
			meshCacheKeyParts.push(mesh.material.uuid);
		}
		final meshCacheKey = meshCacheKeyParts.join(":");
		if (cache.meshes.has(meshCacheKey)) return cache.meshes.get(meshCacheKey);
		final geometry = mesh.geometry;
		var mode:Int;
		// Use the correct mode
		if (mesh.isLineSegments) {
			mode = WEBGL_CONSTANTS.LINES;
		} else if (mesh.isLineLoop) {
			mode = WEBGL_CONSTANTS.LINE_LOOP;
		} else if (mesh.isLine) {
			mode = WEBGL_CONSTANTS.LINE_STRIP;
		} else if (mesh.isPoints) {
			mode = WEBGL_CONSTANTS.POINTS;
		} else {
			mode = mesh.material.wireframe ? WEBGL_CONSTANTS.LINES : WEBGL_CONSTANTS.TRIANGLES;
		}
		final meshDef:Dynamic = {};
		final attributes:Dynamic = {};
		final primitives:Array<Dynamic> = [];
		final targets:Array<Dynamic> = [];
		// Conversion between attributes names in threejs and gltf spec
		final nameConversion:Map<String,String> = new Map();
		nameConversion.set("uv", "TEXCOORD_0");
		nameConversion.set("uv1", "TEXCOORD_1");
		nameConversion.set("uv2", "TEXCOORD_2");
		nameConversion.set("uv3", "TEXCOORD_3");
		nameConversion.set("color", "COLOR_0");
		nameConversion.set("skinWeight", "WEIGHTS_0");
		nameConversion.set("skinIndex", "JOINTS_0");
		final originalNormal = geometry.getAttribute("normal");
		if (originalNormal != null && !isNormalizedNormalAttribute(originalNormal)) {
			console.warn("THREE.GLTFExporter: Creating normalized normal attribute from the non-normalized one.");
			geometry.setAttribute("normal", createNormalizedNormalAttribute(originalNormal));
		}
		// @QUESTION Detect if .vertexColors = true?
		// For every attribute create an accessor
		var modifiedAttribute:BufferAttribute = null;
		for (attributeName in geometry.attributes) {
			// Ignore morph target attributes, which are exported later.
			if (attributeName.substring(0, 5) == "morph") continue;
			final attribute = geometry.attributes[attributeName];
			attributeName = nameConversion.get(attributeName) || attributeName.toUpperCase();
			// Prefix all geometry attributes except the ones specifically
			// listed in the spec; non-spec attributes are considered custom.
			final validVertexAttributes =
				/^(POSITION|NORMAL|TANGENT|TEXCOORD_\d+|COLOR_\d+|JOINTS_\d+|WEIGHTS_\d+)$/;
			if (!validVertexAttributes.test(attributeName)) attributeName = "_" + attributeName;
			if (cache.attributes.has(getUID(attribute))) {
				attributes[attributeName] = cache.attributes.get(getUID(attribute));
				continue;
			}
			// JOINTS_0 must be UNSIGNED_BYTE or UNSIGNED_SHORT.
			modifiedAttribute = null;
			final array = attribute.array;
			if (attributeName == "JOINTS_0" &&
				!(array is Uint16Array) &&
				!(array is Uint8Array)) {
				console.warn("GLTFExporter: Attribute \"skinIndex\" converted to type UNSIGNED_SHORT.");
				modifiedAttribute = new BufferAttribute(new Uint16Array(array), attribute.itemSize, attribute.normalized);
			}
			final accessor = processAccessor(modifiedAttribute || attribute, geometry);
			if (accessor != null) {
				if (!attributeName.startsWith("_")) {
					detectMeshQuantization(attributeName, attribute);
				}
				attributes[attributeName] = accessor;
				cache.attributes.set(getUID(attribute), accessor);
			}
		}
		if (originalNormal != null) geometry.setAttribute("normal", originalNormal);
		// Skip if no exportable attributes found
		if (Reflect.fields(attributes).length == 0) return null;
		// Morph targets
		if (mesh.morphTargetInfluences != null && mesh.morphTargetInfluences.length > 0) {
			final weights:Array<Float> = [];
			final targetNames:Array<String> = [];
			final reverseDictionary:Map<Int,String> = new Map();
			if (mesh.morphTargetDictionary != null) {
				for (key in mesh.morphTargetDictionary) {
					reverseDictionary.set(mesh.morphTargetDictionary[key], key);
				}
			}
			for (i in 0...mesh.morphTargetInfluences.length) {
				final target:Dynamic = {};
				var warned = false;
				for (attributeName in geometry.morphAttributes) {
					// glTF 2.0 morph supports only POSITION/NORMAL/TANGENT.
					// Three.js doesn't support TANGENT yet.
					if (attributeName != "position" && attributeName != "normal") {
						if (!warned) {
							console.warn("GLTFExporter: Only POSITION and NORMAL morph are supported.");
							warned = true;
						}
						continue;
					}
					final attribute = geometry.morphAttributes[attributeName][i];
					final gltfAttributeName = attributeName.toUpperCase();
					// Three.js morph attribute has absolute values while the one of glTF has relative values.
					//
					// glTF 2.0 Specification:
					// https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#morph-targets
					final baseAttribute = geometry.attributes[attributeName];
					if (cache.attributes.has(getUID(attribute, true))) {
						target[gltfAttributeName] = cache.attributes.get(getUID(attribute, true));
						continue;
					}
					// Clones attribute not to override
					final relativeAttribute = attribute.clone();
					if (!geometry.morphTargetsRelative) {
						for (j in 0...attribute.count) {
							for (a in 0...attribute.itemSize) {
								if (a == 0) relativeAttribute.setX(j, attribute.getX(j) - baseAttribute.getX(j));
								if (a == 1) relativeAttribute.setY(j, attribute.getY(j) - baseAttribute.getY(j));
								if (a == 2) relativeAttribute.setZ(j, attribute.getZ(j) - baseAttribute.getZ(j));
								if (a == 3) relativeAttribute.setW(j, attribute.getW(j) - baseAttribute.getW(j));
							}
						}
					}
					target[gltfAttributeName] = processAccessor(relativeAttribute, geometry);
					cache.attributes.set(getUID(baseAttribute, true), target[gltfAttributeName]);
				}
				targets.push(target);
				weights.push(mesh.morphTargetInfluences[i]);
				if (mesh.morphTargetDictionary != null) targetNames.push(reverseDictionary.get(i));
			}
			meshDef.weights = weights;
			if (targetNames.length > 0) {
				meshDef.extras = {};
				meshDef.extras.targetNames = targetNames;
			}
		}
		final isMultiMaterial = Array.isArray(mesh.material);
		if (isMultiMaterial && geometry.groups.length == 0) return null;
		var didForceIndices = false;
		if (isMultiMaterial && geometry.index == null) {
			final indices:Array<Int> = [];
			for (i in 0...geometry.attributes.position.count) {
				indices[i] = i;
			}
			geometry.setIndex(indices);
			didForceIndices = true;
		}
		final materials:Array<Dynamic> = isMultiMaterial ? mesh.material : [mesh.material];
		final groups:Array<Dynamic> = isMultiMaterial ? geometry.groups : [{ materialIndex: 0, start: null, count: null }];
		for (i in 0...groups.length) {
			final primitive:Dynamic = {
				mode: mode,
				attributes: attributes,
			};
			serializeUserData(geometry, primitive);
			if (targets.length > 0) primitive.targets = targets;
			if (geometry.index != null) {
				var cacheKey = getUID(geometry.index);
				if (groups[i].start != null || groups[i].count != null) {
					cacheKey += ":" + groups[i].start + ":" + groups[i].count;
				}
				if (cache.attributes.has(cacheKey)) {
					primitive.indices = cache.attributes.get(cacheKey);
				} else {
					primitive.indices = processAccessor(geometry.index, geometry, groups[i].start, groups[i].count);
					cache.attributes.set(cacheKey, primitive.indices);
				}
				if (primitive.indices == null) delete primitive.indices;
			}
			final material = processMaterial(materials[groups[i].materialIndex]);
			if (material != null) primitive.material = material;
			primitives.push(primitive);
		}
		if (didForceIndices == true) {
			geometry.setIndex(null);
		}
		meshDef.primitives = primitives;
		if (!json.meshes) json.meshes = [];
		this._invokeAll(function(ext:Dynamic) {
			ext.writeMesh && ext.writeMesh(mesh, meshDef);
		});
		final index = json.meshes.push(meshDef) - 1;
		cache.meshes.set(meshCacheKey, index);
		return index;
	}

	/**
	 * If a vertex attribute with a
	 * [non-standard data type](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#meshes-overview)
	 * is used, it is checked whether it is a valid data type according to the
	 * [KHR_mesh_quantization](https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_mesh_quantization/README.md)
	 * extension.
	 * In this case the extension is automatically added to the list of used extensions.
	 *
	 * @param {string} attributeName
	 * @param {THREE.BufferAttribute} attribute
	 */
	private function detectMeshQuantization(attributeName:String, attribute:BufferAttribute):Void {
		if (this.extensionsUsed[KHR_MESH_QUANTIZATION.KHR_mesh_quantization]) return;
		var attrType:String = null;
		switch (attribute.array.constructor) {
			case Int8Array:
				attrType = "byte";
				break;
			case Uint8Array:
				attrType = "unsigned byte";
				break;
			case Int16Array:
				attrType = "short";
				break;
			case Uint16Array:
				attrType = "unsigned short";
				break;
			default:
				return;
		}
		if (attribute.normalized) attrType += " normalized";
		final attrNamePrefix = attributeName.split("_", 1)[0];
		if (KHR_mesh_quantization_ExtraAttrTypes[attrNamePrefix] && KHR_mesh_quantization_ExtraAttrTypes[attrNamePrefix].indexOf(attrType) != -1) {
			this.extensionsUsed[KHR_MESH_QUANTIZATION.KHR_mesh_quantization] = true;
			this.extensionsRequired[KHR_MESH_QUANTIZATION.KHR_mesh_quantization] = true;
		}
	}

	/**
	 * Process camera
	 * @param  {THREE.Camera} camera Camera to process
	 * @return {Integer}      Index of the processed mesh in the "camera" array
	 */
	private function processCamera(camera:Dynamic):Int {
		final json = this.json;
		if (!json.cameras) json.cameras = [];
		final isOrtho = camera.isOrthographicCamera;
		final cameraDef:Dynamic = {
			type: isOrtho ? "orthographic" : "perspective"
		};
		if (isOrtho) {
			cameraDef.orthographic = {
				xmag: camera.right * 2,
				ymag: camera.top * 2,
				zfar: camera.far <= 0 ? 0.001 : camera.far,
				znear: camera.near < 0 ? 0 : camera.near
			};
		} else {
			cameraDef.perspective = {
				aspectRatio: camera.aspect,
				yfov: MathUtils.degToRad(camera.fov),
				zfar: camera.far <= 0 ? 0.001 : camera.far,
				znear: camera.near < 0 ? 0 : camera.near
			};
		}
		// Question: Is saving "type" as name intentional?
		if (camera.name != "") cameraDef.name = camera.type;
		return json.cameras.push(cameraDef) - 1;
	}

	/**
	 * Creates glTF animation entry from AnimationClip object.
	 *
	 * Status:
	 * - Only properties listed in PATH_PROPERTIES may be animated.
	 *
	 * @param {THREE.AnimationClip} clip
	 * @param {THREE.Object3D} root
	 * @return {number|null}
	 */
	private function processAnimation(clip:Dynamic, root:Dynamic):Int {
		final json = this.json;
		final nodeMap = this.nodeMap;
		if (!json.animations) json.animations = [];
		clip = GLTFExporter.Utils.mergeMorphTargetTracks(clip.clone(), root);
		final tracks = clip.tracks;
		final channels:Array<Dynamic> = [];
		final samplers:Array<Dynamic> = [];
		for (i in 0...tracks.length) {
			final track = tracks[i];
			final trackBinding = PropertyBinding.parseTrackName(track.name);
			var trackNode = PropertyBinding.findNode(root, trackBinding.nodeName);
			final trackProperty = PATH_PROPERTIES.get(trackBinding.propertyName);
			if (trackBinding.objectName == "bones") {
				if (trackNode.isSkinnedMesh == true) {
					trackNode = trackNode.skeleton.getBoneByName(trackBinding.objectIndex);
				} else {
					trackNode = null;
				}
			}
			if (trackNode == null || trackProperty == null) {
				console.warn("THREE.GLTFExporter: Could not export animation track \"%s\".", track.name);
				return null;
			}
			final inputItemSize = 1;
			var outputItemSize = track.values.length / track.times.length;
			if (trackProperty == PATH_PROPERTIES.get("morphTargetInfluences")) {
				outputItemSize /= trackNode.morphTargetInfluences.length;
			}
			var interpolation:String;
			// @TODO export CubicInterpolant(InterpolateSmooth) as CUBICSPLINE
			// Detecting glTF cubic spline interpolant by checking factory method's special property
			// GLTFCubicSplineInterpolant is a custom interpolant and track doesn't return
			// valid value from .getInterpolation().
			if (track.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline == true) {
				interpolation = "CUBICSPLINE";
				// itemSize of CUBICSPLINE keyframe is 9
				// (VEC3 * 3: inTangent, splineVertex, and outTangent)
				// but needs to be stored as VEC3 so dividing by 3 here.
				outputItemSize /= 3;
			} else if (track.getInterpolation() == InterpolateDiscrete) {
				interpolation = "STEP";
			} else {
				interpolation = "LINEAR";
			}
			samplers.push({
				input: processAccessor(new BufferAttribute(track.times, inputItemSize)),
				output: processAccessor(new BufferAttribute(track.values, outputItemSize)),
				interpolation: interpolation
			});
			channels.push({
				sampler: samplers.length - 1,
				target: {
					node: nodeMap.get(trackNode),
					path: trackProperty
				}
			});
		}
		json.animations.push({
			name: clip.name || "clip_" + json.animations.length,
			samplers: samplers,
			channels: channels
		});
		return json.animations.length - 1;
	}

	/**
	 * @param {THREE.Object3D} object
	 * @return {number|null}
	 */
	private function processSkin(object:Dynamic):Int {
		final json = this.json;
		final nodeMap = this.nodeMap;
		final node = json.nodes[nodeMap.get(object)];
		final skeleton = object.skeleton;
		if (skeleton == null) return null;
		final rootJoint = object.skeleton.bones[0];
		if (rootJoint == null) return null;
		final joints:Array<Int> = [];
		final inverseBindMatrices = new Float32Array(skeleton.bones.length * 16);
		final temporaryBoneInverse = new Matrix4();
		for (i in 0...skeleton.bones.length) {
			joints.push(nodeMap.get(skeleton.bones[i]));
			temporaryBoneInverse.copy(skeleton.boneInverses[i]);
			temporaryBoneInverse.multiply(object.bindMatrix).toArray(inverseBindMatrices, i * 16);
		}
		if (json.skins == null) json.skins = [];
		json.skins.push({
			inverseBindMatrices: processAccessor(new BufferAttribute(inverseBindMatrices, 16)),
			joints: joints,
			skeleton: nodeMap.get(rootJoint)
		});
		final skinIndex = node.skin = json.skins.length - 1;
		return skinIndex;
	}

	/**
	 * Process Object3D node
	 * @param  {THREE.Object3D} node Object3D to processNode
	 * @return {Integer} Index of the node in the nodes list
	 */
	private function processNode(object:Dynamic):Int {
		final json = this.json;
		final options = this.options;
		final nodeMap = this.nodeMap;
		if (!json.nodes) json.nodes = [];
		final nodeDef:Dynamic = {};
		if (options.trs) {
			final rotation = object.quaternion.toArray();
			final position = object.position.toArray();
			final scale = object.scale.toArray();
			if (!equalArray(rotation, [0, 0, 0, 1])) {
				nodeDef.rotation = rotation;
			}
			if (!equalArray(position, [0, 0, 0])) {
				nodeDef.translation = position;
			}
			if (!equalArray(scale, [1, 1, 1])) {
				nodeDef.scale = scale;
			}
		} else {
			if (object.matrixAutoUpdate) {
				object.updateMatrix();
			}
			if (isIdentityMatrix(object.matrix) == false) {
				nodeDef.matrix = object.matrix.elements;
			}
		}
		// We don't export empty strings name because it represents no-name in Three.js.
		
			}
		} else {
			if (object.matrixAutoUpdate) {
				object.updateMatrix();
			}
			if (isIdentityMatrix(object.matrix) == false) {
				nodeDef.matrix = object.matrix.elements;
			}
		}
		// We don't export empty strings name because it represents no-name in Three.js.
		if (object.name != "") nodeDef.name = String(object.name);
		serializeUserData(object, nodeDef);
		if (object.isMesh || object.isLine || object.isPoints) {
			final meshIndex = processMesh(object);
			if (meshIndex != null) nodeDef.mesh = meshIndex;
		} else if (object.isCamera) {
			nodeDef.camera = processCamera(object);
		}
		if (object.isSkinnedMesh) this.skins.push(object);
		if (object.children.length > 0) {
			final children:Array<Int> = [];
			for (i in 0...object.children.length) {
				final child = object.children[i];
				if (child.visible || options.onlyVisible == false) {
					final nodeIndex = processNode(child);
					if (nodeIndex != null) children.push(nodeIndex);
				}
			}
			if (children.length > 0) nodeDef.children = children;
		}
		this._invokeAll(function(ext:Dynamic) {
			ext.writeNode && ext.writeNode(object, nodeDef);
		});
		final nodeIndex = json.nodes.push(nodeDef) - 1;
		nodeMap.set(object, nodeIndex);
		return nodeIndex;
	}

	/**
	 * Process Scene
	 * @param  {Scene} node Scene to process
	 */
	private function processScene(scene:Scene) {
		final json = this.json;
		final options = this.options;
		if (!json.scenes) {
			json.scenes = [];
			json.scene = 0;
		}
		final sceneDef:Dynamic = {};
		if (scene.name != "") sceneDef.name = scene.name;
		json.scenes.push(sceneDef);
		final nodes:Array<Int> = [];
		for (i in 0...scene.children.length) {
			final child = scene.children[i];
			if (child.visible || options.onlyVisible == false) {
				final nodeIndex = processNode(child);
				if (nodeIndex != null) nodes.push(nodeIndex);
			}
		}
		if (nodes.length > 0) sceneDef.nodes = nodes;
		serializeUserData(scene, sceneDef);
	}

	/**
	 * Creates a Scene to hold a list of objects and parse it
	 * @param  {Array} objects List of objects to process
	 */
	private function processObjects(objects:Array<Dynamic>) {
		final scene = new Scene();
		scene.name = "AuxScene";
		for (i in 0...objects.length) {
			// We push directly to children instead of calling `add` to prevent
			// modify the .parent and break its original scene and hierarchy
			scene.children.push(objects[i]);
		}
		processScene(scene);
	}

	/**
	 * @param {THREE.Object3D|Array<THREE.Object3D>} input
	 */
	private function processInput(input:Dynamic) {
		final options = this.options;
		input = input is Array ? input : [input];
		this._invokeAll(function(ext:Dynamic) {
			ext.beforeParse && ext.beforeParse(input);
		});
		final objectsWithoutScene:Array<Dynamic> = [];
		for (i in 0...input.length) {
			if (input[i] is Scene) {
				processScene(input[i]);
			} else {
				objectsWithoutScene.push(input[i]);
			}
		}
		if (objectsWithoutScene.length > 0) processObjects(objectsWithoutScene);
		for (i in 0...this.skins.length) {
			processSkin(this.skins[i]);
		}
		for (i in 0...options.animations.length) {
			processAnimation(options.animations[i], input[0]);
		}
		this._invokeAll(function(ext:Dynamic) {
			ext.afterParse && ext.afterParse(input);
		});
	}

	private function _invokeAll(func:Dynamic):Void {
		for (i in 0...this.plugins.length) {
			func(this.plugins[i]);
		}
	}

}

/**
 * Punctual Lights Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_lights_punctual
 */
class GLTFLightExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_lights_punctual";
	}

	public function writeNode(light:Dynamic, nodeDef:Dynamic):Void {
		if (!light.isLight) return;
		if (!light.isDirectionalLight && !light.isPointLight && !light.isSpotLight) {
			console.warn("THREE.GLTFExporter: Only directional, point, and spot lights are supported.", light);
			return;
		}
		final writer = this.writer;
		final json = writer.json;
		final extensionsUsed = writer.extensionsUsed;
		final lightDef:Dynamic = {};
		if (light.name) lightDef.name = light.name;
		lightDef.color = light.color.toArray();
		lightDef.intensity = light.intensity;
		if (light.isDirectionalLight) {
			lightDef.type = "directional";
		} else if (light.isPointLight) {
			lightDef.type = "point";
			if (light.distance > 0) lightDef.range = light.distance;
		} else if (light.isSpotLight) {
			lightDef.type = "spot";
			if (light.distance > 0) lightDef.range = light.distance;
			lightDef.spot = {};
			lightDef.spot.innerConeAngle = (1.0 - light.penumbra) * light.angle;
			lightDef.spot.outerConeAngle = light.angle;
		}
		if (light.decay != null && light.decay != 2) {
			console.warn("THREE.GLTFExporter: Light decay may be lost. glTF is physically-based, "
				+ "and expects light.decay=2.");
		}
		if (light.target &&
			(light.target.parent != light ||
			light.target.position.x != 0 ||
			light.target.position.y != 0 ||
			light.target.position.z != -1)) {
			console.warn("THREE.GLTFExporter: Light direction may be lost. For best results, "
				+ "make light.target a child of the light with position 0,0,-1.");
		}
		if (!extensionsUsed[this.name]) {
			json.extensions = json.extensions || {};
			json.extensions[this.name] = { lights: [] };
			extensionsUsed[this.name] = true;
		}
		final lights = json.extensions[this.name].lights;
		lights.push(lightDef);
		nodeDef.extensions = nodeDef.extensions || {};
		nodeDef.extensions[this.name] = { light: lights.length - 1 };
	}

}

/**
 * Unlit Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_unlit
 */
class GLTFMaterialsUnlitExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_unlit";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshBasicMaterial) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = {};
		extensionsUsed[this.name] = true;
		materialDef.pbrMetallicRoughness.metallicFactor = 0.0;
		materialDef.pbrMetallicRoughness.roughnessFactor = 0.9;
	}

}

/**
 * Clearcoat Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_clearcoat
 */
class GLTFMaterialsClearcoatExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_clearcoat";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.clearcoat == 0) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		final extensionDef:Dynamic = {};
		extensionDef.clearcoatFactor = material.clearcoat;
		if (material.clearcoatMap) {
			final clearcoatMapDef = {
				index: writer.processTexture(material.clearcoatMap),
				texCoord: material.clearcoatMap.channel
			};
			writer.applyTextureTransform(clearcoatMapDef, material.clearcoatMap);
			extensionDef.clearcoatTexture = clearcoatMapDef;
		}
		extensionDef.clearcoatRoughnessFactor = material.clearcoatRoughness;
		if (material.clearcoatRoughnessMap) {
			final clearcoatRoughnessMapDef = {
				index: writer.processTexture(material.clearcoatRoughnessMap),
				texCoord: material.clearcoatRoughnessMap.channel
			};
			writer.applyTextureTransform(clearcoatRoughnessMapDef, material.clearcoatRoughnessMap);
			extensionDef.clearcoatRoughnessTexture = clearcoatRoughnessMapDef;
		}
		if (material.clearcoatNormalMap) {
			final clearcoatNormalMapDef = {
				index: writer.processTexture(material.clearcoatNormalMap),
				texCoord: material.clearcoatNormalMap.channel
			};
			if (material.clearcoatNormalScale.x != 1) clearcoatNormalMapDef.scale = material.clearcoatNormalScale.x;
			writer.applyTextureTransform(clearcoatNormalMapDef, material.clearcoatNormalMap);
			extensionDef.clearcoatNormalTexture = clearcoatNormalMapDef;
		}
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed[this.name] = true;
	}

}

/**
 * Materials dispersion Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_dispersion
 */
class GLTFMaterialsDispersionExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_dispersion";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.dispersion == 0) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		final extensionDef:Dynamic = {};
		extensionDef.dispersion = material.dispersion;
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed[this.name] = true;
	}

}

/**
 * Iridescence Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_iridescence
 */
class GLTFMaterialsIridescenceExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_iridescence";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.iridescence == 0) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		final extensionDef:Dynamic = {};
		extensionDef.iridescenceFactor = material.iridescence;
		if (material.iridescenceMap) {
			final iridescenceMapDef = {
				index: writer.processTexture(material.iridescenceMap),
				texCoord: material.iridescenceMap.channel
			};
			writer.applyTextureTransform(iridescenceMapDef, material.iridescenceMap);
			extensionDef.iridescenceTexture = iridescenceMapDef;
		}
		extensionDef.iridescenceIor = material.iridescenceIOR;
		extensionDef.iridescenceThicknessMinimum = material.iridescenceThicknessRange[0];
		extensionDef.iridescenceThicknessMaximum = material.iridescenceThicknessRange[1];
		if (material.iridescenceThicknessMap) {
			final iridescenceThicknessMapDef = {
				index: writer.processTexture(material.iridescenceThicknessMap),
				texCoord: material.iridescenceThicknessMap.channel
			};
			writer.applyTextureTransform(iridescenceThicknessMapDef, material.iridescenceThicknessMap);
			extensionDef.iridescenceThicknessTexture = iridescenceThicknessMapDef;
		}
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed[this.name] = true;
	}

}

/**
 * Transmission Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_transmission
 */
class GLTFMaterialsTransmissionExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_transmission";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.transmission == 0) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		final extensionDef:Dynamic = {};
		extensionDef.transmissionFactor = material.transmission;
		if (material.transmissionMap) {
			final transmissionMapDef = {
				index: writer.processTexture(material.transmissionMap),
				texCoord: material.transmissionMap.channel
			};
			writer.applyTextureTransform(transmissionMapDef, material.transmissionMap);
			extensionDef.transmissionTexture = transmissionMapDef;
		}
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed[this.name] = true;
	}

}

/**
 * Materials Volume Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_volume
 */
class GLTFMaterialsVolumeExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_volume";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.transmission == 0) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		final extensionDef:Dynamic = {};
		extensionDef.thicknessFactor = material.thickness;
		if (material.thicknessMap) {
			final thicknessMapDef = {
				index: writer.processTexture(material.thicknessMap),
				texCoord: material.thicknessMap.channel
			};
			writer.applyTextureTransform(thicknessMapDef, material.thicknessMap);
			extensionDef.thicknessTexture = thicknessMapDef;
		}
		extensionDef.attenuationDistance = material.attenuationDistance;
		extensionDef.attenuationColor = material.attenuationColor.toArray();
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed[this.name] = true;
	}

}

/**
 * Materials ior Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_ior
 */
class GLTFMaterialsIorExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_ior";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.ior == 1.5) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		final extensionDef:Dynamic = {};
		extensionDef.ior = material.ior;
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed[this.name] = true;
	}

}

/**
 * Materials specular Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_specular
 */
class GLTFMaterialsSpecularExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_specular";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || (material.specularIntensity == 1.0 &&
			material.specularColor.equals(DEFAULT_SPECULAR_COLOR) &&
			!material.specularIntensityMap && !material.specularColorMap)) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		final extensionDef:Dynamic = {};
		if (material.specularIntensityMap) {
			final specularIntensityMapDef = {
				index: writer.processTexture(material.specularIntensityMap),
				texCoord: material.specularIntensityMap.channel
			};
			writer.applyTextureTransform(specularIntensityMapDef, material.specularIntensityMap);
			extensionDef.specularTexture = specularIntensityMapDef;
		}
		if (material.specularColorMap) {
			final specularColorMapDef = {
				index: writer.processTexture(material.specularColorMap),
				texCoord: material.specularColorMap.channel
			};
			writer.applyTextureTransform(specularColorMapDef, material.specularColorMap);
			extensionDef.specularColorTexture = specularColorMapDef;
		}
		extensionDef.specularFactor = material.specularIntensity;
		extensionDef.specularColorFactor = material.specularColor.toArray();
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed[this.name] = true;
	}

}

/**
 * Sheen Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_materials_sheen
 */
class GLTFMaterialsSheenExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_sheen";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.sheen == 0.0) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		final extensionDef:Dynamic = {};
		if (material.sheenRoughnessMap) {
			final sheenRoughnessMapDef = {
				index: writer.processTexture(material.sheenRoughnessMap),
				texCoord: material.sheenRoughnessMap.channel
			};
			writer.applyTextureTransform(sheenRoughnessMapDef, material.sheenRoughnessMap);
			extensionDef.sheenRoughnessTexture = sheenRoughnessMapDef;
		}
		if (material.sheenColorMap) {
			final sheenColorMapDef = {
				index: writer.processTexture(material.sheenColorMap),
				texCoord: material.sheenColorMap.channel
			};
			writer.applyTextureTransform(sheenColorMapDef, material.sheenColorMap);
			extensionDef.sheenColorTexture = sheenColorMapDef;
		}
		extensionDef.sheenRoughnessFactor = material.sheenRoughness;
		extensionDef.sheenColorFactor = material.sheenColor.toArray();
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed[this.name] = true;
	}

}

/**
 * Anisotropy Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/main/extensions/2.0/Khronos/KHR_materials_anisotropy
 */
class GLTFMaterialsAnisotropyExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_anisotropy";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshPhysicalMaterial || material.anisotropy == 0.0) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		final extensionDef:Dynamic = {};
		if (material.anisotropyMap) {
			final anisotropyMapDef = { index: writer.processTexture(material.anisotropyMap) };
			writer.applyTextureTransform(anisotropyMapDef, material.anisotropyMap);
			extensionDef.anisotropyTexture = anisotropyMapDef;
		}
		extensionDef.anisotropyStrength = material.anisotropy;
		extensionDef.anisotropyRotation = material.anisotropyRotation;
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed[this.name] = true;
	}

}

/**
 * Materials Emissive Strength Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/blob/5768b3ce0ef32bc39cdf1bef10b948586635ead3/extensions/2.0/Khronos/KHR_materials_emissive_strength/README.md
 */
class GLTFMaterialsEmissiveStrengthExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_emissive_strength";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshStandardMaterial || material.emissiveIntensity == 1.0) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		final extensionDef:Dynamic = {};
		extensionDef.emissiveStrength = material.emissiveIntensity;
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed[this.name] = true;
	}

}


/**
 * Materials bump Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/EXT_materials_bump
 */
class GLTFMaterialsBumpExtension {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "EXT_materials_bump";
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!material.isMeshStandardMaterial || (
			material.bumpScale == 1 &&
			!material.bumpMap)) return;
		final writer = this.writer;
		final extensionsUsed = writer.extensionsUsed;
		final extensionDef:Dynamic = {};
		if (material.bumpMap) {
			final bumpMapDef = {
				index: writer.processTexture(material.bumpMap),
				texCoord: material.bumpMap.channel
			};
			writer.applyTextureTransform(bumpMapDef, material.bumpMap);
			extensionDef.bumpTexture = bumpMapDef;
		}
		extensionDef.bumpFactor = material.bumpScale;
		materialDef.extensions = materialDef.extensions || {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed[this.name] = true;
	}

}

/**
 * GPU Instancing Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Vendor/EXT_mesh_gpu_instancing
 */
class GLTFMeshGpuInstancing {

	private writer:GLTFWriter;
	private name:String;

	public function new(writer:GLTFWriter) {
		this.writer = writer;
		this.name = "EXT_mesh_gpu_instancing";
	}

	public function writeNode(object:Dynamic, nodeDef:Dynamic):Void {
		if (!object.isInstancedMesh) return;
		final writer = this.writer;
		final mesh = object;
		final translationAttr = new Float32Array(mesh.count * 3);
		final rotationAttr = new Float32Array(mesh.count * 4);
		final scaleAttr = new Float32Array(mesh.count * 3);
		final matrix = new Matrix4();
		final position = new Vector3();
		final quaternion = new Quaternion();
		final scale = new Vector3();
		for (i in 0...mesh.count) {
			mesh.getMatrixAt(i, matrix);
			matrix.decompose(position, quaternion, scale);
			position.toArray(translationAttr, i * 3);
			quaternion.toArray(rotationAttr, i * 4);
			scale.toArray(scaleAttr, i * 3);
		}
		final attributes:Dynamic = {
			TRANSLATION: writer.processAccessor(new BufferAttribute(translationAttr, 3)),
			ROTATION: writer.processAccessor(new BufferAttribute(rotationAttr, 4)),
			SCALE: writer.processAccessor(new BufferAttribute(scaleAttr, 3)),
		};
		if (mesh.instanceColor)
			attributes._COLOR_0 = writer.processAccessor(mesh.instanceColor);
		nodeDef.extensions = nodeDef.extensions || {};
		nodeDef.extensions[this.name] = { attributes };
		writer.extensionsUsed[this.name] = true;
		writer.extensionsRequired[this.name] = true;
	}

}

/**
 * Static utility functions
 */
class GLTFExporterUtils {

	public static function insertKeyframe(track:Dynamic, time:Float):Int {
		final tolerance = 0.001; // 1ms
		final valueSize = track.getValueSize();
		final times = new track.TimeBufferType(track.times.length + 1);
		final values = new track.ValueBufferType(track.values.length + valueSize);
		final interpolant = track.createInterpolant(new track.ValueBufferType(valueSize));
		var index:Int;
		if (track.times.length == 0) {
			times[0] = time;
			for (i in 0...valueSize) {
				values[i] = 0;
			}
			index = 0;
		} else if (time < track.times[0]) {
			if (Math.abs(track.times[0] - time) < tolerance) return 0;
			times[0] = time;
			times.set(track.times, 1);
			values.set(interpolant.evaluate(time), 0);
			values.set(track.values, valueSize);
			index = 0;
		} else if (time > track.times[track.times.length - 1]) {
			if (Math.abs(track.times[track.times.length - 1] - time) < tolerance) {
				return track.times.length - 1;
			}
			times[times.length - 1] = time;
			times.set(track.times, 0);
			values.set(track.values, 0);
			values.set(interpolant.evaluate(time), track.values.length);
			index = times.length - 1;
		} else {
			for (i in 0...track.times.length) {
				if (Math.abs(track.times[i] - time) < tolerance) return i;
				if (track.times[i] < time && track.times[i + 1] > time) {
					times.set(track.times.slice(0, i + 1), 0);
					times[i + 1] = time;
					times.set(track.times.slice(i + 1), i + 2);
					values.set(track.values.slice(0, (i + 1) * valueSize), 0);
					values.set(interpolant.evaluate(time), (i + 1) * valueSize);
					values.set(track.values.slice((i + 1) * valueSize), (i + 2) * valueSize);
					index = i + 1;
					break;
				}
			}
		}
		track.times = times;
		track.values = values;
		return index;
	}

	public static function mergeMorphTargetTracks(clip:Dynamic, root:Dynamic):Dynamic {
		final tracks:Array<Dynamic> = [];
		final mergedTracks:Map<String,Dynamic> = new Map();
		final sourceTracks = clip.tracks;
		for (i in 0...sourceTracks.length) {
			var sourceTrack = sourceTracks[i];
			final sourceTrackBinding = PropertyBinding.parseTrackName(sourceTrack.name);
			final sourceTrackNode = PropertyBinding.findNode(root, sourceTrackBinding.nodeName);
			if (sourceTrackBinding.propertyName != "morphTargetInfluences" || sourceTrackBinding.propertyIndex == null) {
				// Tracks that don't affect morph targets, or that affect all morph targets together, can be left as-is.
				tracks.push(sourceTrack);
				continue;
			}
			if (sourceTrack.createInterpolant != sourceTrack.InterpolantFactoryMethodDiscrete &&
				sourceTrack.createInterpolant != sourceTrack.InterpolantFactoryMethodLinear) {
				if (sourceTrack.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline) {
					// This should never happen, because glTF morph target animations
					// affect all targets already.
					throw new Error("THREE.GLTFExporter: Cannot merge tracks with glTF CUBICSPLINE interpolation.");
				}
				console.warn("THREE.GLTFExporter: Morph target interpolation mode not yet supported. Using LINEAR instead.");
				sourceTrack = sourceTrack.clone();
				sourceTrack.setInterpolation(InterpolateLinear);
			}
			final targetCount = sourceTrackNode.morphTargetInfluences.length;
			final targetIndex = sourceTrackNode.morphTargetDictionary[sourceTrackBinding.propertyIndex];
			if (targetIndex == null) {
				throw new Error("THREE.GLTFExporter: Morph target name not found: " + sourceTrackBinding.propertyIndex);
			}
			var mergedTrack:Dynamic;
			// If this is the first time we've seen this object, create a new
			// track to store merged keyframe data for each morph target.
			if (!mergedTracks.has(sourceTrackNode.uuid)) {
				mergedTrack = sourceTrack.clone();
				final values = new mergedTrack.ValueBufferType(targetCount * mergedTrack.times.length);
				for (j in 0...mergedTrack.times.length) {
					values[j * targetCount + targetIndex] = mergedTrack.values[j];
				}
				// We need to take into consideration the intended target node
				// of our original un-merged morphTarget animation.
				mergedTrack.name = (sourceTrackBinding.nodeName || "") + ".morphTargetInfluences";
				mergedTrack.values = values;
				mergedTracks.set(sourceTrackNode.uuid, mergedTrack);
				tracks.push(mergedTrack);
				continue;
			}
			final sourceInterpolant = sourceTrack.createInterpolant(new sourceTrack.ValueBufferType(1));
			mergedTrack = mergedTracks.get(sourceTrackNode.uuid);
			// For every existing keyframe of the merged track, write a (possibly
			// interpolated) value from the source track.
			for (j in 0...mergedTrack.times.length) {
				mergedTrack.values[j * targetCount + targetIndex] = sourceInterpolant.evaluate(mergedTrack.times[j]);
			}
			// For every existing keyframe of the source track, write a (possibly
			// new) keyframe to the merged track. Values from the previous loop may
			// be written again, but keyframes are de-duplicated.
			for (j in 0...sourceTrack.times.length) {
				final keyframeIndex = GLTFExporterUtils.insertKeyframe(mergedTrack, sourceTrack.times[j]);
				mergedTrack.values[keyframeIndex * targetCount + targetIndex
			// interpolated) value from the source track.
			for (j in 0...mergedTrack.times.length) {
				mergedTrack.values[j * targetCount + targetIndex] = sourceInterpolant.evaluate(mergedTrack.times[j]);
			}
			// For every existing keyframe of the source track, write a (possibly
			// new) keyframe to the merged track. Values from the previous loop may
			// be written again, but keyframes are de-duplicated.
			for (j in 0...sourceTrack.times.length) {
				final keyframeIndex = GLTFExporterUtils.insertKeyframe(mergedTrack, sourceTrack.times[j]);
				mergedTrack.values[keyframeIndex * targetCount + targetIndex] = sourceTrack.values[j];
			}
		}
		clip.tracks = tracks;
		return clip;
	}

};

class GLTFExporter {

	private pluginCallbacks:Array<Dynamic> = [];

	public function new() {
		register(function(writer:GLTFWriter) return new GLTFLightExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsUnlitExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsTransmissionExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsVolumeExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsIorExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsSpecularExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsClearcoatExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsDispersionExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsIridescenceExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsSheenExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsAnisotropyExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsEmissiveStrengthExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMaterialsBumpExtension(writer));
		register(function(writer:GLTFWriter) return new GLTFMeshGpuInstancing(writer));
	}

	public function register(callback:Dynamic):GLTFExporter {
		if (pluginCallbacks.indexOf(callback) == -1) {
			pluginCallbacks.push(callback);
		}
		return this;
	}

	public function unregister(callback:Dynamic):GLTFExporter {
		if (pluginCallbacks.indexOf(callback) != -1) {
			pluginCallbacks.splice(pluginCallbacks.indexOf(callback), 1);
		}
		return this;
	}

	/**
	 * Parse scenes and generate GLTF output
	 * @param  {Scene or [THREE.Scenes]} input   Scene or Array of THREE.Scenes
	 * @param  {Function} onDone  Callback on completed
	 * @param  {Function} onError  Callback on errors
	 * @param  {Object} options options
	 */
	public function parse(input:Scene, onDone:Dynamic, onError:Dynamic, options:Dynamic = null) {
		final writer = new GLTFWriter();
		final plugins:Array<Dynamic> = [];

		for (i in 0...pluginCallbacks.length) {
			plugins.push(pluginCallbacks[i](writer));
		}

		writer.setPlugins(plugins);
		writer.write(input, onDone, options).catch(onError);
	}

	public function parseAsync(input:Scene, options:Dynamic = null):Promise<Dynamic> {
		final scope = this;
		return new Promise(function(resolve:Dynamic, reject:Dynamic) {
			scope.parse(input, resolve, reject, options);
		});
	}

}

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

enum WEBGL_CONSTANTS {
	POINTS = 0x0000;
	LINES = 0x0001;
	LINE_LOOP = 0x0002;
	LINE_STRIP = 0x0003;
	TRIANGLES = 0x0004;
	TRIANGLE_STRIP = 0x0005;
	TRIANGLE_FAN = 0x0006;

	BYTE = 0x1400;
	UNSIGNED_BYTE = 0x1401;
	SHORT = 0x1402;
	UNSIGNED_SHORT = 0x1403;
	INT = 0x1404;
	UNSIGNED_INT = 0x1405;
	FLOAT = 0x1406;

	ARRAY_BUFFER = 0x8892;
	ELEMENT_ARRAY_BUFFER = 0x8893;

	NEAREST = 0x2600;
	LINEAR = 0x2601;
	NEAREST_MIPMAP_NEAREST = 0x2700;
	LINEAR_MIPMAP_NEAREST = 0x2701;
	NEAREST_MIPMAP_LINEAR = 0x2702;
	LINEAR_MIPMAP_LINEAR = 0x2703;

	CLAMP_TO_EDGE = 33071;
	MIRRORED_REPEAT = 33648;
	REPEAT = 10497;
}

private enum KHR_MESH_QUANTIZATION {
	KHR_mesh_quantization = "KHR_mesh_quantization";
}

private var THREE_TO_WEBGL:Map<Int,Int> = new Map();

THREE_TO_WEBGL.set(NearestFilter, WEBGL_CONSTANTS.NEAREST);
THREE_TO_WEBGL.set(NearestMipmapNearestFilter, WEBGL_CONSTANTS.NEAREST_MIPMAP_NEAREST);
THREE_TO_WEBGL.set(NearestMipmapLinearFilter, WEBGL_CONSTANTS.NEAREST_MIPMAP_LINEAR);
THREE_TO_WEBGL.set(LinearFilter, WEBGL_CONSTANTS.LINEAR);
THREE_TO_WEBGL.set(LinearMipmapNearestFilter, WEBGL_CONSTANTS.LINEAR_MIPMAP_NEAREST);
THREE_TO_WEBGL.set(LinearMipmapLinearFilter, WEBGL_CONSTANTS.LINEAR_MIPMAP_LINEAR);

THREE_TO_WEBGL.set(ClampToEdgeWrapping, WEBGL_CONSTANTS.CLAMP_TO_EDGE);
THREE_TO_WEBGL.set(RepeatWrapping, WEBGL_CONSTANTS.REPEAT);
THREE_TO_WEBGL.set(MirroredRepeatWrapping, WEBGL_CONSTANTS.MIRRORED_REPEAT);

private var PATH_PROPERTIES:Map<String,String> = new Map();

PATH_PROPERTIES.set("scale", "scale");
PATH_PROPERTIES.set("position", "translation");
PATH_PROPERTIES.set("quaternion", "rotation");
PATH_PROPERTIES.set("morphTargetInfluences", "weights");

private var DEFAULT_SPECULAR_COLOR = new Color();

// GLB constants
// https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#glb-file-format-specification

private const GLB_HEADER_BYTES = 12;
private const GLB_HEADER_MAGIC = 0x46546C67;
private const GLB_VERSION = 2;

private const GLB_CHUNK_PREFIX_BYTES = 8;
private const GLB_CHUNK_TYPE_JSON = 0x4E4F534A;
private const GLB_CHUNK_TYPE_BIN = 0x004E4942;

//------------------------------------------------------------------------------
// Utility functions
//------------------------------------------------------------------------------

/**
 * Compare two arrays
 * @param  {Array} array1 Array 1 to compare
 * @param  {Array} array2 Array 2 to compare
 * @return {Boolean}        Returns true if both arrays are equal
 */
private function equalArray(array1:Array<Float>, array2:Array<Float>):Bool {
	return (array1.length == array2.length) && array1.every(function(element, index) {
		return element == array2[index];
	});
}

/**
 * Converts a string to an ArrayBuffer.
 * @param  {string} text
 * @return {ArrayBuffer}
 */
private function stringToArrayBuffer(text:String):ArrayBuffer {
	return new TextEncoder().encode(text).buffer;
}

/**
 * Is identity matrix
 *
 * @param {Matrix4} matrix
 * @returns {Boolean} Returns true, if parameter is identity matrix
 */
private function isIdentityMatrix(matrix:Matrix4):Bool {
	return equalArray(matrix.elements, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
}

/**
 * Get the min and max vectors from the given attribute
 * @param  {BufferAttribute} attribute Attribute to find the min/max in range from start to start + count
 * @param  {Integer} start
 * @param  {Integer} count
 * @return {Object} Object containing the `min` and `max` values (As an array of attribute.itemSize components)
 */
private function getMinMax(attribute:BufferAttribute, start:Int, count:Int):{min:Array<Float>, max:Array<Float>} {
	final output = {
		min: new Array<Float>(attribute.itemSize).fill(Float.POSITIVE_INFINITY),
		max: new Array<Float>(attribute.itemSize).fill(Float.NEGATIVE_INFINITY)
	};

	for (i in start...start + count) {
		for (a in 0...attribute.itemSize) {
			var value:Float;
			if (attribute.itemSize > 4) {
				// no support for interleaved data for itemSize > 4
				value = attribute.array[i * attribute.itemSize + a];
			} else {
				if (a == 0) value = attribute.getX(i);
				else if (a == 1) value = attribute.getY(i);
				else if (a == 2) value = attribute.getZ(i);
				else if (a == 3) value = attribute.getW(i);
				if (attribute.normalized == true) {
					value = MathUtils.normalize(value, attribute.array);
				}
			}
			output.min[a] = Math.min(output.min[a], value);
			output.max[a] = Math.max(output.max[a], value);
		}
	}
	return output;
}

/**
 * Get the required size + padding for a buffer, rounded to the next 4-byte boundary.
 * https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#data-alignment
 *
 * @param {Integer} bufferSize The size the original buffer.
 * @returns {Integer} new buffer size with required padding.
 *
 */
private function getPaddedBufferSize(bufferSize:Int):Int {
	return Math.ceil(bufferSize / 4) * 4;
}

/**
 * Returns a buffer aligned to 4-byte boundary.
 *
 * @param {ArrayBuffer} arrayBuffer Buffer to pad
 * @param {Integer} paddingByte (Optional)
 * @returns {ArrayBuffer} The same buffer if it's already aligned to 4-byte boundary or a new buffer
 */
private function getPaddedArrayBuffer(arrayBuffer:ArrayBuffer, paddingByte:Int = 0):ArrayBuffer {
	final paddedLength = getPaddedBufferSize(arrayBuffer.byteLength);
	if (paddedLength != arrayBuffer.byteLength) {
		final array = new Uint8Array(paddedLength);
		array.set(new Uint8Array(arrayBuffer));
		if (paddingByte != 0) {
			for (i in arrayBuffer.byteLength...paddedLength) {
				array[i] = paddingByte;
			}
		}
		return array.buffer;
	}
	return arrayBuffer;
}

private function getCanvas():HTMLCanvasElement {
	if (typeof document == "undefined" && typeof OffscreenCanvas != "undefined") {
		return new OffscreenCanvas(1, 1);
	}
	return document.createElement("canvas");
}

private function getToBlobPromise(canvas:HTMLCanvasElement, mimeType:String):Promise<Dynamic> {
	if (canvas.toBlob != null) {
		return new Promise(function(resolve:Dynamic) {
			canvas.toBlob(resolve, mimeType);
		});
	}
	var quality:Float;
	// Blink's implementation of convertToBlob seems to default to a quality level of 100%
	// Use the Blink default quality levels of toBlob instead so that file sizes are comparable.
	if (mimeType == "image/jpeg") {
		quality = 0.92;
	} else if (mimeType == "image/webp") {
		quality = 0.8;
	}
	return canvas.convertToBlob({
		type: mimeType,
		quality: quality
	});
}

/**
 * Writer
 */
class GLTFWriter {

	private plugins:Array<Dynamic> = [];
	private options:Dynamic = null;
	private pending:Array<Promise<Dynamic>> = [];
	private buffers:Array<ArrayBuffer> = [];
	private byteOffset:Int = 0;
	private nodeMap:Map<Dynamic,Int> = new Map();
	private skins:Array<Dynamic> = [];
	private extensionsUsed:Map<String,Bool> = new Map();
	private extensionsRequired:Map<String,Bool> = new Map();
	private uids:Map<Dynamic,Map<Bool,Int>> = new Map();
	private uid:Int = 0;
	private json:Dynamic = {
		asset: {
			version: "2.0",
			generator: "THREE.GLTFExporter r" + REVISION
		}
	};
	private cache:{meshes:Map<String,Int>, attributes:Map<Int,Int>, attributesNormalized:Map<Dynamic,BufferAttribute>, materials:Map<Dynamic,Int>, textures:Map<Dynamic,Int>, images:Map<Dynamic,Dynamic>} = {
		meshes: new Map(),
		attributes: new Map(),
		attributesNormalized: new Map(),
		materials: new Map(),
		textures: new Map(),
		images: new Map()
	};

	public function new() {}

	public function setPlugins(plugins:Array<Dynamic>):Void {
		this.plugins = plugins;
	}

	/**
	 * Parse scenes and generate GLTF output
	 * @param  {Scene or [THREE.Scenes]} input   Scene or Array of THREE.Scenes
	 * @param  {Function} onDone  Callback on completed
	 * @param  {Object} options options
	 */
	public function write(input:Scene, onDone:Dynamic, options:Dynamic = null):Promise<Dynamic> {
		this.options = {
			// default options
			binary: false,
			trs: false,
			onlyVisible: true,
			maxTextureSize: Float.POSITIVE_INFINITY,
			animations: [],
			includeCustomExtensions: false
		}.merge(options);

		if (this.options.animations.length > 0) {
			// Only TRS properties, and not matrices, may be targeted by animation.
			this.options.trs = true;
		}

		processInput(input);
		return Promise.all(pending).then(function(_) {
			final writer = this;
			final buffers = writer.buffers;
			final json = writer.json;
			options = writer.options;
			final extensionsUsed = writer.extensionsUsed;
			final extensionsRequired = writer.extensionsRequired;
			// Merge buffers.
			final blob = new Blob(buffers, { type: "application/octet-stream" });
			// Declare extensions.
			final extensionsUsedList = extensionsUsed.keys();
			final extensionsRequiredList = extensionsRequired.keys();
			if (extensionsUsedList.length > 0) json.extensionsUsed = extensionsUsedList;
			if (extensionsRequiredList.length > 0) json.extensionsRequired = extensionsRequiredList;
			// Update bytelength of the single buffer.
			if (json.buffers && json.buffers.length > 0) json.buffers[0].byteLength = blob.size;
			if (options.binary == true) {
				// https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#glb-file-format-specification
				final reader = new FileReader();
				reader.readAsArrayBuffer(blob);
				reader.onloadend = function() {
					// Binary chunk.
					final binaryChunk = getPaddedArrayBuffer(reader.result);
					final binaryChunkPrefix = new DataView(new ArrayBuffer(GLB_CHUNK_PREFIX_BYTES));
					binaryChunkPrefix.setUint32(0, binaryChunk.byteLength, true);
					binaryChunkPrefix.setUint32(4, GLB_CHUNK_TYPE_BIN, true);
					// JSON chunk.
					final jsonChunk = getPaddedArrayBuffer(stringToArrayBuffer(JSON.stringify(json)), 0x20);
					final jsonChunkPrefix = new DataView(new ArrayBuffer(GLB_CHUNK_PREFIX_BYTES));
					jsonChunkPrefix.setUint32(0, jsonChunk.byteLength, true);
					jsonChunkPrefix.setUint32(4, GLB_CHUNK_TYPE_JSON, true);
					// GLB header.
					final header = new ArrayBuffer(GLB_HEADER_BYTES);
					final headerView = new DataView(header);
					headerView.setUint32(0, GLB_HEADER_MAGIC, true);
					headerView.setUint32(4, GLB_VERSION, true);
					final totalByteLength = GLB_HEADER_BYTES + jsonChunkPrefix.byteLength + jsonChunk.byteLength + binaryChunkPrefix.byteLength + binaryChunk.byteLength;
					headerView.setUint32(8, totalByteLength, true);
					final glbBlob = new Blob([header, jsonChunkPrefix, jsonChunk, binaryChunkPrefix, binaryChunk], { type: "application/octet-stream" });
					final glbReader = new FileReader();
					glbReader.readAsArrayBuffer(glbBlob);
					glbReader.onloadend = function() {
						onDone(glbReader.result);
					};
				};
			} else {
				if (json.buffers && json.buffers.length > 0) {
					final reader = new FileReader();
					reader.readAsDataURL(blob);
					reader.onloadend = function() {
						final base64data = reader.result;
						json.buffers[0].uri = base64data;
						onDone(json);
					};
				} else {
					onDone(json);
				}
			}
		});
	}

	/**
	 * Serializes a userData.
	 *
	 * @param {THREE.Object3D|THREE.Material} object
	 * @param {Object} objectDef
	 */
	public function serializeUserData(object:Dynamic, objectDef:Dynamic):Void {
		if (Reflect.fields(object.userData).length == 0) return;
		final options = this.options;
		final extensionsUsed = this.extensionsUsed;
		try {
			final json = JSON.parse(JSON.stringify(object.userData));
			if (options.includeCustomExtensions && json.gltfExtensions) {
				if (objectDef.extensions == null) objectDef.extensions = {};
				for (extensionName in json.gltfExtensions) {
					objectDef.extensions[extensionName] = json.gltfExtensions[extensionName];
					extensionsUsed.set(extensionName, true);
				}
				delete json.gltfExtensions;
			}
			if (Reflect.fields(json).length > 0) objectDef.extras = json;
		} catch(error:Dynamic) {
			console.warn("THREE.GLTFExporter: userData of '" + object.name + "' won't be serialized because of JSON.stringify error - " + error.message);
		}
	}

	/**
	 * Returns ids for buffer attributes.
	 * @param  {Object} object
	 * @return {Integer}
	 */
	private function getUID(attribute:BufferAttribute, isRelativeCopy:Bool = false):Int {
		if (!uids.has(attribute)) {
			final uids = new Map();
			uids.set(true, uid++);
			uids.set(false, uid++);
			this.uids.set(attribute, uids);
		}
		final uids = this.uids.get(attribute);
		return uids.get(isRelativeCopy);
	}

	/**
	 * Checks if normal attribute values are normalized.
	 *
	 * @param {BufferAttribute} normal
	 * @returns {Boolean}
	 */
	private function isNormalizedNormalAttribute(normal:BufferAttribute):Bool {
		final cache = this.cache;
		if (cache.attributesNormalized.has(normal)) return false;
		final v = new Vector3();
		for (i in 0...normal.count) {
			// 0.0005 is from glTF-validator
			if (Math.abs(v.fromBufferAttribute(normal, i).length() - 1.0) > 0.0005) return false;
		}
		return true;
	}

	/**
	 * Creates normalized normal buffer attribute.
	 *
	 * @param {BufferAttribute} normal
	 * @returns {BufferAttribute}
	 *
	 */
	private function createNormalizedNormalAttribute(normal:BufferAttribute):BufferAttribute {
		final cache = this.cache;
		if (cache.attributesNormalized.has(normal)) return cache.attributesNormalized.get(normal);
		final attribute = normal.clone();
		final v = new Vector3();
		for (i in 0...attribute.count) {
			v.fromBufferAttribute(attribute, i);
			if (v.x == 0 && v.y == 0 && v.z == 0) {
				// if values can't be normalized set (1, 0, 0)
				v.setX(1.0);
			} else {
				v.normalize();
			}
			attribute.setXYZ(i, v.x, v.y, v.z);
		}
		cache.attributesNormalized.set(normal, attribute);
		return attribute;
	}

	/**
	 * Applies a texture transform, if present, to the map definition. Requires
	 * the KHR_texture_transform extension.
	 *
	 * @param {Object} mapDef
	 * @param {THREE.Texture} texture
	 */
	private function applyTextureTransform(mapDef:Dynamic, texture:Dynamic):Void {
		var didTransform = false;
		final transformDef:Dynamic = {};
		if (texture.offset.x != 0 || texture.offset.y != 0) {
			transformDef.offset = texture.offset.toArray();
			didTransform = true;
		}
		if (texture.rotation != 0) {
			transformDef.rotation = texture.rotation;
			didTransform = true;
		}
		if (texture.repeat.x != 1 || texture.repeat.y != 1) {
			transformDef.scale = texture.repeat.toArray();
			didTransform = true;
		}
		if (didTransform) {
			mapDef.extensions = mapDef.extensions || {};
			mapDef.extensions[KHR_MESH_QUANTIZATION.KHR_mesh_quantization] = transformDef;
			extensionsUsed.set(KHR_MESH_QUANTIZATION.KHR_mesh_quantization, true);
		}
	}

	private function buildMetalRoughTexture(metalnessMap:Dynamic, roughnessMap:Dynamic):Dynamic {
		if (metalnessMap == roughnessMap) return metalnessMap;
		function getEncodingConversion(map:Dynamic) {
			if (map.colorSpace == SRGBColorSpace) {
				return function(c:Float) {
					return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
				};
			}
			return function(c:Float) {
				return c;
			};
		}
		console.warn("THREE.GLTFExporter: Merged metalnessMap and roughnessMap textures.");
		if (metalnessMap is CompressedTexture) {
			metalnessMap = TextureUtils.decompress(metalnessMap);
		}
		if (roughnessMap is CompressedTexture) {
			roughnessMap = TextureUtils.decompress(roughnessMap);
		}
		final metalness = metalnessMap ? metalnessMap.image : null;
		final roughness = roughnessMap ? roughnessMap.image : null;
		final width = Math.max(metalness ? metalness.width : 0, roughness ? roughness.width : 0);
		final height = Math.max(metalness ? metalness.height : 0, roughness ? roughness.height : 0);
		final canvas = getCanvas();
		canvas.width = width;
		canvas.height = height;
		final context = canvas.getContext("2d");
		context.fillStyle = "#00ffff";
		context.fillRect(0, 0, width, height);
		final composite = context.getImageData(0, 0, width, height);
		if (metalness) {
			context.drawImage(metalness, 0, 0, width, height);
			final convert = getEncodingConversion(metalnessMap);
			final data = context.getImageData(0, 0, width, height).data;
			for (i in 2...data.length) {
				composite.data[i] = convert(data[i] / 256) * 256;
			}
		}
		if (roughness) {
			context.drawImage(roughness, 0, 0, width, height);
			final convert = getEncodingConversion(roughnessMap);
			final data = context.getImageData(0, 0, width, height).data;
			for (i in 1...data.length) {
				composite.data[i] = convert(data[i] / 256) * 256;
			}
		}
		context.putImageData(composite, 0, 0);
		//
		final reference = metalnessMap || roughnessMap;
		final texture = reference.clone();
		texture.source = new three.Source(canvas);
		texture.colorSpace = NoColorSpace;
		texture.channel = (metalnessMap || roughnessMap).channel;
		if (metalnessMap && roughnessMap && metalnessMap.channel != roughnessMap.channel) {
			console.warn("THREE.GLTFExporter: UV channels for metalnessMap and roughnessMap textures must match.");
		}
		return texture;
	}

	/**
	 * Process a buffer to append to the default one.
	 * @param  {ArrayBuffer} buffer
	 * @return {Integer}
	 */
	private function processBuffer(buffer:ArrayBuffer):Int {
		final json = this.json;
		final buffers = this.buffers;
		if (!json.buffers) json.buffers = [{ byteLength: 0 }];
		// All buffers are merged before export.
		buffers.push(buffer);
		return 0;
	}

	/**
	 * Process and generate a BufferView
	 * @param  {BufferAttribute} attribute
	 * @param  {number} componentType
	 * @param  {number} start
	 * @param  {number} count
	 * @param  {number} target (Optional) Target usage of the BufferView
	 * @return {Object}
	 */
	private function processBufferView(attribute:BufferAttribute, componentType:Int, start:Int, count:Int, target:Int = null):{id:Int, byteLength:Int} {
		final json = this.json;
		if (!json.bufferViews) json.bufferViews = [];
		// Create a new dataview and dump the attribute's array into it
		var componentSize:Int;
		switch (componentType) {
			case WEBGL_CONSTANTS.BYTE:
			case WEBGL_CONSTANTS.UNSIGNED_BYTE:
				componentSize = 1;
				break;
			case WEBGL_CONSTANTS.SHORT:
			case WEBGL_CONSTANTS.UNSIGNED_SHORT:
				componentSize = 2;
				break;
			default:
				componentSize = 4;
		}
		var byteStride = attribute.itemSize * componentSize;
		if (target == WEBGL_CONSTANTS.ARRAY_BUFFER) {
			// Each element of a vertex attribute MUST be aligned to 4-byte boundaries
			// inside a bufferView
			byteStride = Math.ceil(byteStride / 4) * 4;
		}
		final byteLength = getPaddedBufferSize(count * byteStride);
		final dataView = new DataView(new ArrayBuffer(byteLength));
		var offset = 0;
		for (i in start...start + count) {
			for (a in 0...attribute.itemSize) {
				var value:Float;
				if (attribute.itemSize > 4) {
					// no support for interleaved data for itemSize > 4
					value = attribute.array[i * attribute.itemSize + a];
				} else {
					if (a == 0) value = attribute.getX(i);
					else if (a == 1) value = attribute.getY(i);
					else if (a == 2) value = attribute.getZ(i);
					else if (a == 3) value = attribute.getW(i);
					if (attribute.normalized == true) {
						value = MathUtils.normalize(value, attribute.array);
					}
				}
				if (componentType == WEBGL_CONSTANTS.FLOAT) {
					dataView.setFloat32(offset, value, true);
				} else if (componentType == WEBGL_CONSTANTS.INT) {
					dataView.setInt32(offset, value, true);
				} else if (componentType == WEBGL_CONSTANTS.UNSIGNED_INT) {
					dataView.setUint32(offset, value, true);
				} else if (componentType == WEBGL_CONSTANTS.SHORT) {
					dataView.setInt16(offset, value, true);
				} else if (componentType == WEBGL_CONSTANTS.UNSIGNED_SHORT) {
					dataView.setUint16(offset, value, true);
				} else if (componentType == WEBGL_CONSTANTS.BYTE) {
					dataView.setInt8(offset, value);
				} else if (componentType == WEBGL_CONSTANTS.UNSIGNED_BYTE) {
					dataView.setUint8(offset, value);
				}
				offset += componentSize;
			}
			if ((offset % byteStride) != 0) {
				offset += byteStride - (offset % byteStride);
			}
		}
		final bufferViewDef = {
			buffer: processBuffer(dataView.buffer),
			byteOffset: byteOffset,
			byteLength: byteLength
		};
		if (target != null) bufferViewDef.target = target;
		if (target == WEBGL_CONSTANTS.ARRAY_BUFFER) {
			// Only define byteStride for vertex attributes.
			bufferViewDef.byteStride = byteStride;
		}
		byteOffset += byteLength;
		json.bufferViews.push(bufferViewDef);
		// @TODO Merge bufferViews where possible.
		final output = {
			id: json.bufferViews.length - 1,
			byteLength: 0
		};
		return output;
	}

	/**
	 * Process and generate a BufferView from an image Blob.
	 * @param {Blob} blob
	 * @return {Promise<Integer>}
	 */
	private function processBufferViewImage(blob:Dynamic):Promise<Int> {
		final writer = this;
		final json = writer.json;
		if (!json.bufferViews) json.bufferViews = [];
		return new Promise(function(resolve:Dynamic) {
			final reader = new FileReader();
			reader.readAsArrayBuffer(blob);
			reader.onloadend = function() {
				final buffer = getPaddedArrayBuffer(reader.result);
				final bufferViewDef = {
					buffer: writer.processBuffer(buffer),
					byteOffset: writer.byteOffset,
					byteLength: buffer.byteLength
				};
				writer.byteOffset += buffer.byteLength;
				resolve(json.bufferViews.push(bufferViewDef) - 1);
			};
		});
	}

	/**
	 * Process attribute to generate an accessor
	 * @param  {BufferAttribute} attribute Attribute to process
	 * @param  {THREE.BufferGeometry} geometry (Optional) Geometry used for truncated draw range
	 * @param  {Integer} start (Optional)
	 * @param  {Integer} count (Optional)
	 * @return {Integer|null} Index of the processed accessor on the "accessors" array
	 */
	private function processAccessor(attribute:BufferAttribute, geometry:Dynamic = null, start:Int = 0, count:Int = null):Int {
		final json = this.json;
		final types = {
			1: "SCALAR",
			2: "VEC2",
			3: "VEC3",
			4: "VEC4",
			9: "MAT3",
			16: "MAT4"
		};
		var componentType:Int;
		// Detect the component type of the attribute array
		if (attribute.array.constructor == Float32Array) {
			componentType = WEBGL_CONSTANTS.FLOAT;
		} else if (attribute.array.constructor == Int32Array) {
			componentType = WEBGL_CONSTANTS.INT;
		} else if (attribute.array.constructor == Uint32Array) {
			componentType = WEBGL_CONSTANTS.UNSIGNED_INT;
		} else if (attribute.array.constructor == Int16Array) {
			componentType = WEBGL_CONSTANTS.SHORT;
		} else if (attribute.array.constructor == Uint16Array) {
			componentType = WEBGL_CONSTANTS.UNSIGNED_SHORT;
		} else if (attribute.array.constructor == Int8Array) {
			componentType = WEBGL_CONSTANTS.BYTE
		} else if (attribute.array.constructor == Int32Array) {
			componentType = WEBGL_CONSTANTS.INT;
		} else if (attribute.array.constructor == Uint32Array) {
			componentType = WEBGL_CONSTANTS.UNSIGNED_INT;
		} else if (attribute.array.constructor == Int16Array) {
			componentType = WEBGL_CONSTANTS.SHORT;
		} else if (attribute.array.constructor == Uint16Array) {
			componentType = WEBGL_CONSTANTS.UNSIGNED_SHORT;
		} else if (attribute.array.constructor == Int8Array) {
			componentType = WEBGL_CONSTANTS.BYTE;
		} else if (attribute.array.constructor == Uint8Array) {
			componentType = WEBGL_CONSTANTS.UNSIGNED_BYTE;
		} else {
			throw new Error("THREE.GLTFExporter: Unsupported bufferAttribute component type: " + attribute.array.constructor.name);
		}
		if (start == null) start = 0;
		if (count == null || count == Float.POSITIVE_INFINITY) count = attribute.count;
		// Skip creating an accessor if the attribute doesn't have data to export
		if (count == 0) return null;
		final minMax = getMinMax(attribute, start, count);
		var bufferViewTarget:Int;
		// If geometry isn't provided, don't infer the target usage of the bufferView. For
		// animation samplers, target must not be set.
		if (geometry != null) {
			bufferViewTarget = attribute == geometry.index ? WEBGL_CONSTANTS.ELEMENT_ARRAY_BUFFER : WEBGL_CONSTANTS.ARRAY_BUFFER;
		}
		final bufferView = processBufferView(attribute, componentType, start, count, bufferViewTarget);
		final accessorDef = {
			bufferView: bufferView.id,
			byteOffset: bufferView.byteOffset,
			componentType: componentType,
			count: count,
			max: minMax.max,
			min: minMax.min,
			type: types[attribute.itemSize]
		};
		if (attribute.normalized == true) accessorDef.normalized = true;
		if (!json.accessors) json.accessors = [];
		return json.accessors.push(accessorDef) - 1;
	}

	/**
	 * Process image
	 * @param  {Image} image to process
	 * @param  {Integer} format of the image (RGBAFormat)
	 * @param  {Boolean} flipY before writing out the image
	 * @param  {String} mimeType export format
	 * @return {Integer}     Index of the processed texture in the "images" array
	 */
	private function processImage(image:Dynamic, format:Int, flipY:Bool, mimeType:String = "image/png"):Int {
		if (image != null) {
			final writer = this;
			final cache = writer.cache;
			final json = writer.json;
			final options = writer.options;
			final pending = writer.pending;
			if (!cache.images.has(image)) cache.images.set(image, {});
			final cachedImages = cache.images.get(image);
			final key = mimeType + ":flipY/" + flipY.toString();
			if (cachedImages[key] != null) return cachedImages[key];
			if (!json.images) json.images = [];
			final imageDef = { mimeType: mimeType };
			final canvas = getCanvas();
			canvas.width = Math.min(image.width, options.maxTextureSize);
			canvas.height = Math.min(image.height, options.maxTextureSize);
			final ctx = canvas.getContext("2d");
			if (flipY == true) {
				ctx.translate(0, canvas.height);
				ctx.scale(1, -1);
			}
			if (image.data != null) { // THREE.DataTexture
				if (format != RGBAFormat) {
					console.error("GLTFExporter: Only RGBAFormat is supported.", format);
				}
				if (image.width > options.maxTextureSize || image.height > options.maxTextureSize) {
					console.warn("GLTFExporter: Image size is bigger than maxTextureSize", image);
				}
				final data = new Uint8ClampedArray(image.height * image.width * 4);
				for (i in 0...data.length) {
					data[i + 0] = image.data[i + 0];
					data[i + 1] = image.data[i + 1];
					data[i + 2] = image.data[i + 2];
					data[i + 3] = image.data[i + 3];
				}
				ctx.putImageData(new ImageData(data, image.width, image.height), 0, 0);
			} else {
				if ((typeof HTMLImageElement != "undefined" && image is HTMLImageElement) ||
					(typeof HTMLCanvasElement != "undefined" && image is HTMLCanvasElement) ||
					(typeof ImageBitmap != "undefined" && image is ImageBitmap) ||
					(typeof OffscreenCanvas != "undefined" && image is OffscreenCanvas)) {
					ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
				} else {
					throw new Error("THREE.GLTFExporter: Invalid image type. Use HTMLImageElement, HTMLCanvasElement, ImageBitmap or OffscreenCanvas.");
				}
			}
			if (options.binary == true) {
				pending.push(
					getToBlobPromise(canvas, mimeType).then(function(blob:Dynamic) {
						return writer.processBufferViewImage(blob);
					}).then(function(bufferViewIndex:Int) {
						imageDef.bufferView = bufferViewIndex;
					})
				);
			} else {
				if (canvas.toDataURL != null) {
					imageDef.uri = canvas.toDataURL(mimeType);
				} else {
					pending.push(
						getToBlobPromise(canvas, mimeType).then(function(blob:Dynamic) {
							return new FileReader().readAsDataURL(blob);
						}).then(function(dataURL:String) {
							imageDef.uri = dataURL;
						})
					);
				}
			}
			final index = json.images.push(imageDef) - 1;
			cachedImages[key] = index;
			return index;
		} else {
			throw new Error("THREE.GLTFExporter: No valid image data found. Unable to process texture.");
		}
	}

	/**
	 * Process sampler
	 * @param  {Texture} map Texture to process
	 * @return {Integer}     Index of the processed texture in the "samplers" array
	 */
	private function processSampler(map:Dynamic):Int {
		final json = this.json;
		if (!json.samplers) json.samplers = [];
		final samplerDef = {
			magFilter: THREE_TO_WEBGL[map.magFilter],
			minFilter: THREE_TO_WEBGL[map.minFilter],
			wrapS: THREE_TO_WEBGL[map.wrapS],
			wrapT: THREE_TO_WEBGL[map.wrapT]
		};
		return json.samplers.push(samplerDef) - 1;
	}

	/**
	 * Process texture
	 * @param  {Texture} map Map to process
	 * @return {Integer} Index of the processed texture in the "textures" array
	 */
	private function processTexture(map:Dynamic):Int {
		final writer = this;
		final options = writer.options;
		final cache = this.cache;
		final json = this.json;
		if (cache.textures.has(map)) return cache.textures.get(map);
		if (!json.textures) json.textures = [];
		// make non-readable textures (e.g. CompressedTexture) readable by blitting them into a new texture
		if (map is CompressedTexture) {
			map = TextureUtils.decompress(map, options.maxTextureSize);
		}
		var mimeType = map.userData.mimeType;
		if (mimeType == "image/webp") mimeType = "image/png";
		final textureDef = {
			sampler: processSampler(map),
			source: processImage(map.image, map.format, map.flipY, mimeType)
		};
		if (map.name) textureDef.name = map.name;
		this._invokeAll(function(ext:Dynamic) {
			ext.writeTexture && ext.writeTexture(map, textureDef);
		});
		final index = json.textures.push(textureDef) - 1;
		cache.textures.set(map, index);
		return index;
	}

	/**
	 * Process material
	 * @param  {THREE.Material} material Material to process
	 * @return {Integer|null} Index of the processed material in the "materials" array
	 */
	private function processMaterial(material:Dynamic):Int {
		final cache = this.cache;
		final json = this.json;
		if (cache.materials.has(material)) return cache.materials.get(material);
		if (material.isShaderMaterial) {
			console.warn("GLTFExporter: THREE.ShaderMaterial not supported.");
			return null;
		}
		if (!json.materials) json.materials = [];
		// @QUESTION Should we avoid including any attribute that has the default value?
		final materialDef:Dynamic = {	pbrMetallicRoughness: {} };
		if (material.isMeshStandardMaterial != true && material.isMeshBasicMaterial != true) {
			console.warn("GLTFExporter: Use MeshStandardMaterial or MeshBasicMaterial for best results.");
		}
		// pbrMetallicRoughness.baseColorFactor
		final color = material.color.toArray().concat([material.opacity]);
		if (!equalArray(color, [1, 1, 1, 1])) {
			materialDef.pbrMetallicRoughness.baseColorFactor = color;
		}
		if (material.isMeshStandardMaterial) {
			materialDef.pbrMetallicRoughness.metallicFactor = material.metalness;
			materialDef.pbrMetallicRoughness.roughnessFactor = material.roughness;
		} else {
			materialDef.pbrMetallicRoughness.metallicFactor = 0.5;
			materialDef.pbrMetallicRoughness.roughnessFactor = 0.5;
		}
		// pbrMetallicRoughness.metallicRoughnessTexture
		if (material.metalnessMap || material.roughnessMap) {
			final metalRoughTexture = buildMetalRoughTexture(material.metalnessMap, material.roughnessMap);
			final metalRoughMapDef = {
				index: processTexture(metalRoughTexture),
				channel: metalRoughTexture.channel
			};
			applyTextureTransform(metalRoughMapDef, metalRoughTexture);
			materialDef.pbrMetallicRoughness.metallicRoughnessTexture = metalRoughMapDef;
		}
		// pbrMetallicRoughness.baseColorTexture
		if (material.map) {
			final baseColorMapDef = {
				index: processTexture(material.map),
				texCoord: material.map.channel
			};
			applyTextureTransform(baseColorMapDef, material.map);
			materialDef.pbrMetallicRoughness.baseColorTexture = baseColorMapDef;
		}
		if (material.emissive) {
			final emissive = material.emissive;
			final maxEmissiveComponent = Math.max(emissive.r, emissive.g, emissive.b);
			if (maxEmissiveComponent > 0) {
				materialDef.emissiveFactor = material.emissive.toArray();
			}
			// emissiveTexture
			if (material.emissiveMap) {
				final emissiveMapDef = {
					index: processTexture(material.emissiveMap),
					texCoord: material.emissiveMap.channel
				};
				applyTextureTransform(emissiveMapDef, material.emissiveMap);
				materialDef.emissiveTexture = emissiveMapDef;
			}
		}
		// normalTexture
		if (material.normalMap) {
			final normalMapDef = {
				index: processTexture(material.normalMap),
				texCoord: material.normalMap.channel
			};
			if (material.normalScale && material.normalScale.x != 1) {
				// glTF normal scale is univariate. Ignore `y`, which may be flipped.
				// Context: https://github.com/mrdoob/three.js/issues/11438#issuecomment-507003995
				normalMapDef.scale = material.normalScale.x;
			}
			applyTextureTransform(normalMapDef, material.normalMap);
			materialDef.normalTexture = normalMapDef;
		}
		// occlusionTexture
		if (material.aoMap) {
			final occlusionMapDef = {
				index: processTexture(material.aoMap),
				texCoord: material.aoMap.channel
			};
			if (material.aoMapIntensity != 1.0) {
				occlusionMapDef.strength = material.aoMapIntensity;
			}
			applyTextureTransform(occlusionMapDef, material.aoMap);
			materialDef.occlusionTexture = occlusionMapDef;
		}
		// alphaMode
		if (material.transparent) {
			materialDef.alphaMode = "BLEND";
		} else {
			if (material.alphaTest > 0.0) {
				materialDef.alphaMode = "MASK";
				materialDef.alphaCutoff = material.alphaTest;
			}
		}
		// doubleSided
		if (material.side == DoubleSide) materialDef.doubleSided = true;
		if (material.name != "") materialDef.name = material.name;
		serializeUserData(material, materialDef);
		this._invokeAll(function(ext:Dynamic) {
			ext.writeMaterial && ext.writeMaterial(material, materialDef);
		});
		final index = json.materials.push(materialDef) - 1;
		cache.materials.set(material, index);
		return index;
	}

	/**
	 * Process mesh
	 * @param  {THREE.Mesh} mesh Mesh to process
	 * @return {Integer|null} Index of the processed mesh in the "meshes" array
	 */
	private function processMesh(mesh:Dynamic):Int {
		final cache = this.cache;
		final json = this.json;
		final meshCacheKeyParts:Array<String> = [mesh.geometry.uuid];
		if (Array.isArray(mesh.material)) {
			for (i in 0...mesh.material.length) {
				meshCacheKeyParts.push(mesh.material[i].uuid);
			}
		} else {
			meshCacheKeyParts.push(mesh.material.uuid);
		}
		final meshCacheKey = meshCacheKeyParts.join(":");
		if (cache.meshes.has(meshCacheKey)) return cache.meshes.get(meshCacheKey);
		final geometry = mesh.geometry;
		var mode:Int;
		// Use the correct mode
		if (mesh.isLineSegments) {
			mode = WEBGL_CONSTANTS.LINES;
		} else if (mesh.isLineLoop) {
			mode = WEBGL_CONSTANTS.LINE_LOOP;
		} else if (mesh.isLine) {
			mode = WEBGL_CONSTANTS.LINE_STRIP;
		} else if (mesh.isPoints) {
			mode = WEBGL_CONSTANTS.POINTS;
		} else {
			mode = mesh.material.wireframe ? WEBGL_CONSTANTS.LINES : WEBGL_CONSTANTS.TRIANGLES;
		}
		final meshDef:Dynamic = {};
		final attributes:Dynamic = {};
		final primitives:Array<Dynamic> = [];
		final targets:Array<Dynamic> = [];
		// Conversion between attributes names in threejs and gltf spec
		final nameConversion:Map<String,String> = new Map();
		nameConversion.set("uv", "TEXCOORD_0");
		nameConversion.set("uv1", "TEXCOORD_1");
		nameConversion.set("uv2", "TEXCOORD_2");
		nameConversion.set("uv3", "TEXCOORD_3");
		nameConversion.set("color", "COLOR_0");
		nameConversion.set("skinWeight", "WEIGHTS_0");
		nameConversion.set("skinIndex", "JOINTS_0");
		final originalNormal = geometry.getAttribute("normal");
		if (originalNormal != null && !isNormalizedNormalAttribute(originalNormal)) {
			console.warn("THREE.GLTFExporter: Creating normalized normal attribute from the non-normalized one.");
			geometry.setAttribute("normal", createNormalizedNormalAttribute(originalNormal));
		}
		// @QUESTION Detect if .vertexColors = true?
		// For every attribute create an accessor
		var modifiedAttribute:BufferAttribute = null;
		for (attributeName in geometry.attributes) {
			// Ignore morph target attributes, which are exported later.
			if (attributeName.substring(0, 5) == "morph") continue;
			final attribute = geometry.attributes[attributeName];
			attributeName = nameConversion.get(attributeName) || attributeName.toUpperCase();
			// Prefix all geometry attributes except the ones specifically
			// listed in the spec; non-spec attributes are considered custom.
			final validVertexAttributes =
				/^(POSITION|NORMAL|TANGENT|TEXCOORD_\d+|COLOR_\d+|JOINTS_\d+|WEIGHTS_\d+)$/;
			if (!validVertexAttributes.test(attributeName)) attributeName = "_" + attributeName;
			if (cache.attributes.has(getUID(attribute))) {
				attributes[attributeName] = cache.attributes.get(getUID(attribute));
				continue;
			}
			// JOINTS_0 must be UNSIGNED_BYTE or UNSIGNED_SHORT.
			modifiedAttribute = null;
			final array = attribute.array;
			if (attributeName == "JOINTS_0" &&
				!(array is Uint16Array) &&
				!(array is Uint8Array)) {
				console.warn("GLTFExporter: Attribute \"skinIndex\" converted to type UNSIGNED_SHORT.");
				modifiedAttribute = new BufferAttribute(new Uint16Array(array), attribute.itemSize, attribute.normalized);
			}
			final accessor = processAccessor(modifiedAttribute || attribute, geometry);
			if (accessor != null) {
				if (!attributeName.startsWith("_")) {
					detectMeshQuantization(attributeName, attribute);
				}
				attributes[attributeName] = accessor;
				cache.attributes.set(getUID(attribute), accessor);
			}
		}
		if (originalNormal != null) geometry.setAttribute("normal", originalNormal);
		// Skip if no exportable attributes found
		if (Reflect.fields(attributes).length == 0) return null;
		// Morph targets
		if (mesh.morphTargetInfluences != null && mesh.morphTargetInfluences.length > 0) {
			final weights:Array<Float> = [];
			final targetNames:Array<String> = [];
			final reverseDictionary:Map<Int,String> = new Map();
			if (mesh.morphTargetDictionary != null) {
				for (key in mesh.morphTargetDictionary) {
					reverseDictionary.set(mesh.morphTargetDictionary[key], key);
				}
			}
			for (i in 0...mesh.morphTargetInfluences.length) {
				final target:Dynamic = {};
				var warned = false;
				for (attributeName in geometry.morphAttributes) {
					// glTF 2.0 morph supports only POSITION/NORMAL/TANGENT.
					// Three.js doesn't support TANGENT yet.
					if (attributeName != "position" && attributeName != "normal") {
						if (!warned) {
							console.warn("GLTFExporter: Only POSITION and NORMAL morph are supported.");
							warned = true;
						}
						continue;
					}
					final attribute = geometry.morphAttributes[attributeName][i];
					final gltfAttributeName = attributeName.toUpperCase();
					// Three.js morph attribute has absolute values while the one of glTF has relative values.
					//
					// glTF 2.0 Specification:
					// https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#morph-targets
					final baseAttribute = geometry.attributes[attributeName];
					if (cache.attributes.has(getUID(attribute, true))) {
						target[gltfAttributeName] = cache.attributes.get(getUID(attribute, true));
						continue;
					}
					// Clones attribute not to override
					final relativeAttribute = attribute.clone();
					if (!geometry.morphTargetsRelative) {
						for (j in 0...attribute.count) {
							for (a in 0...attribute.itemSize) {
								if (a == 0) relativeAttribute.setX(j, attribute.getX(j) - baseAttribute.getX(j));
								if (a == 1) relativeAttribute.setY(j, attribute.getY(j) - baseAttribute.getY(j));
								if (a == 2) relativeAttribute.setZ(j, attribute.getZ(j) - baseAttribute.getZ(j));
								if (a == 3) relativeAttribute.setW(j, attribute.getW(j) - baseAttribute.getW(j));
							}
						}
					}
					target[gltfAttributeName] = processAccessor(relativeAttribute, geometry);
					cache.attributes.set(getUID(baseAttribute, true), target[gltfAttributeName]);
				}
				targets.push(target);
				weights.push(mesh.morphTargetInfluences[i]);
				if (mesh.morphTargetDictionary != null) targetNames.push(reverseDictionary.get(i));
			}
			meshDef.weights = weights;
			if (targetNames.length > 0) {
				meshDef.extras = {};
				meshDef.extras.targetNames = targetNames;
			}
		}
		final isMultiMaterial = Array.isArray(mesh.material);
		if (isMultiMaterial && geometry.groups.length == 0) return null;
		var didForceIndices = false;
		if (isMultiMaterial && geometry.index == null) {
			final indices:Array<Int> = [];
			for (i in 0...geometry.attributes.position.count) {
				indices[i] = i;
			}
			geometry.setIndex(indices);
			didForceIndices = true;
		}
		final materials:Array<Dynamic> = isMultiMaterial ? mesh.material : [mesh.material];
		final groups:Array<Dynamic> = isMultiMaterial ? geometry.groups : [{ materialIndex: 0, start: null, count: null }];
		for (i in 0...groups.length) {
			final primitive:Dynamic = {
				mode: mode,
				attributes: attributes,
			};
			serializeUserData(geometry, primitive);
			if (targets.length > 0) primitive.targets = targets;
			if (geometry.index != null) {
				var cacheKey = getUID(geometry.index);
				if (groups[i].start != null || groups[i].count != null) {
					cacheKey += ":" + groups[i].start + ":" + groups[i].count;
				}
				if (cache.attributes.has(cacheKey)) {
					primitive.indices = cache.attributes.get(cacheKey);
				} else {
					primitive.indices = processAccessor(geometry.index, geometry, groups[i].start, groups[i].count);
					cache.attributes.set(cacheKey, primitive.indices);
				}
				if (primitive.indices == null) delete primitive.indices;
			}
			final material = processMaterial(materials[groups[i].materialIndex]);
			if (material != null) primitive.material = material;
			primitives.push(primitive);
		}
		if (didForceIndices == true) {
			geometry.setIndex(null);
		}
		meshDef.primitives = primitives;
		if (!json.meshes) json.meshes = [];
		this._invokeAll(function(ext:Dynamic) {
			ext.writeMesh && ext.writeMesh(mesh, meshDef);
		});
		final index = json.meshes.push(meshDef) - 1;
		cache.meshes.set(meshCacheKey, index);
		return index;
	}

	/**
	 * If a vertex attribute with a
	 * [non-standard data type](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#meshes-overview)
	 * is used, it is checked whether it is a valid data type according to the
	 * [KHR_mesh_quantization](https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_mesh_quantization/README.md)
	 * extension.
	 * In this case the extension is automatically added to the list of used extensions.
	 *
	 * @param {string} attributeName
	 * @param {THREE.BufferAttribute} attribute
	 */
	private function detectMeshQuantization(attributeName:String, attribute:BufferAttribute):Void {
		if (this.extensionsUsed[KHR_MESH_QUANTIZATION.KHR_mesh_quantization]) return;
		var attrType:String = null;
		switch (attribute.array.constructor) {
			case Int8Array:
				attrType = "byte";
				break;
			case Uint8Array:
				attrType = "unsigned byte";
				break;
			case Int16Array:
				attrType = "short";
				break;
			case Uint16Array:
				attrType = "unsigned short";
				break;
			default:
				return;
		}
		if (attribute.normalized) attrType += " normalized";
		final attrNamePrefix = attributeName.split("_", 1)[0];
		if (KHR_mesh_quantization_ExtraAttrTypes[attrNamePrefix] && KHR_mesh_quantization_ExtraAttrTypes[attrNamePrefix].indexOf(attrType) != -1) {
			this.extensionsUsed[KHR_MESH_QUANTIZATION.KHR_mesh_quantization] = true;
			this.extensionsRequired[KHR_MESH_QUANTIZATION.KHR_mesh_quantization] = true;
		}
	}

	/**
	 * Process camera
	 * @param  {THREE.Camera} camera Camera to process
	 * @return {Integer}      Index of the processed mesh in the "camera" array
	 */
	private function processCamera(camera:Dynamic):Int {
		final json = this.json;
		if (!json.cameras) json.cameras = [];
		final isOrtho = camera.isOrthographicCamera;
		final cameraDef:Dynamic = {
			type: isOrtho ? "orthographic" : "perspective"
		};
		if (isOrtho) {
			cameraDef.orthographic = {
				xmag: camera.right * 2,
				ymag: camera.top * 2,
				zfar: camera.far <= 0 ? 0.001 : camera.far,
				znear: camera.near < 0 ? 0 : camera.near
			};
		} else {
			cameraDef.perspective = {
				aspectRatio: camera.aspect,
				yfov: MathUtils.degToRad(camera.fov),
				zfar: camera.far <= 0 ? 0.001 : camera.far,
				znear: camera.near < 0 ? 0 : camera.near
			};
		}
		// Question: Is saving "type" as name intentional?
		if (camera.name != "") cameraDef.name = camera.type;
		return json.cameras.push(cameraDef) - 1;
	}

	/**
	 * Creates glTF animation entry from AnimationClip object.
	 *
	 * Status:
	 * - Only properties listed in PATH_PROPERTIES may be animated.
	 *
	 * @param {THREE.AnimationClip} clip
	 * @param {THREE.Object3D} root
	 * @return {number|null}
	 */
	private function processAnimation(clip:Dynamic, root:Dynamic):Int {
		final json = this.json;
		final nodeMap = this.nodeMap;
		if (!json.animations) json.animations = [];
		clip = GLTFExporterUtils.mergeMorphTargetTracks(clip.clone(), root);
		final tracks = clip.tracks;
		final channels:Array<Dynamic> = [];
		final samplers:Array<Dynamic> = [];
		for (i in 0...tracks.length) {
			final track = tracks[i];
			final trackBinding = PropertyBinding.parseTrackName(track.name);
			var trackNode = PropertyBinding.findNode(root, trackBinding.nodeName);
			final trackProperty = PATH_PROPERTIES.get(trackBinding.propertyName);
			if (trackBinding.objectName == "bones") {
				if (trackNode.isSkinnedMesh == true) {
					trackNode = trackNode.skeleton.getBoneByName(trackBinding.objectIndex);
				} else {
					trackNode = null;
				}
			}
			if (trackNode == null || trackProperty == null) {
				console.warn("THREE.GLTFExporter: Could not export animation track \"%s\".", track.name);
				return null;
			}
			final inputItemSize = 1;
			var outputItemSize = track.values.length / track.times.length;
			if (trackProperty == PATH_PROPERTIES.get("morphTargetInfluences")) {
				outputItemSize /= trackNode.morphTargetInfluences.length;
			}
			var interpolation:String;
			// @TODO export CubicInterpolant(InterpolateSmooth) as CUBICSPLINE
			// Detecting glTF cubic spline interpolant by checking factory method's special property
			// GLTFCubicSplineInterpolant is a custom interpolant and track doesn't return
			// valid value from .getInterpolation().
			if (track.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline == true) {
				interpolation = "CUBICSPLINE";
				// itemSize of CUBICSPLINE keyframe is 9
				// (VEC3 * 3: inTangent, splineVertex, and outTangent)
				// but needs to be stored as VEC3 so dividing by 3 here.
				outputItemSize /= 3;
			} else if (track.getInterpolation() == InterpolateDiscrete) {
				interpolation = "STEP";
			} else {
				interpolation = "LINEAR";
			}
			samplers.push({
				input: processAccessor(new BufferAttribute(track.times, inputItemSize)),
				output: processAccessor(new BufferAttribute(track.values, outputItemSize)),
				interpolation: interpolation
			});
			channels.push({
				sampler: samplers.length - 1,
				target: {
					node: nodeMap.get(trackNode),
					path: trackProperty
				}
			});
		}
		json.animations.push({
			name: clip.name || "clip_" + json.animations.length,
			samplers: samplers,
			channels: channels
		});
		return json.animations.length - 1;
	}

	/**
	 * @param {THREE.Object3D} object
	 * @return {number|null}
	 */
	private function processSkin(object:Dynamic):Int {
		final json = this.json;
		final nodeMap = this.nodeMap;
		final node = json.nodes[nodeMap.get(object)];
		final skeleton = object.skeleton;
		if (skeleton == null) return null;
		final rootJoint = object.skeleton.bones[0];
		if (rootJoint == null) return null;
		final joints:Array<Int> = [];
		final inverseBindMatrices = new Float32Array(skeleton.bones.length * 16);
		final temporaryBoneInverse = new Matrix4();
		for (i in 0...skeleton.bones.length) {
			joints.push(nodeMap.get(skeleton.bones[i]));
			temporaryBoneInverse.copy(skeleton.boneInverses[i]);
			temporaryBoneInverse.multiply(object.bindMatrix).toArray(inverseBindMatrices, i * 16);
		}
		if (json.skins == null) json.skins = [];
		json.skins.push({
			inverseBindMatrices: processAccessor(new BufferAttribute(inverseBindMatrices, 16)),
			joints: joints,
			skeleton: nodeMap.get(rootJoint)
		});
		final skinIndex = node.skin = json.skins.length - 1;
		return skinIndex;
	}

	/**
	 * Process Object3D node
	 * @param  {THREE.Object3D} node Object3D to processNode
	 * @return {Integer} Index of the node in the nodes list
	 */
	private function processNode(object:Dynamic):Int {
		final json = this.json;
		final options = this.options;
		final nodeMap = this.nodeMap;
		if (!json.nodes) json.nodes = [];
		final nodeDef:Dynamic = {};
		if (options.trs) {
			final rotation = object.quaternion.toArray();
			final position = object.position.toArray();
			final scale = object.scale.toArray();
			if (!equalArray(rotation, [0, 0, 0, 1])) {
				nodeDef.rotation = rotation;
			}
			if (!equalArray(position, [0, 0, 0])) {
				nodeDef.translation = position;
			}
			if (!equalArray(scale, [1, 1, 1])) {
				nodeDef.scale = scale;
			}
		} else {
			if (object.matrixAutoUpdate) {
				object.updateMatrix();
			}
			if (isIdentityMatrix(object.matrix) == false) {
				nodeDef.matrix = object.matrix.elements;
			}
		}
		// We don't export empty strings name because it represents no-name in Three.js.
		if (object.name != "") nodeDef.name = String(object.name);
		serializeUserData(object, nodeDef);
		if (object.isMesh || object.isLine || object.isPoints) {
			final meshIndex = processMesh(object);
			if (meshIndex != null) nodeDef.mesh = meshIndex;
		} else if (object.isCamera) {
			nodeDef.camera = processCamera(object);
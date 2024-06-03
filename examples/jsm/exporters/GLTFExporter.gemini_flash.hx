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
import three.Source;
import three.SRGBColorSpace;
import three.Texture;
import three.Vector3;
import three.Quaternion;
import three.REVISION;
import haxe.io.Bytes;
import haxe.io.Output;
import haxe.io.StringOutput;
import haxe.io.BytesOutput;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.GenericArray;
import haxe.ds.Option;
import js.html.CanvasElement;
import js.html.OffscreenCanvas;
import js.html.ImageElement;
import js.html.HTMLCanvasElement;
import js.html.ImageBitmap;
import js.html.FileReader;
import js.html.Blob;
import js.html.TextEncoder;
import js.html.CanvasRenderingContext2D;

/**
 * The KHR_mesh_quantization extension allows these extra attribute component types
 *
 * @see https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_mesh_quantization/README.md#extending-mesh-attributes
 */
private enum KHR_mesh_quantization_ExtraAttrTypes {
	POSITION,
	NORMAL,
	TANGENT,
	TEXCOORD;
}

private var KHR_mesh_quantization_ExtraAttrTypes_POSITION : Array<String> = [
	"byte",
	"byte normalized",
	"unsigned byte",
	"unsigned byte normalized",
	"short",
	"short normalized",
	"unsigned short",
	"unsigned short normalized",
];
private var KHR_mesh_quantization_ExtraAttrTypes_NORMAL : Array<String> = [
	"byte normalized",
	"short normalized",
];
private var KHR_mesh_quantization_ExtraAttrTypes_TANGENT : Array<String> = [
	"byte normalized",
	"short normalized",
];
private var KHR_mesh_quantization_ExtraAttrTypes_TEXCOORD : Array<String> = [
	"byte",
	"byte normalized",
	"unsigned byte",
	"short",
	"short normalized",
	"unsigned short",
];

private var KHR_mesh_quantization_ExtraAttrTypes_map : Map<KHR_mesh_quantization_ExtraAttrTypes, Array<String>> = new Map([
	[KHR_mesh_quantization_ExtraAttrTypes.POSITION, KHR_mesh_quantization_ExtraAttrTypes_POSITION],
	[KHR_mesh_quantization_ExtraAttrTypes.NORMAL, KHR_mesh_quantization_ExtraAttrTypes_NORMAL],
	[KHR_mesh_quantization_ExtraAttrTypes.TANGENT, KHR_mesh_quantization_ExtraAttrTypes_TANGENT],
	[KHR_mesh_quantization_ExtraAttrTypes.TEXCOORD, KHR_mesh_quantization_ExtraAttrTypes_TEXCOORD],
]);

/**
 * @see https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#extensions
 */
private enum ExtensionNames {
	KHR_lights_punctual,
	KHR_materials_unlit,
	KHR_materials_transmission,
	KHR_materials_volume,
	KHR_materials_ior,
	KHR_materials_specular,
	KHR_materials_sheen,
	KHR_materials_anisotropy,
	KHR_materials_emissive_strength,
	EXT_materials_bump,
	EXT_mesh_gpu_instancing,
	KHR_texture_transform;
}

/**
 * @see https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#types-and-definitions
 */
private enum AccessorTypes {
	SCALAR,
	VEC2,
	VEC3,
	VEC4,
	MAT3,
	MAT4;
}

/**
 * @see https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#types-and-definitions
 */
private enum ComponentTypes {
	BYTE,
	UNSIGNED_BYTE,
	SHORT,
	UNSIGNED_SHORT,
	INT,
	UNSIGNED_INT,
	FLOAT;
}

/**
 * @see https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#types-and-definitions
 */
private enum BufferViewTargets {
	ARRAY_BUFFER,
	ELEMENT_ARRAY_BUFFER;
}

/**
 * @see https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#glb-file-format-specification
 */
private enum ChunkTypes {
	JSON,
	BIN;
}

private enum GLBHeaderMagic {
	GLB_HEADER_MAGIC = 0x46546C67;
}

private enum GLBVersion {
	GLB_VERSION = 2;
}

private enum GLBChunkPrefixBytes {
	GLB_CHUNK_PREFIX_BYTES = 8;
}

private var WEBGL_CONSTANTS : Map<Int, Int> = new Map([
	[0x0000, 0x0000],
	[0x0001, 0x0001],
	[0x0002, 0x0002],
	[0x0003, 0x0003],
	[0x0004, 0x0004],
	[0x0005, 0x0005],
	[0x0006, 0x0006],
	[0x1400, 0x1400],
	[0x1401, 0x1401],
	[0x1402, 0x1402],
	[0x1403, 0x1403],
	[0x1404, 0x1404],
	[0x1405, 0x1405],
	[0x1406, 0x1406],
	[0x8892, 0x8892],
	[0x8893, 0x8893],
	[0x2600, 0x2600],
	[0x2601, 0x2601],
	[0x2700, 0x2700],
	[0x2701, 0x2701],
	[0x2702, 0x2702],
	[0x2703, 0x2703],
	[33071, 33071],
	[33648, 33648],
	[10497, 10497],
]);

private var THREE_TO_WEBGL : Map<Int, Int> = new Map([
	[NearestFilter, WEBGL_CONSTANTS.get(NearestFilter)],
	[NearestMipmapNearestFilter, WEBGL_CONSTANTS.get(NearestMipmapNearestFilter)],
	[NearestMipmapLinearFilter, WEBGL_CONSTANTS.get(NearestMipmapLinearFilter)],
	[LinearFilter, WEBGL_CONSTANTS.get(LinearFilter)],
	[LinearMipmapNearestFilter, WEBGL_CONSTANTS.get(LinearMipmapNearestFilter)],
	[LinearMipmapLinearFilter, WEBGL_CONSTANTS.get(LinearMipmapLinearFilter)],
	[ClampToEdgeWrapping, WEBGL_CONSTANTS.get(ClampToEdgeWrapping)],
	[RepeatWrapping, WEBGL_CONSTANTS.get(RepeatWrapping)],
	[MirroredRepeatWrapping, WEBGL_CONSTANTS.get(MirroredRepeatWrapping)],
]);

private var PATH_PROPERTIES : Map<String, String> = new Map([
	["scale", "scale"],
	["position", "translation"],
	["quaternion", "rotation"],
	["morphTargetInfluences", "weights"],
]);

private var DEFAULT_SPECULAR_COLOR : Color = new Color();

private var KHR_MESH_QUANTIZATION : String = "KHR_mesh_quantization";

class GLTFExporter {

	private var pluginCallbacks : Array<Function> = [];
	private var extensionsUsed : StringMap = new StringMap();
	private var extensionsRequired : StringMap = new StringMap();
	private var uids : Map<BufferAttribute, Map<Bool, Int>> = new Map();
	private var uid : Int = 0;
	private var cache : {
		meshes : Map<String, Int>,
		attributes : Map<Int, Int>,
		attributesNormalized : Map<BufferAttribute, BufferAttribute>,
		materials : Map<Texture, Int>,
		textures : Map<Texture, Int>,
		images : Map<Texture, {
			[String] : Int
		}>
	} = {
		meshes : new Map(),
		attributes : new Map(),
		attributesNormalized : new Map(),
		materials : new Map(),
		textures : new Map(),
		images : new Map(),
	};

	public function new() {
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

	public function register(callback : Function) : GLTFExporter {
		if (this.pluginCallbacks.indexOf(callback) == -1) {
			this.pluginCallbacks.push(callback);
		}
		return this;
	}

	public function unregister(callback : Function) : GLTFExporter {
		if (this.pluginCallbacks.indexOf(callback) != -1) {
			this.pluginCallbacks.splice(this.pluginCallbacks.indexOf(callback), 1);
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
	public function parse(input : Scene | Array<Scene>, onDone : Function, onError : Function, options : {
		binary : Bool,
		trs : Bool,
		onlyVisible : Bool,
		maxTextureSize : Int,
		animations : Array<Dynamic>,
		includeCustomExtensions : Bool
	} = {
		binary : false,
		trs : false,
		onlyVisible : true,
		maxTextureSize : -1,
		animations : [],
		includeCustomExtensions : false,
	}) : Void {
		var writer : GLTFWriter = new GLTFWriter();
		var plugins : Array<Dynamic> = [];
		for (i in 0...this.pluginCallbacks.length) {
			plugins.push(this.pluginCallbacks[i](writer));
		}
		writer.setPlugins(plugins);
		writer.write(input, onDone, options).catch(onError);
	}

	public function parseAsync(input : Scene | Array<Scene>, options : {
		binary : Bool,
		trs : Bool,
		onlyVisible : Bool,
		maxTextureSize : Int,
		animations : Array<Dynamic>,
		includeCustomExtensions : Bool
	} = {
		binary : false,
		trs : false,
		onlyVisible : true,
		maxTextureSize : -1,
		animations : [],
		includeCustomExtensions : false,
	}) : js.lib.Promise<Dynamic> {
		var scope : GLTFExporter = this;
		return new js.lib.Promise(function(resolve : Function, reject : Function) {
			scope.parse(input, resolve, reject, options);
		});
	}

}

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

private var KHR_MESH_QUANTIZATION : String = "KHR_mesh_quantization";

//------------------------------------------------------------------------------
// Utility functions
//------------------------------------------------------------------------------

/**
 * Compare two arrays
 * @param  {Array} array1 Array 1 to compare
 * @param  {Array} array2 Array 2 to compare
 * @return {Boolean}        Returns true if both arrays are equal
 */
private function equalArray(array1 : Array<Float>, array2 : Array<Float>) : Bool {
	return (array1.length == array2.length) && array1.every(function(element : Float, index : Int) {
		return element == array2[index];
	});
}

/**
 * Converts a string to an ArrayBuffer.
 * @param  {string} text
 * @return {ArrayBuffer}
 */
private function stringToArrayBuffer(text : String) : ArrayBuffer {
	return new TextEncoder().encode(text).buffer;
}

/**
 * Is identity matrix
 *
 * @param {Matrix4} matrix
 * @returns {Boolean} Returns true, if parameter is identity matrix
 */
private function isIdentityMatrix(matrix : Matrix4) : Bool {
	return equalArray(matrix.elements, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
}

/**
 * Get the min and max vectors from the given attribute
 * @param  {BufferAttribute} attribute Attribute to find the min/max in range from start to start + count
 * @param  {Integer} start
 * @param  {Integer} count
 * @return {Object} Object containing the `min` and `max` values (As an array of attribute.itemSize components)
 */
private function getMinMax(attribute : BufferAttribute, start : Int, count : Int) : {
	min : Array<Float>,
	max : Array<Float>
} {
	var output : {
		min : Array<Float>,
		max : Array<Float>
	} = {
		min : new Array<Float>(attribute.itemSize).fill(Number.POSITIVE_INFINITY),
		max : new Array<Float>(attribute.itemSize).fill(Number.NEGATIVE_INFINITY),
	};
	for (i in start...start + count) {
		for (a in 0...attribute.itemSize) {
			var value : Float;
			if (attribute.itemSize > 4) {
				// no support for interleaved data for itemSize > 4
				value = attribute.array[i * attribute.itemSize + a];
			} else {
				if (a == 0) value = attribute.getX(i);
				else if (a == 1) value = attribute.getY(i);
				else if (a == 2) value = attribute.getZ(i);
				else if (a == 3) value = attribute.getW(i);
				if (attribute.normalized) {
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
private function getPaddedBufferSize(bufferSize : Int) : Int {
	return Math.ceil(bufferSize / 4) * 4;
}

/**
 * Returns a buffer aligned to 4-byte boundary.
 *
 * @param {ArrayBuffer} arrayBuffer Buffer to pad
 * @param {Integer} paddingByte (Optional)
 * @returns {ArrayBuffer} The same buffer if it's already aligned to 4-byte boundary or a new buffer
 */
private function getPaddedArrayBuffer(arrayBuffer : ArrayBuffer, paddingByte : Int = 0) : ArrayBuffer {
	var paddedLength : Int = getPaddedBufferSize(arrayBuffer.byteLength);
	if (paddedLength != arrayBuffer.byteLength) {
		var array : Uint8Array = new Uint8Array(paddedLength);
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

private function getCanvas() : CanvasElement {
	if (typeof(document) == "undefined" && typeof(OffscreenCanvas) != "undefined") {
		return new OffscreenCanvas(1, 1);
	}
	return document.createElement("canvas");
}

private function getToBlobPromise(canvas : CanvasElement, mimeType : String) : js.lib.Promise<Blob> {
	if (canvas.toBlob != null) {
		return new js.lib.Promise(function(resolve : Function) {
			canvas.toBlob(resolve, mimeType);
		});
	}
	var quality : Float;
	// Blink's implementation of convertToBlob seems to default to a quality level of 100%
	// Use the Blink default quality levels of toBlob instead so that file sizes are comparable.
	if (mimeType == "image/jpeg") {
		quality = 0.92;
	} else if (mimeType == "image/webp") {
		quality = 0.8;
	}
	return canvas.convertToBlob({
		type : mimeType,
		quality : quality,
	});
}

/**
 * Writer
 */
class GLTFWriter {

	private var plugins : Array<Dynamic> = [];
	private var options : {
		binary : Bool,
		trs : Bool,
		onlyVisible : Bool,
		maxTextureSize : Int,
		animations : Array<Dynamic>,
		includeCustomExtensions : Bool
	};
	private var pending : Array<js.lib.Promise<Dynamic>> = [];
	private var buffers : Array<ArrayBuffer> = [];
	private var byteOffset : Int = 0;
	private var nodeMap : Map<Scene, Int> = new Map();
	private var skins : Array<Scene> = [];
	private var json : {
		asset : {
			version : String,
			generator : String
		},
		extensionsUsed : Array<String>,
		extensionsRequired : Array<String>,
		buffers : Array<{
			byteLength : Int,
			uri : String
		}>,
		bufferViews : Array<{
			buffer : Int,
			byteOffset : Int,
			byteLength : Int,
			byteStride : Int,
			target : BufferViewTargets
		}>,
		accessors : Array<{
			bufferView : Int,
			byteOffset : Int,
			componentType : ComponentTypes,
			count : Int,
			max : Array<Float>,
			min : Array<Float>,
			type : AccessorTypes,
			normalized : Bool
		}>,
		images : Array<{
			mimeType : String,
			bufferView : Int,
			uri : String
		}>,
		samplers : Array<{
			magFilter : Int,
			minFilter : Int,
			wrapS : Int,
			wrapT : Int
		}>,
		textures : Array<{
			sampler : Int,
			source : Int,
			name : String
		}>,
		materials : Array<{
			pbrMetallicRoughness : {
				baseColorFactor : Array<Float>,
				metallicFactor : Float,
				roughnessFactor : Float,
				metallicRoughnessTexture : {
					index : Int,
					texCoord : Int
				},
				baseColorTexture : {
					index : Int,
					texCoord : Int
				}
			},
			emissiveFactor : Array<Float>,
			emissiveTexture : {
				index : Int,
				texCoord : Int
			},
			normalTexture : {
				index : Int,
				texCoord : Int,
				scale : Float
			},
			occlusionTexture : {
				index : Int,
				texCoord : Int,
				strength : Float
			},
			alphaMode : String,
			alphaCutoff : Float,
			doubleSided : Bool,
			name : String,
			extensions : {
				[String] : Dynamic
			},
			extras : {
				[String] : Dynamic
			}
		}>,
		meshes : Array<{
			primitives : Array<{
				mode : Int,
				attributes : {
					[String] : Int
				},
				indices : Int,
				material : Int,
				targets : Array<{
					POSITION : Int,
					NORMAL : Int
				}>,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			weights : Array<Float>,
			extras : {
				targetNames : Array<String>
			}
		}>,
		cameras : Array<{
			type : String,
			orthographic : {
				xmag : Float,
				ymag : Float,
				zfar : Float,
				znear : Float
			},
			perspective : {
				aspectRatio : Float,
				yfov : Float,
				zfar : Float,
				znear : Float
			},
			name : String
		}>,
		scenes : Array<{
			nodes : Array<Int>,
			name : String
		}>,
		scene : Int,
		animations : Array<{
			name : String,
			samplers : Array<{
				input : Int,
				output : Int,
				interpolation : String
			}>,
			channels : Array<{
				sampler : Int,
				target : {
					node : Int,
					path : String
				}
			}>
		}>,
		skins : Array<{
			inverseBindMatrices : Int,
			joints : Array<Int>,
			skeleton : Int
		}>,
		extensions : {
			[String] : Dynamic
		}
	} = {
		asset : {
			version : "2.0",
			generator : "THREE.GLTFExporter r" + REVISION,
		},
		extensionsUsed : [],
		extensionsRequired : [],
		buffers : [],
		bufferViews : [],
		accessors : [],
		images : [],
		samplers : [],
		textures : [],
		materials : [],
		meshes : [],
		cameras : [],
		scenes : [],
		scene : 0,
		animations : [],
		skins : [],
		extensions : {},
	};

	public function new() {
	}

	public function setPlugins(plugins : Array<Dynamic>) : Void {
		this.plugins = plugins;
	}

	/**
	 * Parse scenes and generate GLTF output
	 * @param  {Scene or [THREE.Scenes]} input   Scene or Array of THREE.Scenes
	 * @param  {Function} onDone  Callback on completed
	 * @param  {Object} options options
	 */
	public function write(input : Scene | Array<Scene>, onDone : Function, options : {
		binary : Bool,
		trs : Bool,
		onlyVisible : Bool,
		maxTextureSize : Int,
		animations : Array<Dynamic>,
		includeCustomExtensions : Bool
	} = {
		binary : false,
		trs : false,
		onlyVisible : true,
		maxTextureSize : -1,
		animations : [],
		includeCustomExtensions : false,
	}) : js.lib.Promise<Dynamic> {
		this.options = {
			binary : options.binary,
			trs : options.trs,
			onlyVisible : options.onlyVisible,
			maxTextureSize : options.maxTextureSize,
			animations : options.animations,
			includeCustomExtensions : options.includeCustomExtensions,
		};
		if (this.options.animations.length > 0) {
			// Only TRS properties, and not matrices, may be targeted by animation.
			this.options.trs = true;
		}
		this.processInput(input);
		return new js.lib.Promise(function(resolve : Function) {
			Promise.all(this.pending).then(function(_) {
				var writer : GLTFWriter = this;
				var buffers : Array<ArrayBuffer> = writer.buffers;
				var json : {
					asset : {
						version : String,
						generator : String
					},
					extensionsUsed : Array<String>,
					extensionsRequired : Array<String>,
					buffers : Array<{
						byteLength : Int,
						uri : String
					}>,
					bufferViews : Array<{
						buffer : Int,
						byteOffset : Int,
						byteLength : Int,
						byteStride : Int,
						target : BufferViewTargets
					}>,
					accessors : Array<{
						bufferView : Int,
						byteOffset : Int,
						componentType : ComponentTypes,
						count : Int,
						max : Array<Float>,
						min : Array<Float>,
						type : AccessorTypes,
						normalized : Bool
					}>,
					images : Array<{
						mimeType : String,
						bufferView : Int,
						uri : String
					}>,
					samplers : Array<{
						magFilter : Int,
						minFilter : Int,
						wrapS : Int,
						wrapT : Int
					}>,
					textures : Array<{
						sampler : Int,
						source : Int,
						name : String
					}>,
					materials : Array<{
						pbrMetallicRoughness : {
							baseColorFactor : Array<Float>,
							metallicFactor : Float,
							roughnessFactor : Float,
							metallicRoughnessTexture : {
								index : Int,
								texCoord : Int
							},
							baseColorTexture : {
								index : Int,
								texCoord : Int
							}
						},
						emissiveFactor : Array<Float>,
						emissiveTexture : {
							index : Int,
							texCoord : Int
						},
						normalTexture : {
							index : Int,
							texCoord : Int,
							scale : Float
						},
						occlusionTexture : {
							index : Int,
							texCoord : Int,
							strength : Float
						},
						alphaMode : String,
						alphaCutoff : Float,
						doubleSided : Bool,
						name : String,
						extensions : {
							[String] : Dynamic
						},
						extras : {
							[String] : Dynamic
						}
					}>,
					meshes : Array<{
						primitives : Array<{
							mode : Int,
							attributes : {
								[String] : Int
							},
							indices : Int,
							material : Int,
							targets : Array<{
								POSITION : Int,
								NORMAL : Int
							}>,
							extensions : {
								[String] : Dynamic
							},
							extras : {
								[String] : Dynamic
							}
						}>,
						weights : Array<Float>,
						extras : {
							targetNames : Array<String>
						}
					}>,
					cameras : Array<{
						type : String,
						orthographic : {
							xmag : Float,
							ymag : Float,
							zfar : Float,
							znear : Float
						},
						perspective : {
							aspectRatio : Float,
							yfov : Float,
							zfar : Float,
							znear : Float
						},
						name : String
					}>,
					scenes : Array<{
						nodes : Array<Int>,
						name : String
					}>,
					scene : Int,
					animations : Array<{
						name : String,
						samplers : Array<{
							input : Int,
							output : Int,
							interpolation : String
						}>,
						channels : Array<{
							sampler : Int,
							target : {
								node : Int,
								path : String
							}
						}>
					}>,
					skins : Array<{
						inverseBindMatrices : Int,
						joints : Array<Int>,
						skeleton : Int
					}>,
					extensions : {
						[String] : Dynamic
					}
				} = writer.json;
				var options : {
					binary : Bool,
					trs : Bool,
					onlyVisible : Bool,
					maxTextureSize : Int,
					animations : Array<Dynamic>,
					includeCustomExtensions : Bool
				} = writer.options;
				var extensionsUsed : StringMap = writer.extensionsUsed;
				var extensionsRequired : StringMap = writer.extensionsRequired;
				// Merge buffers.
				var blob : Blob = new Blob(buffers, { type : "application/octet-stream" });
				// Declare extensions.
				var extensionsUsedList : Array<String> = extensionsUsed.keys();
				var extensionsRequiredList : Array<String> = extensionsRequired.keys();
				if (extensionsUsedList.length > 0) json.extensionsUsed = extensionsUsedList;
				if (extensionsRequiredList.length > 0) json.extensionsRequired = extensionsRequiredList;
				// Update bytelength of the single buffer.
				if (json.buffers != null && json.buffers.length > 0) json.buffers[0].byteLength = blob.size;
				if (options.binary) {
					// https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#glb-file-format-specification
					var reader : FileReader = new FileReader();
					reader.readAsArrayBuffer(blob);
					reader.onloadend = function() {
						// Binary chunk.
						var binaryChunk : ArrayBuffer = getPaddedArrayBuffer(reader.result);
						var binaryChunkPrefix : DataView = new DataView(new ArrayBuffer(GLBChunkPrefixBytes.GLB_CHUNK_PREFIX_BYTES));
						binaryChunkPrefix.setUint32(0, binaryChunk.byteLength, true);
						binaryChunkPrefix.setUint32(4, ChunkTypes.BIN, true);
						// JSON chunk.
						var jsonChunk : ArrayBuffer = getPaddedArrayBuffer(stringToArrayBuffer(JSON.stringify(json)), 0x20);
						var jsonChunkPrefix : DataView = new DataView(new ArrayBuffer(GLBChunkPrefixBytes.GLB_CHUNK_PREFIX_BYTES));
						jsonChunkPrefix.setUint32(0, jsonChunk.byteLength, true);
						jsonChunkPrefix.setUint32(4, ChunkTypes.JSON, true);
						// GLB header.
						var header : ArrayBuffer = new ArrayBuffer(12);
						var headerView : DataView = new DataView(header);
						headerView.setUint32(0, GLBHeaderMagic.GLB_HEADER_MAGIC, true);
						headerView.setUint32(4, GLBVersion.GLB_VERSION, true);
						var totalByteLength : Int = 12 + jsonChunkPrefix.byteLength + jsonChunk.byteLength + binaryChunkPrefix.byteLength + binaryChunk.byteLength;
						headerView.setUint32(8, totalByteLength, true);
						var glbBlob : Blob = new Blob([
							header,
							jsonChunkPrefix.buffer,
							jsonChunk,
							binaryChunkPrefix.buffer,
							binaryChunk,
						], { type : "application/octet-stream" });
						var glbReader : FileReader = new FileReader();
						glbReader.readAsArrayBuffer(glbBlob);
						glbReader.onloadend = function() {
							onDone(glbReader.result);
						};
					};
				} else {
					if (json.buffers != null && json.buffers.length > 0) {
						var reader : FileReader = new FileReader();
						reader.readAsDataURL(blob);
						reader.onloadend = function() {
							var base64data : String = reader.result;
							json.buffers[0].uri = base64data;
							onDone(json);
						};
					} else {
						onDone(json);
					}
				}
			});
		}, this);
	}

	/**
	 * Serializes a userData.
	 *
	 * @param {THREE.Object3D|THREE.Material} object
	 * @param {Object} objectDef
	 */
	private function serializeUserData(object : Scene, objectDef : {
		extensions : {
			[String] : Dynamic
		},
		extras : {
			[String] : Dynamic
		}
	}) : Void {
		if (Reflect.fields(object.userData).length == 0) return;
		var options : {
			binary : Bool,
			trs : Bool,
			onlyVisible : Bool,
			maxTextureSize : Int,
			animations : Array<Dynamic>,
			
			includeCustomExtensions : Bool
		} = this.options;
		var extensionsUsed : StringMap = this.extensionsUsed;

		try {
			var json : Dynamic = JSON.parse(JSON.stringify(object.userData));
			if (options.includeCustomExtensions && json.gltfExtensions != null) {
				if (objectDef.extensions == null) objectDef.extensions = {};
				for (extensionName in json.gltfExtensions) {
					objectDef.extensions[extensionName] = json.gltfExtensions[extensionName];
					extensionsUsed.set(extensionName, true);
				}
				json.gltfExtensions = null;
			}
			if (Reflect.fields(json).length > 0) objectDef.extras = json;
		} catch (error : Dynamic) {
			console.warn("THREE.GLTFExporter: userData of '" + object.name + "' " +
				"won't be serialized because of JSON.stringify error - " + error.message);
		}

	}

	/**
	 * Returns ids for buffer attributes.
	 * @param  {Object} object
	 * @return {Integer}
	 */
	private function getUID(attribute : BufferAttribute, isRelativeCopy : Bool = false) : Int {
		if (!this.uids.has(attribute)) {
			var uids : Map<Bool, Int> = new Map();
			uids.set(true, this.uid++);
			uids.set(false, this.uid++);
			this.uids.set(attribute, uids);
		}
		var uids : Map<Bool, Int> = this.uids.get(attribute);
		return uids.get(isRelativeCopy);
	}

	/**
	 * Checks if normal attribute values are normalized.
	 *
	 * @param {BufferAttribute} normal
	 * @returns {Boolean}
	 */
	private function isNormalizedNormalAttribute(normal : BufferAttribute) : Bool {
		var cache : {
			meshes : Map<String, Int>,
			attributes : Map<Int, Int>,
			attributesNormalized : Map<BufferAttribute, BufferAttribute>,
			materials : Map<Texture, Int>,
			textures : Map<Texture, Int>,
			images : Map<Texture, {
				[String] : Int
			}>
		} = this.cache;
		if (cache.attributesNormalized.has(normal)) return false;
		var v : Vector3 = new Vector3();
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
	private function createNormalizedNormalAttribute(normal : BufferAttribute) : BufferAttribute {
		var cache : {
			meshes : Map<String, Int>,
			attributes : Map<Int, Int>,
			attributesNormalized : Map<BufferAttribute, BufferAttribute>,
			materials : Map<Texture, Int>,
			textures : Map<Texture, Int>,
			images : Map<Texture, {
				[String] : Int
			}>
		} = this.cache;
		if (cache.attributesNormalized.has(normal))	return cache.attributesNormalized.get(normal);
		var attribute : BufferAttribute = normal.clone();
		var v : Vector3 = new Vector3();
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
	private function applyTextureTransform(mapDef : {
		extensions : {
			[String] : Dynamic
		}
	}, texture : Texture) : Void {
		var didTransform : Bool = false;
		var transformDef : {
			offset : Array<Float>,
			rotation : Float,
			scale : Array<Float>
		} = {};
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
			mapDef.extensions = mapDef.extensions != null ? mapDef.extensions : {};
			mapDef.extensions["KHR_texture_transform"] = transformDef;
			this.extensionsUsed.set("KHR_texture_transform", true);
		}
	}

	private function buildMetalRoughTexture(metalnessMap : Texture, roughnessMap : Texture) : Texture {
		if (metalnessMap == roughnessMap) return metalnessMap;
		function getEncodingConversion(map : Texture) : Function {
			if (map.colorSpace == SRGBColorSpace) {
				return function(c : Float) : Float {
					return (c < 0.04045) ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
				};
			}
			return function(c : Float) : Float {
				return c;
			};
		}
		console.warn("THREE.GLTFExporter: Merged metalnessMap and roughnessMap textures.");
		if (Std.isOfType(metalnessMap, CompressedTexture)) {
			metalnessMap = decompress(metalnessMap);
		}
		if (Std.isOfType(roughnessMap, CompressedTexture)) {
			roughnessMap = decompress(roughnessMap);
		}
		var metalness : ImageElement = metalnessMap != null ? metalnessMap.image : null;
		var roughness : ImageElement = roughnessMap != null ? roughnessMap.image : null;
		var width : Int = Math.max(metalness != null ? metalness.width : 0, roughness != null ? roughness.width : 0);
		var height : Int = Math.max(metalness != null ? metalness.height : 0, roughness != null ? roughness.height : 0);
		var canvas : CanvasElement = getCanvas();
		canvas.width = width;
		canvas.height = height;
		var context : CanvasRenderingContext2D = canvas.getContext("2d");
		context.fillStyle = "#00ffff";
		context.fillRect(0, 0, width, height);
		var composite : ImageData = context.getImageData(0, 0, width, height);
		if (metalness != null) {
			context.drawImage(metalness, 0, 0, width, height);
			var convert : Function = getEncodingConversion(metalnessMap);
			var data : Uint8ClampedArray = context.getImageData(0, 0, width, height).data;
			for (i in 2...data.length) {
				if ((i % 4) == 2) composite.data[i] = convert(data[i] / 256) * 256;
			}
		}
		if (roughness != null) {
			context.drawImage(roughness, 0, 0, width, height);
			var convert : Function = getEncodingConversion(roughnessMap);
			var data : Uint8ClampedArray = context.getImageData(0, 0, width, height).data;
			for (i in 1...data.length) {
				if ((i % 4) == 1) composite.data[i] = convert(data[i] / 256) * 256;
			}
		}
		context.putImageData(composite, 0, 0);
		//
		var reference : Texture = metalnessMap != null ? metalnessMap : roughnessMap;
		var texture : Texture = reference.clone();
		texture.source = new Source(canvas);
		texture.colorSpace = NoColorSpace;
		texture.channel = (metalnessMap != null ? metalnessMap.channel : roughnessMap.channel);
		if (metalnessMap != null && roughnessMap != null && metalnessMap.channel != roughnessMap.channel) {
			console.warn("THREE.GLTFExporter: UV channels for metalnessMap and roughnessMap textures must match.");
		}
		return texture;
	}

	/**
	 * Process a buffer to append to the default one.
	 * @param  {ArrayBuffer} buffer
	 * @return {Integer}
	 */
	private function processBuffer(buffer : ArrayBuffer) : Int {
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		var buffers : Array<ArrayBuffer> = this.buffers;
		if (json.buffers == null) json.buffers = [{ byteLength : 0 }];
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
	private function processBufferView(attribute : BufferAttribute, componentType : ComponentTypes, start : Int, count : Int, target : BufferViewTargets) : {
		id : Int,
		byteLength : Int
	} {
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		if (json.bufferViews == null) json.bufferViews = [];
		// Create a new dataview and dump the attribute's array into it
		var componentSize : Int;
		switch (componentType) {
			case ComponentTypes.BYTE:
			case ComponentTypes.UNSIGNED_BYTE:
				componentSize = 1;
				break;
			case ComponentTypes.SHORT:
			case ComponentTypes.UNSIGNED_SHORT:
				componentSize = 2;
				break;
			default:
				componentSize = 4;
		}
		var byteStride : Int = attribute.itemSize * componentSize;
		if (target == WEBGL_CONSTANTS.get(BufferViewTargets.ARRAY_BUFFER)) {
			// Each element of a vertex attribute MUST be aligned to 4-byte boundaries
			// inside a bufferView
			byteStride = Math.ceil(byteStride / 4) * 4;
		}
		var byteLength : Int = getPaddedBufferSize(count * byteStride);
		var dataView : DataView = new DataView(new ArrayBuffer(byteLength));
		var offset : Int = 0;
		for (i in start...start + count) {
			for (a in 0...attribute.itemSize) {
				var value : Float;
				if (attribute.itemSize > 4) {
					// no support for interleaved data for itemSize > 4
					value = attribute.array[i * attribute.itemSize + a];
				} else {
					if (a == 0) value = attribute.getX(i);
					else if (a == 1) value = attribute.getY(i);
					else if (a == 2) value = attribute.getZ(i);
					else if (a == 3) value = attribute.getW(i);
					if (attribute.normalized) {
						value = MathUtils.normalize(value, attribute.array);
					}
				}
				switch (componentType) {
					case ComponentTypes.FLOAT:
						dataView.setFloat32(offset, value, true);
						break;
					case ComponentTypes.INT:
						dataView.setInt32(offset, value, true);
						break;
					case ComponentTypes.UNSIGNED_INT:
						dataView.setUint32(offset, value, true);
						break;
					case ComponentTypes.SHORT:
						dataView.setInt16(offset, value, true);
						break;
					case ComponentTypes.UNSIGNED_SHORT:
						dataView.setUint16(offset, value, true);
						break;
					case ComponentTypes.BYTE:
						dataView.setInt8(offset, value);
						break;
					case ComponentTypes.UNSIGNED_BYTE:
						dataView.setUint8(offset, value);
						break;
				}
				offset += componentSize;
			}
			if ((offset % byteStride) != 0) {
				offset += byteStride - (offset % byteStride);
			}
		}
		var bufferViewDef : {
			buffer : Int,
			byteOffset : Int,
			byteLength : Int,
			byteStride : Int,
			target : BufferViewTargets
		} = {
			buffer : this.processBuffer(dataView.buffer),
			byteOffset : this.byteOffset,
			byteLength : byteLength,
		};
		if (target != null) bufferViewDef.target = target;
		if (target == WEBGL_CONSTANTS.get(BufferViewTargets.ARRAY_BUFFER)) {
			// Only define byteStride for vertex attributes.
			bufferViewDef.byteStride = byteStride;
		}
		this.byteOffset += byteLength;
		json.bufferViews.push(bufferViewDef);
		// @TODO Merge bufferViews where possible.
		var output : {
			id : Int,
			byteLength : Int
		} = {
			id : json.bufferViews.length - 1,
			byteLength : 0,
		};
		return output;
	}

	/**
	 * Process and generate a BufferView from an image Blob.
	 * @param {Blob} blob
	 * @return {Promise<Integer>}
	 */
	private function processBufferViewImage(blob : Blob) : js.lib.Promise<Int> {
		var writer : GLTFWriter = this;
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		if (json.bufferViews == null) json.bufferViews = [];
		return new js.lib.Promise(function(resolve : Function) {
			var reader : FileReader = new FileReader();
			reader.readAsArrayBuffer(blob);
			reader.onloadend = function() {
				var buffer : ArrayBuffer = getPaddedArrayBuffer(reader.result);
				var bufferViewDef : {
					buffer : Int,
					byteOffset : Int,
					byteLength : Int
				} = {
					buffer : writer.processBuffer(buffer),
					byteOffset : writer.byteOffset,
					byteLength : buffer.byteLength,
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
	private function processAccessor(attribute : BufferAttribute, geometry : Scene, start : Int, count : Int) : Int {
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		var types : Map<Int, String> = new Map([
			[1, "SCALAR"],
			[2, "VEC2"],
			[3, "VEC3"],
			[4, "VEC4"],
			[9, "MAT3"],
			[16, "MAT4"],
		]);
		var componentType : ComponentTypes;
		// Detect the component type of the attribute array
		if (Std.isOfType(attribute.array, Float32Array)) {
			componentType = ComponentTypes.FLOAT;
		} else if (Std.isOfType(attribute.array, Int32Array)) {
			componentType = ComponentTypes.INT;
		} else if (Std.isOfType(attribute.array, Uint32Array)) {
			componentType = ComponentTypes.UNSIGNED_INT;
		} else if (Std.isOfType(attribute.array, Int16Array)) {
			componentType = ComponentTypes.SHORT;
		} else if (Std.isOfType(attribute.array, Uint16Array)) {
			componentType = ComponentTypes.UNSIGNED_SHORT;
		} else if (Std.isOfType(attribute.array, Int8Array)) {
			componentType = ComponentTypes.BYTE;
		} else if (Std.isOfType(attribute.array, Uint8Array)) {
			componentType = ComponentTypes.UNSIGNED_BYTE;
		} else {
			throw new Error("THREE.GLTFExporter: Unsupported bufferAttribute component type: " + attribute.array.constructor.name);
		}
		if (start == null) start = 0;
		if (count == null || count == -1) count = attribute.count;
		// Skip creating an accessor if the attribute doesn't have data to export
		if (count == 0) return null;
		var minMax : {
			min : Array<Float>,
			max : Array<Float>
		} = getMinMax(attribute, start, count);
		var bufferViewTarget : BufferViewTargets;
		// If geometry isn't provided, don't infer the target usage of the bufferView. For
		// animation samplers, target must not be set.
		if (geometry != null) {
			bufferViewTarget = attribute == geometry.index ? WEBGL_CONSTANTS.get(BufferViewTargets.ELEMENT_ARRAY_BUFFER) : WEBGL_CONSTANTS.get(BufferViewTargets.ARRAY_BUFFER);
		}
		var bufferView : {
			id : Int,
			byteLength : Int
		} = this.processBufferView(attribute, componentType, start, count, bufferViewTarget);
		var accessorDef : {
			bufferView : Int,
			byteOffset : Int,
			componentType : ComponentTypes,
			count : Int,
			max : Array<Float>,
			min : Array<Float>,
			type : AccessorTypes,
			normalized : Bool
		} = {
			bufferView : bufferView.id,
			byteOffset : bufferView.byteOffset,
			componentType : componentType,
			count : count,
			max : minMax.max,
			min : minMax.min,
			type : types.get(attribute.itemSize),
		};
		if (attribute.normalized) accessorDef.normalized = true;
		if (json.accessors == null) json.accessors = [];
		return json.accessors.push(accessorDef) - 1;
	}

	/**
	 * Process image
	 * @param  {Image} image to process
	 * @param  {Integer} format of the image (RGBAFormat)
	 * @param  {Boolean} flipY before writing out the image
	 * @param  {String} mimeType export format
	 * @return {Integer
	 *     Index of the processed texture in the "images" array
	 */
	private function processImage(image : ImageElement, format : Int, flipY : Bool, mimeType : String = "image/png") : Int {
		if (image != null) {
			var writer : GLTFWriter = this;
			var cache : {
				meshes : Map<String, Int>,
				attributes : Map<Int, Int>,
				attributesNormalized : Map<BufferAttribute, BufferAttribute>,
				materials : Map<Texture, Int>,
				textures : Map<Texture, Int>,
				images : Map<Texture, {
					[String] : Int
				}>
			} = writer.cache;
			var json : {
				asset : {
					version : String,
					generator : String
				},
				extensionsUsed : Array<String>,
				extensionsRequired : Array<String>,
				buffers : Array<{
					byteLength : Int,
					uri : String
				}>,
				bufferViews : Array<{
					buffer : Int,
					byteOffset : Int,
					byteLength : Int,
					byteStride : Int,
					target : BufferViewTargets
				}>,
				accessors : Array<{
					bufferView : Int,
					byteOffset : Int,
					componentType : ComponentTypes,
					count : Int,
					max : Array<Float>,
					min : Array<Float>,
					type : AccessorTypes,
					normalized : Bool
				}>,
				images : Array<{
					mimeType : String,
					bufferView : Int,
					uri : String
				}>,
				samplers : Array<{
					magFilter : Int,
					minFilter : Int,
					wrapS : Int,
					wrapT : Int
				}>,
				textures : Array<{
					sampler : Int,
					source : Int,
					name : String
				}>,
				materials : Array<{
					pbrMetallicRoughness : {
						baseColorFactor : Array<Float>,
						metallicFactor : Float,
						roughnessFactor : Float,
						metallicRoughnessTexture : {
							index : Int,
							texCoord : Int
						},
						baseColorTexture : {
							index : Int,
							texCoord : Int
						}
					},
					emissiveFactor : Array<Float>,
					emissiveTexture : {
						index : Int,
						texCoord : Int
					},
					normalTexture : {
						index : Int,
						texCoord : Int,
						scale : Float
					},
					occlusionTexture : {
						index : Int,
						texCoord : Int,
						strength : Float
					},
					alphaMode : String,
					alphaCutoff : Float,
					doubleSided : Bool,
					name : String,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				meshes : Array<{
					primitives : Array<{
						mode : Int,
						attributes : {
							[String] : Int
						},
						indices : Int,
						material : Int,
						targets : Array<{
							POSITION : Int,
							NORMAL : Int
						}>,
						extensions : {
							[String] : Dynamic
						},
						extras : {
							[String] : Dynamic
						}
					}>,
					weights : Array<Float>,
					extras : {
						targetNames : Array<String>
					}
				}>,
				cameras : Array<{
					type : String,
					orthographic : {
						xmag : Float,
						ymag : Float,
						zfar : Float,
						znear : Float
					},
					perspective : {
						aspectRatio : Float,
						yfov : Float,
						zfar : Float,
						znear : Float
					},
					name : String
				}>,
				scenes : Array<{
					nodes : Array<Int>,
					name : String
				}>,
				scene : Int,
				animations : Array<{
					name : String,
					samplers : Array<{
						input : Int,
						output : Int,
						interpolation : String
					}>,
					channels : Array<{
						sampler : Int,
						target : {
							node : Int,
							path : String
						}
					}>
				}>,
				skins : Array<{
					inverseBindMatrices : Int,
					joints : Array<Int>,
					skeleton : Int
				}>,
				extensions : {
					[String] : Dynamic
				}
			} = this.json;
			var options : {
				binary : Bool,
				trs : Bool,
				onlyVisible : Bool,
				maxTextureSize : Int,
				animations : Array<Dynamic>,
				includeCustomExtensions : Bool
			} = writer.options;
			var pending : Array<js.lib.Promise<Dynamic>> = writer.pending;
			if (!cache.images.has(image)) cache.images.set(image, {});
			var cachedImages : {
				[String] : Int
			} = cache.images.get(image);
			var key : String = mimeType + ":flipY/" + flipY.toString();
			if (cachedImages[key] != null) return cachedImages[key];
			if (json.images == null) json.images = [];
			var imageDef : {
				mimeType : String,
				bufferView : Int,
				uri : String
			} = { mimeType : mimeType };
			var canvas : CanvasElement = getCanvas();
			canvas.width = Math.min(image.width, options.maxTextureSize);
			canvas.height = Math.min(image.height, options.maxTextureSize);
			var ctx : CanvasRenderingContext2D = canvas.getContext("2d");
			if (flipY) {
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
				var data : Uint8ClampedArray = new Uint8ClampedArray(image.height * image.width * 4);
				for (i in 0...data.length) {
					if ((i % 4) == 0) data[i] = image.data[i];
					else if ((i % 4) == 1) data[i] = image.data[i + 1];
					else if ((i % 4) == 2) data[i] = image.data[i + 2];
					else if ((i % 4) == 3) data[i] = image.data[i + 3];
				}
				ctx.putImageData(new ImageData(data, image.width, image.height), 0, 0);
			} else {
				if (((typeof(HTMLImageElement) != "undefined" && Std.isOfType(image, HTMLImageElement)) ||
					(typeof(HTMLCanvasElement) != "undefined" && Std.isOfType(image, HTMLCanvasElement)) ||
					(typeof(ImageBitmap) != "undefined" && Std.isOfType(image, ImageBitmap)) ||
					(typeof(OffscreenCanvas) != "undefined" && Std.isOfType(image, OffscreenCanvas)))) {
					ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
				} else {
					throw new Error("THREE.GLTFExporter: Invalid image type. Use HTMLImageElement, HTMLCanvasElement, ImageBitmap or OffscreenCanvas.");
				}
			}
			if (options.binary) {
				pending.push(
					getToBlobPromise(canvas, mimeType).then(function(blob : Blob) : js.lib.Promise<Int> {
						return writer.processBufferViewImage(blob);
					}).then(function(bufferViewIndex : Int) : Void {
						imageDef.bufferView = bufferViewIndex;
					})
				);
			} else {
				if (canvas.toDataURL != null) {
					imageDef.uri = canvas.toDataURL(mimeType);
				} else {
					pending.push(
						getToBlobPromise(canvas, mimeType).then(function(blob : Blob) : js.lib.Promise<String> {
							return new js.lib.Promise(function(resolve : Function) : Void {
								var reader : FileReader = new FileReader();
								reader.readAsDataURL(blob);
								reader.onloadend = function() : Void {
									resolve(reader.result);
								};
							});
						}).then(function(dataURL : String) : Void {
							imageDef.uri = dataURL;
						})
					);
				}
			}
			var index : Int = json.images.push(imageDef) - 1;
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
	private function processSampler(map : Texture) : Int {
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		if (json.samplers == null) json.samplers = [];
		var samplerDef : {
			magFilter : Int,
			minFilter : Int,
			wrapS : Int,
			wrapT : Int
		} = {
			magFilter : THREE_TO_WEBGL.get(map.magFilter),
			minFilter : THREE_TO_WEBGL.get(map.minFilter),
			wrapS : THREE_TO_WEBGL.get(map.wrapS),
			wrapT : THREE_TO_WEBGL.get(map.wrapT),
		};
		return json.samplers.push(samplerDef) - 1;
	}

	/**
	 * Process texture
	 * @param  {Texture} map Map to process
	 * @return {Integer} Index of the processed texture in the "textures" array
	 */
	private function processTexture(map : Texture) : Int {
		var writer : GLTFWriter = this;
		var options : {
			binary : Bool,
			trs : Bool,
			onlyVisible : Bool,
			maxTextureSize : Int,
			animations : Array<Dynamic>,
			includeCustomExtensions : Bool
		} = writer.options;
		var cache : {
			meshes : Map<String, Int>,
			attributes : Map<Int, Int>,
			attributesNormalized : Map<BufferAttribute, BufferAttribute>,
			materials : Map<Texture, Int>,
			textures : Map<Texture, Int>,
			images : Map<Texture, {
				[String] : Int
			}>
		} = writer.cache;
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		if (cache.textures.has(map)) return cache.textures.get(map);
		if (json.textures == null) json.textures = [];
		// make non-readable textures (e.g. CompressedTexture) readable by blitting them into a new texture
		if (Std.isOfType(map, CompressedTexture)) {
			map = decompress(map, options.maxTextureSize);
		}
		var mimeType : String = map.userData.mimeType;
		if (mimeType == "image/webp") mimeType = "image/png";
		var textureDef : {
			sampler : Int,
			source : Int,
			name : String
		} = {
			sampler : this.processSampler(map),
			source : this.processImage(map.image, map.format, map.flipY, mimeType),
		};
		if (map.name != null) textureDef.name = map.name;
		this._invokeAll(function(ext : Dynamic) : Void {
			if (ext.writeTexture != null) ext.writeTexture(map, textureDef);
		});
		var index : Int = json.textures.push(textureDef) - 1;
		cache.textures.set(map, index);
		return index;
	}

	/**
	 * Process material
	 * @param  {THREE.Material} material Material to process
	 * @return {Integer|null} Index of the processed material in the "materials" array
	 */
	private function processMaterial(material : Texture) : Int {
		var cache : {
			meshes : Map<String, Int>,
			attributes : Map<Int, Int>,
			attributesNormalized : Map<BufferAttribute, BufferAttribute>,
			materials : Map<Texture, Int>,
			textures : Map<Texture, Int>,
			images : Map<Texture, {
				[String] : Int
			}>
		} = this.cache;
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		if (cache.materials.has(material)) return cache.materials.get(material);
		if (material.isShaderMaterial) {
			console.warn("THREE.GLTFExporter: THREE.ShaderMaterial not supported.");
			return null;
		}
		if (json.materials == null) json.materials = [];
		// @QUESTION Should we avoid including any attribute that has the default value?
		var materialDef : {
			pbrMetallicRoughness : {
				baseColorFactor : Array<Float>,
				metallicFactor : Float,
				roughnessFactor : Float,
				metallicRoughnessTexture : {
					index : Int,
					texCoord : Int
				},
				baseColorTexture : {
					index : Int,
					texCoord : Int
				}
			},
			emissiveFactor : Array<Float>,
			emissiveTexture : {
				index : Int,
				texCoord : Int
			},
			normalTexture : {
				index : Int,
				texCoord : Int,
				scale : Float
			},
			occlusionTexture : {
				index : Int,
				texCoord : Int,
				strength : Float
			},
			alphaMode : String,
			alphaCutoff : Float,
			doubleSided : Bool,
			name : String,
			extensions : {
				[String] : Dynamic
			},
			extras : {
				[String] : Dynamic
			}
		} = { pbrMetallicRoughness : {} };
		if (!material.isMeshStandardMaterial && !material.isMeshBasicMaterial) {
			console.warn("THREE.GLTFExporter: Use MeshStandardMaterial or MeshBasicMaterial for best results.");
		}
		// pbrMetallicRoughness.baseColorFactor
		var color : Array<Float> = material.color.toArray().concat([material.opacity]);
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
		if (material.metalnessMap != null || material.roughnessMap != null) {
			var metalRoughTexture : Texture = this.buildMetalRoughTexture(material.metalnessMap, material.roughnessMap);
			var metalRoughMapDef : {
				index : Int,
				texCoord : Int
			} = {
				index : this.processTexture(metalRoughTexture),
				channel : metalRoughTexture.channel,
			};
			this.applyTextureTransform(metalRoughMapDef, metalRoughTexture);
			materialDef.pbrMetallicRoughness.metallicRoughnessTexture = metalRoughMapDef;
		}
		// pbrMetallicRoughness.baseColorTexture
		if (material.map != null) {
			var baseColorMapDef : {
				index : Int,
				texCoord : Int
			} = {
				index : this.processTexture(material.map),
				texCoord : material.map.channel,
			};
			this.applyTextureTransform(baseColorMapDef, material.map);
			materialDef.pbrMetallicRoughness.baseColorTexture = baseColorMapDef;
		}
		if (material.emissive != null) {
			var emissive : Color = material.emissive;
			var maxEmissiveComponent : Float = Math.max(emissive.r, emissive.g, emissive.b);
			if (maxEmissiveComponent > 0) {
				materialDef.emissiveFactor = material.emissive.toArray();
			}
			// emissiveTexture
			if (material.emissiveMap != null) {
				var emissiveMapDef : {
					index : Int,
					texCoord : Int
				} = {
					index : this.processTexture(material.emissiveMap),
					texCoord : material.emissiveMap.channel,
				};
				this.applyTextureTransform(emissiveMapDef, material.emissiveMap);
				materialDef.emissiveTexture = emissiveMapDef;
			}
		}
		// normalTexture
		if (material.normalMap != null) {
			var normalMapDef : {
				index : Int,
				texCoord : Int,
				scale : Float
			} = {
				index : this.processTexture(material.normalMap),
				texCoord : material.normalMap.channel,
			};
			if (material.normalScale != null && material.normalScale.x != 1) {
				// glTF normal scale is univariate. Ignore `y`, which may be flipped.
				// Context: https://github.com/mrdoob/three.js/issues/11438#issuecomment-507003995
				normalMapDef.scale = material.normalScale.x;
			}
			this.applyTextureTransform(normalMapDef, material.normalMap);
			materialDef.normalTexture = normalMapDef;
		}
		// occlusionTexture
		if (material.aoMap != null) {
			var occlusionMapDef : {
				index : Int,
				texCoord : Int,
				strength : Float
			} = {
				index : this.processTexture(material.aoMap),
				texCoord : material.aoMap.channel,
			};
			if (material.aoMapIntensity != 1.0) {
				occlusionMapDef.strength = material.aoMapIntensity;
			}
			this.applyTextureTransform(occlusionMapDef, material.aoMap);
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
		this.serializeUserData(material, materialDef);
		this._invokeAll(function(ext : Dynamic) : Void {
			if (ext.writeMaterial != null) ext.writeMaterial(material, materialDef);
		});
		var index : Int = json.materials.push(materialDef) - 1;
		cache.materials.set(material, index);
		return index;
	}

	/**
	 * Process mesh
	 * @param  {THREE.Mesh} mesh Mesh to process
	 * @return {Integer|null} Index of the processed mesh in the "meshes" array
	 */
	private function processMesh(mesh : Scene) : Int {
		var cache : {
			meshes : Map<String, Int>,
			attributes : Map<Int, Int>,
			attributesNormalized : Map<BufferAttribute, BufferAttribute>,
			materials : Map<Texture, Int>,
			textures : Map<Texture, Int>,
			images : Map<Texture, {
				[String] : Int
			}>
		} = this.cache;
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,

			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		var cache : {
			meshes : Map<String, Int>,
			attributes : Map<Int, Int>,
			attributesNormalized : Map<BufferAttribute, BufferAttribute>,
			materials : Map<Texture, Int>,
			textures : Map<Texture, Int>,
			images : Map<Texture, {
				[String] : Int
			}>
		} = this.cache;
		var meshCacheKeyParts : Array<String> = [mesh.geometry.uuid];
		if (Std.isOfType(mesh.material, Array)) {
			for (i in 0...mesh.material.length) {
				meshCacheKeyParts.push(mesh.material[i].uuid);
			}
		} else {
			meshCacheKeyParts.push(mesh.material.uuid);
		}
		var meshCacheKey : String = meshCacheKeyParts.join(":");
		if (cache.meshes.has(meshCacheKey)) return cache.meshes.get(meshCacheKey);
		var geometry : Scene = mesh.geometry;
		var mode : Int;
		// Use the correct mode
		if (mesh.isLineSegments) {
			mode = WEBGL_CONSTANTS.get(0x0001);
		} else if (mesh.isLineLoop) {
			mode = WEBGL_CONSTANTS.get(0x0002);
		} else if (mesh.isLine) {
			mode = WEBGL_CONSTANTS.get(0x0003);
		} else if (mesh.isPoints) {
			mode = WEBGL_CONSTANTS.get(0x0000);
		} else {
			mode = mesh.material.wireframe ? WEBGL_CONSTANTS.get(0x0001) : WEBGL_CONSTANTS.get(0x0004);
		}
		var meshDef : {
			primitives : Array<{
				mode : Int,
				attributes : {
					[String] : Int
				},
				indices : Int,
				material : Int,
				targets : Array<{
					POSITION : Int,
					NORMAL : Int
				}>,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			weights : Array<Float>,
			extras : {
				targetNames : Array<String>
			}
		} = {};
		var attributes : {
			[String] : Int
		} = {};
		var primitives : Array<{
			mode : Int,
			attributes : {
				[String] : Int
			},
			indices : Int,
			material : Int,
			targets : Array<{
				POSITION : Int,
				NORMAL : Int
			}>,
			extensions : {
				[String] : Dynamic
			},
			extras : {
				[String] : Dynamic
			}
		}> = [];
		var targets : Array<{
			POSITION : Int,
			NORMAL : Int
		}> = [];
		// Conversion between attributes names in threejs and gltf spec
		var nameConversion : Map<String, String> = new Map([
			["uv", "TEXCOORD_0"],
			["uv1", "TEXCOORD_1"],
			["uv2", "TEXCOORD_2"],
			["uv3", "TEXCOORD_3"],
			["color", "COLOR_0"],
			["skinWeight", "WEIGHTS_0"],
			["skinIndex", "JOINTS_0"],
		]);
		var originalNormal : BufferAttribute = geometry.getAttribute("normal");
		if (originalNormal != null && !this.isNormalizedNormalAttribute(originalNormal)) {
			console.warn("THREE.GLTFExporter: Creating normalized normal attribute from the non-normalized one.");
			geometry.setAttribute("normal", this.createNormalizedNormalAttribute(originalNormal));
		}
		// @QUESTION Detect if .vertexColors = true?
		// For every attribute create an accessor
		var modifiedAttribute : BufferAttribute = null;
		for (attributeName in geometry.attributes) {
			// Ignore morph target attributes, which are exported later.
			if (attributeName.substring(0, 5) == "morph") continue;
			var attribute : BufferAttribute = geometry.attributes[attributeName];
			attributeName = nameConversion.get(attributeName) != null ? nameConversion.get(attributeName) : attributeName.toUpperCase();
			// Prefix all geometry attributes except the ones specifically
			// listed in the spec; non-spec attributes are considered custom.
			var validVertexAttributes : RegExp = /^(POSITION|NORMAL|TANGENT|TEXCOORD_\d+|COLOR_\d+|JOINTS_\d+|WEIGHTS_\d+)$/;
			if (!validVertexAttributes.match(attributeName)) attributeName = "_" + attributeName;
			if (cache.attributes.has(this.getUID(attribute))) {
				attributes[attributeName] = cache.attributes.get(this.getUID(attribute));
				continue;
			}
			// JOINTS_0 must be UNSIGNED_BYTE or UNSIGNED_SHORT.
			modifiedAttribute = null;
			var array : ArrayBuffer = attribute.array;
			if (attributeName == "JOINTS_0" &&
				!(Std.isOfType(array, Uint16Array)) &&
				!(Std.isOfType(array, Uint8Array))) {
				console.warn("GLTFExporter: Attribute \"skinIndex\" converted to type UNSIGNED_SHORT.");
				modifiedAttribute = new BufferAttribute(new Uint16Array(array), attribute.itemSize, attribute.normalized);
			}
			var accessor : Int = this.processAccessor(modifiedAttribute != null ? modifiedAttribute : attribute, geometry);
			if (accessor != null) {
				if (!attributeName.startsWith("_")) {
					this.detectMeshQuantization(attributeName, attribute);
				}
				attributes[attributeName] = accessor;
				cache.attributes.set(this.getUID(attribute), accessor);
			}
		}
		if (originalNormal != null) geometry.setAttribute("normal", originalNormal);
		// Skip if no exportable attributes found
		if (Reflect.fields(attributes).length == 0) return null;
		// Morph targets
		if (mesh.morphTargetInfluences != null && mesh.morphTargetInfluences.length > 0) {
			var weights : Array<Float> = [];
			var targetNames : Array<String> = [];
			var reverseDictionary : {
				[Int] : String
			} = {};
			if (mesh.morphTargetDictionary != null) {
				for (key in mesh.morphTargetDictionary) {
					reverseDictionary[mesh.morphTargetDictionary[key]] = key;
				}
			}
			for (i in 0...mesh.morphTargetInfluences.length) {
				var target : {
					POSITION : Int,
					NORMAL : Int
				} = {};
				var warned : Bool = false;
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
					var attribute : BufferAttribute = geometry.morphAttributes[attributeName][i];
					var gltfAttributeName : String = attributeName.toUpperCase();
					// Three.js morph attribute has absolute values while the one of glTF has relative values.
					//
					// glTF 2.0 Specification:
					// https://github.com/KhronosGroup/glTF/tree/master/specification/2.0#morph-targets
					var baseAttribute : BufferAttribute = geometry.attributes[attributeName];
					if (cache.attributes.has(this.getUID(attribute, true))) {
						target[gltfAttributeName] = cache.attributes.get(this.getUID(attribute, true));
						continue;
					}
					// Clones attribute not to override
					var relativeAttribute : BufferAttribute = attribute.clone();
					if (!geometry.morphTargetsRelative) {
						for (j in 0...attribute.count) {
							for (a in 0...attribute.itemSize) {
								if (a == 0) relativeAttribute.setX(j, attribute.getX(j) - baseAttribute.getX(j));
								else if (a == 1) relativeAttribute.setY(j, attribute.getY(j) - baseAttribute.getY(j));
								else if (a == 2) relativeAttribute.setZ(j, attribute.getZ(j) - baseAttribute.getZ(j));
								else if (a == 3) relativeAttribute.setW(j, attribute.getW(j) - baseAttribute.getW(j));
							}
						}
					}
					target[gltfAttributeName] = this.processAccessor(relativeAttribute, geometry);
					cache.attributes.set(this.getUID(baseAttribute, true), target[gltfAttributeName]);
				}
				targets.push(target);
				weights.push(mesh.morphTargetInfluences[i]);
				if (mesh.morphTargetDictionary != null) targetNames.push(reverseDictionary[i]);
			}
			meshDef.weights = weights;
			if (targetNames.length > 0) {
				meshDef.extras = {};
				meshDef.extras.targetNames = targetNames;
			}
		}
		var isMultiMaterial : Bool = Std.isOfType(mesh.material, Array);
		if (isMultiMaterial && geometry.groups.length == 0) return null;
		var didForceIndices : Bool = false;
		if (isMultiMaterial && geometry.index == null) {
			var indices : Array<Int> = [];
			for (i in 0...geometry.attributes.position.count) {
				indices[i] = i;
			}
			geometry.setIndex(indices);
			didForceIndices = true;
		}
		var materials : Array<Texture> = isMultiMaterial ? mesh.material : [mesh.material];
		var groups : Array<{
			materialIndex : Int,
			start : Int,
			count : Int
		}> = isMultiMaterial ? geometry.groups : [{ materialIndex : 0, start : null, count : null }];
		for (i in 0...groups.length) {
			var primitive : {
				mode : Int,
				attributes : {
					[String] : Int
				},
				indices : Int,
				material : Int,
				targets : Array<{
					POSITION : Int,
					NORMAL : Int
				}>,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			} = {
				mode : mode,
				attributes : attributes,
			};
			this.serializeUserData(geometry, primitive);
			if (targets.length > 0) primitive.targets = targets;
			if (geometry.index != null) {
				var cacheKey : String = this.getUID(geometry.index).toString();
				if (groups[i].start != null || groups[i].count != null) {
					cacheKey += ":" + groups[i].start + ":" + groups[i].count;
				}
				if (cache.attributes.has(cacheKey)) {
					primitive.indices = cache.attributes.get(cacheKey);
				} else {
					primitive.indices = this.processAccessor(geometry.index, geometry, groups[i].start, groups[i].count);
					cache.attributes.set(cacheKey, primitive.indices);
				}
				if (primitive.indices == null) primitive.indices = null;
			}
			var material : Int = this.processMaterial(materials[groups[i].materialIndex]);
			if (material != null) primitive.material = material;
			primitives.push(primitive);
		}
		if (didForceIndices) {
			geometry.setIndex(null);
		}
		meshDef.primitives = primitives;
		if (json.meshes == null) json.meshes = [];
		this._invokeAll(function(ext : Dynamic) : Void {
			if (ext.writeMesh != null) ext.writeMesh(mesh, meshDef);
		});
		var index : Int = json.meshes.push(meshDef) - 1;
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
	private function detectMeshQuantization(attributeName : String, attribute : BufferAttribute) : Void {
		if (this.extensionsUsed.get(KHR_MESH_QUANTIZATION)) return;
		var attrType : String = null;
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
		var attrNamePrefix : String = attributeName.split("_", 1)[0];
		if (KHR_mesh_quantization_ExtraAttrTypes_map.get(KHR_mesh_quantization_ExtraAttrTypes.valueOf(attrNamePrefix)) != null && KHR_mesh_quantization_ExtraAttrTypes_map.get(KHR_mesh_quantization_ExtraAttrTypes.valueOf(attrNamePrefix)).indexOf(attrType) != -1) {
			this.extensionsUsed.set(KHR_MESH_QUANTIZATION, true);
			this.extensionsRequired.set(KHR_MESH_QUANTIZATION, true);
		}
	}

	/**
	 * Process camera
	 * @param  {THREE.Camera} camera Camera to process
	 * @return {Integer}      Index of the processed mesh in the "camera" array
	 */
	private function processCamera(camera : Scene) : Int {
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		if (json.cameras == null) json.cameras = [];
		var isOrtho : Bool = camera.isOrthographicCamera;
		var cameraDef : {
			type : String,
			orthographic : {
				xmag : Float,
				ymag : Float,
				zfar : Float,
				znear : Float
			},
			perspective : {
				aspectRatio : Float,
				yfov : Float,
				zfar : Float,
				znear : Float
			},
			name : String
		} = {
			type : isOrtho ? "orthographic" : "perspective",
		};
		if (isOrtho) {
			cameraDef.orthographic = {
				xmag : camera.right * 2,
				ymag : camera.top * 2,
				zfar : camera.far <= 0 ? 0.001 : camera.far,
				znear : camera.near < 0 ? 0 : camera.near,
			};
		} else {
			cameraDef.perspective = {
				aspectRatio : camera.aspect,
				yfov : MathUtils.degToRad(camera.fov),
				zfar : camera.far <= 0 ? 0.001 : camera.far,
				znear : camera.near < 0 ? 0 : camera.near,
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
	private function processAnimation(clip : Dynamic, root : Scene) : Int {
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		var nodeMap : Map<Scene, Int> = this.nodeMap;
		if (json.animations == null) json.animations = [];
		clip = GLTFExporter.Utils.mergeMorphTargetTracks(clip.clone(), root);
		var tracks : Array<Dynamic> = clip.tracks;
		var channels : Array<{
			sampler : Int,
			target : {
				node : Int,
				path : String
			}
		}> = [];
		var samplers : Array<{
			input : Int,
			output : Int,
			interpolation : String
		}> = [];
		for (i in 0...tracks.length) {
			var track : Dynamic = tracks[i];
			var trackBinding : Dynamic = PropertyBinding.parseTrackName(track.name);
			var trackNode : Scene = PropertyBinding.findNode(root, trackBinding.nodeName);
			var trackProperty : String = PATH_PROPERTIES.get(trackBinding.propertyName);
			if (trackBinding.objectName == "bones") {
				if (trackNode.isSkinnedMesh) {
					trackNode = trackNode.skeleton.getBoneByName(trackBinding.objectIndex);
				} else {
					trackNode = null;
				}
			}
			if (trackNode == null || trackProperty == null) {
				console.warn("THREE.GLTFExporter: Could not export animation track \"%s\".", track.name);
				return null;
			}
			var inputItemSize : Int = 1;
			var outputItemSize : Float = track.values.length / track.times.length;
			if (trackProperty == PATH_PROPERTIES.get("morphTargetInfluences")) {
				outputItemSize /= trackNode.morphTargetInfluences.length;
			}
			var interpolation : String;
			// @TODO export CubicInterpolant(InterpolateSmooth) as CUBICSPLINE
			// Detecting glTF cubic spline interpolant by checking factory method's special property
			// GLTFCubicSplineInterpolant is a custom interpolant and track doesn't return
			// valid value from .getInterpolation().
			if (track.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline) {
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
				input : this.processAccessor(new BufferAttribute(track.times, inputItemSize)),
				output : this.processAccessor(new BufferAttribute(track.values, outputItemSize)),
				interpolation : interpolation,
			});
			channels.push({
				sampler : samplers.length - 1,
				target : {
					node : nodeMap.get(trackNode),
					path : trackProperty,
				},
			});
		}
		json.animations.push({
			name : clip.name != null ? clip.name : "clip_" + json.animations.length,
			samplers : samplers,
			channels : channels,
		});
		return json.animations.length - 1;
	}

	/**
	 * @param {THREE.Object3D} object
	 * @return {number|null}
	 */
	private function processSkin(object : Scene) : Int {
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		var nodeMap : Map<Scene, Int> = this.nodeMap;
		var node : {
			extensions : {
				[String] : Dynamic
			},
			extras : {
				[String] : Dynamic
			}
		} = json.nodes[nodeMap.get(object)];
		var skeleton : Dynamic = object.skeleton;
		if (skeleton == null) return null;
		var rootJoint : Scene = object.skeleton.bones[0];
		if (rootJoint == null) return null;
		var joints : Array<Int> = [];
		var inverseBindMatrices : Float32Array = new Float32Array(skeleton.bones.length * 16);
		var temporaryBoneInverse : Matrix4 = new Matrix4();
		for (i in 0...skeleton.bones.length) {
			joints.push(nodeMap.get(skeleton.bones[i]));
			temporaryBoneInverse.copy(skeleton.boneInverses[i]);
			temporaryBoneInverse.multiply(object.bindMatrix).toArray(inverseBindMatrices, i * 16);
		}
		if (json.skins == null) json.skins = [];
		json.skins.push({
			inverseBindMatrices : this.processAccessor(new BufferAttribute(inverseBindMatrices, 16)),
			joints : joints,
			skeleton : nodeMap.get(rootJoint),
		});
		var skinIndex : Int = node.skin = json.skins.length - 1;
		return skinIndex;
	}

	/**
	 * Process Object3D node
	 * @param  {THREE.Object3D} node Object3D to processNode
	 * @return {Integer} Index of the node in the nodes list
	 */
	private function processNode(object : Scene) : Int {
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		var options : {
			binary : Bool,
			trs : Bool,
			onlyVisible : Bool,
			maxTextureSize : Int,
			animations : Array<Dynamic>,
			includeCustomExtensions : Bool
		} = this.options;
		var nodeMap : Map<Scene, Int> = this.nodeMap;
		if (json.nodes == null) json.nodes = [];
		var nodeDef : {
			extensions : {
				[String] : Dynamic
			},
			extras : {
				[String] : Dynamic
			},
			rotation : Array<Float>,
			translation : Array<Float>,
			scale : Array<Float>,
			matrix : Array<Float>,
			mesh : Int,
			camera : Int,
			children : Array<Int>,
			skin : Int
		} = {};
		if (options.trs) {
			var rotation : Array<Float> = object.quaternion.toArray();
			var position : Array<Float> = object.position.toArray();
			var scale : Array<Float> = object.scale.toArray();
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
			if (!isIdentityMatrix(object.matrix)) {
				nodeDef.matrix = object.matrix.elements;
			}
		}
		// We don't export empty strings name because it represents no-name in Three.js.
		if (object.name != "") nodeDef.name = String(object.name);
		this.serializeUserData(object, nodeDef);
		if (object.isMesh || object.isLine || object.isPoints) {
			var meshIndex : Int = this.processMesh(object);
			if (meshIndex != null) nodeDef.mesh = meshIndex;
		} else if (object.isCamera) {
			nodeDef.camera = this.processCamera(object);
		}
		if (object.isSkinnedMesh) this.skins.push(object);
		if (object.children.length > 0) {
			var children : Array<Int> = [];
			for (i in 0...object.children.length) {
				var child : Scene = object.children[i];
				if (child.visible || options.onlyVisible == false) {
					var nodeIndex : Int = this.processNode(child);
					if (nodeIndex != null) children.push(nodeIndex);
				}
			}
			if (children.length > 0) nodeDef.children = children;
		}
		this._invokeAll(function(ext : Dynamic) : Void {
			if (ext.writeNode != null) ext.writeNode(object, nodeDef);
		});
		var nodeIndex : Int = json.nodes.push(nodeDef) - 1;
		nodeMap.set(object, nodeIndex);
		return nodeIndex;
	}

	/**
	 * Process Scene
	 * @param  {Scene} node Scene to process
	 */
	private function processScene(scene : Scene) : Void {
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = this.json;
		var options : {
			binary : Bool,
			trs : Bool,
			onlyVisible : Bool,
			maxTextureSize : Int,
			animations : Array<Dynamic>,
			includeCustomExtensions : Bool
		} = this.options;
		if (json.scenes == null) {
			json.scenes = [];
			json.scene = 0;
		}
		var sceneDef : {
			nodes : Array<Int>,
			name : String
		} = {};
		if (scene.name != "") sceneDef.name = scene.name;
		json.scenes.push(sceneDef);
		var nodes : Array<Int> = [];
		for (i in 0...scene.children.length) {
			var child : Scene = scene.children[i];
			if (child.visible || options.onlyVisible == false) {
				var nodeIndex : Int = this.processNode(child);
				if (nodeIndex != null) nodes.push(nodeIndex);
			}
		}
		if (nodes.length > 0) sceneDef.nodes = nodes;
		this.serializeUserData(scene, sceneDef);
	}

	/**
	 * Creates a Scene to hold a list of objects and parse it
	 * @param  {Array} objects List of objects to process
	 */
	private function processObjects(objects : Array<Scene>) : Void {
		var scene : Scene = new Scene();
		scene.name = "AuxScene";
		for (i in 0...objects.length) {
			// We push directly to children instead of calling `add` to prevent
			// modify the .parent and break its original scene and hierarchy
			scene.children.push(objects[i]);
		}
		this.processScene(scene);
	}

	/**
	 * @param {THREE.Object3D|Array<THREE.Object3D>} input
	 */
	private function processInput(input : Scene | Array<Scene>) : Void {
		var options : {
			binary : Bool,
			trs : Bool,
			onlyVisible : Bool,
			maxTextureSize : Int,
			animations : Array<Dynamic>,
			includeCustomExtensions : Bool
		} = this.options;
		input = Std.isOfType(input, Array) ? input : [input];
		this._invokeAll(function(ext : Dynamic) : Void {
			if (ext.beforeParse != null) ext.beforeParse(input);
		});
		var objectsWithoutScene : Array<Scene> = [];
		for (i in 0...input.length) {
			if (Std.isOfType(input[i], Scene)) {
				this.processScene(input[i]);
			} else {
				objectsWithoutScene.push(input[i]);
			}
		}
		if (objectsWithoutScene.length > 0) this.processObjects(objectsWithoutScene);
		for (i in 0...this.skins.length) {
			this.processSkin(this.skins[i]);
		}
		for (i in 0...options.animations.length) {
			this.processAnimation(options.animations[i], input[0]);
		}
		this._invokeAll(function(ext : Dynamic) : Void {
			if (ext.afterParse != null) ext.afterParse(input);
		});
	}

	private function _invokeAll(func : Function) : Void {
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

	private var writer : GLTFWriter;
	private var name : String;

	public function new(writer : GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_lights_punctual";
	}

	public function writeNode(light : Scene, nodeDef : {
		extensions : {
			[String] : Dynamic
		},
		extras : {
			[String] : Dynamic
		},
		rotation : Array<Float>,
		translation : Array<Float>,
		scale : Array<Float>,
		matrix : Array<Float>,
		mesh : Int,
		camera : Int,
		children : Array<Int>,
		skin : Int
	}) : Void {
		if (!light.isLight) return;
		if (!light.isDirectionalLight && !light.isPointLight && !light.isSpotLight) {
			console.warn("THREE.GLTFExporter: Only directional, point, and spot lights are supported.", light);
			return;
		}
		var writer : GLTFWriter = this.writer;
		var json : {
			asset : {
				version : String,
				generator : String
			},
			extensionsUsed : Array<String>,
			extensionsRequired : Array<String>,
			buffers : Array<{
				byteLength : Int,
				uri : String
			}>,
			bufferViews : Array<{
				buffer : Int,
				byteOffset : Int,
				byteLength : Int,
				byteStride : Int,
				target : BufferViewTargets
			}>,
			accessors : Array<{
				bufferView : Int,
				byteOffset : Int,
				componentType : ComponentTypes,
				count : Int,
				max : Array<Float>,
				min : Array<Float>,
				type : AccessorTypes,
				normalized : Bool
			}>,
			images : Array<{
				mimeType : String,
				bufferView : Int,
				uri : String
			}>,
			samplers : Array<{
				magFilter : Int,
				minFilter : Int,
				wrapS : Int,
				wrapT : Int
			}>,
			textures : Array<{
				sampler : Int,
				source : Int,
				name : String
			}>,
			materials : Array<{
				pbrMetallicRoughness : {
					baseColorFactor : Array<Float>,
					metallicFactor : Float,
					roughnessFactor : Float,
					metallicRoughnessTexture : {
						index : Int,
						texCoord : Int
					},
					baseColorTexture : {
						index : Int,
						texCoord : Int
					}
				},
				emissiveFactor : Array<Float>,
				emissiveTexture : {
					index : Int,
					texCoord : Int
				},
				normalTexture : {
					index : Int,
					texCoord : Int,
					scale : Float
				},
				occlusionTexture : {
					index : Int,
					texCoord : Int,
					strength : Float
				},
				alphaMode : String,
				alphaCutoff : Float,
				doubleSided : Bool,
				name : String,
				extensions : {
					[String] : Dynamic
				},
				extras : {
					[String] : Dynamic
				}
			}>,
			meshes : Array<{
				primitives : Array<{
					mode : Int,
					attributes : {
						[String] : Int
					},
					indices : Int,
					material : Int,
					targets : Array<{
						POSITION : Int,
						NORMAL : Int
					}>,
					extensions : {
						[String] : Dynamic
					},
					extras : {
						[String] : Dynamic
					}
				}>,
				weights : Array<Float>,
				extras : {
					targetNames : Array<String>
				}
			}>,
			cameras : Array<{
				type : String,
				orthographic : {
					xmag : Float,
					ymag : Float,
					zfar : Float,
					znear : Float
				},
				perspective : {
					aspectRatio : Float,
					yfov : Float,
					zfar : Float,
					znear : Float
				},
				name : String
			}>,
			scenes : Array<{
				nodes : Array<Int>,
				name : String
			}>,
			scene : Int,
			animations : Array<{
				name : String,
				samplers : Array<{
					input : Int,
					output : Int,
					interpolation : String
				}>,
				channels : Array<{
					sampler : Int,
					target : {
						node : Int,
						path : String
					}
				}>
			}>,
			skins : Array<{
				inverseBindMatrices : Int,
				joints : Array<Int>,
				skeleton : Int
			}>,
			extensions : {
				[String] : Dynamic
			}
		} = writer.json;
		var extensionsUsed : StringMap = writer.extensionsUsed;
		var lightDef : {
			type : String,
			color : Array<Float>,
			intensity : Float,
			range : Float,
			spot : {
				innerConeAngle : Float,
				outerConeAngle : Float
			},
			name : String
		} = {};
		if (light.name != null) lightDef.name = light.name;
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
			console.warn("THREE.GLTFExporter: Light decay may be lost. glTF is physically-based, " +
				"and expects light.decay=2.");
		}
		if (light.target != null &&
			(light.target.parent != light ||
			 light.target.position.x != 0 ||
			 light.target.position.y != 0 ||
			 light.target.position.z != -1)) {
			console.warn("THREE.GLTFExporter: Light direction may be lost. For best results, " +
				"make light.target a child of the light with position 0,0,-1.");
		}
		if (!extensionsUsed.get(this.name)) {
			json.extensions = json.extensions != null ? json.extensions : {};
			json.extensions[this.name] = { lights : [] };
			extensionsUsed.set(this.name, true);
		}
		var lights : Array<Dynamic> = json.extensions[this.name].lights;
		lights.push(lightDef);
		nodeDef.extensions = nodeDef.extensions != null ? nodeDef.extensions : {};
		nodeDef.extensions[this.name] = { light : lights.length - 1 };
	}

}

/**
 * Unlit Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_unlit
 */
class GLTFMaterialsUnlitExtension {

	private var writer : GLTFWriter;
	private var name : String;

	public function new(writer : GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_unlit";
	}

	public function writeMaterial(material : Texture, materialDef : {
		pbrMetallicRoughness : {
			baseColorFactor : Array<Float>,
			metallicFactor : Float,
			roughnessFactor : Float,
			metallicRoughnessTexture : {
				index : Int,
				texCoord : Int
			},
			baseColorTexture : {
				index : Int,
				texCoord : Int
			}
		},
		emissiveFactor : Array<Float>,
		emissiveTexture : {
			index : Int,
			texCoord : Int
		},
		normalTexture : {
			index : Int,
			texCoord : Int,
			scale : Float
		},
		occlusionTexture : {
			index : Int,
			texCoord : Int,
			strength : Float
		},
		alphaMode : String,
		alphaCutoff : Float,
		doubleSided : Bool,
		name : String,
		extensions : {
			[String] : Dynamic
		},
		extras : {
			[String] : Dynamic
		}
	}) : Void {
		if (!material.isMeshBasicMaterial) return;
		var writer : GLTFWriter = this.writer;
		var extensionsUsed : StringMap = writer.extensionsUsed;
		materialDef.extensions = materialDef.extensions != null ? materialDef.extensions : {};
		materialDef.extensions[this.name] = {};
		extensionsUsed.set(this.name, true);
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

	private var writer : GLTFWriter;
	private var name : String;

	public function new(writer : GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_clearcoat";
	}

	public function writeMaterial(material : Texture, materialDef : {
		pbrMetallicRoughness : {
			baseColorFactor : Array<Float>,
			metallicFactor : Float,
			roughnessFactor : Float,
			metallicRoughnessTexture : {
				index : Int,
				texCoord : Int
			},
			baseColorTexture : {
				index : Int,
				texCoord : Int
			}
		},
		emissiveFactor : Array<Float>,
		emissiveTexture : {
			index : Int,
			texCoord : Int
		},
		normalTexture : {
			index : Int,
			texCoord : Int,
			scale : Float
		},
		occlusionTexture : {
			index : Int,
			texCoord : Int,
			strength : Float
		},
		alphaMode : String,
		alphaCutoff : Float,
		doubleSided : Bool,
		name : String,
		extensions : {
			[String] : Dynamic
		},
		extras : {
			[String] : Dynamic
		}
	}) : Void {
		if (!material.isMeshPhysicalMaterial || material.clearcoat == 0) return;
		var writer : GLTFWriter = this.writer;
		var extensionsUsed : StringMap = writer.extensionsUsed;
		var extensionDef : {
			clearcoatFactor : Float,
			clearcoatTexture : {
				index : Int,
				texCoord : Int
			},
			clearcoatRoughnessFactor : Float,
			clearcoatRoughnessTexture : {
				index : Int,
				texCoord : Int
			},
			clearcoatNormalTexture : {
				index : Int,
				texCoord : Int,
				scale : Float
			}
		} = {};
		extensionDef.clearcoatFactor = material.clearcoat;
		if (material.clearcoatMap != null) {
			var clearcoatMapDef : {
				index : Int,
				texCoord : Int
			} = {
				index : writer.processTexture(material.clearcoatMap),
				texCoord : material.clearcoatMap.channel,
			};
			writer.applyTextureTransform(clearcoatMapDef, material.clearcoatMap);
			extensionDef.clearcoatTexture = clearcoatMapDef;
		}
		extensionDef.clearcoatRoughnessFactor = material.clearcoatRoughness;
		if (material.clearcoatRoughnessMap != null) {
			var clearcoatRoughnessMapDef : {
				index : Int,
				texCoord : Int
			} = {
				index : writer.processTexture(material.clearcoatRoughnessMap),
				texCoord : material.clearcoatRoughnessMap.channel,
			};
			writer.applyTextureTransform(clearcoatRoughnessMapDef, material.clearcoatRoughnessMap);
			extensionDef.clearcoatRoughnessTexture = clearcoatRoughnessMapDef;
		}
		if (material.clearcoatNormalMap != null) {
			var clearcoatNormalMapDef : {
				index : Int,
				texCoord : Int,
				scale : Float
			} = {
				index : writer.processTexture(material.clearcoatNormalMap),
				texCoord : material.clearcoatNormalMap.channel,
			};
			if (material.clearcoatNormalScale.x != 1) clearcoatNormalMapDef.scale = material.clearcoatNormalScale.x;
			writer.applyTextureTransform(clearcoatNormalMapDef, material.clearcoatNormalMap);
			extensionDef.clearcoatNormalTexture = clearcoatNormalMapDef;
		}
		materialDef.extensions = materialDef.extensions != null ? materialDef.extensions : {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed.set(this.name, true);
	}

}

/**
 * Materials dispersion Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_dispersion
 */
class GLTFMaterialsDispersionExtension {

	private var writer : GLTFWriter;
	private var name : String;

	public function new(writer : GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_dispersion";
	}

	public function writeMaterial(material : Texture, materialDef : {
		pbrMetallicRoughness : {
			baseColorFactor : Array<Float>,
			metallicFactor : Float,
			roughnessFactor : Float,
			metallicRoughnessTexture : {
				index : Int,
				texCoord : Int
			},
			baseColorTexture : {
				index : Int,
				texCoord : Int
			}
		},
		emissiveFactor : Array<Float>,
		emissiveTexture : {
			index : Int,
			texCoord : Int
		},
		normalTexture : {
			index : Int,
			texCoord : Int,
			scale : Float
		},
		occlusionTexture : {
			index : Int,
			texCoord : Int,
			strength : Float
		},
		alphaMode : String,
		alphaCutoff : Float,
		doubleSided : Bool,
		name : String,
		extensions : {
			[String] : Dynamic
		},
		extras : {
			[String] : Dynamic
		}
	}) : Void {
		if (!material.isMeshPhysicalMaterial || material.dispersion == 0) return;
		var writer : GLTFWriter = this.writer;
		var extensionsUsed : StringMap = writer.extensionsUsed;
		var extensionDef : {
			dispersion : Float
		} = {};
		extensionDef.dispersion = material.dispersion;
		materialDef.extensions = materialDef.extensions != null ? materialDef.extensions : {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed.set(this.name, true);
	}

}

/**
 * Iridescence Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_iridescence
 */
class GLTFMaterialsIridescenceExtension {

	private var writer : GLTFWriter;
	private var name : String;

	public function new(writer : GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_iridescence";
	}

	public function writeMaterial(material : Texture, materialDef : {
		pbrMetallicRoughness : {
			baseColorFactor : Array<Float>,
			metallicFactor : Float,
			roughnessFactor : Float,
			metallicRoughnessTexture : {
				index : Int,
				texCoord : Int
			},
			baseColorTexture : {
				index : Int,
				texCoord : Int
			}
		},
		emissiveFactor : Array<Float>,
		emissiveTexture : {
			index : Int,
			texCoord : Int
		},
		normalTexture : {
			index : Int,
			texCoord : Int,
			scale : Float
		},
		occlusionTexture : {
			index : Int,
			texCoord : Int,
			strength : Float
		},
		alphaMode : String,
		alphaCutoff : Float,
		doubleSided : Bool,
		name : String,
		extensions : {
			[String] : Dynamic
		},
		extras : {
			[String] : Dynamic
		}
	}) : Void {
		if (!material.isMeshPhysicalMaterial || material.iridescence == 0) return;
		var writer : GLTFWriter = this.writer;
		var extensionsUsed : StringMap = writer.extensionsUsed;
		var extensionDef : {
			iridescenceFactor : Float,
			iridescenceTexture : {
				index : Int,
				texCoord : Int
			},
			iridescenceIor : Float,
			iridescenceThicknessMinimum : Float,
			iridescenceThicknessMaximum : Float,
			iridescenceThicknessTexture : {
				index : Int,
				texCoord : Int
			}
		} = {};
		extensionDef.iridescenceFactor = material.iridescence;
		if (material.iridescenceMap != null) {
			var iridescenceMapDef : {
				index : Int,
				texCoord : Int
			} = {
				index : writer.processTexture(material.iridescenceMap),
				texCoord : material.iridescenceMap.channel,
			};
			writer.applyTextureTransform(iridescenceMapDef, material.iridescenceMap);
			extensionDef.iridescenceTexture = iridescenceMapDef;
		}
		extensionDef.iridescenceIor = material.iridescenceIOR;
		extensionDef.iridescenceThicknessMinimum = material.iridescenceThicknessRange[0];
		extensionDef.iridescenceThicknessMaximum = material.iridescenceThicknessRange[1];
		if (material.iridescenceThicknessMap != null) {
			var iridescenceThicknessMapDef : {
				index : Int,
				texCoord : Int
			} = {
				index : writer.processTexture(material.iridescenceThicknessMap),
				texCoord : material.iridescenceThicknessMap.channel,
			};
			writer.applyTextureTransform(iridescenceThicknessMapDef, material.iridescenceThicknessMap);
			extensionDef.iridescenceThicknessTexture = iridescenceThicknessMapDef;
		}
		materialDef.extensions = materialDef.extensions != null ? materialDef.extensions : {};
		materialDef.extensions[this.name] = extensionDef;
		extensionsUsed.set(this.name, true);
	}

}

/**
 * Transmission Materials Extension
 *
 * Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_transmission
 */
class GLTFMaterialsTransmissionExtension {

	private var writer : GLTFWriter;
	private var name : String;

	public function new(writer : GLTFWriter) {
		this.writer = writer;
		this.name = "KHR_materials_transmission";
	}

	public function writeMaterial(material : Texture, materialDef : {
		pbrMetallicRoughness : {
			baseColorFactor : Array<Float>,
			metallicFactor : Float,
			roughnessFactor : Float,
			metallicRoughnessTexture : {
				index : Int,
				texCoord : Int
			},
			baseColorTexture : {
				index : Int,
				texCoord : Int
			}
		},
		emissiveFactor : Array<Float>,
		emissiveTexture : {
			index : Int,
			texCoord : Int
		},
		normalTexture : {
			index : Int,
			texCoord : Int,
			scale : Float
		},
		occlusionTexture : {
			index : Int,
			texCoord : Int,
			strength : Float
		},
		alphaMode : String,
		alphaCutoff : Float,
		doubleSided : Bool,
		name : String,
		extensions : {
			[String] : Dynamic
		},
		extras : {
			[String] : Dynamic
		}
	}) : Void {
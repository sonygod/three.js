import haxe.io.Bytes;
import haxe.io.Output;
import haxe.io.BytesInput;
import haxe.io.Eof;
import haxe.io.StringInput;
import haxe.io.BytesOutput;
import haxe.io.Input;
import haxe.io.FileOutput;
import haxe.io.Path;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.Vector;
import haxe.ds.ArraySort;
import haxe.ds.GenericArray;
import haxe.ds.List;

class GLTFWriter {
	public var plugins:Array<Dynamic>;
	public var options:Dynamic;
	public var pending:Array<Dynamic>;
	public var buffers:Array<Bytes>;
	public var byteOffset:Int;
	public var nodeMap:Map<Dynamic, Int>;
	public var skins:Array<Dynamic>;
	public var extensionsUsed:StringMap<Bool>;
	public var extensionsRequired:StringMap<Bool>;
	public var uids:Map<Dynamic, Map<Bool, Int>>;
	public var uid:Int;
	public var json:Dynamic;
	public var cache:Dynamic;

	public function new() {
		this.plugins = new Array();
		this.options = {};
		this.pending = new Array();
		this.buffers = new Array();
		this.byteOffset = 0;
		this.buffers = new Array();
		this.nodeMap = new Map();
		this.skins = new Array();
		this.extensionsUsed = new StringMap();
		this.extensionsRequired = new StringMap();
		this.uids = new Map();
		this.uid = 0;
		this.json = {
			asset: {
				version: "2.0",
				generator: "THREE.GLTFExporter r" + REVISION
			}
		};
		this.cache = {
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

	public function write(input:Dynamic, onDone:Dynamic, options:Dynamic = {}):Void {
		this.options = Object.assign( {
			binary: false,
			trs: false,
			onlyVisible: true,
			maxTextureSize: Infinity,
			animations: new Array(),
			includeCustomExtensions: false
		}, options);
		if (this.options.animations.length > 0) {
			this.options.trs = true;
		}
		this.processInput(input);
		Promise.all(this.pending).then(function() {
			var writer = this;
			var buffers = writer.buffers;
			var json = writer.json;
			options = writer.options;
			var extensionsUsed = writer.extensionsUsed;
			var extensionsRequired = writer.extensionsRequired;
			var blob = new Blob(buffers, { type: "application/octet-stream" });
			var extensionsUsedList = Object.keys(extensionsUsed);
			var extensionsRequiredList = Object.keys(extensionsRequired);
			if (extensionsUsedList.length > 0) json.extensionsUsed = extensionsUsedList;
			if (extensionsRequiredList.length > 0) json.extensionsRequired = extensionsRequiredList;
			if (json.buffers && json.buffers.length > 0) json.buffers[0].byteLength = blob.size;
			if (options.binary == true) {
				var reader = new FileReader();
				reader.readAsArrayBuffer(blob);
				reader.onloadend = function() {
					var binaryChunk = getPaddedArrayBuffer(reader.result);
					var binaryChunkPrefix = new DataView(new ArrayBuffer(GLB_CHUNK_PREFIX_BYTES));
					binaryChunkPrefix.setUint32(0, binaryChunk.byteLength, true);
					binaryChunkPrefix.setUint32(4, GLB_CHUNK_TYPE_BIN, true);
					var jsonChunk = getPaddedArrayBuffer(stringToArrayBuffer(JSON.stringify(json)), 0x20);
					var jsonChunkPrefix = new DataView(new ArrayBuffer(GLB_CHUNK_PREFIX_BYTES));
					jsonChunkPrefix.setUint32(0, jsonChunk.byteLength, true);
					jsonChunkPrefix.setUint32(4, GLB_CHUNK_TYPE_JSON, true);
					var header = new ArrayBuffer(GLB_HEADER_BYTES);
					var headerView = new DataView(header);
					headerView.setUint32(0, GLB_HEADER_MAGIC, true);
					headerView.setUint32(4, GLB_VERSION, true);
					var totalByteLength = GLB_HEADER_BYTES + jsonChunkPrefix.byteLength + jsonChunk.byteLength + binaryChunkPrefix.byteLength + binaryChunk.byteLength;
					headerView.setUint32(8, totalByteLength, true);
					var glbBlob = new Blob([header, jsonChunkPrefix, jsonChunk, binaryChunkPrefix, binaryChunk], { type: "application/octet-stream" });
					var glbReader = new FileReader();
					glbReader.readAsArrayBuffer(glbBlob);
					glbReader.onloadend = function() {
						onDone(glbReader.result);
					};
				};
			} else {
				if (json.buffers && json.buffers.length > 0) {
					var reader = new FileReader();
					reader.readAsDataURL(blob);
					reader.onloadend = function() {
						var base64data = reader.result;
						json.buffers[0].uri = base64data;
						onDone(json);
					};
				} else {
					onDone(json);
				}
			}
		}, this);
	}

	public function serializeUserData(object:Dynamic, objectDef:Dynamic):Void {
		if (Object.keys(object.userData).length == 0) return;
		var options = this.options;
		var extensionsUsed = this.extensionsUsed;
		try {
			var json = JSON.parse(JSON.stringify(object.userData));
			if (options.includeCustomExtensions && json.gltfExtensions) {
				if (objectDef.extensions == undefined) objectDef.extensions = {};
				for (var extensionName in json.gltfExtensions) {
					objectDef.extensions[extensionName] = json.gltfExtensions[extensionName];
					extensionsUsed[extensionName] = true;
				}
				delete json.gltfExtensions;
			}
			if (Object.keys(json).length > 0) objectDef.extras = json;
		} catch (error) {
			console.warn("THREE.GLTFExporter: userData of '" + object.name + "' " + "won't be serialized because of JSON.stringify error - " + error.message);
		}
	}

	public function getUID(attribute:Dynamic, isRelativeCopy:Bool = false):Int {
		if (this.uids.has(attribute) == false) {
			var uids = new Map();
			uids.set(true, this.uid++);
			uids.set(false, this.uid++);
			this.uids.set(attribute, uids);
		}
		var uids = this.uids.get(attribute);
		return uids.get(isRelativeCopy);
	}

	public function isNormalizedNormalAttribute(normal:Dynamic):Bool {
		var cache = this.cache;
		if (cache.attributesNormalized.has(normal)) return false;
		var v = new Vector3();
		for (var i = 0, il = normal.count; i < il; i++) {
			if (Math.abs(v.fromBufferAttribute(normal, i).length() - 1.0) > 0.0005) return false;
		}
		return true;
	}

	public function createNormalizedNormalAttribute(normal:Dynamic):Dynamic {
		var cache = this.cache;
		if (cache.attributesNormalized.has(normal)) return cache.attributesNormalized.get(normal);
		var attribute = normal.clone();
		var v = new Vector3();
		for (var i = 0, il = attribute.count; i < il; i++) {
			v.fromBufferAttribute(attribute, i);
			if (v.x == 0 && v.y == 0 && v.z == 0) {
				v.setX(1.0);
			} else {
				v.normalize();
			}
			attribute.setXYZ(i, v.x, v.y, v.z);
		}
		cache.attributesNormalized.set(normal, attribute);
		return attribute;
	}

	public function applyTextureTransform(mapDef:Dynamic, texture:Dynamic):Void {
		var didTransform = false;
		var transformDef = {};
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
			mapDef.extensions["KHR_texture_transform"] = transformDef;
			this.extensionsUsed["KHR_texture_transform"] = true;
		}
	}

	public function buildMetalRoughTexture(metalnessMap:Dynamic, roughnessMap:Dynamic):Dynamic {
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
		if (metalnessMap instanceof CompressedTexture) {
			metalnessMap = decompress(metalnessMap);
		}
		if (roughnessMap instanceof CompressedTexture) {
			roughnessMap = decompress(roughnessMap);
		}
		var metalness = metalnessMap ? metalnessMap.image : null;
		var roughness = roughnessMap ? roughnessMap.image : null;
		var width = Math.max(metalness ? metalness.width : 0, roughness ? roughness.width : 0);
		var height = Math.max(metalness ? metalness.height : 0, roughness ? roughness.height : 0);
		var canvas = getCanvas();
		canvas.width = width;
		canvas.height = height;
		var context = canvas.getContext('2d');
		context.fillStyle = "#00ffff";
		context.fillRect(0, 0, width, height);
		var composite = context.getImageData(0, 0, width, height);
		if (metalness) {
			context.drawImage(metalness, 0, 0, width, height);
			var convert = getEncodingConversion(metalnessMap);
			var data = context.getImageData(0, 0, width, height).data;
			for (var i = 2; i < data.length; i += 4) {
				composite.data[i] = convert(data[i] / 256) * 256;
			}
		}
		if (roughness) {
			context.drawImage(roughness, 0, 0, width, height);
			var convert = getEncodingConversion(roughnessMap);
			var data = context.getImageData(0, 0, width, height).data;
			for (var i = 1; i < data.length; i += 4) {
				composite.data[i] = convert(data[i] / 256) * 256;
			}
		}
		context.putImageData(composite, 0, 0);
		var reference = metalnessMap || roughnessMap;
		var texture = reference.clone();
		texture.source = new Source(canvas);
		texture.colorSpace = NoColorSpace;
		texture.channel = (metalnessMap || roughnessMap).channel;
		if (metalnessMap && roughnessMap && metalnessMap.channel != roughnessMap.channel) {
			console.warn("THREE.GLTFExporter: UV channels for metalnessMap and roughnessMap textures must match.");
		}
		return texture;
	}

	public function processBuffer(buffer:Bytes):Int {
		var json = this.json;
		var buffers = this.buffers;
		if (!json.buffers) json.buffers = [{ byteLength: 0 }];
		buffers.push(buffer);
		return 0;
	}

	public function processBufferView(attribute:Dynamic, componentType:Int, start:Int, count:Int, target:Int):Dynamic {
		var json = this.json;
		if (!json.bufferViews) json.bufferViews = new Array();
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
			byteStride = Math.ceil(byteStride / 4) * 4;
		}
		var byteLength = getPaddedBufferSize(count * byteStride);
		var dataView = new DataView(new ArrayBuffer(byteLength));
		var offset = 0;
		for (var i = start; i < start + count; i++) {
			for (var a = 0; a < attribute.itemSize; a++) {
				var value:Float;
				if (attribute.itemSize > 4) {
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
		var bufferViewDef = {
			buffer: this.processBuffer(dataView.buffer),
			byteOffset: this.byteOffset,
			byteLength: byteLength
		};
		if (target != undefined) bufferViewDef.target = target;
		if (target == WEBGL_CONSTANTS.ARRAY_BUFFER) {
			bufferViewDef.byteStride = byteStride;
		}
		this.byteOffset += byteLength;
		json.bufferViews.push(bufferViewDef);
		var output = {
			id: json.bufferViews.length - 1,
			byteLength: 0
		};
		return output;
	}

	public function processBufferViewImage(blob:Blob):Dynamic {
		var writer = this;
		var json = writer.json;
		if (!json.bufferViews) json.bufferViews = new Array();
		return new Promise(function(resolve) {
			var reader = new FileReader();
			reader.readAsArrayBuffer(blob);
			reader.onloadend = function() {
				var buffer = getPaddedArrayBuffer(reader.result);
				var bufferViewDef = {
					buffer: writer.processBuffer(buffer),
					byteOffset: writer.byteOffset,
					byteLength: buffer.byteLength
				};
				writer.byteOffset += buffer.byteLength;
				resolve(json.bufferViews.push(bufferViewDef) - 1);
			};
		});
	}

	public function processAccessor(attribute:Dynamic, geometry:Dynamic, start:Int = 0, count:Int = 0):Int {
		var json = this.json;
		var types = {
			1: "SCALAR",
			2: "VEC2",
			3: "VEC3",
			4: "VEC4",
			9: "MAT3",
			16: "MAT4"
		};
		var componentType:Int;
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
		if (start == undefined) start = 0;
		if (count == undefined || count == Infinity) count = attribute.count;
		if (count == 0) return null;
		var minMax = getMinMax(attribute, start, count);
		var bufferViewTarget:Int;
		if (geometry != undefined) {
			bufferViewTarget = attribute == geometry.index ? WEBGL_CONSTANTS.ELEMENT_ARRAY_BUFFER : WEBGL_CONSTANTS.ARRAY_BUFFER;
		}
		var bufferView = this.processBufferView(attribute, componentType, start, count, bufferViewTarget);
		var accessorDef = {
			bufferView: bufferView.id,
			byteOffset: bufferView.byteOffset,
			componentType: componentType,
			count: count,
			max: minMax.max,
			min: minMax.min,
			type: types[attribute.itemSize]
		};
		if (attribute.normalized == true) accessorDef.normalized = true;
		if (!json.accessors) json.accessors = new Array();
		return json.accessors.push(accessorDef) - 1;
	}

	public function processImage(image:Dynamic, format:Int, flipY:Bool, mimeType:String = "image/png"):Int {
		if (image != null) {
			var writer = this;
			var cache = writer.cache;
			var json = writer.json;
			var options = writer.options;
			var pending = writer.pending;
			if (!cache.images.has(image)) cache.images.set(image, {});
			var cachedImages = cache.images.get(image);
			var key = mimeType + ":flipY/" + flipY.toString();
			if (cachedImages[key] != undefined) return cachedImages[key];
			if (!json.images) json.images = new Array();
			var imageDef = { mimeType: mimeType };
			var canvas = getCanvas();
			canvas.width = Math.min(image.width, options.maxTextureSize);
			canvas.height = Math.min(image.height, options.maxTextureSize);
			var ctx = canvas.getContext('2d');
			if (flipY == true) {
				ctx.translate(0, canvas.height);
				ctx.scale(1, -1);
			}
			if (image.data != undefined) {
				if (format != RGBAFormat) {
					console.error("GLTFExporter: Only RGBAFormat is supported.", format);
				}
				if (image.width > options.maxTextureSize || image.height > options.maxTextureSize) {
					console.warn("GLTFExporter: Image size is bigger than maxTextureSize", image);
				}
				var data = new Uint8ClampedArray(image.height * image.width * 4);
				for (var i = 0; i < data.length; i += 4) {
					data[i + 0] = image.data[i + 0];
					data[i + 1] = image.data[i + 1];
					data[i + 2] = image.data[i + 2];
					data[i + 3] = image.data[i + 3];
				}
				ctx.putImageData(new ImageData(data, image.width, image.height), 0, 0);
			} else {
				if ((typeof HTMLImageElement != 'undefined' && image instanceof HTMLImageElement) || (typeof HTMLCanvasElement != 'undefined' && image instanceof HTMLCanvasElement) || (typeof ImageBitmap != 'undefined' && image instanceof ImageBitmap) || (typeof OffscreenCanvas != 'undefined' && image instanceof OffscreenCanvas)) {
					ctx.drawImage(image, 0, 0, canvas.width, canvas.height);
				} else {
					throw new Error("THREE.GLTFExporter: Invalid image type. Use HTMLImageElement, HTMLCanvasElement, ImageBitmap or OffscreenCanvas.");
				}
			}
			if (options.binary == true) {
				pending.push(getToBlobPromise(canvas, mimeType).then(function(blob:Blob) {
					return writer.processBufferViewImage(blob);
				}).then(function(bufferViewIndex:Int) {
					imageDef.bufferView = bufferViewIndex;
				}));
			} else {
				if (canvas.toDataURL != undefined) {
					imageDef.uri = canvas.toDataURL(mimeType);
				} else {
					pending.push(getToBlobPromise(canvas, mimeType).then(function(blob:Blob) {
						return new FileReader().readAsDataURL(blob);
					}).then(function(dataURL:String) {
						imageDef.uri = dataURL;
					}));
				}
			}
			var index = json.images.push(imageDef) - 1;
			cachedImages[key] = index;
			return index;
		} else {
			throw new Error("THREE.GLTFExporter: No valid image data found. Unable to process texture.");
		}
	}

	public function processSampler(map:Dynamic):Int {
		var json = this.json;
		if (!json.samplers) json.samplers = new Array();
		var samplerDef = {
			magFilter: THREE_TO_WEBGL[map.magFilter],
			minFilter: THREE_TO_WEBGL[map.minFilter],
			wrapS: THREE_TO_WEBGL[map.wrapS],
			wrapT: THREE_TO_WEBGL[map.wrapT]
		};
		return json.samplers.push(samplerDef) - 1;
	}

	public function processTexture(map:Dynamic):Int {
		var writer = this;
		var options = writer.options;
		var cache = writer.cache;
		var json = writer.json;
		if (cache.textures.has(map)) return cache.textures.get(map);
		if (!json.textures) json.textures = new Array();
		if (map instanceof CompressedTexture) {
			map = decompress(map, options.maxTextureSize);
		}
		var mimeType = map.userData.mimeType;
		if (mimeType == "image/webp") mimeType = "image/png";
		var textureDef = {
			sampler: this.processSampler(map),
			source: this.processImage(map.image, map.format, map.flipY, mimeType)
		};
		if (map.name) textureDef.name = map.name;
		this._invokeAll(function(ext:Dynamic) {
			ext.writeTexture && ext.writeTexture(map, textureDef);
		});
		var index = json.textures.push(textureDef) - 1;
		cache.textures.set(map, index);
		return index;
	}

	public function processMaterial(material:Dynamic):Int {
		var cache = this.cache;
		var json = this.json;
		if (cache.materials.has(material)) return cache.materials.get(material);
		if (material.isShaderMaterial) {
			console.warn("GLTFExporter: THREE.ShaderMaterial not supported.");
			return null;
		}
		if (!json.materials) json.materials = new Array();
		var materialDef = {	pbrMetallicRoughness: {} };
		if (material.isMeshStandardMaterial != true && material.isMeshBasicMaterial != true) {
			console.warn("GLTFExporter: Use MeshStandardMaterial or MeshBasicMaterial for best results.");
		}
		var color = material.color.toArray().concat([material.opacity]);
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
		if (material.metalnessMap || material.roughnessMap) {
			var metalRoughTexture = this.buildMetalRoughTexture(material.metalnessMap, material.roughnessMap);
			var metalRoughMapDef = {
				index: this.processTexture(metalRoughTexture),
				channel: metalRoughTexture.channel
			};
			this.applyTextureTransform(metalRoughMapDef, metalRoughTexture);
			materialDef.pbrMetallicRoughness.metallicRoughnessTexture = metalRoughMapDef;
		}
		if (material.map) {
			var baseColorMapDef = {
				index: this.processTexture(material.map),
				texCoord: material.map.channel
			};
			this.applyTextureTransform(baseColorMapDef, material.map);
			materialDef.pbrMetallicRoughness.baseColorTexture = baseColorMapDef;
		}
		if (material.emissive) {
			var emissive = material.emissive;
			var maxEmissiveComponent = Math.max(emissive.r, emissive.g, emissive.b);
			if (maxEmissiveComponent > 0) {
				materialDef.emissiveFactor = material.emissive.toArray();
			}
			if (material.emissiveMap) {
				var emissiveMapDef = {
					index: this.processTexture(material.emissiveMap),
					texCoord: material.emissiveMap.channel
				};
				this.applyTextureTransform(emissiveMapDef, material.emissiveMap);
				materialDef.emissiveTexture = emissiveMapDef;
			}
		}
		if (material.normalMap) {
			var normalMapDef = {
				index: this.processTexture(material.normalMap),
				texCoord: material.normalMap.channel
			};
			if (material.normalScale && material.normalScale.x != 1) {
				normalMapDef.scale = material.normalScale.x;
			}
			this.applyTextureTransform(normalMapDef, material.normalMap);
			materialDef.normalTexture = normalMapDef;
		}
		if (material.aoMap) {
			var occlusionMapDef = {
				index: this.processTexture(material.aoMap),
				texCoord: material.aoMap.channel
			};
			if (material.aoMapIntensity != 1.0) {
				occlusionMapDef.strength = material.aoMapIntensity;
			}
			this.applyTextureTransform(occlusionMapDef, material.aoMap);
			materialDef.occlusionTexture = occlusionMapDef;
		}
		if (material.transparent) {
			materialDef.alphaMode = "BLEND";
		} else {
			if (material.alphaTest > 0.0) {
				materialDef.alphaMode = "MASK";
				materialDef.alphaCutoff = material.alphaTest;
			}
		}
		if (material.side == DoubleSide) materialDef.doubleSided = true;
		if (material.name != "") materialDef.name = material.name;
		this.serializeUserData(material, materialDef);
		this._invokeAll(function(ext:Dynamic) {
			ext.writeMaterial && ext.writeMaterial(material, materialDef);
		});
		var index = json.materials.push(materialDef) - 1;
		cache.materials.set(material, index);
		return index;
	}

	public function processMesh(mesh:Dynamic):Int {
		var cache = this.cache;
		var json = this.json;
		var meshCacheKeyParts = [mesh.geometry.uuid];
		if (Array.isArray(mesh.material)) {
			for (var i = 0, l = mesh.material.length; i < l; i++) {
				meshCacheKeyParts.push(mesh.material[i].uuid);
			}
		} else {
			meshCacheKeyParts.push(mesh.material.uuid);
		}
		var meshCacheKey = meshCacheKeyParts.join(":");
		if (cache.meshes.has(meshCacheKey)) return cache.meshes.get(mesh
		var meshCacheKeyParts = [mesh.geometry.uuid];
		if (Array.isArray(mesh.material)) {
			for (var i = 0, l = mesh.material.length; i < l; i++) {
				meshCacheKeyParts.push(mesh.material[i].uuid);
			}
		} else {
			meshCacheKeyParts.push(mesh.material.uuid);
		}
		var meshCacheKey = meshCacheKeyParts.join(":");
		if (cache.meshes.has(meshCacheKey)) return cache.meshes.get(meshCacheKey);
		var geometry = mesh.geometry;
		var mode:Int;
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
		var meshDef = {};
		var attributes = {};
		var primitives = new Array();
		var targets = new Array();
		var nameConversion = {
			uv: "TEXCOORD_0",
			uv1: "TEXCOORD_1",
			uv2: "TEXCOORD_2",
			uv3: "TEXCOORD_3",
			color: "COLOR_0",
			skinWeight: "WEIGHTS_0",
			skinIndex: "JOINTS_0"
		};
		var originalNormal = geometry.getAttribute("normal");
		if (originalNormal != undefined && !this.isNormalizedNormalAttribute(originalNormal)) {
			console.warn("THREE.GLTFExporter: Creating normalized normal attribute from the non-normalized one.");
			geometry.setAttribute("normal", this.createNormalizedNormalAttribute(originalNormal));
		}
		var modifiedAttribute = null;
		for (var attributeName in geometry.attributes) {
			if (attributeName.slice(0, 5) == "morph") continue;
			var attribute = geometry.attributes[attributeName];
			attributeName = nameConversion[attributeName] || attributeName.toUpperCase();
			var validVertexAttributes = /^(POSITION|NORMAL|TANGENT|TEXCOORD_\d+|COLOR_\d+|JOINTS_\d+|WEIGHTS_\d+)$/;
			if (!validVertexAttributes.test(attributeName)) attributeName = "_" + attributeName;
			if (cache.attributes.has(this.getUID(attribute))) {
				attributes[attributeName] = cache.attributes.get(this.getUID(attribute));
				continue;
			}
			modifiedAttribute = null;
			var array = attribute.array;
			if (attributeName == "JOINTS_0" && !(array instanceof Uint16Array) && !(array instanceof Uint8Array)) {
				console.warn("GLTFExporter: Attribute \"skinIndex\" converted to type UNSIGNED_SHORT.");
				modifiedAttribute = new BufferAttribute(new Uint16Array(array), attribute.itemSize, attribute.normalized);
			}
			var accessor = this.processAccessor(modifiedAttribute || attribute, geometry);
			if (accessor != null) {
				if (!attributeName.startsWith("_")) {
					this.detectMeshQuantization(attributeName, attribute);
				}
				attributes[attributeName] = accessor;
				cache.attributes.set(this.getUID(attribute), accessor);
			}
		}
		if (originalNormal != undefined) geometry.setAttribute("normal", originalNormal);
		if (Object.keys(attributes).length == 0) return null;
		if (mesh.morphTargetInfluences != undefined && mesh.morphTargetInfluences.length > 0) {
			var weights = new Array();
			var targetNames = new Array();
			var reverseDictionary = {};
			if (mesh.morphTargetDictionary != undefined) {
				for (var key in mesh.morphTargetDictionary) {
					reverseDictionary[mesh.morphTargetDictionary[key]] = key;
				}
			}
			for (var i = 0; i < mesh.morphTargetInfluences.length; i++) {
				var target = {};
				var warned = false;
				for (var attributeName in geometry.morphAttributes) {
					if (attributeName != "position" && attributeName != "normal") {
						if (!warned) {
							console.warn("GLTFExporter: Only POSITION and NORMAL morph are supported.");
							warned = true;
						}
						continue;
					}
					var attribute = geometry.morphAttributes[attributeName][i];
					var gltfAttributeName = attributeName.toUpperCase();
					var baseAttribute = geometry.attributes[attributeName];
					if (cache.attributes.has(this.getUID(attribute, true))) {
						target[gltfAttributeName] = cache.attributes.get(this.getUID(attribute, true));
						continue;
					}
					var relativeAttribute = attribute.clone();
					if (!geometry.morphTargetsRelative) {
						for (var j = 0, jl = attribute.count; j < jl; j++) {
							for (var a = 0; a < attribute.itemSize; a++) {
								if (a == 0) relativeAttribute.setX(j, attribute.getX(j) - baseAttribute.getX(j));
								if (a == 1) relativeAttribute.setY(j, attribute.getY(j) - baseAttribute.getY(j));
								if (a == 2) relativeAttribute.setZ(j, attribute.getZ(j) - baseAttribute.getZ(j));
								if (a == 3) relativeAttribute.setW(j, attribute.getW(j) - baseAttribute.getW(j));
							}
						}
					}
					target[gltfAttributeName] = this.processAccessor(relativeAttribute, geometry);
					cache.attributes.set(this.getUID(baseAttribute, true), target[gltfAttributeName]);
				}
				targets.push(target);
				weights.push(mesh.morphTargetInfluences[i]);
				if (mesh.morphTargetDictionary != undefined) targetNames.push(reverseDictionary[i]);
			}
			meshDef.weights = weights;
			if (targetNames.length > 0) {
				meshDef.extras = {};
				meshDef.extras.targetNames = targetNames;
			}
		}
		var isMultiMaterial = Array.isArray(mesh.material);
		if (isMultiMaterial && geometry.groups.length == 0) return null;
		var didForceIndices = false;
		if (isMultiMaterial && geometry.index == null) {
			var indices = new Array();
			for (var i = 0, il = geometry.attributes.position.count; i < il; i++) {
				indices[i] = i;
			}
			geometry.setIndex(indices);
			didForceIndices = true;
		}
		var materials = isMultiMaterial ? mesh.material : [mesh.material];
		var groups = isMultiMaterial ? geometry.groups : [{ materialIndex: 0, start: undefined, count: undefined }];
		for (var i = 0, il = groups.length; i < il; i++) {
			var primitive = {
				mode: mode,
				attributes: attributes
			};
			this.serializeUserData(geometry, primitive);
			if (targets.length > 0) primitive.targets = targets;
			if (geometry.index != null) {
				var cacheKey = this.getUID(geometry.index);
				if (groups[i].start != undefined || groups[i].count != undefined) {
					cacheKey += ":" + groups[i].start + ":" + groups[i].count;
				}
				if (cache.attributes.has(cacheKey)) {
					primitive.indices = cache.attributes.get(cacheKey);
				} else {
					primitive.indices = this.processAccessor(geometry.index, geometry, groups[i].start, groups[i].count);
					cache.attributes.set(cacheKey, primitive.indices);
				}
				if (primitive.indices == null) delete primitive.indices;
			}
			var material = this.processMaterial(materials[groups[i].materialIndex]);
			if (material != null) primitive.material = material;
			primitives.push(primitive);
		}
		if (didForceIndices == true) {
			geometry.setIndex(null);
		}
		meshDef.primitives = primitives;
		if (!json.meshes) json.meshes = new Array();
		this._invokeAll(function(ext:Dynamic) {
			ext.writeMesh && ext.writeMesh(mesh, meshDef);
		});
		var index = json.meshes.push(meshDef) - 1;
		cache.meshes.set(meshCacheKey, index);
		return index;
	}

	public function detectMeshQuantization(attributeName:String, attribute:Dynamic):Void {
		if (this.extensionsUsed[KHR_MESH_QUANTIZATION]) return;
		var attrType:String;
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
		var attrNamePrefix = attributeName.split("_", 1)[0];
		if (KHR_mesh_quantization_ExtraAttrTypes[attrNamePrefix] && KHR_mesh_quantization_ExtraAttrTypes[attrNamePrefix].includes(attrType)) {
			this.extensionsUsed[KHR_MESH_QUANTIZATION] = true;
			this.extensionsRequired[KHR_MESH_QUANTIZATION] = true;
		}
	}

	public function processCamera(camera:Dynamic):Int {
		var json = this.json;
		if (!json.cameras) json.cameras = new Array();
		var isOrtho = camera.isOrthographicCamera;
		var cameraDef = {
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
		if (camera.name != "") cameraDef.name = camera.type;
		return json.cameras.push(cameraDef) - 1;
	}

	public function processAnimation(clip:Dynamic, root:Dynamic):Int {
		var json = this.json;
		var nodeMap = this.nodeMap;
		if (!json.animations) json.animations = new Array();
		clip = GLTFExporter.Utils.mergeMorphTargetTracks(clip.clone(), root);
		var tracks = clip.tracks;
		var channels = new Array();
		var samplers = new Array();
		for (var i = 0; i < tracks.length; i++) {
			var track = tracks[i];
			var trackBinding = PropertyBinding.parseTrackName(track.name);
			var trackNode = PropertyBinding.findNode(root, trackBinding.nodeName);
			var trackProperty = PATH_PROPERTIES[trackBinding.propertyName];
			if (trackBinding.objectName == "bones") {
				if (trackNode.isSkinnedMesh == true) {
					trackNode = trackNode.skeleton.getBoneByName(trackBinding.objectIndex);
				} else {
					trackNode = undefined;
				}
			}
			if (!trackNode || !trackProperty) {
				console.warn("THREE.GLTFExporter: Could not export animation track \"" + track.name + "\".");
				return null;
			}
			var inputItemSize = 1;
			var outputItemSize = track.values.length / track.times.length;
			if (trackProperty == PATH_PROPERTIES.morphTargetInfluences) {
				outputItemSize /= trackNode.morphTargetInfluences.length;
			}
			var interpolation:String;
			if (track.createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline == true) {
				interpolation = "CUBICSPLINE";
				outputItemSize /= 3;
			} else if (track.getInterpolation() == InterpolateDiscrete) {
				interpolation = "STEP";
			} else {
				interpolation = "LINEAR";
			}
			samplers.push({
				input: this.processAccessor(new BufferAttribute(track.times, inputItemSize)),
				output: this.processAccessor(new BufferAttribute(track.values, outputItemSize)),
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

	public function processSkin(object:Dynamic):Int {
		var json = this.json;
		var nodeMap = this.nodeMap;
		var node = json.nodes[nodeMap.get(object)];
		var skeleton = object.skeleton;
		if (skeleton == undefined) return null;
		var rootJoint = object.skeleton.bones[0];
		if (rootJoint == undefined) return null;
		var joints = new Array();
		var inverseBindMatrices = new Float32Array(skeleton.bones.length * 16);
		var temporaryBoneInverse = new Matrix4();
		for (var i = 0; i < skeleton.bones.length; i++) {
			joints.push(nodeMap.get(skeleton.bones[i]));
			temporaryBoneInverse.copy(skeleton.boneInverses[i]);
			temporaryBoneInverse.multiply(object.bindMatrix).toArray(inverseBindMatrices, i * 16);
		}
		if (json.skins == undefined) json.skins = new Array();
		json.skins.push({
			inverseBindMatrices: this.processAccessor(new BufferAttribute(inverseBindMatrices, 16)),
			joints: joints,
			skeleton: nodeMap.get(rootJoint)
		});
		var skinIndex = node.skin = json.skins.length - 1;
		return skinIndex;
	}

	public function processNode(object:Dynamic):Int {
		var json = this.json;
		var options = this.options;
		var nodeMap = this.nodeMap;
		if (!json.nodes) json.nodes = new Array();
		var nodeDef = {};
		if (options.trs) {
			var rotation = object.quaternion.toArray();
			var position = object.position.toArray();
			var scale = object.scale.toArray();
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
		if (object.name != "") nodeDef.name = String(object.name);
		this.serializeUserData(object, nodeDef);
		if (object.isMesh || object.isLine || object.isPoints) {
			var meshIndex = this.processMesh(object);
			if (meshIndex != null) nodeDef.mesh = meshIndex;
		} else if (object.isCamera) {
			nodeDef.camera = this.processCamera(object);
		}
		if (object.isSkinnedMesh) this.skins.push(object);
		if (object.children.length > 0) {
			var children = new Array();
			for (var i = 0, l = object.children.length; i < l; i++) {
				var child = object.children[i];
				if (child.visible || options.onlyVisible == false) {
					var nodeIndex = this.processNode(child);
					if (nodeIndex != null) children.push(nodeIndex);
				}
			}
			if (children.length > 0) nodeDef.children = children;
		}
		this._invokeAll(function(ext:Dynamic) {
			ext.writeNode && ext.writeNode(object, nodeDef);
		});
		var nodeIndex = json.nodes.push(nodeDef) - 1;
		nodeMap.set(object, nodeIndex);
		return nodeIndex;
	}

	public function processScene(scene:Dynamic):Void {
		var json = this.json;
		var options = this.options;
		if (!json.scenes) {
			json.scenes = new Array();
			json.scene = 0;
		}
		var sceneDef = {};
		if (scene.name != "") sceneDef.name = scene.name;
		json.scenes.push(sceneDef);
		var nodes = new Array();
		for (var i = 0, l = scene.children.length; i < l; i++) {
			var child = scene.children[i];
			if (child.visible || options.onlyVisible == false) {
				var nodeIndex = this.processNode(child);
				if (nodeIndex != null) nodes.push(nodeIndex);
			}
		}
		if (nodes.length > 0) sceneDef.nodes = nodes;
		this.serializeUserData(scene, sceneDef);
	}

	public function processObjects(objects:Array<Dynamic>):Void {
		var scene = new Scene();
		scene.name = "AuxScene";
		for (var i = 0; i < objects.length; i++) {
			scene.children.push(objects[i]);
		}
		this.processScene(scene);
	}

	public function processInput(input:Dynamic):Void {
		var options = this.options;
		input = input instanceof Array ? input : [input];
		this._invokeAll(function(ext:Dynamic) {
			ext.beforeParse && ext.beforeParse(input);
		});
		var objectsWithoutScene = new Array();
		for (var i = 0; i < input.length; i++) {
			if (input[i] instanceof Scene) {
				this.processScene(input[i]);
			} else {
				objectsWithoutScene.push(input[i]);
			}
		}
		if (objectsWithoutScene.length > 0) this.processObjects(objectsWithoutScene);
		for (var i = 0; i < this.skins.length; i++) {
			this.processSkin(this.skins[i]);
		}
		for (var i = 0; i < options.animations.length; i++) {
			this.processAnimation(options.animations[i], input[0]);
		}
		this._invokeAll(function(ext:Dynamic) {
			ext.afterParse && ext.afterParse(input);
		});
	}

	public function _invokeAll(func:Dynamic->Void):Void {
		for (var i = 0, il = this.plugins.length; i < il; i++) {
			func(this.plugins[i]);
		}
	}

}
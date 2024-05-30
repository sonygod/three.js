class GLTFWriter {
    public var plugins:Array<Dynamic>;
    public var options:Map<String, Dynamic>;
    public var pending:Array<Dynamic>;
    public var buffers:Array<Bytes>;
    public var byteOffset:Int;
    public var nodeMap:Map<Dynamic, Int>;
    public var skins:Array<Dynamic>;
    public var extensionsUsed:Map<String, Bool>;
    public var extensionsRequired:Map<String, Bool>;
    public var uids:Map<Dynamic, Map<Bool, Int>>;
    public var uid:Int;
    public var json:Map<String, Map<String, Dynamic>>;
    public var cache:Map<String, Map<Dynamic, Dynamic>>;
    public function new() {
        plugins = [];
        options = {
            'binary': false,
            'trs': false,
            'onlyVisible': true,
            'maxTextureSize': Std.intInfinity,
            'animations': [],
            'includeCustomExtensions': false
        };
        pending = [];
        buffers = [];
        byteOffset = 0;
        buffers = [];
        nodeMap = new Map();
        skins = [];
        extensionsUsed = new Map();
        extensionsRequired = new Map();
        uids = new Map();
        uid = 0;
        json = {
            'asset': {
                'version': '2.0',
                'generator': 'THREE.GLTFExporter r' + REVISION
            }
        };
        cache = {
            'meshes': new Map(),
            'attributes': new Map(),
            'attributesNormalized': new Map(),
            'materials': new Map(),
            'textures': new Map(),
            'images': new Map()
        };
    }
    public function setPlugins(plugins:Array<Dynamic>) {
        this.plugins = plugins;
    }
    public async function write(input:Dynamic, onDone:Dynamic, ?options:Map<String, Dynamic>) {
        this.options = options != null ? options : {
            // default options
            'binary': false,
            'trs': false,
            'onlyVisible': true,
            'maxTextureSize': Std.intInfinity,
            'animations': [],
            'includeCustomExtensions': false
        };
        if (options.exists('animations') && options.get('animations').length > 0) {
            // Only TRS properties, and not matrices, may be targeted by animation.
            options.set('trs', true);
        }
        processInput(input);
        await Promise.all(pending);
        var writer = this;
        var buffers = writer.buffers;
        var json = writer.json;
        options = writer.options;
        var extensionsUsed = writer.extensionsUsed;
        var extensionsRequired = writer.extensionsRequired;
        // Merge buffers.
        var blob = new Blob(buffers, {
            'type': 'application/octet-stream'
        });
        // Declare extensions.
        var extensionsUsedList = Reflect.fields(extensionsUsed);
        var extensionsRequiredList = Reflect.fields(extensionsRequired);
        if (extensionsUsedList.length > 0) json.set('extensionsUsed', extensionsUsedList);
        if (extensionsRequiredList.length > 0) json.set('extensionsRequired', extensionsRequiredList);
        // Update bytelength of the single buffer.
        if (json.exists('buffers') && json.get('buffers').length > 0) json.get('buffers')[0].set('byteLength', blob.size);
        if (options.get('binary')) {
            // https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#glb-file-format-specification
            var reader = new FileReader();
            reader.readAsArrayBuffer(blob);
            reader.onloadend = function() {
                // Binary chunk.
                var binaryChunk = getPaddedArrayBuffer(reader.result);
                var binaryChunkPrefix = new DataView(new ArrayBuffer(GLB_CHUNK_PREFIX_BYTES));
                binaryChunkPrefix.setUint32(0, binaryChunk.byteLength, true);
                binaryChunkPrefix.setUint32(4, GLB_CHUNK_TYPE_BIN, true);
                // JSON chunk.
                var jsonChunk = getPaddedArrayBuffer(stringToArrayBuffer(JSON.stringify(json)), 0x20);
                var jsonChunkPrefix = new DataView(new ArrayBuffer(GLB_CHUNK_PREFIX_BYTES));
                jsonChunkPrefix.setUint32(0, jsonChunk.byteLength, true);
                jsonChunkPrefix.setUint32(4, GLB_CHUNK_TYPE_JSON, true);
                // GLB header.
                var header = new ArrayBuffer(GLB_HEADER_BYTES);
                var headerView = new DataView(header);
                headerView.setUint32(0, GLB_HEADER_MAGIC, true);
                headerView.setUint32(4, GLB_VERSION, true);
                var totalByteLength = GLB_HEADER_BYTES + jsonChunkPrefix.byteLength + jsonChunk.byteLength + binaryChunkPrefix.byteLength + binaryChunk.byteLength;
                headerView.setUint32(8, totalByteLength, true);
                var glbBlob = new Blob([
                    header,
                    jsonChunkPrefix,
                    jsonChunk,
                    binaryChunkPrefix,
                    binaryChunk
                ], {
                    'type': 'application/octet-stream'
                });
                var glbReader = new FileReader();
                glbReader.readAsArrayBuffer(glbBlob);
                glbReader.onloadend = function() {
                    onDone(glbReader.result);
                };
            };
        } else {
            if (json.exists('buffers') && json.get('buffers').length > 0) {
                var reader = new FileReader();
                reader.readAsDataURL(blob);
                reader.onloadend = function() {
                    var base64data = reader.result;
                    json.get('buffers')[0].set('uri', base64data);
                    onDone(json);
                };
            } else {
                onDone(json);
            }
        }
    }
    public function serializeUserData(object:Dynamic, objectDef:Dynamic) {
        if (Reflect.field(object, 'userData').keys().length == 0) return;
        var options = this.options;
        var extensionsUsed = this.extensionsUsed;
        try {
            var json = JSON.parse(JSON.stringify(object.userData));
            if (options.get('includeCustomExtensions') && json.exists('gltfExtensions')) {
                if (!objectDef.exists('extensions')) objectDef.set('extensions', new Map());
                for (extensionName in json.get('gltfExtensions')) {
                    objectDef.get('extensions').set(extensionName, json.get('gltfExtensions').get(extensionName));
                    extensionsUsed.set(extensionName, true);
                }
                json.delete('gltfExtensions');
            }
            if (Reflect.field(json, 'keys').length > 0) objectDef.set('extras', json);
        } catch (error) {
            trace('THREE.GLTFExporter: userData of \'' + object.name + '\' ' +
                'won\'t be serialized because of JSON.stringify error - ' + error.message);
        }
    }
    public function getUID(attribute:Dynamic, ?isRelativeCopy:Bool) {
        if (!uids.exists(attribute)) {
            var uids = new Map();
            uids.set(true, uid++);
            uids.set(false, uid++);
            uids.set(attribute, uids);
        }
        var uids = uids.get(attribute);
        return uids.get(isRelativeCopy != null ? isRelativeCopy : false);
    }
    public function isNormalizedNormalAttribute(normal:Dynamic) {
        var cache = this.cache;
        if (cache.attributesNormalized.exists(normal)) return false;
        var v = new Vector3();
        var il = normal.count;
        for (i in 0...il) {
            // 0.0005 is from glTF-validator
            if (Math.abs(v.fromBufferAttribute(normal, i).length() - 1.0) > 0.0005) return false;
        }
        return true;
    }
    public function createNormalizedNormalAttribute(normal:Dynamic) {
        var cache = this.cache;
        if (cache.attributesNormalized.exists(normal)) return cache.attributesNormalized.get(normal);
        var attribute = normal.clone();
        var v = new Vector3();
        var il = attribute.count;
        for (i in 0...il) {
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
    public function applyTextureTransform(mapDef:Dynamic, texture:Dynamic) {
        var didTransform = false;
        var transformDef = new Map();
        if (texture.offset.x != 0 || texture.offset.y != 0) {
            transformDef.set('offset', texture.offset.toArray());
            didTransform = true;
        }
        if (texture.rotation != 0) {
            transformDef.set('rotation', texture.rotation);
            didTransform = true;
        }
        if (texture.repeat.x != 1 || texture.repeat.y != 1) {
            transformDef.set('scale', texture.repeat.toArray());
            didTransform = true;
        }
        if (didTransform) {
            if (!mapDef.exists('extensions')) mapDef.set('extensions', new Map());
            mapDef.get('extensions').set('KHR_texture_transform', transformDef);
            extensionsUsed.set('KHR_texture_transform', true);
        }
    }
    public function buildMetalRoughTexture(metalnessMap:Dynamic, roughnessMap:Dynamic) {
        if (metalnessMap == roughnessMap) return metalnessMap;
        function getEncodingConversion(map:Dynamic) {
            if (map.colorSpace == SRGBColorSpace) {
                return function(c:Float) {
                    return c < 0.04045 ? c * 0.0773993808 : Math.pow(c * 0.9478672986 + 0.0521327014, 2.4);
                };
            }
            return function(c:Float) {
                return c;
            };
        }
        trace('THREE.GLTFExporter: Merged metalnessMap and roughnessMap textures.');
        if (metalnessMap instanceof CompressedTexture) {
            metalnessMap = decompress(metalnessMap);
        }
        if (roughnessMap instanceof CompressedTexture) {
            roughnessMap = decompress(roughnessMap);
        }
        var metalness = metalnessMap != null ? metalnessMap.image : null;
        var roughness = roughnessMap != null ? roughnessMap.image : null;
        var width = Math.max(metalness != null ? metalness.width : 0, roughness != null ? roughness.width : 0);
        var height = Math.max(metalness != null ? metalness.height : 0, roughness != null ? roughness.height : 0);
        var canvas = getCanvas();
        canvas.width = width;
        canvas.height = height;
        var context = canvas.getContext('2d');
        context.fillStyle = '#00ffff';
        context.fillRect(0, 0, width, height);
        var composite = context.getImageData(0, 0, width, height);
        if (metalness != null) {
            context.drawImage(metalness, 0, 0, width, height);
            var convert = getEncodingConversion(metalnessMap);
            var data = context.getImageData(0, 0, width, height).data;
            var i = 2;
            while (i < data.length) {
                composite.data[i] = convert(data[i] / 256) * 256;
                i += 4;
            }
        }
        if (roughness != null) {
            context.drawImage(roughness, 0, 0, width, height);
            var convert = getEncodingConversion(roughnessMap);
            var data = context.getImageData(0, 0, width, height).data;
            var i = 1;
            while (i < data.length) {
                composite.data[i] = convert(data[i] / 256) * 256;
                i += 4;
            }
        }
        context.putImageData(composite, 0, 0);
        //
        var reference = metalnessMap != null ? metalnessMap : roughnessMap;
        var texture = reference.clone();
        texture.source = new Source(canvas);
        texture.colorSpace = NoColorSpace;
        texture.channel = (metalnessMap != null ? metalnessMap : roughnessMap).channel;
        if (metalnessMap != null && roughnessMap != null && metalnessMap.channel != roughnessMap.channel) {
            trace('THREE.GLTFExporter: UV channels for metalnessMap and roughnessMap textures must match.');
        }
        return texture;
    }
    public function processBuffer(buffer:Bytes) {
        var json = this.json;
        if (!json.exists('buffers')) json.set('buffers', []);
        // All buffers are merged before export.
        buffers.push(buffer);
        return 0;
    }
    public function processBufferView(attribute:Dynamic, componentType:Int, start:Int, count:Int, ?target:Int) {
        var json = this.json;
        if (!json.exists('bufferViews')) json.set('bufferViews', []);
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
            byteStride = Std.intCeil(byteStride / 4) * 4;
        }
        var byteLength = getPaddedBufferSize(count * byteStride);
        var dataView = new DataView(new ArrayBuffer(byteLength));
        var offset = 0;
        var i = start;
        while (i < start + count) {
            var a = 0;
            while (a < attribute.itemSize) {
                var value:Dynamic;
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
                a++;
            }
            if ((offset % byteStride) != 0) {
                offset += byteStride - (offset % byteStride);
            }
            i++;
        }
        var bufferViewDef = {
            'buffer': processBuffer(dataView.buffer),
            'byteOffset': byteOffset,
            'byteLength': byteLength
        };
        if (target != null) bufferViewDef.set('target', target);
        if (target == WEBGL_CONSTANTS.ARRAY_BUFFER) {
            // Only define byteStride for vertex attributes.
            bufferViewDef.set('byteStride', byteStride);
        }
        byteOffset += byteLength;
        json.get('bufferViews').push(bufferViewDef);
        // @TODO Merge bufferViews where possible.
        var output = {
            'id': json.get('bufferViews').length - 1,
            'byteLength': 0
        };
        return output;
    }
    public function processBufferViewImage(blob:Dynamic) {
        var writer = this;
        var json = writer.json;
        if (!json.exists('bufferViews')) json.set('bufferViews', []);
        return new Promise(function(resolve) {
            var reader = new FileReader();
            reader.readAsArrayBuffer(blob);
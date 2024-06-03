import three.math.Sphere;
import three.math.Vector3;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.core.InstancedBufferGeometry;
import three.core.InstancedBufferAttribute;
import three.core.InterleavedBufferAttribute;
import three.core.InterleavedBuffer;
import three.utils.Utils;

class BufferGeometryLoader extends Loader {

    public function new(manager:LoaderManager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic -> Void, onProgress:Dynamic -> Void, onError:Dynamic -> Void) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(this.parse(haxe.Json.parse(text)));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(json:Dynamic):BufferGeometry {
        var interleavedBufferMap:haxe.ds.StringMap<InterleavedBuffer> = new haxe.ds.StringMap();
        var arrayBufferMap:haxe.ds.StringMap<ArrayBuffer> = new haxe.ds.StringMap();

        function getInterleavedBuffer(json:Dynamic, uuid:String):InterleavedBuffer {
            if (interleavedBufferMap.exists(uuid)) return interleavedBufferMap.get(uuid);

            var interleavedBuffers = json.interleavedBuffers;
            var interleavedBuffer = interleavedBuffers[uuid];

            var buffer = getArrayBuffer(json, interleavedBuffer.buffer);

            var array = Utils.getTypedArray(interleavedBuffer.type, buffer);
            var ib = new InterleavedBuffer(array, interleavedBuffer.stride);
            ib.uuid = interleavedBuffer.uuid;

            interleavedBufferMap.set(uuid, ib);

            return ib;
        }

        function getArrayBuffer(json:Dynamic, uuid:String):ArrayBuffer {
            if (arrayBufferMap.exists(uuid)) return arrayBufferMap.get(uuid);

            var arrayBuffers = json.arrayBuffers;
            var arrayBuffer = arrayBuffers[uuid];

            var ab = new Uint32Array(arrayBuffer).buffer;

            arrayBufferMap.set(uuid, ab);

            return ab;
        }

        var geometry:BufferGeometry = json.isInstancedBufferGeometry ? new InstancedBufferGeometry() : new BufferGeometry();

        var index = json.data.index;

        if (index != null) {
            var typedArray = Utils.getTypedArray(index.type, index.array);
            geometry.setIndex(new BufferAttribute(typedArray, 1));
        }

        var attributes = json.data.attributes;

        for (key in Reflect.fields(attributes)) {
            var attribute = attributes[key];
            var bufferAttribute:BufferAttribute;

            if (attribute.isInterleavedBufferAttribute) {
                var interleavedBuffer = getInterleavedBuffer(json.data, attribute.data);
                bufferAttribute = new InterleavedBufferAttribute(interleavedBuffer, attribute.itemSize, attribute.offset, attribute.normalized);
            } else {
                var typedArray = Utils.getTypedArray(attribute.type, attribute.array);
                var bufferAttributeConstr = attribute.isInstancedBufferAttribute ? InstancedBufferAttribute : BufferAttribute;
                bufferAttribute = Type.createInstance(bufferAttributeConstr, [typedArray, attribute.itemSize, attribute.normalized]);
            }

            if (attribute.name != null) bufferAttribute.name = attribute.name;
            if (attribute.usage != null) bufferAttribute.setUsage(attribute.usage);

            geometry.setAttribute(key, bufferAttribute);
        }

        var morphAttributes = json.data.morphAttributes;

        if (morphAttributes != null) {
            for (key in Reflect.fields(morphAttributes)) {
                var attributeArray = morphAttributes[key];

                var array = [];

                for (i in 0...attributeArray.length) {
                    var attribute = attributeArray[i];
                    var bufferAttribute:BufferAttribute;

                    if (attribute.isInterleavedBufferAttribute) {
                        var interleavedBuffer = getInterleavedBuffer(json.data, attribute.data);
                        bufferAttribute = new InterleavedBufferAttribute(interleavedBuffer, attribute.itemSize, attribute.offset, attribute.normalized);
                    } else {
                        var typedArray = Utils.getTypedArray(attribute.type, attribute.array);
                        bufferAttribute = new BufferAttribute(typedArray, attribute.itemSize, attribute.normalized);
                    }

                    if (attribute.name != null) bufferAttribute.name = attribute.name;
                    array.push(bufferAttribute);
                }

                geometry.morphAttributes[key] = array;
            }
        }

        var morphTargetsRelative = json.data.morphTargetsRelative;

        if (morphTargetsRelative != null) {
            geometry.morphTargetsRelative = true;
        }

        var groups = json.data.groups != null ? json.data.groups : (json.data.drawcalls != null ? json.data.drawcalls : json.data.offsets);

        if (groups != null) {
            for (i in 0...groups.length) {
                var group = groups[i];
                geometry.addGroup(group.start, group.count, group.materialIndex);
            }
        }

        var boundingSphere = json.data.boundingSphere;

        if (boundingSphere != null) {
            var center = new Vector3();

            if (boundingSphere.center != null) {
                center.fromArray(boundingSphere.center);
            }

            geometry.boundingSphere = new Sphere(center, boundingSphere.radius);
        }

        if (json.name != null) geometry.name = json.name;
        if (json.userData != null) geometry.userData = json.userData;

        return geometry;
    }
}
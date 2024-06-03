import DataMap;
import Constants.AttributeType;
import three.Uint32BufferAttribute;
import three.Uint16BufferAttribute;

class Geometries extends DataMap {

    public var attributes:Dynamic;
    public var info:Dynamic;
    public var wireframes:WeakMap<Dynamic, Dynamic>;
    public var attributeCall:WeakMap<Dynamic, Int>;

    public function new(attributes:Dynamic, info:Dynamic) {
        super();
        this.attributes = attributes;
        this.info = info;
        this.wireframes = new WeakMap<Dynamic, Dynamic>();
        this.attributeCall = new WeakMap<Dynamic, Int>();
    }

    public function has(renderObject:Dynamic):Bool {
        var geometry = renderObject.geometry;
        return super.has(geometry) && this.get(geometry).initialized === true;
    }

    public function updateForRender(renderObject:Dynamic):Void {
        if (this.has(renderObject) === false) this.initGeometry(renderObject);
        this.updateAttributes(renderObject);
    }

    public function initGeometry(renderObject:Dynamic):Void {
        var geometry = renderObject.geometry;
        var geometryData = this.get(geometry);
        geometryData.initialized = true;
        this.info.memory.geometries++;
        var onDispose = function() {
            this.info.memory.geometries--;
            var index = geometry.index;
            var geometryAttributes = renderObject.getAttributes();
            if (index !== null) {
                this.attributes.delete(index);
            }
            for (var geometryAttribute in geometryAttributes) {
                this.attributes.delete(geometryAttribute);
            }
            var wireframeAttribute = this.wireframes.get(geometry);
            if (wireframeAttribute !== null) {
                this.attributes.delete(wireframeAttribute);
            }
            geometry.removeEventListener('dispose', onDispose);
        };
        geometry.addEventListener('dispose', onDispose);
    }

    public function updateAttributes(renderObject:Dynamic):Void {
        var attributes = renderObject.getAttributes();
        for (var attribute in attributes) {
            this.updateAttribute(attribute, AttributeType.VERTEX);
        }
        var index = this.getIndex(renderObject);
        if (index !== null) {
            this.updateAttribute(index, AttributeType.INDEX);
        }
    }

    public function updateAttribute(attribute:Dynamic, type:AttributeType):Void {
        var callId = this.info.render.calls;
        if (this.attributeCall.get(attribute) !== callId) {
            this.attributes.update(attribute, type);
            this.attributeCall.set(attribute, callId);
        }
    }

    public function getIndex(renderObject:Dynamic):Dynamic {
        var geometry = renderObject.geometry;
        var material = renderObject.material;
        var index = geometry.index;
        if (material.wireframe === true) {
            var wireframes = this.wireframes;
            var wireframeAttribute = wireframes.get(geometry);
            if (wireframeAttribute === null) {
                wireframeAttribute = getWireframeIndex(geometry);
                wireframes.set(geometry, wireframeAttribute);
            } else if (wireframeAttribute.version !== getWireframeVersion(geometry)) {
                this.attributes.delete(wireframeAttribute);
                wireframeAttribute = getWireframeIndex(geometry);
                wireframes.set(geometry, wireframeAttribute);
            }
            index = wireframeAttribute;
        }
        return index;
    }
}

function arrayNeedsUint32(array:Array<Int>):Bool {
    for (var i = array.length - 1; i >= 0; --i) {
        if (array[i] >= 65535) return true;
    }
    return false;
}

function getWireframeVersion(geometry:Dynamic):Int {
    return geometry.index !== null ? geometry.index.version : geometry.attributes.position.version;
}

function getWireframeIndex(geometry:Dynamic):Dynamic {
    var indices = [];
    var geometryIndex = geometry.index;
    var geometryPosition = geometry.attributes.position;
    if (geometryIndex !== null) {
        var array = geometryIndex.array;
        for (var i = 0, l = array.length; i < l; i += 3) {
            var a = array[i + 0];
            var b = array[i + 1];
            var c = array[i + 2];
            indices.push(a, b, b, c, c, a);
        }
    } else {
        var array = geometryPosition.array;
        for (var i = 0, l = (array.length / 3) - 1; i < l; i += 3) {
            var a = i + 0;
            var b = i + 1;
            var c = i + 2;
            indices.push(a, b, b, c, c, a);
        }
    }
    var attribute = new (arrayNeedsUint32(indices) ? Uint32BufferAttribute : Uint16BufferAttribute)(indices, 1);
    attribute.version = getWireframeVersion(geometry);
    return attribute;
}
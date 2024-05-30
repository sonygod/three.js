import DataMap from './DataMap.hx';
import Constants.AttributeType;
import three.Uint32BufferAttribute;
import three.Uint16BufferAttribute;

function arrayNeedsUint32(array:Array<Int>):Bool {
    for (i in array.reverse()) {
        if (i >= 65535) return true;
    }
    return false;
}

function getWireframeVersion(geometry:Geometry):Int {
    return if (geometry.index != null) geometry.index.version else geometry.attributes.position.version;
}

function getWireframeIndex(geometry:Geometry):BufferAttribute {
    var indices:Array<Int> = [];
    var geometryIndex = geometry.index;
    var geometryPosition = geometry.attributes.position;
    if (geometryIndex != null) {
        var array = geometryIndex.array;
        for (i in array.length) {
            var a = array[i + 0];
            var b = array[i + 1];
            var c = array[i + 2];
            indices.push(a, b, b, c, c, a);
        }
    } else {
        var array = geometryPosition.array;
        for (i in (array.length / 3) - 1) {
            var a = i + 0;
            var b = i + 1;
            var c = i + 2;
            indices.push(a, b, b, c, c, a);
        }
    }
    var attribute = if (arrayNeedsUint32(indices)) new Uint32BufferAttribute(indices, 1) else new Uint16BufferAttribute(indices, 1);
    attribute.version = getWireframeVersion(geometry);
    return attribute;
}

class Geometries extends DataMap {
    public var attributes:Dynamic;
    public var info:Dynamic;
    public var wireframes:WeakMap<Geometry, BufferAttribute>;
    public var attributeCall:WeakMap<BufferAttribute, Int>;

    public function new(attributes:Dynamic, info:Dynamic) {
        super();
        this.attributes = attributes;
        this.info = info;
        this.wireframes = new WeakMap();
        this.attributeCall = new WeakMap();
    }

    public function has(renderObject:Dynamic):Bool {
        var geometry = renderObject.geometry;
        return super.has(geometry) && this.get(geometry).initialized == true;
    }

    public function updateForRender(renderObject:Dynamic):Void {
        if (!this.has(renderObject)) this.initGeometry(renderObject);
        this.updateAttributes(renderObject);
    }

    public function initGeometry(renderObject:Dynamic):Void {
        var geometry = renderObject.geometry;
        var geometryData = this.get(geometry);
        geometryData.initialized = true;
        this.info.memory.geometries++;
        var onDispose = () -> {
            this.info.memory.geometries--;
            var index = geometry.index;
            var geometryAttributes = renderObject.getAttributes();
            if (index != null) this.attributes.delete(index);
            for (geometryAttribute in geometryAttributes) this.attributes.delete(geometryAttribute);
            var wireframeAttribute = this.wireframes.get(geometry);
            if (wireframeAttribute != null) this.attributes.delete(wireframeAttribute);
            geometry.removeEventListener('dispose', onDispose);
        };
        geometry.addEventListener('dispose', onDispose);
    }

    public function updateAttributes(renderObject:Dynamic):Void {
        var attributes = renderObject.getAttributes();
        for (attribute in attributes) this.updateAttribute(attribute, AttributeType.VERTEX);
        var index = this.getIndex(renderObject);
        if (index != null) this.updateAttribute(index, AttributeType.INDEX);
    }

    public function updateAttribute(attribute:BufferAttribute, type:Int):Void {
        var callId = this.info.render.calls;
        if (this.attributeCall.get(attribute) != callId) {
            this.attributes.update(attribute, type);
            this.attributeCall.set(attribute, callId);
        }
    }

    public function getIndex(renderObject:Dynamic):BufferAttribute {
        var geometry = renderObject.geometry;
        var material = renderObject.material;
        var index = geometry.index;
        if (material.wireframe) {
            var wireframes = this.wireframes;
            var wireframeAttribute = wireframes.get(geometry);
            if (wireframeAttribute == null) {
                wireframeAttribute = getWireframeIndex(geometry);
                wireframes.set(geometry, wireframeAttribute);
            } else if (wireframeAttribute.version != getWireframeVersion(geometry)) {
                this.attributes.delete(wireframeAttribute);
                wireframeAttribute = getWireframeIndex(geometry);
                wireframes.set(geometry, wireframeAttribute);
            }
            index = wireframeAttribute;
        }
        return index;
    }
}

typedef Geometry = {
    index:BufferAttribute;
    attributes:{position:BufferAttribute};
    getAttributes():Array<BufferAttribute>;
    addEventListener(event:String, listener:Dynamic->Void):Void;
    removeEventListener(event:String, listener:Dynamic->Void):Void;
}

typedef BufferAttribute = {
    array:Array<Int>;
    version:Int;
}

typedef RenderObject = {
    geometry:Geometry;
    material:{wireframe:Bool};
    getAttributes():Array<BufferAttribute>;
}

typedef Info = {
    memory:{geometries:Int};
    render:{calls:Int};
}
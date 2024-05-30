import DataMap from './DataMap.hx';
import { AttributeType } from './Constants.hx';
import { Uint32BufferAttribute, Uint16BufferAttribute } from 'three';

function arrayNeedsUint32(array: Array<Int>) : Bool {
    for (i in array.length - 1 ... 0) {
        if (array[i] >= 65535) {
            return true; // account for PRIMITIVE_RESTART_FIXED_INDEX, #24565
        }
    }
    return false;
}

function getWireframeVersion(geometry: Geometry) : Int {
    if (geometry.index != null) {
        return geometry.index.version;
    } else {
        return geometry.attributes.position.version;
    }
}

function getWireframeIndex(geometry: Geometry) : BufferAttribute {
    var indices = [];
    if (geometry.index != null) {
        var array = geometry.index.array;
        for (i in 0...array.length) {
            var a = array[i * 3];
            var b = array[i * 3 + 1];
            var c = array[i * 3 + 2];
            indices.push(a, b, b, c, c, a);
        }
    } else {
        var array = geometry.attributes.position.array;
        for (i in 0...(array.length / 3) - 1) {
            var a = i * 3;
            var b = i * 3 + 1;
            var c = i * 3 + 2;
            indices.push(a, b, b, c, c, a);
        }
    }
    var attribute = new (if (arrayNeedsUint32(indices)) Uint32BufferAttribute else Uint16BufferAttribute)(indices, 1);
    attribute.version = getWireframeVersion(geometry);
    return attribute;
}

class Geometries extends DataMap {
    public attributes: Attributes;
    public info: Info;
    public wireframes: WeakMap<Geometry, BufferAttribute>;
    public attributeCall: WeakMap<Attribute, Int>;

    public function new(attributes: Attributes, info: Info) {
        super();
        this.attributes = attributes;
        this.info = info;
        this.wireframes = new WeakMap();
        this.attributeCall = new WeakMap();
    }

    public function has(renderObject: RenderObject) : Bool {
        var geometry = renderObject.geometry;
        return super.has(geometry) && this.get(geometry).initialized;
    }

    public function updateForRender(renderObject: RenderObject) {
        if (!this.has(renderObject)) {
            this.initGeometry(renderObject);
        }
        this.updateAttributes(renderObject);
    }

    public function initGeometry(renderObject: RenderObject) {
        var geometry = renderObject.geometry;
        var geometryData = this.get(geometry);
        geometryData.initialized = true;
        this.info.memory.geometries++;

        var onDispose = function() {
            this.info.memory.geometries--;
            var index = geometry.index;
            var geometryAttributes = renderObject.getAttributes();
            if (index != null) {
                this.attributes.delete(index);
            }
            for (attribute in geometryAttributes) {
                this.attributes.delete(attribute);
            }
            var wireframeAttribute = this.wireframes.get(geometry);
            if (wireframeAttribute != null) {
                this.attributes.delete(wireframeAttribute);
            }
            geometry.removeEventListener('dispose', onDispose);
        };

        geometry.addEventListener('dispose', onDispose);
    }

    public function updateAttributes(renderObject: RenderObject) {
        var attributes = renderObject.getAttributes();
        for (attribute in attributes) {
            this.updateAttribute(attribute, AttributeType.VERTEX);
        }
        var index = this.getIndex(renderObject);
        if (index != null) {
            this.updateAttribute(index, AttributeType.INDEX);
        }
    }

    public function updateAttribute(attribute: Attribute, type: AttributeType) {
        var callId = this.info.render.calls;
        if (this.attributeCall.get(attribute) != callId) {
            this.attributes.update(attribute, type);
            this.attributeCall.set(attribute, callId);
        }
    }

    public function getIndex(renderObject: RenderObject) : Null<BufferAttribute> {
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

export default Geometries;
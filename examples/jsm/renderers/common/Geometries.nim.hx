import DataMap from './DataMap.js';
import AttributeType from './Constants.js';
import Uint32BufferAttribute from 'three';
import Uint16BufferAttribute from 'three';

function arrayNeedsUint32(array) {
  for (i in array.length - 1...0) {
    if (array[i] >= 65535) return true; // account for PRIMITIVE_RESTART_FIXED_INDEX, #24565
  }
  return false;
}

function getWireframeVersion(geometry) {
  return (geometry.index != null) ? geometry.index.version : geometry.attributes.position.version;
}

function getWireframeIndex(geometry) {
  var indices = [];
  var geometryIndex = geometry.index;
  var geometryPosition = geometry.attributes.position;
  if (geometryIndex != null) {
    var array = geometryIndex.array;
    for (i in 0...array.length by 3) {
      var a = array[i + 0];
      var b = array[i + 1];
      var c = array[i + 2];
      indices.push(a, b, b, c, c, a);
    }
  } else {
    var array = geometryPosition.array;
    for (i in 0...(array.length / 3) - 1 by 3) {
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

class Geometries extends DataMap {
  var attributes;
  var info;
  var wireframes = new WeakMap<Geometry, BufferAttribute>();
  var attributeCall = new WeakMap<BufferAttribute, Int>();

  public function new(attributes:Map<String, BufferAttribute>, info:Object) {
    super();
    this.attributes = attributes;
    this.info = info;
  }

  public function has(renderObject:Object):Bool {
    var geometry = renderObject.geometry;
    return super.has(geometry) && this.get(geometry).initialized == true;
  }

  public function updateForRender(renderObject:Object) {
    if (this.has(renderObject) == false) this.initGeometry(renderObject);
    this.updateAttributes(renderObject);
  }

  public function initGeometry(renderObject:Object) {
    var geometry = renderObject.geometry;
    var geometryData = this.get(geometry);
    geometryData.initialized = true;
    this.info.memory.geometries++;
    var onDispose = function() {
      this.info.memory.geometries--;
      var index = geometry.index;
      var geometryAttributes = renderObject.getAttributes();
      if (index != null) {
        this.attributes.remove(index);
      }
      for (attribute in geometryAttributes) {
        this.attributes.remove(attribute);
      }
      var wireframeAttribute = this.wireframes.get(geometry);
      if (wireframeAttribute != null) {
        this.attributes.remove(wireframeAttribute);
      }
      geometry.removeEventListener('dispose', onDispose);
    };
    geometry.addEventListener('dispose', onDispose);
  }

  public function updateAttributes(renderObject:Object) {
    var attributes = renderObject.getAttributes();
    for (attribute in attributes) {
      this.updateAttribute(attribute, AttributeType.VERTEX);
    }
    var index = this.getIndex(renderObject);
    if (index != null) {
      this.updateAttribute(index, AttributeType.INDEX);
    }
  }

  public function updateAttribute(attribute:BufferAttribute, type:AttributeType) {
    var callId = this.info.render.calls;
    if (this.attributeCall.get(attribute) != callId) {
      this.attributes.update(attribute, type);
      this.attributeCall.set(attribute, callId);
    }
  }

  public function getIndex(renderObject:Object):BufferAttribute {
    var geometry = renderObject.geometry;
    var material = renderObject.material;
    var index = geometry.index;
    if (material.wireframe == true) {
      var wireframes = this.wireframes;
      var wireframeAttribute = wireframes.get(geometry);
      if (wireframeAttribute == null) {
        wireframeAttribute = getWireframeIndex(geometry);
        wireframes.set(geometry, wireframeAttribute);
      } else if (wireframeAttribute.version != getWireframeVersion(geometry)) {
        this.attributes.remove(wireframeAttribute);
        wireframeAttribute = getWireframeIndex(geometry);
        wireframes.set(geometry, wireframeAttribute);
      }
      index = wireframeAttribute;
    }
    return index;
  }
}

export default Geometries;
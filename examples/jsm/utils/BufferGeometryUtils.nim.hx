import three.js.extras.core.BufferGeometry;
import three.js.extras.core.BufferAttribute;
import three.js.extras.core.Float32BufferAttribute;
import three.js.extras.core.InstancedBufferAttribute;
import three.js.extras.core.InterleavedBuffer;
import three.js.extras.core.InterleavedBufferAttribute;
import three.js.extras.core.TriangleFanDrawMode;
import three.js.extras.core.TriangleStripDrawMode;
import three.js.extras.core.TrianglesDrawMode;
import three.js.extras.math.Vector3;

function computeMikkTSpaceTangents(geometry:BufferGeometry, MikkTSpace:Dynamic, negateSign:Bool = true):BufferGeometry {
  if (!MikkTSpace || !MikkTSpace.isReady) {
    throw new Error("BufferGeometryUtils: Initialized MikkTSpace library required.");
  }
  if (!geometry.hasAttribute("position") || !geometry.hasAttribute("normal") || !geometry.hasAttribute("uv")) {
    throw new Error("BufferGeometryUtils: Tangents require 'position', 'normal', and 'uv' attributes.");
  }
  function getAttributeArray(attribute:BufferAttribute):Array<Float> {
    if (attribute.normalized || attribute.isInterleavedBufferAttribute) {
      var dstArray = new Float32Array(attribute.count * attribute.itemSize);
      for (i in 0...attribute.count) {
        dstArray[i] = attribute.getX(i);
        dstArray[i + 1] = attribute.getY(i);
        if (attribute.itemSize > 2) {
          dstArray[i + 2] = attribute.getZ(i);
        }
      }
      return dstArray;
    }
    if (attribute.array instanceof Float32Array) {
      return attribute.array;
    }
    return new Float32Array(attribute.array);
  }
  var _geometry = geometry.index ? geometry.toNonIndexed() : geometry;
  var tangents = MikkTSpace.generateTangents(getAttributeArray(_geometry.attributes.position), getAttributeArray(_geometry.attributes.normal), getAttributeArray(_geometry.attributes.uv));
  if (negateSign) {
    for (i in 3...tangents.length) {
      tangents[i] *= -1;
    }
  }
  _geometry.setAttribute("tangent", new Float32BufferAttribute(tangents, 4));
  if (geometry !== _geometry) {
    geometry.copy(_geometry);
  }
  return geometry;
}

function mergeGeometries(geometries:Array<BufferGeometry>, useGroups:Bool = false):BufferGeometry {
  var isIndexed = geometries[0].index !== null;
  var attributesUsed = new Set<String>();
  var morphAttributesUsed = new Set<String>();
  var attributes = new Map<String, Array<BufferAttribute>>();
  var morphAttributes = new Map<String, Array<BufferAttribute>>();
  var morphTargetsRelative = geometries[0].morphTargetsRelative;
  var mergedGeometry = new BufferGeometry();
  var offset = 0;
  for (i in 0...geometries.length) {
    var geometry = geometries[i];
    var attributesCount = 0;
    if (isIndexed !== (geometry.index !== null)) {
      console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index " + i + ". All geometries must have compatible attributes; make sure index attribute exists among all geometries, or in none of them.");
      return null;
    }
    for (name in geometry.attributes) {
      if (!attributesUsed.has(name)) {
        console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index " + i + ". All geometries must have compatible attributes; make sure '" + name + "' attribute exists among all geometries, or in none of them.");
        return null;
      }
      if (attributes[name] === undefined) {
        attributes[name] = [];
      }
      attributes[name].push(geometry.attributes[name]);
      attributesCount++;
    }
    if (attributesCount !== attributesUsed.size) {
      console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index " + i + ". Make sure all geometries have the same number of attributes.");
      return null;
    }
    if (morphTargetsRelative !== geometry.morphTargetsRelative) {
      console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index " + i + ". .morphTargetsRelative must be consistent throughout all geometries.");
      return null;
    }
    for (name in geometry.morphAttributes) {
      if (!morphAttributesUsed.has(name)) {
        console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index " + i + ".  .morphAttributes must be consistent throughout all geometries.");
        return null;
      }
      if (morphAttributes[name] === undefined) {
        morphAttributes[name] = [];
      }
      morphAttributes[name].push(geometry.morphAttributes[name]);
    }
    if (useGroups) {
      var count;
      if (isIndexed) {
        count = geometry.index.count;
      } else if (geometry.attributes.position !== undefined) {
        count = geometry.attributes.position.count;
      } else {
        console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index " + i + ". The geometry must have either an index or a position attribute");
        return null;
      }
      mergedGeometry.addGroup(offset, count, i);
      offset += count;
    }
  }
  // merge indices
  if (isIndexed) {
    var indexOffset = 0;
    var mergedIndex = [];
    for (i in 0...geometries.length) {
      var index = geometries[i].index;
      for (j in 0...index.count) {
        mergedIndex.push(index.getX(j) + indexOffset);
      }
      indexOffset += geometries[i].attributes.position.count;
    }
    mergedGeometry.setIndex(mergedIndex);
  }
  // merge attributes
  for (name in attributes) {
    var mergedAttribute = mergeAttributes(attributes[name]);
    if (mergedAttribute === null) {
      console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the " + name + " attribute.");
      return null;
    }
    mergedGeometry.setAttribute(name, mergedAttribute);
  }
  // merge morph attributes
  for (name in morphAttributes) {
    var numMorphTargets = morphAttributes[name][0].length;
    if (numMorphTargets === 0) {
      break;
    }
    mergedGeometry.morphAttributes = mergedGeometry.morphAttributes || {};
    mergedGeometry.morphAttributes[name] = [];
    for (i in 0...numMorphTargets) {
      var morphAttributesToMerge = [];
      for (j in 0...morphAttributes[name].length) {
        morphAttributesToMerge.push(morphAttributes[name][j][i]);
      }
      var mergedMorphAttribute = mergeAttributes(morphAttributesToMerge);
      if (mergedMorphAttribute === null) {
        console.error("THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the " + name + " morphAttribute.");
        return null;
      }
      mergedGeometry.morphAttributes[name].push(mergedMorphAttribute);
    }
  }
  return mergedGeometry;
}

function mergeAttributes(attributes:Array<BufferAttribute>):BufferAttribute {
  var TypedArray;
  var itemSize;
  var normalized;
  var gpuType = -1;
  var arrayLength = 0;
  for (i in 0...attributes.length) {
    var attribute = attributes[i];
    if (TypedArray === undefined) {
      TypedArray = attribute.array.constructor;
    }
    if (TypedArray !== attribute.array.constructor) {
      console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.array must be of consistent array types across matching attributes.");
      return null;
    }
    if (itemSize === undefined) {
      itemSize = attribute.itemSize;
    }
    if (itemSize !== attribute.itemSize) {
      console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.itemSize must be consistent across matching attributes.");
      return null;
    }
    if (normalized === undefined) {
      normalized = attribute.normalized;
    }
    if (normalized !== attribute.normalized) {
      console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.normalized must be consistent across matching attributes.");
      return null;
    }
    if (gpuType === -1) {
      gpuType = attribute.gpuType;
    }
    if (gpuType !== attribute.gpuType) {
      console.error("THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.gpuType must be consistent across matching attributes.");
      return null;
    }
    arrayLength += attribute.count * itemSize;
  }
  var array = new TypedArray(arrayLength);
  var result = new BufferAttribute(array, itemSize, normalized);
  var offset = 0;
  for (i in 0...attributes.length) {
    var attribute = attributes[i];
    if (attribute.isInterleavedBufferAttribute) {
      var tupleOffset = offset / itemSize;
      for (j in 0...attribute.count) {
        for (k in 0...itemSize) {
          var value = attribute.getComponent(j, k);
          result.setComponent(j + tupleOffset, k, value);
        }
      }
    } else {
      array.set(attribute.array, offset);
    }
    offset += attribute.count * itemSize;
  }
  if (gpuType !== undefined) {
    result.gpuType = gpuType;
  }
  return result;
}

function deepCloneAttribute(attribute:BufferAttribute):BufferAttribute {
  if (attribute.isInstancedInterleavedBufferAttribute || attribute.isInterleavedBufferAttribute) {
    return deinterleaveAttribute(attribute);
  }
  if (attribute.isInstancedBufferAttribute) {
    return new InstancedBufferAttribute().copy(attribute);
  }
  return new BufferAttribute().copy(attribute);
}

function interleaveAttributes(attributes:Array<BufferAttribute>):Array<InterleavedBufferAttribute> {
  var TypedArray;
  var arrayLength = 0;
  var stride = 0;
  for (i in 0...attributes.length) {
    var attribute = attributes[i];
    if (TypedArray === undefined) {
      TypedArray = attribute.array.constructor;
    }
    if (TypedArray !== attribute.array.constructor) {
      console.error("AttributeBuffers of different types cannot be interleaved");
      return null;
    }
    arrayLength += attribute.array.length;
    stride += attribute.itemSize;
  }
  var interleavedBuffer = new InterleavedBuffer(new TypedArray(arrayLength), stride);
  var offset = 0;
  var res = [];
  var getters = ["getX", "getY", "getZ", "getW"];
  var setters = ["setX", "setY", "setZ", "setW"];
  for (j in 0...attributes.length) {
    var attribute = attributes[j];
    var itemSize = attribute.itemSize;
    var count = attribute.count;
    var iba = new InterleavedBufferAttribute(interleavedBuffer, itemSize, offset, attribute.normalized);
    res.push(iba);
    offset += itemSize;
    for (k in 0...count) {
      for (l in 0...itemSize) {
        var getterFunc = getters[l];
        var setterFunc = setters[l];
        iba[setterFunc](k, attribute[getterFunc](k));
      }
    }
  }
  return res;
}

function deinterleaveAttribute(attribute:InterleavedBufferAttribute):BufferAttribute {
  var cons = attribute.data.array.constructor;
  var count = attribute.count;
  var itemSize = attribute.itemSize;
  var normalized = attribute.normalized;
  var array = new cons(count * itemSize);
  var newAttribute;
  if (attribute.isInstancedInterleavedBufferAttribute) {
    newAttribute = new InstancedBufferAttribute(array, itemSize, normalized, attribute.meshPerAttribute);
  } else {
    newAttribute = new BufferAttribute(array, itemSize, normalized);
  }
  for (i in 0...count) {
    newAttribute.setX(i, attribute.getX(i));
    if (itemSize >= 2) {
      newAttribute.setY(i, attribute.getY(i));
    }
    if (itemSize >= 3) {
      newAttribute.setZ(i, attribute.getZ(i));
    }
    if (itemSize >= 4) {
      newAttribute.setW(i, attribute.getW(i));
    }
  }
  return newAttribute;
}

function deinterleaveGeometry(geometry:BufferGeometry) {
  var attributes = geometry.attributes;
  var morphTargets = geometry.morphTargets;
  var attrMap = new Map<BufferAttribute, BufferAttribute>();
  for (name in attributes) {
    var attr = attributes[name];
    if (attr.isInterleavedBufferAttribute) {
      if (!attrMap.has(attr)) {
        attrMap.set(attr, deinterleaveAttribute(attr));
      }
      attributes[name] = attrMap.get(attr);
    }
  }
  for (name in morphTargets) {
    var attr = morphTargets[name];
    if (attr.isInterleavedBufferAttribute) {
      if (!attrMap.has(attr)) {
        attrMap.set(attr, deinterleaveAttribute(attr));
      }
      morphTargets[name] = attrMap.get(attr);
    }
  }
}

function estimateBytesUsed(geometry:BufferGeometry):Int {
  var mem = 0;
  for (name in geometry.attributes) {
    var attr = geometry.getAttribute(name);
    mem += attr.count * attr.itemSize * attr.array.BYTES_PER_ELEMENT;
  }
  var indices = geometry.getIndex();
  mem += indices ? indices.count * indices.itemSize * indices.array.BYTES_PER_ELEMENT : 0;
  return mem;
}

function mergeVertices(geometry:BufferGeometry, tolerance:Float = 1e-4):BufferGeometry {
  tolerance = Math.max(tolerance, Number.EPSILON);
  var hashToIndex = new Map<String, Int>();
  var indices = geometry.getIndex();
  var positions = geometry.getAttribute("position");
  var vertexCount = indices ? indices.count : positions.count;
  var nextIndex = 0;
  var attributeNames = Object.keys(geometry.attributes);
  var tmpAttributes = new Map<String, BufferAttribute>();
  var tmpMorphAttributes = new Map<String, BufferAttribute>();
  var newIndices = [];
  var getters = ["getX", "getY", "getZ", "getW"];
  var setters = ["setX", "setY", "setZ", "setW"];
  for (i in 0...attributeNames.length) {
    var name = attributeNames[i];
    var attr = geometry.attributes[name];
    tmpAttributes[name] = new BufferAttribute(new attr.array.constructor(attr.count * attr.itemSize), attr.itemSize, attr.normalized);
    var morphAttr = geometry.morphAttributes[name];
    if (morphAttr) {
      tmpMorphAttributes[name] = new BufferAttribute(new morphAttr.array.constructor(morphAttr.count * morphAttr.itemSize), morphAttr.itemSize, morphAttr.normalized);
    }
  }
  var halfTolerance = tolerance * 0.5;
  var exponent = Math.log10(1 / tolerance);
  var hashMultiplier = Math.pow(10, exponent);
  var hashAdditive = halfTolerance * hashMultiplier;
  for (i in 0...vertexCount) {
    var index = indices ? indices.getX(i) : i;
    var hash = "";
    for (j in 0...attributeNames.length) {
      var name = attributeNames[j];
      var attribute = geometry.getAttribute(name);
      var itemSize = attribute.itemSize;
      for (k in 0...itemSize) {
        hash += `${~ ~ (attribute[getters[k]](index) * hashMultiplier + hashAdditive)},`;
      }
    }
    if (hash in hashToIndex) {
      newIndices.push(hashToIndex[hash]);
    } else {
      for (j in 0...attributeNames.length) {
        var name = attributeNames[j];
        var attribute = geometry.getAttribute(name);
        var morphAttr = geometry.morphAttributes[name];
        var itemSize = attribute.itemSize;
        var count = attribute.count;
        var newarray = tmpAttributes[name];
        var newMorphArrays = tmpMorphAttributes[name];
        for (k in 0...itemSize) {
          var getterFunc = getters[k];
          var setterFunc = setters[k];
          newarray[setterFunc](nextIndex, attribute[getterFunc](index));
          if (morphAttr) {
            for (l in 0...morphAttr.length) {
              newMorphArrays[l][setterFunc](nextIndex, morphAttr[l][getterFunc](index));
            }
          }
        }
      }
      hashToIndex[hash] = nextIndex;
      newIndices.push(nextIndex);
      nextIndex++;
    }
  }
  var result = geometry.clone();
  for (name in geometry.attributes) {
    var tmpAttribute = tmpAttributes[name];
    result.setAttribute(name, new BufferAttribute(tmpAttribute.array.slice(0, nextIndex * tmpAttribute.itemSize), tmpAttribute.itemSize, tmpAttribute.normalized));
    if (!(name in tmpMorphAttributes)) {
      continue;
    }
    for (j in 0...tmpMorphAttributes[name].length) {
      var tmpMorphAttribute = tmpMorphAttributes[name][j];
      result.morphAttributes[name][j] = new BufferAttribute(tmpMorphAttribute.array.slice(0, nextIndex * tmpMorphAttribute.itemSize), tmpMorphAttribute.itemSize, tmpMorphAttribute.normalized);
    }
  }
  result.setIndex(newIndices);
  return result;
}

function toTrianglesDrawMode(geometry:BufferGeometry, drawMode:Int):BufferGeometry {
  if (drawMode === TrianglesDrawMode) {
    console.warn("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Geometry already defined as triangles.");
    return geometry;
  }
  if (drawMode === TriangleFanDrawMode || drawMode === TriangleStripDrawMode) {
    var index = geometry.getIndex();
    if (index === null) {
      var indices = [];
      var position = geometry.getAttribute("position");
      if (position !== undefined) {
        for (i in 0...position.count) {
          indices.push(i);
        }
        geometry.setIndex(indices);
        index = geometry.getIndex();
      } else {
        console.error("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Undefined position attribute. Processing not possible.");
        return geometry;
      }
    }
    var numberOfTriangles = index.count - 2;
    var newIndices = [];
    if (drawMode === TriangleFanDrawMode) {
      for (i in 1...numberOfTriangles) {
        newIndices.push(index.getX(0));
        newIndices.push(index.getX(i));
        newIndices.push(index.getX(i + 1));
      }
    } else {
      for (i in 0...numberOfTriangles) {
        if (i % 2 === 0) {
          newIndices.push(index.getX(i));
          newIndices.push(index.getX(i + 1));
          newIndices.push(index.getX(i + 2));
        } else {
          newIndices.push(index.getX(i + 2));
          newIndices.push(index.getX(i + 1));
          newIndices.push(index.getX(i));
        }
      }
    }
    if ((newIndices.length / 3) !== numberOfTriangles) {
      console.error("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Unable to generate correct amount of triangles.");
    }
    var newGeometry = geometry.clone();
    newGeometry.setIndex(newIndices);
    newGeometry.clearGroups();
    return newGeometry;
  } else {
    console.error("THREE.BufferGeometryUtils.toTrianglesDrawMode(): Unknown draw mode: " + drawMode);
    return geometry;
  }
}

function computeMorphedAttributes(object:Dynamic):Dynamic {
  var _vA = new Vector3();
  var _vB = new Vector3();
  var _vC = new Vector3();
  var _tempA = new Vector3();
  var _tempB = new Vector3();
  var _tempC = new Vector3();
  var _morphA = new Vector3();
  var _morphB = new Vector3();
  var _morphC = new Vector3();
  function _calculateMorphedAttributeData(object:Dynamic, attribute:BufferAttribute, morphAttribute:Dynamic, morphTargetsRelative:Bool, a:Int, b:Int, c:Int, modifiedAttributeArray:Array<Float>) {
    _vA.fromBufferAttribute(attribute, a);
    _vB.fromBufferAttribute(attribute, b);
    _vC.fromBufferAttribute(attribute, c);
    var morphInfluences = object.morphTargetInfluences;
    if (morphAttribute && morphInfluences) {
      _morphA.set(0, 0, 0);
      _morphB.set(0, 0, 0);
      _morphC.set(0, 0, 0);
      for (i in 0...morphAttribute.length) {
        var influence = morphInfluences[i];
        var morph = morphAttribute[i];
        if (influence === 0) {
          continue;
        }
        _tempA.fromBufferAttribute(morph, a);
        _tempB.fromBufferAttribute(morph, b);
        _tempC.fromBufferAttribute(morph, c);
        if (morphTargetsRelative) {
          _morphA.addScaledVector(
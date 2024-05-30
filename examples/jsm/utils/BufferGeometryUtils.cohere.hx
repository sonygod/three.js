import haxe.io.Bytes;
import js.Browser;
import js.html.ArrayBuffer;
import js.html.Float32Array;
import js.html.Int16Array;
import js.html.Int32Array;
import js.html.Int8Array;
import js.html.Uint16Array;
import js.html.Uint32Array;
import js.html.Uint8Array;
import js.html.Uint8ClampedArray;

function computeMikkTSpaceTangents(geometry: BufferGeometry, MikkTSpace: Dynamic, negateSign: Bool = true): BufferGeometry {
    if (!MikkTSpace || !MikkTSpace.isReady) {
        throw new Error('BufferGeometryUtils: Initialized MikkTSpace library required.');
    }

    if (!geometry.hasAttribute('position') || !geometry.hasAttribute('normal') || !geometry.hasAttribute('uv')) {
        throw new Error('BufferGeometryUtils: Tangents require "position", "normal", and "uv" attributes.');
    }

    function getAttributeArray(attribute: BufferAttribute): Float32Array {
        if (attribute.normalized || attribute.isInterleavedBufferAttribute) {
            var dstArray = new Float32Array(attribute.count * attribute.itemSize);
            var j = 0;
            for (i in 0...attribute.count) {
                dstArray[j++] = attribute.getX(i);
                dstArray[j++] = attribute.getY(i);
                if (attribute.itemSize > 2) {
                    dstArray[j++] = attribute.getZ(i);
                }
            }
            return dstArray;
        }

        if (attribute.array instanceof Float32Array) {
            return attribute.array;
        }

        return new Float32Array(attribute.array);
    }

    // MikkTSpace algorithm requires non-indexed input.
    var _geometry = geometry.index ? geometry.toNonIndexed() : geometry;

    // Compute vertex tangents.
    var tangents = MikkTSpace.generateTangents(
        getAttributeArray(_geometry.attributes.position),
        getAttributeArray(_geometry.attributes.normal),
        getAttributeArray(_geometry.attributes.uv)
    );

    // Texture coordinate convention of glTF differs from the apparent
    // default of the MikkTSpace library; .w component must be flipped.
    if (negateSign) {
        for (i in 3...tangents.length) {
            tangents[i] *= -1;
        }
    }

    //
    _geometry.setAttribute('tangent', new BufferAttribute(tangents, 4));

    if (geometry != _geometry) {
        geometry.copy(_geometry);
    }

    return geometry;
}

/**
 * @param geometries Array<BufferGeometry>
 * @param useGroups Bool
 * @return BufferGeometry
 */
function mergeGeometries(geometries: Array<BufferGeometry>, useGroups: Bool = false): BufferGeometry {
    var isIndexed = geometries[0].index != null;

    var attributesUsed = new Set<String>(geometries[0].attributes.keys());
    var morphAttributesUsed = new Set<String>(geometries[0].morphAttributes.keys());

    var attributes = {};
    var morphAttributes = {};

    var morphTargetsRelative = geometries[0].morphTargetsRelative;

    var mergedGeometry = new BufferGeometry();

    var offset = 0;

    for (i in 0...geometries.length) {
        var geometry = geometries[i];
        var attributesCount = 0;

        // ensure that all geometries are indexed, or none
        if (isIndexed != (geometry.index != null)) {
            trace('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '. All geometries must have compatible attributes; make sure index attribute exists among all geometries, or in none of them.');
            return null;
        }

        // gather attributes, exit early if they're different
        for (name in geometry.attributes.keys()) {
            if (!attributesUsed.has(name)) {
                trace('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '. All geometries must have compatible attributes; make sure "' + name + '" attribute exists among all geometries, or in none of them.');
                return null;
            }

            if (!attributes.hasOwnProperty(name)) {
                attributes[name] = [];
            }

            attributes[name].push(geometry.attributes[name]);

            attributesCount++;
        }

        // ensure geometries have the same number of attributes
        if (attributesCount != attributesUsed.size) {
            trace('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '. Make sure all geometries have the same number of attributes.');
            return null;
        }

        // gather morph attributes, exit early if they're different
        if (morphTargetsRelative != geometry.morphTargetsRelative) {
            trace('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '. .morphTargetsRelative must be consistent throughout all geometries.');
            return null;
        }

        for (name in geometry.morphAttributes.keys()) {
            if (!morphAttributesUsed.has(name)) {
                trace('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '.  .morphAttributes must be consistent throughout all geometries.');
                return null;
            }

            if (!morphAttributes.hasOwnProperty(name)) {
                morphAttributes[name] = [];
            }

            morphAttributes[name].push(geometry.morphAttributes[name]);
        }

        if (useGroups) {
            var count: Int;

            if (isIndexed) {
                count = geometry.index.count;
            } else if (geometry.attributes.hasOwnProperty('position')) {
                count = geometry.attributes['position'].count;
            } else {
                trace('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '. The geometry must have either an index or a position attribute');
                return null;
            }

            mergedGeometry.addGroup(offset, count, i);

            offset += count;
        }
    }

    // merge indices
    if (isIndexed) {
        var indexOffset = 0;
        var mergedIndex: Array<Int> = [];

        for (i in 0...geometries.length) {
            var index = geometries[i].index;

            for (j in 0...index.count) {
                mergedIndex.push(index.getX(j) + indexOffset);
            }

            indexOffset += geometries[i].attributes['position'].count;
        }

        mergedGeometry.setIndex(mergedIndex);
    }

    // merge attributes
    for (name in attributes.keys()) {
        var mergedAttribute = mergeAttributes(attributes[name]);

        if (!mergedAttribute) {
            trace('THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the ' + name + ' attribute.');
            return null;
        }

        mergedGeometry.setAttribute(name, mergedAttribute);
    }

    // merge morph attributes
    for (name in morphAttributes.keys()) {
        var numMorphTargets = morphAttributes[name][0].length;

        if (numMorphTargets == 0) {
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

            if (!mergedMorphAttribute) {
                trace('THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the ' + name + ' morphAttribute.');
                return null;
            }

            mergedGeometry.morphAttributes[name].push(mergedMorphAttribute);
        }
    }

    return mergedGeometry;
}

/**
 * @param attributes Array<BufferAttribute>
 * @return BufferAttribute
 */
function mergeAttributes(attributes: Array<BufferAttribute>): BufferAttribute {
    var TypedArray: Dynamic;
    var itemSize: Int;
    var normalized: Bool;
    var gpuType = -1;
    var arrayLength = 0;

    for (i in 0...attributes.length) {
        var attribute = attributes[i];

        if (TypedArray == null) {
            TypedArray = attribute.array.constructor;
        }
        if (TypedArray != attribute.array.constructor) {
            trace('THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.array must be of consistent array types across matching attributes.');
            return null;
        }

        if (itemSize == null) {
            itemSize = attribute.itemSize;
        }
        if (itemSize != attribute.itemSize) {
            trace('THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.itemSize must be consistent across matching attributes.');
            return null;
        }

        if (normalized == null) {
            normalized = attribute.normalized;
        }
        if (normalized != attribute.normalized) {
            trace('THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.normalized must be consistent across matching attributes.');
            return null;
        }

        if (gpuType == -1) {
            gpuType = attribute.gpuType;
        }
        if (gpuType != attribute.gpuType) {
            trace('THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.gpuType must be consistent across matching attributes.');
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
                for (c in 0...itemSize) {
                    var value = attribute.getComponent(j, c);
                    result.setComponent(j + tupleOffset, c, value);
                }
            }
        } else {
            array.set(attribute.array, offset);
        }

        offset += attribute.count * itemSize;
    }

    if (gpuType != -1) {
        result.gpuType = gpuType;
    }

    return result;
}

/**
 * @param attribute BufferAttribute
 * @return BufferAttribute
 */
function deepCloneAttribute(attribute: BufferAttribute): BufferAttribute {
    if (attribute.isInstancedInterleavedBufferAttribute || attribute.isInterleavedBufferAttribute) {
        return deinterleaveAttribute(attribute);
    }

    if (attribute.isInstancedBufferAttribute) {
        return new InstancedBufferAttribute().copy(attribute);
    }

    return new BufferAttribute().copy(attribute);
}

/**
 * @param attributes Array<BufferAttribute>
 * @return Array<InterleavedBufferAttribute>
 */
function interleaveAttributes(attributes: Array<BufferAttribute>): Array<InterleavedBufferAttribute> {
    // Interleaves the provided attributes into an InterleavedBuffer and returns
    // a set of InterleavedBufferAttributes for each attribute
    var TypedArray: Dynamic;
    var arrayLength = 0;
    var stride = 0;

    // calculate the length and type of the interleavedBuffer
    for (i in 0...attributes.length) {
        var attribute = attributes[i];

        if (TypedArray == null) {
            TypedArray = attribute.array.constructor;
        }
        if (TypedArray != attribute.array.constructor) {
            trace('AttributeBuffers of different types cannot be interleaved');
            return null;
        }

        arrayLength += attribute.array.length;
        stride += attribute.itemSize;
    }

    // Create the set of buffer attributes
    var interleavedBuffer = new InterleavedBuffer(new TypedArray(arrayLength), stride);
    var offset = 0;
    var res = [];
    var getters = ['getX', 'getY', 'getZ', 'getW'];
    var setters = ['setX', 'setY', 'setZ', 'setW'];

    for (j in 0...attributes.length) {
        var attribute = attributes[j];
        var itemSize = attribute.itemSize;
        var count = attribute.count;
        var iba = new InterleavedBufferAttribute(interleavedBuffer, itemSize, offset, attribute.normalized);
        res.push(iba);

        offset += itemSize;

        // Move the data for each attribute into the new interleavedBuffer
        // at the appropriate offset
        for (c in 0...count) {
            for (k in 0...itemSize) {
                var getterFunc = getters[k];
                var setterFunc = setters[k];
                iba[setterFunc](c, attribute[getterFunc](c));
            }
        }
    }

    return res;
}

// returns a new, non-interleaved version of the provided attribute
function deinterleaveAttribute(attribute: BufferAttribute): BufferAttribute {
    var cons = attribute.data.array.constructor;
    var count = attribute.count;
    var itemSize = attribute.itemSize;
    var normalized = attribute.normalized;

    var array = new cons(count * itemSize);
    var newAttribute: BufferAttribute;
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

// deinterleaves all attributes on the geometry
function deinterleaveGeometry(geometry: BufferGeometry) {
    var attributes = geometry.attributes;
    var morphTargets = geometry.morphTargets;
    var attrMap = new Map();

    for (key in attributes.keys()) {
        var attr = attributes[key];
        if (attr.isInterleavedBufferAttribute) {
            if (!attrMap.has(attr)) {
                attrMap.set(attr, deinterleaveAttribute(attr));
            }

            attributes[key] = attrMap.get(attr);
        }
    }

    for (key in morphTargets.keys()) {
        var attr = morphTargets[key];
        if (attr.isInterleavedBufferAttribute) {
            if (!attrMap.has(attr)) {
                attrMap.set(attr, deinterleaveAttribute(attr));
            }

            morphTargets[key] = attrMap.get(attr);
        }
    }
}

/**
 * @param geometry BufferGeometry
 * @return Int
 */
function estimateBytesUsed(geometry: BufferGeometry): Int {
    // Return the estimated memory used by this geometry in bytes
    // Calculate using itemSize, count, and BYTES_PER_ELEMENT to account
    // for InterleavedBufferAttributes.
    var mem = 0;
    for (name in geometry.attributes.keys()) {
        var attr = geometry.getAttribute(name);
        mem += attr.count * attr.itemSize * attr.array.BYTES_PER_ELEMENT;
    }

    var indices = geometry.getIndex();
    mem += indices ? indices.count * indices.itemSize * indices.array.BYTES_PER_ELEMENT : 0;
    return mem;
}

/**
 * @param geometry BufferGeometry
 * @param tolerance Float
 * @return BufferGeometry
 */
function mergeVertices(geometry: BufferGeometry, tolerance: Float = 1e-4): BufferGeometry {
    tolerance = Math.max(tolerance, Number.EPSILON);

    // Generate an index buffer if the geometry doesn't have one, or optimize it
    // if it's already available.
    var hashToIndex = new Map<String, Int>();
    var indices = geometry.getIndex();
    var positions = geometry.getAttribute('position');
    var vertexCount = indices ? indices.count : positions.count;

    // next value for triangle indices
    var nextIndex = 0;

    // attributes and new attribute arrays
    var attributeNames = geometry.attributes.keys();
    var tmpAttributes = {};
    var tmpMorphAttributes = {};
    var newIndices = [];
    var getters = ['getX', 'getY', 'getZ', 'getW'];
    var setters = ['setX', 'setY', 'setZ', 'setW'];

    // Initialize the arrays, allocating space conservatively. Extra
    // space will be trimmed in the last step.
    for (i in 0...attributeNames.length) {
        var name = attributeNames[i];
        var attr = geometry.attributes[name];

        tmpAttributes[name] = new BufferAttribute(
            new attr.array.constructor(attr.count * attr.itemSize),
            attr.itemSize,
            attr.normalized
        );

        var morphAttr = geometry.morphAttributes[name];
        if (morphAttr) {
            tmpMorphAttributes[name] = new BufferAttribute(
                new morphAttr.array.constructor(morphAttr.count * morphAttr.itemSize),
                morphAttr.itemSize,
                morphAttr.normalized
            );
        }
    }

    // convert the error tolerance to an amount of decimal places to truncate to
    var halfTolerance = tolerance * 0.5;
    var exponent = Math.log10(1 / tolerance);
    var hashMultiplier = Math.pow(10, exponent);
    var hashAdditive = halfTolerance * hashMultiplier;
    for (i in 0...vertexCount) {
        var index = indices ? indices.getX(i) : i;

        // Generate a hash for the vertex attributes at the current index 'i'
        var hash = '';
        for (j in 0...attributeNames.length) {
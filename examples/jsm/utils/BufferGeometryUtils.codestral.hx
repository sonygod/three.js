import three.BufferAttribute;
import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.InstancedBufferAttribute;
import three.InterleavedBuffer;
import three.InterleavedBufferAttribute;
import three.TriangleFanDrawMode;
import three.TriangleStripDrawMode;
import three.TrianglesDrawMode;
import three.Vector3;

class BufferGeometryUtils {
    static function computeMikkTSpaceTangents(geometry: BufferGeometry, MikkTSpace: any, negateSign: Bool = true): BufferGeometry {
        if (!MikkTSpace || !MikkTSpace.isReady) throw new Error('BufferGeometryUtils: Initialized MikkTSpace library required.');
        if (!geometry.hasAttribute('position') || !geometry.hasAttribute('normal') || !geometry.hasAttribute('uv')) throw new Error('BufferGeometryUtils: Tangents require "position", "normal", and "uv" attributes.');

        function getAttributeArray(attribute: BufferAttribute): Float32Array {
            if (attribute.normalized || attribute.isInterleavedBufferAttribute) {
                var dstArray = new Float32Array(attribute.count * attribute.itemSize);
                for (var i = 0, j = 0; i < attribute.count; i++) {
                    dstArray[j++] = attribute.getX(i);
                    dstArray[j++] = attribute.getY(i);
                    if (attribute.itemSize > 2) dstArray[j++] = attribute.getZ(i);
                }
                return dstArray;
            }
            if (Std.is(attribute.array, Float32Array)) return attribute.array;
            return new Float32Array(attribute.array);
        }

        var _geometry = geometry.index ? geometry.toNonIndexed() : geometry;

        var tangents = MikkTSpace.generateTangents(
            getAttributeArray(_geometry.attributes.position),
            getAttributeArray(_geometry.attributes.normal),
            getAttributeArray(_geometry.attributes.uv)
        );

        if (negateSign) {
            for (var i = 3; i < tangents.length; i += 4) tangents[i] *= -1;
        }

        _geometry.setAttribute('tangent', new BufferAttribute(tangents, 4));

        if (geometry !== _geometry) geometry.copy(_geometry);

        return geometry;
    }

    static function mergeGeometries(geometries: Array<BufferGeometry>, useGroups: Bool = false): BufferGeometry {
        var isIndexed = geometries[0].index !== null;
        var attributesUsed = new haxe.ds.StringMap<Bool>();
        var morphAttributesUsed = new haxe.ds.StringMap<Bool>();
        var attributes = new haxe.ds.StringMap<Array<BufferAttribute>>();
        var morphAttributes = new haxe.ds.StringMap<Array<Array<BufferAttribute>>>();
        var morphTargetsRelative = geometries[0].morphTargetsRelative;
        var mergedGeometry = new BufferGeometry();
        var offset = 0;

        for (var i = 0; i < geometries.length; ++i) {
            var geometry = geometries[i];
            var attributesCount = 0;

            if (isIndexed !== (geometry.index !== null)) {
                console.error('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '. All geometries must have compatible attributes; make sure index attribute exists among all geometries, or in none of them.');
                return null;
            }

            for (var name in geometry.attributes.h) {
                if (!attributesUsed.exists(name)) {
                    console.error('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '. All geometries must have compatible attributes; make sure "' + name + '" attribute exists among all geometries, or in none of them.');
                    return null;
                }

                if (!attributes.exists(name)) attributes.set(name, []);

                attributes.get(name).push(geometry.attributes.get(name));
                attributesCount++;
            }

            if (attributesCount !== attributesUsed.size) {
                console.error('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '. Make sure all geometries have the same number of attributes.');
                return null;
            }

            if (morphTargetsRelative !== geometry.morphTargetsRelative) {
                console.error('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '. .morphTargetsRelative must be consistent throughout all geometries.');
                return null;
            }

            for (var name in geometry.morphAttributes.h) {
                if (!morphAttributesUsed.exists(name)) {
                    console.error('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '.  .morphAttributes must be consistent throughout all geometries.');
                    return null;
                }

                if (!morphAttributes.exists(name)) morphAttributes.set(name, []);

                morphAttributes.get(name).push(geometry.morphAttributes.get(name));
            }

            if (useGroups) {
                var count;

                if (isIndexed) {
                    count = geometry.index.count;
                } else if (geometry.attributes.exists('position')) {
                    count = geometry.attributes.get('position').count;
                } else {
                    console.error('THREE.BufferGeometryUtils: .mergeGeometries() failed with geometry at index ' + i + '. The geometry must have either an index or a position attribute');
                    return null;
                }

                mergedGeometry.addGroup(offset, count, i);
                offset += count;
            }
        }

        if (isIndexed) {
            var indexOffset = 0;
            var mergedIndex = new Array<Int>();

            for (var i = 0; i < geometries.length; ++i) {
                var index = geometries[i].index;

                for (var j = 0; j < index.count; ++j) {
                    mergedIndex.push(index.getX(j) + indexOffset);
                }

                indexOffset += geometries[i].attributes.get('position').count;
            }

            mergedGeometry.setIndex(mergedIndex);
        }

        for (var name in attributes.h) {
            var mergedAttribute = mergeAttributes(attributes.get(name));

            if (!mergedAttribute) {
                console.error('THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the ' + name + ' attribute.');
                return null;
            }

            mergedGeometry.setAttribute(name, mergedAttribute);
        }

        for (var name in morphAttributes.h) {
            var numMorphTargets = morphAttributes.get(name)[0].length;

            if (numMorphTargets === 0) break;

            mergedGeometry.morphAttributes = mergedGeometry.morphAttributes || {};
            mergedGeometry.morphAttributes[name] = [];

            for (var i = 0; i < numMorphTargets; ++i) {
                var morphAttributesToMerge = new Array<BufferAttribute>();

                for (var j = 0; j < morphAttributes.get(name).length; ++j) {
                    morphAttributesToMerge.push(morphAttributes.get(name)[j][i]);
                }

                var mergedMorphAttribute = mergeAttributes(morphAttributesToMerge);

                if (!mergedMorphAttribute) {
                    console.error('THREE.BufferGeometryUtils: .mergeGeometries() failed while trying to merge the ' + name + ' morphAttribute.');
                    return null;
                }

                mergedGeometry.morphAttributes[name].push(mergedMorphAttribute);
            }
        }

        return mergedGeometry;
    }

    static function mergeAttributes(attributes: Array<BufferAttribute>): BufferAttribute {
        var TypedArray;
        var itemSize;
        var normalized;
        var gpuType = -1;
        var arrayLength = 0;

        for (var i = 0; i < attributes.length; ++i) {
            var attribute = attributes[i];

            if (TypedArray === null) TypedArray = Type.getClass(attribute.array);
            if (Type.getClass(attribute.array) !== TypedArray) {
                console.error('THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.array must be of consistent array types across matching attributes.');
                return null;
            }

            if (itemSize === null) itemSize = attribute.itemSize;
            if (itemSize !== attribute.itemSize) {
                console.error('THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.itemSize must be consistent across matching attributes.');
                return null;
            }

            if (normalized === null) normalized = attribute.normalized;
            if (normalized !== attribute.normalized) {
                console.error('THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.normalized must be consistent across matching attributes.');
                return null;
            }

            if (gpuType === -1) gpuType = attribute.gpuType;
            if (gpuType !== attribute.gpuType) {
                console.error('THREE.BufferGeometryUtils: .mergeAttributes() failed. BufferAttribute.gpuType must be consistent across matching attributes.');
                return null;
            }

            arrayLength += attribute.count * itemSize;
        }

        var array = Type.createEmptyInstance(TypedArray, [arrayLength]);
        var result = new BufferAttribute(array, itemSize, normalized);
        var offset = 0;

        for (var i = 0; i < attributes.length; ++i) {
            var attribute = attributes[i];
            if (attribute.isInterleavedBufferAttribute) {
                var tupleOffset = offset / itemSize;
                for (var j = 0, l = attribute.count; j < l; j++) {
                    for (var c = 0; c < itemSize; c++) {
                        var value = attribute.getComponent(j, c);
                        result.setComponent(j + tupleOffset, c, value);
                    }
                }
            } else {
                array.set(attribute.array, offset);
            }

            offset += attribute.count * itemSize;
        }

        if (gpuType !== null) result.gpuType = gpuType;

        return result;
    }

    static function deepCloneAttribute(attribute: BufferAttribute): BufferAttribute {
        if (attribute.isInstancedInterleavedBufferAttribute || attribute.isInterleavedBufferAttribute) {
            return deinterleaveAttribute(attribute);
        }

        if (attribute.isInstancedBufferAttribute) {
            return new InstancedBufferAttribute().copy(attribute);
        }

        return new BufferAttribute().copy(attribute);
    }

    static function interleaveAttributes(attributes: Array<BufferAttribute>): Array<InterleavedBufferAttribute> {
        var TypedArray;
        var arrayLength = 0;
        var stride = 0;

        for (var i = 0, l = attributes.length; i < l; ++i) {
            var attribute = attributes[i];

            if (TypedArray === null) TypedArray = Type.getClass(attribute.array);
            if (Type.getClass(attribute.array) !== TypedArray) {
                console.error('AttributeBuffers of different types cannot be interleaved');
                return null;
            }

            arrayLength += attribute.array.length;
            stride += attribute.itemSize;
        }

        var interleavedBuffer = new InterleavedBuffer(Type.createEmptyInstance(TypedArray, [arrayLength]), stride);
        var offset = 0;
        var res = new Array<InterleavedBufferAttribute>();
        var getters = ['getX', 'getY', 'getZ', 'getW'];
        var setters = ['setX', 'setY', 'setZ', 'setW'];

        for (var j = 0, l = attributes.length; j < l; j++) {
            var attribute = attributes[j];
            var itemSize = attribute.itemSize;
            var count = attribute.count;
            var iba = new InterleavedBufferAttribute(interleavedBuffer, itemSize, offset, attribute.normalized);
            res.push(iba);

            offset += itemSize;

            for (var c = 0; c < count; c++) {
                for (var k = 0; k < itemSize; k++) {
                    iba.setComponent(c, k, attribute.getComponent(c, k));
                }
            }
        }

        return res;
    }

    static function deinterleaveAttribute(attribute: InterleavedBufferAttribute): BufferAttribute {
        var cons = Type.getClass(attribute.data.array);
        var count = attribute.count;
        var itemSize = attribute.itemSize;
        var normalized = attribute.normalized;

        var array = Type.createEmptyInstance(cons, [count * itemSize]);
        var newAttribute;
        if (attribute.isInstancedInterleavedBufferAttribute) {
            newAttribute = new InstancedBufferAttribute(array, itemSize, normalized, attribute.meshPerAttribute);
        } else {
            newAttribute = new BufferAttribute(array, itemSize, normalized);
        }

        for (var i = 0; i < count; i++) {
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

    static function deinterleaveGeometry(geometry: BufferGeometry): Void {
        var attributes = geometry.attributes;
        var morphTargets = geometry.morphTargets;
        var attrMap = new haxe.ds.ObjectMap<InterleavedBufferAttribute, BufferAttribute>();

        for (var key in attributes.h) {
            var attr = attributes.get(key);
            if (attr.isInterleavedBufferAttribute) {
                if (!attrMap.exists(attr)) {
                    attrMap.set(attr, deinterleaveAttribute(attr));
                }

                attributes.set(key, attrMap.get(attr));
            }
        }

        for (var key in morphTargets.h) {
            var attr = morphTargets.get(key);
            if (attr.isInterleavedBufferAttribute) {
                if (!attrMap.exists(attr)) {
                    attrMap.set(attr, deinterleaveAttribute(attr));
                }

                morphTargets.set(key, attrMap.get(attr));
            }
        }
    }

    static function estimateBytesUsed(geometry: BufferGeometry): Int {
        var mem = 0;
        for (var name in geometry.attributes.h) {
            var attr = geometry.getAttribute(name);
            mem += attr.count * attr.itemSize * attr.array.BYTES_PER_ELEMENT;
        }

        var indices = geometry.getIndex();
        mem += indices ? indices.count * indices.itemSize * indices.array.BYTES_PER_ELEMENT : 0;
        return mem;
    }

    static function mergeVertices(geometry: BufferGeometry, tolerance: Float = 1e-4): BufferGeometry {
        tolerance = Math.max(tolerance, Number.EPSILON);

        var hashToIndex = new haxe.ds.StringMap<Int>();
        var indices = geometry.getIndex();
        var positions = geometry.getAttribute('position');
        var vertexCount = indices ? indices.count : positions.count;

        var nextIndex = 0;

        var attributeNames = Reflect.fields(geometry.attributes.h);
        var tmpAttributes = new haxe.ds.StringMap<BufferAttribute>();
        var tmpMorphAttributes = new haxe.ds.StringMap<BufferAttribute>();
        var newIndices = new Array<Int>();
        var getters = ['getX', 'getY', 'getZ', 'getW'];
        var setters = ['setX', 'setY', 'setZ', 'setW'];

        for (var i = 0, l = attributeNames.length; i < l; i++) {
            var name = attributeNames[i];
            var attr = geometry.attributes.get(name);

            tmpAttributes.set(name, new BufferAttribute(
                Type.createEmptyInstance(Type.getClass(attr.array), [attr.count * attr.itemSize]),
                attr.itemSize,
                attr.normalized
            ));

            var morphAttr = geometry.morphAttributes.get(name);
            if (morphAttr) {
                tmpMorphAttributes.set(name, new BufferAttribute(
                    Type.createEmptyInstance(Type.getClass(morphAttr.array), [morphAttr.count * morphAttr.itemSize]),
                    morphAttr.itemSize,
                    morphAttr.normalized
                ));
            }
        }

        var halfTolerance = tolerance * 0.5;
        var exponent = Math.log10(1 / tolerance);
        var hashMultiplier = Math.pow(10, exponent);
        var hashAdditive = halfTolerance * hashMultiplier;
        for (var i = 0; i < vertexCount; i++) {
            var index = indices ? indices.getX(i) : i;

            var hash = '';
            for (var j = 0, l = attributeNames.length; j < l; j++) {
                var name = attributeNames[j];
                var attribute = geometry.getAttribute(name);
                var itemSize = attribute.itemSize;

                for (var k = 0; k < itemSize; k++) {
                    hash += ~~(attribute.getComponent(index, k) * hashMultiplier + hashAdditive) + ',';
                }
            }

            if (hashToIndex.exists(hash)) {
                newIndices.push(hashToIndex.get(hash));
            } else {
                for (var j = 0, l = attributeNames.length; j < l; j++) {
                    var name = attributeNames[j];
                    var attribute = geometry.getAttribute(name);
                    var morphAttr = geometry.morphAttributes.get(name);
                    var itemSize = attribute.itemSize;
                    var newarray = tmpAttributes.get(name);
                    var newMorphArrays = tmpMorphAttributes.get(name);

                    for (var k = 0; k < itemSize; k++) {
                        var getterFunc = getters[k];
                        var setterFunc = setters[k];
                        newarray.setComponent(nextIndex, k, attribute.getComponent(index, k));

                        if (morphAttr) {
                            for (var m = 0, ml = morphAttr.length; m < ml; m++) {
                                newMorphArrays[m].setComponent(nextIndex, k, morphAttr[m].getComponent(index, k));
                            }
                        }
                    }
                }

                hashToIndex.set(hash, nextIndex);
                newIndices.push(nextIndex);
                nextIndex++;
            }
        }

        var result = geometry.clone();
        for (var name in geometry.attributes.h) {
            var tmpAttribute = tmpAttributes.get(name);

            result.setAttribute(name, new BufferAttribute(
                tmpAttribute.array.slice(0, nextIndex * tmpAttribute.itemSize),
                tmpAttribute.itemSize,
                tmpAttribute.normalized,
            ));

            if (!tmpMorphAttributes.exists(name)) continue;

            for (var j = 0; j < tmpMorphAttributes.get(name).length; j++) {
                var tmpMorphAttribute = tmpMorphAttributes.get(name)[j];

                result.morphAttributes.set(name, [new BufferAttribute(
                    tmpMorphAttribute.array.slice(0, nextIndex * tmpMorphAttribute.itemSize),
                    tmpMorphAttribute.itemSize,
                    tmpMorphAttribute.normalized,
                )]);
            }
        }

        result.setIndex(newIndices);

        return result;
    }

    static function toTrianglesDrawMode(geometry: BufferGeometry, drawMode: Int): BufferGeometry {
        if (drawMode === TrianglesDrawMode) {
            console.warn('THREE.BufferGeometryUtils.toTrianglesDrawMode(): Geometry already defined as triangles.');
            return geometry;
        }

        if (drawMode === TriangleFanDrawMode || drawMode === TriangleStripDrawMode) {
            var index = geometry.getIndex();

            if (index === null) {
                var indices = new Array<Int>();

                var position = geometry.getAttribute('position');

                if (position !== null) {
                    for (var i = 0; i < position.count; i++) {
                        indices.push(i);
                    }

                    geometry.setIndex(indices);
                    index = geometry.getIndex();
                } else {
                    console.error('THREE.BufferGeometryUtils.toTrianglesDrawMode(): Undefined position attribute. Processing not possible.');
                    return geometry;
                }
            }

            var numberOfTriangles = index.count - 2;
            var newIndices = new Array<Int>();

            if (drawMode === TriangleFanDrawMode) {
                for (var i = 1; i <= numberOfTriangles; i++) {
                    newIndices.push(index.getX(0));
                    newIndices.push(index.getX(i));
                    newIndices.push(index.getX(i + 1));
                }
            } else {
                for (var i = 0; i < numberOfTriangles; i++) {
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
                console.error('THREE.BufferGeometryUtils.toTrianglesDrawMode(): Unable to generate correct amount of triangles.');
            }

            var newGeometry = geometry.clone();
            newGeometry.setIndex(newIndices);
            newGeometry.clearGroups();

            return newGeometry;
        } else {
            console.error('THREE.BufferGeometryUtils.toTrianglesDrawMode(): Unknown draw mode:', drawMode);
            return geometry;
        }
    }

    static function computeMorphedAttributes(object: any): Dynamic {
        var _vA = new Vector3();
        var _vB = new Vector3();
        var _vC = new Vector3();

        var _tempA = new Vector3();
        var _tempB = new Vector3();
        var _tempC = new Vector3();

        var _morphA = new Vector3();
        var _morphB = new Vector3();
        var _morphC = new Vector3();

        function _calculateMorphedAttributeData(
            object,
            attribute: BufferAttribute,
            morphAttribute: Array<BufferAttribute>,
            morphTargetsRelative: Bool,
            a: Int,
            b: Int,
            c: Int,
            modifiedAttributeArray: Float32Array
        ): Void {
            _vA.fromBufferAttribute(attribute, a);
            _vB.fromBufferAttribute(attribute, b);
            _vC.fromBufferAttribute(attribute, c);

            var morphInfluences = object.morphTargetInfluences;

            if (morphAttribute && morphInfluences) {
                _morphA.set(0, 0, 0);
                _morphB.set(0, 0, 0);
                _morphC.set(0, 0, 0);

                for (var i = 0, il = morphAttribute.length; i < il; i++) {
                    var influence = morphInfluences[i];
                    var morph = morphAttribute[i];

                    if (influence === 0) continue;

                    _tempA.fromBufferAttribute(morph, a);
                    _tempB.fromBufferAttribute(morph, b);
                    _tempC.fromBufferAttribute(morph, c);

                    if (morphTargetsRelative) {
                        _morphA.addScaledVector(_tempA, influence);
                        _morphB.addScaledVector(_tempB, influence);
                        _morphC.addScaledVector(_tempC, influence);
                    } else {
                        _morphA.addScaledVector(_tempA.sub(_vA), influence);
                        _morphB.addScaledVector(_tempB.sub(_vB), influence);
                        _morphC.addScaledVector(_tempC.sub(_vC), influence);
                    }
                }

                _vA.add(_morphA);
                _vB.add(_morphB);
                _vC.add(_morphC);
            }

            if (object.isSkinnedMesh) {
                object.applyBoneTransform(a, _vA);
                object.applyBoneTransform(b, _vB);
                object.applyBoneTransform(c, _vC);
            }

            modifiedAttributeArray[a * 3 + 0] = _vA.x;
            modifiedAttributeArray[a * 3 + 1] = _vA.y;
            modifiedAttributeArray[a * 3 + 2] = _vA.z;
            modifiedAttributeArray[b * 3 + 0] = _vB.x;
            modifiedAttributeArray[b * 3 + 1] = _vB.y;
            modifiedAttributeArray[b * 3 + 2] = _vB.z;
            modifiedAttributeArray[c * 3 + 0] = _vC.x;
            modifiedAttributeArray[c * 3 + 1] = _vC.y;
            modifiedAttributeArray[c * 3 + 2] = _vC.z;
        }

        var geometry = object.geometry;
        var material = object.material;

        var a, b, c;
        var index = geometry.index;
        var positionAttribute = geometry.attributes.get('position');
        var morphPosition = geometry.morphAttributes.get('position');
        var morphTargetsRelative = geometry.morphTargetsRelative;
        var normalAttribute = geometry.attributes.get('normal');
        var morphNormal = geometry.morphAttributes.get('position');

        var groups = geometry.groups;
        var drawRange = geometry.drawRange;
        var i, j, il, jl;
        var group;
        var start, end;

        var modifiedPosition = new Float32Array(positionAttribute.count * positionAttribute.itemSize);
        var modifiedNormal = new Float32Array(normalAttribute.count * normalAttribute.itemSize);

        if (index !== null) {
            if (Std.is(material, Array)) {
                for (i = 0, il = groups.length; i < il; i++) {
                    group = groups[i];

                    start = Math.max(group.start, drawRange.start);
                    end = Math.min((group.start + group.count), (drawRange.start + drawRange.count));

                    for (j = start, jl = end; j < jl; j += 3) {
                        a = index.getX(j);
                        b = index.getX(j + 1);
                        c = index.getX(j + 2);

                        _calculateMorphedAttributeData(
                            object,
                            positionAttribute,
                            morphPosition,
                            morphTargetsRelative,
                            a, b, c,
                            modifiedPosition
                        );

                        _calculateMorphedAttributeData(
                            object,
                            normalAttribute,
                            morphNormal,
                            morphTargetsRelative,
                            a, b, c,
                            modifiedNormal
                        );
                    }
                }
            } else {
                start = Math.max(0, drawRange.start);
                end = Math.min(index.count, (drawRange.start + drawRange.count));

                for (i = start, il = end; i < il; i += 3) {
                    a = index.getX(i);
                    b = index.getX(i + 1);
                    c = index.getX(i + 2);

                    _calculateMorphedAttributeData(
                        object,
                        positionAttribute,
                        morphPosition,
                        morphTargetsRelative,
                        a, b, c,
                        modifiedPosition
                    );

                    _calculateMorphedAttributeData(
                        object,
                        normalAttribute,
                        morphNormal,
                        morphTargetsRelative,
                        a, b, c,
                        modifiedNormal
                    );
                }
            }
        } else {
            if (Std.is(material, Array)) {
                for (i = 0, il = groups.length; i < il; i++) {
                    group = groups[i];

                    start = Math.max(group.start, drawRange.start);
                    end = Math.min((group.start + group.count), (drawRange.start + drawRange.count));

                    for (j = start, jl = end; j < jl; j += 3) {
                        a = j;
                        b = j + 1;
                        c = j + 2;

                        _calculateMorphedAttributeData(
                            object,
                            positionAttribute,
                            morphPosition,
                            morphTargetsRelative,
                            a, b, c,
                            modifiedPosition
                        );

                        _calculateMorphedAttributeData(
                            object,
                            normalAttribute,
                            morphNormal,
                            morphTargetsRelative,
                            a, b, c,
                            modifiedNormal
                        );
                    }
                }
            } else {
                start = Math.max(0, drawRange.start);
                end = Math.min(positionAttribute.count, (drawRange.start + drawRange.count));

                for (i = start, il = end; i < il; i += 3) {
                    a = i;
                    b = i + 1;
                    c = i + 2;

                    _calculateMorphedAttributeData(
                        object,
                        positionAttribute,
                        morphPosition,
                        morphTargetsRelative,
                        a, b, c,
                        modifiedPosition
                    );

                    _calculateMorphedAttributeData(
                        object,
                        normalAttribute,
                        morphNormal,
                        morphTargetsRelative,
                        a, b, c,
                        modifiedNormal
                    );
                }
            }
        }

        var morphedPositionAttribute = new Float32BufferAttribute(modifiedPosition, 3);
        var morphedNormalAttribute = new Float32BufferAttribute(modifiedNormal, 3);

        return {
            positionAttribute: positionAttribute,
            normalAttribute: normalAttribute,
            morphedPositionAttribute: morphedPositionAttribute,
            morphedNormalAttribute: morphedNormalAttribute
        };
    }

    static function mergeGroups(geometry: BufferGeometry): BufferGeometry {
        if (geometry.groups.length === 0) {
            console.warn('THREE.BufferGeometryUtils.mergeGroups(): No groups are defined. Nothing to merge.');
            return geometry;
        }

        var groups = geometry.groups;

        groups = groups.sort(function (a: any, b: any): Int {
            if (a.materialIndex !== b.materialIndex) return a.materialIndex - b.materialIndex;
            return a.start - b.start;
        });

        if (geometry.getIndex() === null) {
            var positionAttribute = geometry.getAttribute('position');
            var indices = new Array<Int>();

            for (var i = 0; i < positionAttribute.count; i += 3) {
                indices.push(i, i + 1, i + 2);
            }

            geometry.setIndex(indices);
        }

        var index = geometry.getIndex();

        var newIndices = new Array<Int>();

        for (var i = 0; i < groups.length; i++) {
            var group = groups[i];

            var groupStart = group.start;
            var groupLength = groupStart + group.count;

            for (var j = groupStart; j < groupLength; j++) {
                newIndices.push(index.getX(j));
            }
        }

        geometry.dispose();
        geometry.setIndex(newIndices);

        var start = 0;

        for (var i = 0; i < groups.length; i++) {
            var group = groups[i];

            group.start = start;
            start += group.count;
        }

        var currentGroup = groups[0];

        geometry.groups = [currentGroup];

        for (var i = 1; i < groups.length; i++) {
            var group = groups[i];

            if (currentGroup.materialIndex === group.materialIndex) {
                currentGroup.count += group.count;
            } else {
                currentGroup = group;
                geometry.groups.push(currentGroup);
            }
        }

        return geometry;
    }

    static function toCreasedNormals(geometry: BufferGeometry, creaseAngle: Float = Math.PI / 3): BufferGeometry {
        var creaseDot = Math.cos(creaseAngle);
        var hashMultiplier = (1 + 1e-10) * 1e2;

        var verts = [new Vector3(), new Vector3(), new Vector3()];
        var tempVec1 = new Vector3();
        var tempVec2 = new Vector3();
        var tempNorm = new Vector3();
        var tempNorm2 = new Vector3();

        function hashVertex(v: Vector3): String {
            var x = ~~(v.x * hashMultiplier);
            var y = ~~(v.y * hashMultiplier);
            var z = ~~(v.z * hashMultiplier);
            return x + ',' + y + ',' + z;
        }

        var resultGeometry = geometry.index ? geometry.toNonIndexed() : geometry;
        var posAttr = resultGeometry.attributes.get('position');
        var vertexMap = new haxe.ds.StringMap<Array<Vector3>>();

        for (var i = 0, l = posAttr.count / 3; i < l; i++) {
            var i3 = 3 * i;
            var a = verts[0].fromBufferAttribute(posAttr, i3 + 0);
            var b = verts[1].fromBufferAttribute(posAttr, i3 + 1);
            var c = verts[2].fromBufferAttribute(posAttr, i3 + 2);

            tempVec1.subVectors(c, b);
            tempVec2.subVectors(a, b);

            var normal = new Vector3().crossVectors(tempVec1, tempVec2).normalize();
            for (var n = 0; n < 3; n++) {
                var vert = verts[n];
                var hash = hashVertex(vert);
                if (!vertexMap.exists(hash)) {
                    vertexMap.set(hash, []);
                }

                vertexMap.get(hash).push(normal);
            }
        }

        var normalArray = new Float32Array(posAttr.count * 3);
        var normAttr = new BufferAttribute(normalArray, 3, false);
        for (var i = 0, l = posAttr.count / 3; i < l; i++) {
            var i3 = 3 * i;
            var a = verts[0].fromBufferAttribute(posAttr, i3 + 0);
            var b = verts[1].fromBufferAttribute(posAttr, i3 + 1);
            var c = verts[2].fromBufferAttribute(posAttr, i3 + 2);

            tempVec1.subVectors(c, b);
            tempVec2.subVectors(a, b);

            tempNorm.crossVectors(tempVec1, tempVec2).normalize();

            for (var n = 0; n < 3; n++) {
                var vert = verts[n];
                var hash = hashVertex(vert);
                var otherNormals = vertexMap.get(hash);
                tempNorm2.set(0, 0, 0);

                for (var k = 0, lk = otherNormals.length; k < lk; k++) {
                    var otherNorm = otherNormals[k];
                    if (tempNorm.dot(otherNorm) > creaseDot) {
                        tempNorm2.add(otherNorm);
                    }
                }

                tempNorm2.normalize();
                normAttr.setXYZ(i3 + n, tempNorm2.x, tempNorm2.y, tempNorm2.z);
            }
        }

        resultGeometry.setAttribute('normal', normAttr);
        return resultGeometry;
    }
}
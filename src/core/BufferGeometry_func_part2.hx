package three.core;

import haxe.ds.Vector;
import three.math.Vector2;
import three.math.Vector3;
import three.bufferattribute.BufferAttribute;
import three.buffergeometry.BufferGeometry;

class BufferGeometry {
    public function computeTangents():Void {
        var index:Array<Int> = this.index.array;
        var attributes:Map<String, BufferAttribute> = this.attributes;

        if (index == null || attributes.position == null || attributes.normal == null || attributes.uv == null) {
            console.error("THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)");
            return;
        }

        var positionAttribute:BufferAttribute = attributes.position;
        var normalAttribute:BufferAttribute = attributes.normal;
        var uvAttribute:BufferAttribute = attributes.uv;

        if (!this.hasAttribute("tangent")) {
            this.setAttribute("tangent", new BufferAttribute(new Float32Array(4 * positionAttribute.count), 4));
        }

        var tangentAttribute:BufferAttribute = this.getAttribute("tangent");

        var tan1:Array<Vector3> = [];
        var tan2:Array<Vector3> = [];

        for (i in 0...positionAttribute.count) {
            tan1.push(new Vector3());
            tan2.push(new Vector3());
        }

        var vA:Vector3 = new Vector3();
        var vB:Vector3 = new Vector3();
        var vC:Vector3 = new Vector3();

        var uvA:Vector2 = new Vector2();
        var uvB:Vector2 = new Vector2();
        var uvC:Vector2 = new Vector2();

        var sdir:Vector3 = new Vector3();
        var tdir:Vector3 = new Vector3();

        function handleTriangle(a:Int, b:Int, c:Int):Void {
            vA.fromBufferAttribute(positionAttribute, a);
            vB.fromBufferAttribute(positionAttribute, b);
            vC.fromBufferAttribute(positionAttribute, c);

            uvA.fromBufferAttribute(uvAttribute, a);
            uvB.fromBufferAttribute(uvAttribute, b);
            uvC.fromBufferAttribute(uvAttribute, c);

            vB.sub(vA);
            vC.sub(vA);

            uvB.sub(uvA);
            uvC.sub(uvA);

            var r:Float = 1.0 / (uvB.x * uvC.y - uvC.x * uvB.y);

            if (!Math.isFinite(r)) return;

            sdir.copy(vB).multiplyScalar(uvC.y).addScaledVector(vC, -uvB.y).multiplyScalar(r);
            tdir.copy(vC).multiplyScalar(uvB.x).addScaledVector(vB, -uvC.x).multiplyScalar(r);

            tan1[a].add(sdir);
            tan1[b].add(sdir);
            tan1[c].add(sdir);

            tan2[a].add(tdir);
            tan2[b].add(tdir);
            tan2[c].add(tdir);
        }

        var groups:Array<{ start:Int, count:Int }> = this.groups;

        if (groups.length == 0) {
            groups = [{ start: 0, count: index.length }];
        }

        for (i in 0...groups.length) {
            var group:{ start:Int, count:Int } = groups[i];

            var start:Int = group.start;
            var count:Int = group.count;

            for (j in start...start + count) {
                handleTriangle(index[j + 0], index[j + 1], index[j + 2]);
            }
        }

        var tmp:Vector3 = new Vector3();
        var tmp2:Vector3 = new Vector3();
        var n:Vector3 = new Vector3();
        var n2:Vector3 = new Vector3();

        function handleVertex(v:Int):Void {
            n.fromBufferAttribute(normalAttribute, v);
            n2.copy(n);

            var t:Vector3 = tan1[v];

            tmp.copy(t);
            tmp.sub(n.multiplyScalar(n.dot(t))).normalize();

            tmp2.crossVectors(n2, t);
            var test:Float = tmp2.dot(tan2[v]);
            var w:Float = (test < 0.0) ? -1.0 : 1.0;

            tangentAttribute.setXYZW(v, tmp.x, tmp.y, tmp.z, w);
        }

        for (i in 0...groups.length) {
            var group:{ start:Int, count:Int } = groups[i];

            var start:Int = group.start;
            var count:Int = group.count;

            for (j in start...start + count) {
                handleVertex(index[j + 0]);
                handleVertex(index[j + 1]);
                handleVertex(index[j + 2]);
            }
        }
    }

    public function computeVertexNormals():Void {
        var index:Array<Int> = this.index.array;
        var positionAttribute:BufferAttribute = this.getAttribute("position");

        if (positionAttribute != null) {
            var normalAttribute:BufferAttribute = this.getAttribute("normal");

            if (normalAttribute == null) {
                normalAttribute = new BufferAttribute(new Float32Array(positionAttribute.count * 3), 3);
                this.setAttribute("normal", normalAttribute);
            } else {
                for (i in 0...normalAttribute.count) {
                    normalAttribute.setXYZ(i, 0, 0, 0);
                }
            }

            var pA:Vector3 = new Vector3();
            var pB:Vector3 = new Vector3();
            var pC:Vector3 = new Vector3();
            var nA:Vector3 = new Vector3();
            var nB:Vector3 = new Vector3();
            var nC:Vector3 = new Vector3();
            var cb:Vector3 = new Vector3();
            var ab:Vector3 = new Vector3();

            if (index != null) {
                for (i in 0...index.length) {
                    var vA:Int = index[i + 0];
                    var vB:Int = index[i + 1];
                    var vC:Int = index[i + 2];

                    pA.fromBufferAttribute(positionAttribute, vA);
                    pB.fromBufferAttribute(positionAttribute, vB);
                    pC.fromBufferAttribute(positionAttribute, vC);

                    cb.subVectors(pC, pB);
                    ab.subVectors(pA, pB);
                    cb.cross(ab);

                    nA.fromBufferAttribute(normalAttribute, vA);
                    nB.fromBufferAttribute(normalAttribute, vB);
                    nC.fromBufferAttribute(normalAttribute, vC);

                    nA.add(cb);
                    nB.add(cb);
                    nC.add(cb);

                    normalAttribute.setXYZ(vA, nA.x, nA.y, nA.z);
                    normalAttribute.setXYZ(vB, nB.x, nB.y, nB.z);
                    normalAttribute.setXYZ(vC, nC.x, nC.y, nC.z);
                }
            } else {
                for (i in 0...positionAttribute.count) {
                    pA.fromBufferAttribute(positionAttribute, i + 0);
                    pB.fromBufferAttribute(positionAttribute, i + 1);
                    pC.fromBufferAttribute(positionAttribute, i + 2);

                    cb.subVectors(pC, pB);
                    ab.subVectors(pA, pB);
                    cb.cross(ab);

                    normalAttribute.setXYZ(i + 0, cb.x, cb.y, cb.z);
                    normalAttribute.setXYZ(i + 1, cb.x, cb.y, cb.z);
                    normalAttribute.setXYZ(i + 2, cb.x, cb.y, cb.z);
                }
            }

            this.normalizeNormals();

            normalAttribute.needsUpdate = true;
        }
    }

    public function normalizeNormals():Void {
        var normals:BufferAttribute = this.getAttribute("normal");

        for (i in 0...normals.count) {
            var v:Vector3 = new Vector3();
            v.fromBufferAttribute(normals, i);
            v.normalize();
            normals.setXYZ(i, v.x, v.y, v.z);
        }
    }

    public function toNonIndexed():BufferGeometry {
        function convertBufferAttribute(attribute:BufferAttribute, indices:Array<Int>):BufferAttribute {
            var array:Array<Float> = attribute.array;
            var itemSize:Int = attribute.itemSize;
            var normalized:Bool = attribute.normalized;

            var array2:Array<Float> = new Array<Float>();
            var index:Int = 0;
            var index2:Int = 0;

            for (i in 0...indices.length) {
                if (attribute.isInterleavedBufferAttribute) {
                    index = indices[i] * attribute.data.stride + attribute.offset;
                } else {
                    index = indices[i] * itemSize;
                }

                for (j in 0...itemSize) {
                    array2[index2++] = array[index++];
                }
            }

            return new BufferAttribute(array2, itemSize, normalized);
        }

        if (this.index == null) {
            console.warn("THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed.");
            return this;
        }

        var geometry:BufferGeometry = new BufferGeometry();

        var indices:Array<Int> = this.index.array;
        var attributes:Map<String, BufferAttribute> = this.attributes;

        for (name in attributes.keys()) {
            var attribute:BufferAttribute = attributes[name];
            var newAttribute:BufferAttribute = convertBufferAttribute(attribute, indices);
            geometry.setAttribute(name, newAttribute);
        }

        var morphAttributes:Map<String, Array<BufferAttribute>> = this.morphAttributes;

        for (name in morphAttributes.keys()) {
            var morphArray:Array<BufferAttribute> = morphAttributes[name];
            var newMorphArray:Array<BufferAttribute> = [];

            for (i in 0...morphArray.length) {
                var attribute:BufferAttribute = morphArray[i];
                var newAttribute:BufferAttribute = convertBufferAttribute(attribute, indices);
                newMorphArray.push(newAttribute);
            }

            geometry.morphAttributes[name] = newMorphArray;
        }

        geometry.morphTargetsRelative = this.morphTargetsRelative;

        var groups:Array<{ start:Int, count:Int }> = this.groups;

        for (i in 0...groups.length) {
            var group:{ start:Int, count:Int } = groups[i];
            geometry.addGroup(group.start, group.count, group.materialIndex);
        }

        return geometry;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = {
            metadata: {
                version: 4.6,
                type: "BufferGeometry",
                generator: "BufferGeometry.toJSON"
            }
        };

        data.uuid = this.uuid;
        data.type = this.type;
        if (this.name != "") data.name = this.name;
        if (Object.keys(this.userData).length > 0) data.userData = this.userData;

        if (this.parameters != null) {
            var parameters:Dynamic = this.parameters;

            for (key in parameters.keys()) {
                if (parameters[key] != null) data[key] = parameters[key];
            }

            return data;
        }

        data.data = { attributes: {} };

        var index:Array<Int> = this.index.array;

        if (index != null) {
            data.data.index = {
                type: index.constructor.name,
                array: index.slice(0)
            };
        }

        var attributes:Map<String, BufferAttribute> = this.attributes;

        for (key in attributes.keys()) {
            var attribute:BufferAttribute = attributes[key];
            data.data.attributes[key] = attribute.toJSON(data.data);
        }

        var morphAttributes:Map<String, Array<BufferAttribute>> = this.morphAttributes;

        var hasMorphAttributes:Bool = false;

        for (key in morphAttributes.keys()) {
            var attributeArray:Array<BufferAttribute> = morphAttributes[key];

            var array:Array<Dynamic> = [];

            for (i in 0...attributeArray.length) {
                var attribute:BufferAttribute = attributeArray[i];
                array.push(attribute.toJSON(data.data));
            }

            if (array.length > 0) {
                morphAttributes[key] = array;
                hasMorphAttributes = true;
            }
        }

        if (hasMorphAttributes) {
            data.data.morphAttributes = morphAttributes;
            data.data.morphTargetsRelative = this.morphTargetsRelative;
        }

        var groups:Array<{ start:Int, count:Int }> = this.groups;

        if (groups.length > 0) {
            data.data.groups = JSON.parse(JSON.stringify(groups));
        }

        var boundingSphere:Dynamic = this.boundingSphere;

        if (boundingSphere != null) {
            data.data.boundingSphere = {
                center: boundingSphere.center.toArray(),
                radius: boundingSphere.radius
            };
        }

        return data;
    }

    public function clone():BufferGeometry {
        return new BufferGeometry().copy(this);
    }

    public function copy(source:BufferGeometry):BufferGeometry {
        this.index = null;
        this.attributes = {};
        this.morphAttributes = {};
        this.groups = [];
        this.boundingBox = null;
        this.boundingSphere = null;

        this.name = source.name;

        var index:Array<Int> = source.index.array;

        if (index != null) {
            this.setIndex(index.clone());
        }

        var attributes:Map<String, BufferAttribute> = source.attributes;

        for (key in attributes.keys()) {
            var attribute:BufferAttribute = attributes[key];
            this.setAttribute(key, attribute.clone());
        }

        var morphAttributes:Map<String, Array<BufferAttribute>> = source.morphAttributes;

        for (key in morphAttributes.keys()) {
            var attributeArray:Array<BufferAttribute> = morphAttributes[key];

            var array:Array<BufferAttribute> = [];

            for (i in 0...attributeArray.length) {
                array.push(attributeArray[i].clone());
            }

            this.morphAttributes[key] = array;
        }

        this.morphTargetsRelative = source.morphTargetsRelative;

        var groups:Array<{ start:Int, count:Int }> = source.groups;

        for (i in 0...groups.length) {
            var group:{ start:Int, count:Int } = groups[i];
            this.addGroup(group.start, group.count, group.materialIndex);
        }

        var boundingBox:Dynamic = source.boundingBox;

        if (boundingBox != null) {
            this.boundingBox = boundingBox.clone();
        }

        var boundingSphere:Dynamic = source.boundingSphere;

        if (boundingSphere != null) {
            this.boundingSphere = boundingSphere.clone();
        }

        this.drawRange.start = source.drawRange.start;
        this.drawRange.count = source.drawRange.count;

        this.userData = source.userData;

        return this;
    }

    public function dispose():Void {
        this.dispatchEvent({ type: "dispose" });
    }
}
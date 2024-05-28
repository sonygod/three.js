package three.js.src.geometries;

import three.js.src.core.BufferGeometry;
import three.js.src.core.Float32BufferAttribute;
import three.js.src.math.MathUtils;
import three.js.src.math.Triangle;
import three.js.src.math.Vector3;

class EdgesGeometry extends BufferGeometry {
    
    public function new(?geometry:BufferGeometry, ?thresholdAngle:Float = 1) {
        super();
        
        type = 'EdgesGeometry';

        parameters = {
            geometry: geometry,
            thresholdAngle: thresholdAngle
        };

        if (geometry != null) {
            var precisionPoints = 4;
            var precision = Math.pow(10, precisionPoints);
            var thresholdDot = Math.cos(MathUtils.DEG2RAD * thresholdAngle);

            var indexAttr = geometry.getIndex();
            var positionAttr = geometry.getAttribute('position');
            var indexCount = indexAttr != null ? indexAttr.count : positionAttr.count;

            var indexArr = [0, 0, 0];
            var vertKeys = ['a', 'b', 'c'];
            var hashes = new Array<Dynamic>(3);

            var edgeData = {};
            var vertices = new Array<Float>();

            for (i in 0...indexCount) {
                if (indexAttr != null) {
                    indexArr[0] = indexAttr.getX(i);
                    indexArr[1] = indexAttr.getX(i + 1);
                    indexArr[2] = indexAttr.getX(i + 2);
                } else {
                    indexArr[0] = i;
                    indexArr[1] = i + 1;
                    indexArr[2] = i + 2;
                }

                var a = _triangle.a;
                a.fromBufferAttribute(positionAttr, indexArr[0]);
                var b = _triangle.b;
                b.fromBufferAttribute(positionAttr, indexArr[1]);
                var c = _triangle.c;
                c.fromBufferAttribute(positionAttr, indexArr[2]);
                _triangle.getNormal(_normal);

                // create hashes for the edge from the vertices
                hashes[0] = '${Math.round(a.x * precision)},${Math.round(a.y * precision)},${Math.round(a.z * precision)}';
                hashes[1] = '${Math.round(b.x * precision)},${Math.round(b.y * precision)},${Math.round(b.z * precision)}';
                hashes[2] = '${Math.round(c.x * precision)},${Math.round(c.y * precision)},${Math.round(c.z * precision)}';

                // skip degenerate triangles
                if (hashes[0] == hashes[1] || hashes[1] == hashes[2] || hashes[2] == hashes[0]) {
                    continue;
                }

                // iterate over every edge
                for (j in 0...3) {
                    // get the first and next vertex making up the edge
                    var jNext = (j + 1) % 3;
                    var vecHash0 = hashes[j];
                    var vecHash1 = hashes[jNext];
                    var v0 = _triangle[vertKeys[j]];
                    var v1 = _triangle[vertKeys[jNext]];

                    var hash = '${vecHash0}_${vecHash1}';
                    var reverseHash = '${vecHash1}_${vecHash0}';

                    if (Reflect.hasField(edgeData, reverseHash) && edgeData[reverseHash] != null) {
                        // if we found a sibling edge add it into the vertex array if
                        // it meets the angle threshold and delete the edge from the map.
                        if (_normal.dot(edgeData[reverseHash].normal) <= thresholdDot) {
                            vertices.push(v0.x, v0.y, v0.z);
                            vertices.push(v1.x, v1.y, v1.z);
                        }

                        Reflect.setField(edgeData, reverseHash, null);
                    } else if (!Reflect.hasField(edgeData, hash)) {
                        // if we've already got an edge here then skip adding a new one
                        Reflect.setField(edgeData, hash, {
                            index0: indexArr[j],
                            index1: indexArr[jNext],
                            normal: _normal.clone()
                        });
                    }
                }
            }

            // iterate over all remaining, unmatched edges and add them to the vertex array
            for (key in Reflect.fields(edgeData)) {
                if (Reflect.field(edgeData, key) != null) {
                    var edge = Reflect.field(edgeData, key);
                    _v0.fromBufferAttribute(positionAttr, edge.index0);
                    _v1.fromBufferAttribute(positionAttr, edge.index1);

                    vertices.push(_v0.x, _v0.y, _v0.z);
                    vertices.push(_v1.x, _v1.y, _v1.z);
                }
            }

            setAttribute('position', new Float32BufferAttribute(vertices, 3));
        }
    }

    public function copy(source:EdgesGeometry):EdgesGeometry {
        super.copy(source);

        parameters = Reflect.copy(source.parameters);

        return this;
    }
}
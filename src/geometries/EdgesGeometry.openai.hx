package three.geom;

import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.MathUtils;
import three.math.Triangle;
import three.math.Vector3;

class EdgesGeometry extends BufferGeometry {

    var _v0:Vector3 = new Vector3();
    var _v1:Vector3 = new Vector3();
    var _normal:Vector3 = new Vector3();
    var _triangle:Triangle = new Triangle();

    public function new(?geometry:BufferGeometry, thresholdAngle:Float = 1) {
        super();
        this.type = 'EdgesGeometry';
        this.parameters = {
            geometry: geometry,
            thresholdAngle: thresholdAngle
        };

        if (geometry != null) {
            var precisionPoints:Int = 4;
            var precision:Float = Math.pow(10, precisionPoints);
            var thresholdDot:Float = Math.cos(MathUtils.degToRad(thresholdAngle));

            var indexAttr:BufferAttribute = geometry.getIndex();
            var positionAttr:BufferAttribute = geometry.getAttribute('position');
            var indexCount:Int = indexAttr != null ? indexAttr.count : positionAttr.count;

            var indexArr:Array<Int> = [0, 0, 0];
            var vertKeys:Array<String> = ['a', 'b', 'c'];
            var hashes:Array<String> = new Array<String>();

            var edgeData:Map<String, Dynamic> = new Map<String, Dynamic>();
            var vertices:Array<Float> = new Array<Float>();

            for (i in 0...indexCount step 3) {
                if (indexAttr != null) {
                    indexArr[0] = indexAttr.getX(i);
                    indexArr[1] = indexAttr.getX(i + 1);
                    indexArr[2] = indexAttr.getX(i + 2);
                } else {
                    indexArr[0] = i;
                    indexArr[1] = i + 1;
                    indexArr[2] = i + 2;
                }

                var triangle:Triangle = _triangle;
                var a:Vector3 = _triangle[vertKeys[0]];
                var b:Vector3 = _triangle[vertKeys[1]];
                var c:Vector3 = _triangle[vertKeys[2]];
                a.fromBufferAttribute(positionAttr, indexArr[0]);
                b.fromBufferAttribute(positionAttr, indexArr[1]);
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
                    var jNext:Int = (j + 1) % 3;
                    var vecHash0:String = hashes[j];
                    var vecHash1:String = hashes[jNext];
                    var v0:Vector3 = _triangle[vertKeys[j]];
                    var v1:Vector3 = _triangle[vertKeys[jNext]];

                    var hash:String = '$vecHash0_$vecHash1';
                    var reverseHash:String = '$vecHash1_$vecHash0';

                    if (edgeData.exists(reverseHash) && edgeData.get(reverseHash) != null) {
                        // if we found a sibling edge add it into the vertex array if
                        // it meets the angle threshold and delete the edge from the map.
                        if (_normal.dot(edgeData.get(reverseHash).normal) <= thresholdDot) {
                            vertices.push(v0.x);
                            vertices.push(v0.y);
                            vertices.push(v0.z);
                            vertices.push(v1.x);
                            vertices.push(v1.y);
                            vertices.push(v1.z);
                        }

                        edgeData.set(reverseHash, null);
                    } else if (!edgeData.exists(hash)) {
                        // if we've already got an edge here then skip adding a new one
                        edgeData.set(hash, {
                            index0: indexArr[j],
                            index1: indexArr[jNext],
                            normal: _normal.clone(),
                        });
                    }
                }
            }

            // iterate over all remaining, unmatched edges and add them to the vertex array
            for (key in edgeData.keys()) {
                if (edgeData.get(key) != null) {
                    var data:Dynamic = edgeData.get(key);
                    _v0.fromBufferAttribute(positionAttr, data.index0);
                    _v1.fromBufferAttribute(positionAttr, data.index1);

                    vertices.push(_v0.x);
                    vertices.push(_v0.y);
                    vertices.push(_v0.z);
                    vertices.push(_v1.x);
                    vertices.push(_v1.y);
                    vertices.push(_v1.z);
                }
            }

            this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        }
    }

    override public function copy(source:EdgesGeometry):EdgesGeometry {
        super.copy(source);

        this.parameters = Object.assign({}, source.parameters);

        return this;
    }

}
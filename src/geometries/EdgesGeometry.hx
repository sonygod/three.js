package three.geometries;

import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.MathUtils;
import three.math.Triangle;
import three.math.Vector3;

class EdgesGeometry extends BufferGeometry {
    public var type:String = 'EdgesGeometry';
    public var parameters:Dynamic;

    private var _v0:Vector3 = new Vector3();
    private var _v1:Vector3 = new Vector3();
    private var _normal:Vector3 = new Vector3();
    private var _triangle:Triangle = new Triangle();

    public function new(geometry:BufferGeometry = null, thresholdAngle:Float = 1) {
        super();
        this.type = 'EdgesGeometry';
        this.parameters = {
            geometry: geometry,
            thresholdAngle: thresholdAngle
        };

        if (geometry != null) {
            var precisionPoints:Int = 4;
            var precision:Float = Math.pow(10, precisionPoints);
            var thresholdDot:Float = Math.cos(MathUtils.DEG2RAD * thresholdAngle);

            var indexAttr:Array<Int> = geometry.getIndex();
            var positionAttr:Array<Float> = geometry.getAttribute('position');
            var indexCount:Int = indexAttr != null ? indexAttr.length : positionAttr.length;

            var indexArr:Array<Int> = [0, 0, 0];
            var vertKeys:Array<String> = ['a', 'b', 'c'];
            var hashes:Array<String> = new Array<String>();

            var edgeData:Map<String, Dynamic> = new Map();
            var vertices:Array<Float> = new Array();

            for (i in 0...indexCount step 3) {
                if (indexAttr != null) {
                    indexArr[0] = indexAttr[i];
                    indexArr[1] = indexAttr[i + 1];
                    indexArr[2] = indexAttr[i + 2];
                } else {
                    indexArr[0] = i;
                    indexArr[1] = i + 1;
                    indexArr[2] = i + 2;
                }

                var a:Vector3 = _triangle.a;
                var b:Vector3 = _triangle.b;
                var c:Vector3 = _triangle.c;
                a.fromBufferAttribute(positionAttr, indexArr[0]);
                b.fromBufferAttribute(positionAttr, indexArr[1]);
                c.fromBufferAttribute(positionAttr, indexArr[2]);
                _triangle.getNormal(_normal);

                hashes[0] = '${Math.round(a.x * precision)},${Math.round(a.y * precision)},${Math.round(a.z * precision)}';
                hashes[1] = '${Math.round(b.x * precision)},${Math.round(b.y * precision)},${Math.round(b.z * precision)}';
                hashes[2] = '${Math.round(c.x * precision)},${Math.round(c.y * precision)},${Math.round(c.z * precision)}';

                if (hashes[0] == hashes[1] || hashes[1] == hashes[2] || hashes[2] == hashes[0]) {
                    continue;
                }

                for (j in 0...3) {
                    var jNext:Int = (j + 1) % 3;
                    var vecHash0:String = hashes[j];
                    var vecHash1:String = hashes[jNext];
                    var v0:Vector3 = _triangle[vertKeys[j]];
                    var v1:Vector3 = _triangle[vertKeys[jNext]];

                    var hash:String = '${vecHash0}_${vecHash1}';
                    var reverseHash:String = '${vecHash1}_${vecHash0}';

                    if (edgeData.exists(reverseHash) && edgeData.get(reverseHash) != null) {
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
                        edgeData.set(hash, {
                            index0: indexArr[j],
                            index1: indexArr[jNext],
                            normal: _normal.clone(),
                        });
                    }
                }
            }

            for (key in edgeData.keys()) {
                if (edgeData.get(key) != null) {
                    var edge:Dynamic = edgeData.get(key);
                    _v0.fromBufferAttribute(positionAttr, edge.index0);
                    _v1.fromBufferAttribute(positionAttr, edge.index1);

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
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.MathUtils;
import three.math.Triangle;
import three.math.Vector3;

class EdgesGeometry extends BufferGeometry {

    private var _v0:Vector3 = new Vector3();
    private var _v1:Vector3 = new Vector3();
    private var _normal:Vector3 = new Vector3();
    private var _triangle:Triangle = new Triangle();

    public function new(geometry:BufferGeometry = null, thresholdAngle:Float = 1.0) {
        super();
        this.type = 'EdgesGeometry';
        this.parameters = {
            geometry: geometry,
            thresholdAngle: thresholdAngle
        };

        if (geometry !== null) {
            var precisionPoints = 4;
            var precision = Math.pow(10, precisionPoints);
            var thresholdDot = Math.cos(MathUtils.DEG2RAD * thresholdAngle);
            var indexAttr = geometry.getIndex();
            var positionAttr = geometry.getAttribute('position');
            var indexCount = indexAttr ? indexAttr.count : positionAttr.count;
            var indexArr = [0, 0, 0];
            var vertKeys = ['a', 'b', 'c'];
            var hashes = new Array<String>(3);
            var edgeData = new haxe.ds.StringMap<Dynamic>();
            var vertices = new Array<Float>();

            for (var i = 0; i < indexCount; i += 3) {
                if (indexAttr) {
                    indexArr[0] = indexAttr.getX(i);
                    indexArr[1] = indexAttr.getX(i + 1);
                    indexArr[2] = indexAttr.getX(i + 2);
                } else {
                    indexArr[0] = i;
                    indexArr[1] = i + 1;
                    indexArr[2] = i + 2;
                }

                var a = _triangle.a;
                var b = _triangle.b;
                var c = _triangle.c;

                a.fromBufferAttribute(positionAttr, indexArr[0]);
                b.fromBufferAttribute(positionAttr, indexArr[1]);
                c.fromBufferAttribute(positionAttr, indexArr[2]);
                _triangle.getNormal(_normal);

                hashes[0] = Math.round(a.x * precision) + ',' + Math.round(a.y * precision) + ',' + Math.round(a.z * precision);
                hashes[1] = Math.round(b.x * precision) + ',' + Math.round(b.y * precision) + ',' + Math.round(b.z * precision);
                hashes[2] = Math.round(c.x * precision) + ',' + Math.round(c.y * precision) + ',' + Math.round(c.z * precision);

                if (hashes[0] == hashes[1] || hashes[1] == hashes[2] || hashes[2] == hashes[0]) {
                    continue;
                }

                for (var j = 0; j < 3; j++) {
                    var jNext = (j + 1) % 3;
                    var vecHash0 = hashes[j];
                    var vecHash1 = hashes[jNext];
                    var v0 = _triangle.getField(vertKeys[j]);
                    var v1 = _triangle.getField(vertKeys[jNext]);

                    var hash = vecHash0 + '_' + vecHash1;
                    var reverseHash = vecHash1 + '_' + vecHash0;

                    if (edgeData.exists(reverseHash) && edgeData.get(reverseHash) != null) {
                        if (_normal.dot(edgeData.get(reverseHash).normal) <= thresholdDot) {
                            vertices.push(v0.x, v0.y, v0.z);
                            vertices.push(v1.x, v1.y, v1.z);
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

            for (var key in edgeData.keys()) {
                if (edgeData.get(key) != null) {
                    var index0 = edgeData.get(key).index0;
                    var index1 = edgeData.get(key).index1;
                    _v0.fromBufferAttribute(positionAttr, index0);
                    _v1.fromBufferAttribute(positionAttr, index1);
                    vertices.push(_v0.x, _v0.y, _v0.z);
                    vertices.push(_v1.x, _v1.y, _v1.z);
                }
            }

            this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        }
    }

    public function copy(source:EdgesGeometry):EdgesGeometry {
        super.copy(source);
        this.parameters = haxe.ds.StringMap.copy(source.parameters);
        return this;
    }
}
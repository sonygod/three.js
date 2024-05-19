import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.MathUtils;
import three.math.Triangle;
import three.math.Vector3;

class EdgesGeometry extends BufferGeometry {

    static var _v0:Vector3 = new Vector3();
    static var _v1:Vector3 = new Vector3();
    static var _normal:Vector3 = new Vector3();
    static var _triangle:Triangle = new Triangle();

    public function new(geometry:BufferGeometry = null, thresholdAngle:Float = 1) {
        super();

        this.type = 'EdgesGeometry';

        this.parameters = {
            geometry: geometry,
            thresholdAngle: thresholdAngle
        };

        if (geometry != null) {

            var precisionPoints = 4;
            var precision = Math.pow(10, precisionPoints);
            var thresholdDot = Math.cos(MathUtils.DEG2RAD * thresholdAngle);

            var indexAttr = geometry.getIndex();
            var positionAttr = geometry.getAttribute('position');
            var indexCount = if (indexAttr != null) indexAttr.count else positionAttr.count;

            var indexArr = [0, 0, 0];
            var vertKeys = ['a', 'b', 'c'];
            var hashes = new Array(3);

            var edgeData = {};
            var vertices = [];
            for (i in 0...indexCount) {
                var j = i % 3;

                if (indexAttr != null) {
                    indexArr[j] = indexAttr.getX(i);
                } else {
                    indexArr[j] = i;
                }

                var a = _triangle.a;
                var b = _triangle.b;
                var c = _triangle.c;
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
                    var jNext = (j + 1) % 3;
                    var vecHash0 = hashes[j];
                    var vecHash1 = hashes[jNext];
                    var v0 = _triangle[vertKeys[j]];
                    var v1 = _triangle[vertKeys[jNext]];

                    var hash = '${vecHash0}_${vecHash1}';
                    var reverseHash = '${vecHash1}_${vecHash0}';

                    if (reverseHash in edgeData && edgeData[reverseHash] != null) {
                        if (_normal.dot(edgeData[reverseHash].normal) <= thresholdDot) {
                            vertices.push(v0.x, v0.y, v0.z);
                            vertices.push(v1.x, v1.y, v1.z);
                        }
                        edgeData[reverseHash] = null;
                    } else if (!(hash in edgeData)) {
                        edgeData[hash] = {
                            index0: indexArr[j],
                            index1: indexArr[jNext],
                            normal: _normal.clone()
                        };
                    }
                }
            }

            for (key in edgeData) {
                if (edgeData[key] != null) {
                    var index0 = edgeData[key].index0;
                    var index1 = edgeData[key].index1;
                    _v0.fromBufferAttribute(positionAttr, index0);
                    _v1.fromBufferAttribute(positionAttr, index1);

                    vertices.push(_v0.x, _v0.y, _v0.z);
                    vertices.push(_v1.x, _v1.y, _v1.z);
                }
            }

            this.setAttribute('position', new BufferAttribute(vertices, 3));
        }
    }

    public function copy(source:EdgesGeometry):EdgesGeometry {
        super.copy(source);

        this.parameters = {...source.parameters};

        return this;
    }
}
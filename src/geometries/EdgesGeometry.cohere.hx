import js.BufferGeometry;
import js.Float32BufferAttribute;
import js.MathUtils;
import js.Triangle;
import js.Vector3;

class EdgesGeometry extends js.BufferGeometry {
    public var type: String = 'EdgesGeometry';
    public var parameters: { geometry: js.BufferGeometry, thresholdAngle: Float };

    public function new(geometry: js.BufferGeometry = null, thresholdAngle: Float = 1) {
        super();

        this.parameters = { geometry, thresholdAngle };

        if (geometry != null) {
            var precisionPoints = 4;
            var precision = Math.pow(10, precisionPoints);
            var thresholdDot = Math.cos(js.MathUtils.DEG2RAD * thresholdAngle);

            var indexAttr = geometry.getIndex();
            var positionAttr = geometry.getAttribute('position');
            var indexCount = if (indexAttr != null) indexAttr.count else positionAttr.count;

            var indexArr = [0, 0, 0];
            var vertKeys = ['a', 'b', 'c'];
            var hashes = [null, null, null];

            var edgeData = { };
            var vertices = [];

            for (i in 0...indexCount) {
                var i3 = i ~/ 3;
                if (indexAttr != null) {
                    indexArr[0] = indexAttr.getX(i3);
                    indexArr[1] = indexAttr.getX(i3 + 1);
                    indexArr[2] = indexAttr.getX(i3 + 2);
                } else {
                    indexArr[0] = i3;
                    indexArr[1] = i3 + 1;
                    indexArr[2] = i3 + 2;
                }

                var a = js.Triangle.a;
                var b = js.Triangle.b;
                var c = js.Triangle.c;
                a.fromBufferAttribute(positionAttr, indexArr[0]);
                b.fromBufferAttribute(positionAttr, indexArr[1]);
                c.fromBufferAttribute(positionAttr, indexArr[2]);
                var _normal = js.Triangle.getNormal(null);

                hashes[0] = Std.string(a.x.toFixed(precisionPoints)) + ',' + Std.string(a.y.toFixed(precisionPoints)) + ',' + Std.string(a.z.toFixed(precisionPoints));
                hashes[1] = Std.string(b.x.toFixed(precisionPoints)) + ',' + Std.string(b.y.toFixed(precisionPoints)) + ',' + Std.string(b.z.toFixed(precisionPoints));
                hashes[2] = Std.string(c.x.toFixed(precisionPoints)) + ',' + Std.string(c.y.toFixed(precisionPoints)) + ',' + Std.string(c.z.toFixed(precisionPoints));

                if (hashes[0] == hashes[1] || hashes[1] == hashes[2] || hashes[2] == hashes[0]) {
                    continue;
                }

                for (j in 0...3) {
                    var jNext = (j + 1) % 3;
                    var vecHash0 = hashes[j];
                    var vecHash1 = hashes[jNext];
                    var v0 = js.Triangle[$vertKeys[j]];
                    var v1 = js.Triangle[$vertKeys[jNext]];

                    var hash = vecHash0 + '_' + vecHash1;
                    var reverseHash = vecHash1 + '_' + vecHash0;

                    if (edgeData.exists(reverseHash) && edgeData[reverseHash] != null) {
                        if (_normal.dot(edgeData[reverseHash].normal) <= thresholdDot) {
                            vertices.push(v0.x, v0.y, v0.z);
                            vertices.push(v1.x, v1.y, v1.z);
                        }
                        edgeData[reverseHash] = null;
                    } else if (!edgeData.exists(hash)) {
                        edgeData[hash] = { index0: indexArr[j], index1: indexArr[jNext], normal: _normal.clone() };
                    }
                }
            }

            for (key in edgeData) {
                if (edgeData[key] != null) {
                    var { index0, index1, normal } = edgeData[key];
                    var _v0 = js.Vector3.fromBufferAttribute(positionAttr, index0);
                    var _v1 = js.Vector3.fromBufferAttribute(positionAttr, index1);
                    vertices.push(_v0.x, _v0.y, _v0.z);
                    vertices.push(_v1.x, _v1.y, _v1.z);
                }
            }

            this.setAttribute('position', js.Float32BufferAttribute.fromArray(vertices, 3));
        }
    }

    public function copy(source: EdgesGeometry) {
        super.copy(source);
        this.parameters = source.parameters;
        return this;
    }
}
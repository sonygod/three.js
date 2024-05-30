import BufferGeometry.BufferGeometry;
import BufferAttribute.Float32BufferAttribute;
import MathUtils.*;
import Triangle.Triangle;
import Vector3.Vector3;

class EdgesGeometry extends BufferGeometry {
    public static var _v0(default, null):Vector3 = new Vector3();
    public static var _v1(default, null):Vector3 = new Vector3();
    public static var _normal(default, null):Vector3 = new Vector3();
    public static var _triangle(default, null):Triangle = new Triangle();

    public var type(default, null):String = "EdgesGeometry";
    public var parameters(default, null):Dynamic = { geometry: null, thresholdAngle: 1 };

    public function new(geometry:BufferGeometry = null, thresholdAngle:Float = 1) {
        super();

        this.parameters.geometry = geometry;
        this.parameters.thresholdAngle = thresholdAngle;

        if (geometry != null) {
            var precisionPoints:Int = 4;
            var precision:Float = Math.pow(10, precisionPoints);
            var thresholdDot:Float = Math.cos(DEG2RAD * thresholdAngle);

            var indexAttr:Dynamic = geometry.getIndex();
            var positionAttr:Dynamic = geometry.getAttribute("position");
            var indexCount:Int = indexAttr != null ? indexAttr.count : positionAttr.count;

            var indexArr:Array<Int> = [0, 0, 0];
            var vertKeys:Array<String> = ["a", "b", "c"];
            var hashes:Array<String> = new Array<String>();

            var edgeData:Dynamic = new haxe.ds.StringMap<Dynamic>();
            var vertices:Array<Float> = [];
            for (i in 0...indexCount by 3) {
                if (indexAttr != null) {
                    indexArr[0] = indexAttr.getX(i);
                    indexArr[1] = indexAttr.getX(i + 1);
                    indexArr[2] = indexAttr.getX(i + 2);
                } else {
                    indexArr[0] = i;
                    indexArr[1] = i + 1;
                    indexArr[2] = i + 2;
                }

                var { a, b, c } = _triangle;
                a.fromBufferAttribute(positionAttr, indexArr[0]);
                b.fromBufferAttribute(positionAttr, indexArr[1]);
                c.fromBufferAttribute(positionAttr, indexArr[2]);
                _triangle.getNormal(_normal);

                hashes[0] = "" + Math.round(a.x * precision) + "," + Math.round(a.y * precision) + "," + Math.round(a.z * precision);
                hashes[1] = "" + Math.round(b.x * precision) + "," + Math.round(b.y * precision) + "," + Math.round(b.z * precision);
                hashes[2] = "" + Math.round(c.x * precision) + "," + Math.round(c.y * precision) + "," + Math.round(c.z * precision);

                if (hashes[0] == hashes[1] || hashes[1] == hashes[2] || hashes[2] == hashes[0]) {
                    continue;
                }

                for (j in 0...3) {
                    var jNext:Int = (j + 1) % 3;
                    var vecHash0:String = hashes[j];
                    var vecHash1:String = hashes[jNext];
                    var v0:Vector3 = _triangle[vertKeys[j]];
                    var v1:Vector3 = _triangle[vertKeys[jNext]];

                    var hash:String = vecHash0 + "_" + vecHash1;
                    var reverseHash:String = vecHash1 + "_" + vecHash0;

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
                            normal: _normal.clone()
                        });
                    }
                }
            }

            for (key in edgeData.keys()) {
                if (edgeData.get(key) != null) {
                    var { index0, index1 } = edgeData.get(key);
                    _v0.fromBufferAttribute(positionAttr, index0);
                    _v1.fromBufferAttribute(positionAttr, index1);

                    vertices.push(_v0.x, _v0.y, _v0.z);
                    vertices.push(_v1.x, _v1.y, _v1.z);
                }
            }

            this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
        }
    }

    public function copy(source:EdgesGeometry):EdgesGeometry {
        super.copy(source);
        this.parameters = Type.clone(source.parameters);
        return this;
    }
}
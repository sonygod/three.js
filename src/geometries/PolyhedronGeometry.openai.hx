package three.js.src.geometries;

import three.js.core.BufferGeometry;
import three.js.core.Float32BufferAttribute;
import three.js.math.Vector3;
import three.js.math.Vector2;

class PolyhedronGeometry extends BufferGeometry {
    public function new(vertices:Array<Float> = [], indices:Array<Int> = [], radius:Float = 1, detail:Int = 0) {
        super();

        type = 'PolyhedronGeometry';

        parameters = {
            vertices: vertices,
            indices: indices,
            radius: radius,
            detail: detail
        };

        var vertexBuffer:Array<Float> = [];
        var uvBuffer:Array<Float> = [];

        subdivide(detail);

        applyRadius(radius);

        generateUVs();

        setAttribute('position', new Float32BufferAttribute(vertexBuffer, 3));
        setAttribute('normal', new Float32BufferAttribute(vertexBuffer.slice(), 3));
        setAttribute('uv', new Float32BufferAttribute(uvBuffer, 2));

        if (detail == 0) {
            computeVertexNormals(); // flat normals
        } else {
            normalizeNormals(); // smooth normals
        }

        function subdivide(detail:Int) {
            var a:Vector3 = new Vector3();
            var b:Vector3 = new Vector3();
            var c:Vector3 = new Vector3();

            for (i in 0...indices.length step 3) {
                getVertexByIndex(indices[i + 0], a);
                getVertexByIndex(indices[i + 1], b);
                getVertexByIndex(indices[i + 2], c);

                subdivideFace(a, b, c, detail);
            }
        }

        function subdivideFace(a:Vector3, b:Vector3, c:Vector3, detail:Int) {
            var cols:Int = detail + 1;

            var v:Array<Array<Vector3>> = [];

            for (i in 0...cols + 1) {
                v[i] = [];

                var aj:Vector3 = a.clone().lerp(c, i / cols);
                var bj:Vector3 = b.clone().lerp(c, i / cols);

                var rows:Int = cols - i;

                for (j in 0...rows + 1) {
                    if (j == 0 && i == cols) {
                        v[i][j] = aj;
                    } else {
                        v[i][j] = aj.clone().lerp(bj, j / rows);
                    }
                }
            }

            for (i in 0...cols) {
                for (j in 0...(2 * (cols - i) - 1)) {
                    var k:Int = Math.floor(j / 2);

                    if (j % 2 == 0) {
                        pushVertex(v[i][k + 1]);
                        pushVertex(v[i + 1][k]);
                        pushVertex(v[i][k]);
                    } else {
                        pushVertex(v[i][k + 1]);
                        pushVertex(v[i + 1][k + 1]);
                        pushVertex(v[i + 1][k]);
                    }
                }
            }
        }

        function applyRadius(radius:Float) {
            var vertex:Vector3 = new Vector3();

            for (i in 0...vertexBuffer.length step 3) {
                vertex.x = vertexBuffer[i + 0];
                vertex.y = vertexBuffer[i + 1];
                vertex.z = vertexBuffer[i + 2];

                vertex.normalize().multiplyScalar(radius);

                vertexBuffer[i + 0] = vertex.x;
                vertexBuffer[i + 1] = vertex.y;
                vertexBuffer[i + 2] = vertex.z;
            }
        }

        function generateUVs() {
            var vertex:Vector3 = new Vector3();

            for (i in 0...vertexBuffer.length step 3) {
                vertex.x = vertexBuffer[i + 0];
                vertex.y = vertexBuffer[i + 1];
                vertex.z = vertexBuffer[i + 2];

                var u:Float = azimuth(vertex) / 2 / Math.PI + 0.5;
                var v:Float = inclination(vertex) / Math.PI + 0.5;
                uvBuffer.push(u, 1 - v);
            }

            correctUVs();
            correctSeam();
        }

        function correctSeam() {
            for (i in 0...uvBuffer.length step 6) {
                var x0:Float = uvBuffer[i + 0];
                var x1:Float = uvBuffer[i + 2];
                var x2:Float = uvBuffer[i + 4];

                var max:Float = Math.max(x0, x1, x2);
                var min:Float = Math.min(x0, x1, x2);

                if (max > 0.9 && min < 0.1) {
                    if (x0 < 0.2) uvBuffer[i + 0] += 1;
                    if (x1 < 0.2) uvBuffer[i + 2] += 1;
                    if (x2 < 0.2) uvBuffer[i + 4] += 1;
                }
            }
        }

        function pushVertex(vertex:Vector3) {
            vertexBuffer.push(vertex.x, vertex.y, vertex.z);
        }

        function getVertexByIndex(index:Int, vertex:Vector3) {
            var stride:Int = index * 3;

            vertex.x = vertices[stride + 0];
            vertex.y = vertices[stride + 1];
            vertex.z = vertices[stride + 2];
        }

        function correctUVs() {
            var a:Vector3 = new Vector3();
            var b:Vector3 = new Vector3();
            var c:Vector3 = new Vector3();

            var centroid:Vector3 = new Vector3();

            var uvA:Vector2 = new Vector2();
            var uvB:Vector2 = new Vector2();
            var uvC:Vector2 = new Vector2();

            for (i in 0...vertexBuffer.length step 9) {
                a.set(vertexBuffer[i + 0], vertexBuffer[i + 1], vertexBuffer[i + 2]);
                b.set(vertexBuffer[i + 3], vertexBuffer[i + 4], vertexBuffer[i + 5]);
                c.set(vertexBuffer[i + 6], vertexBuffer[i + 7], vertexBuffer[i + 8]);

                uvA.set(uvBuffer[i + 0], uvBuffer[i + 1]);
                uvB.set(uvBuffer[i + 2], uvBuffer[i + 3]);
                uvC.set(uvBuffer[i + 4], uvBuffer[i + 5]);

                centroid.copy(a).add(b).add(c).divideScalar(3);

                var azi:Float = azimuth(centroid);

                correctUV(uvA, i + 0, a, azi);
                correctUV(uvB, i + 2, b, azi);
                correctUV(uvC, i + 4, c, azi);
            }
        }

        function correctUV(uv:Vector2, stride:Int, vector:Vector3, azimuth:Float) {
            if (azimuth < 0 && uv.x == 1) {
                uvBuffer[stride] = uv.x - 1;
            }

            if (vector.x == 0 && vector.z == 0) {
                uvBuffer[stride] = azimuth / 2 / Math.PI + 0.5;
            }
        }

        function azimuth(vector:Vector3):Float {
            return Math.atan2(vector.z, -vector.x);
        }

        function inclination(vector:Vector3):Float {
            return Math.atan2(-vector.y, Math.sqrt(vector.x * vector.x + vector.z * vector.z));
        }
    }

    override public function copy(source:PolyhedronGeometry):PolyhedronGeometry {
        super.copy(source);

        parameters = Object.assign({}, source.parameters);

        return this;
    }

    static public function fromJSON(data:Dynamic):PolyhedronGeometry {
        return new PolyhedronGeometry(data.vertices, data.indices, data.radius, data.detail);
    }
}
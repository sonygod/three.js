import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;
import three.math.Vector2;

class PolyhedronGeometry extends BufferGeometry {

    public var type:String;
    public var parameters:Dynamic;

    public function new(vertices:Array<Float> = [], indices:Array<Int> = [], radius:Float = 1, detail:Int = 0) {

        super();

        this.type = 'PolyhedronGeometry';

        this.parameters = {
            vertices: vertices,
            indices: indices,
            radius: radius,
            detail: detail
        };

        // default buffer data

        var vertexBuffer:Array<Float> = [];
        var uvBuffer:Array<Float> = [];

        // the subdivision creates the vertex buffer data

        subdivide(detail);

        // all vertices should lie on a conceptual sphere with a given radius

        applyRadius(radius);

        // finally, create the uv data

        generateUVs();

        // build non-indexed geometry

        this.setAttribute('position', new BufferAttribute(vertexBuffer, 3));
        this.setAttribute('normal', new BufferAttribute(vertexBuffer.slice(), 3));
        this.setAttribute('uv', new BufferAttribute(uvBuffer, 2));

        if (detail === 0) {

            this.computeVertexNormals(); // flat normals

        } else {

            this.normalizeNormals(); // smooth normals

        }

        // helper functions

        function subdivide(detail:Int) {

            var a:Vector3 = new Vector3();
            var b:Vector3 = new Vector3();
            var c:Vector3 = new Vector3();

            // iterate over all faces and apply a subdivision with the given detail value

            for (i in 0...indices.length by 3) {

                // get the vertices of the face

                getVertexByIndex(indices[i], a);
                getVertexByIndex(indices[i + 1], b);
                getVertexByIndex(indices[i + 2], c);

                // perform subdivision

                subdivideFace(a, b, c, detail);

            }

        }

        function subdivideFace(a:Vector3, b:Vector3, c:Vector3, detail:Int) {

            var cols:Int = detail + 1;

            // we use this multidimensional array as a data structure for creating the subdivision

            var v:Array<Array<Vector3>> = [];

            // construct all of the vertices for this subdivision

            for (i in 0...cols + 1) {

                v[i] = [];

                var aj:Vector3 = a.clone().lerp(c, i / cols);
                var bj:Vector3 = b.clone().lerp(c, i / cols);

                var rows:Int = cols - i;

                for (j in 0...rows + 1) {

                    if (j === 0 && i === cols) {

                        v[i][j] = aj;

                    } else {

                        v[i][j] = aj.clone().lerp(bj, j / rows);

                    }

                }

            }

            // construct all of the faces

            for (i in 0...cols) {

                for (j in 0...2 * (cols - i) - 1) {

                    var k:Int = Std.int(j / 2);

                    if (j % 2 === 0) {

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

            // iterate over the entire buffer and apply the radius to each vertex

            for (i in 0...vertexBuffer.length by 3) {

                vertex.x = vertexBuffer[i];
                vertex.y = vertexBuffer[i + 1];
                vertex.z = vertexBuffer[i + 2];

                vertex.normalize().multiplyScalar(radius);

                vertexBuffer[i] = vertex.x;
                vertexBuffer[i + 1] = vertex.y;
                vertexBuffer[i + 2] = vertex.z;

            }

        }

        function generateUVs() {

            var vertex:Vector3 = new Vector3();

            for (i in 0...vertexBuffer.length by 3) {

                vertex.x = vertexBuffer[i];
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

            // handle case when face straddles the seam, see #3269

            for (i in 0...uvBuffer.length by 6) {

                // uv data of a single face

                var x0:Float = uvBuffer[i];
                var x1:Float = uvBuffer[i + 2];
                var x2:Float = uvBuffer[i + 4];

                var max:Float = Math.max(x0, x1, x2);
                var min:Float = Math.min(x0, x1, x2);

                // 0.9 is somewhat arbitrary

                if (max > 0.9 && min < 0.1) {

                    if (x0 < 0.2) uvBuffer[i] += 1;
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

            vertex.x = vertices[stride];
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

            for (i in 0...vertexBuffer.length by 9, j in 0...uvBuffer.length by 6) {

                a.set(vertexBuffer[i], vertexBuffer[i + 1], vertexBuffer[i + 2]);
                b.set(vertexBuffer[i + 3], vertexBuffer[i + 4], vertexBuffer[i + 5]);
                c.set(vertexBuffer[i + 6], vertexBuffer[i + 7], vertexBuffer[i + 8]);

                uvA.set(uvBuffer[j], uvBuffer[j + 1]);
                uvB.set(uvBuffer[j + 2], uvBuffer[j + 3]);
                uvC.set(uvBuffer[j + 4], uvBuffer[j + 5]);

                centroid.copy(a).add(b).add(c).divideScalar(3);

                var azi:Float = azimuth(centroid);

                correctUV(uvA, j, a, azi);
                correctUV(uvB, j + 2, b, azi);
                correctUV(uvC, j + 4, c, azi);

            }

        }

        function correctUV(uv:Vector2, stride:Int, vector:Vector3, azimuth:Float) {

            if ((azimuth < 0) && (uv.x === 1)) {

                uvBuffer[stride] = uv.x - 1;

            }

            if ((vector.x === 0) && (vector.z === 0)) {

                uvBuffer[stride] = azimuth / 2 / Math.PI + 0.5;

            }

        }

        // Angle around the Y axis, counter-clockwise when looking from above.

        function azimuth(vector:Vector3):Float {

            return Math.atan2(vector.z, -vector.x);

        }

        // Angle above the XZ plane.

        function inclination(vector:Vector3):Float {

            return Math.atan2(-vector.y, Math.sqrt((vector.x * vector.x) + (vector.z * vector.z)));

        }

    }

    public function copy(source:PolyhedronGeometry):PolyhedronGeometry {

        super.copy(source);

        this.parameters = Type.clone(source.parameters);

        return this;

    }

    public static function fromJSON(data:Dynamic):PolyhedronGeometry {

        return new PolyhedronGeometry(data.vertices, data.indices, data.radius, data.details);

    }

}
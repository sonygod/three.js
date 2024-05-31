import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;
import three.math.Vector2;

class PolyhedronGeometry extends BufferGeometry {

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
        subdivide(detail, indices, vertices, vertexBuffer);

        // all vertices should lie on a conceptual sphere with a given radius
        applyRadius(radius, vertexBuffer);

        // finally, create the uv data
        generateUVs(vertexBuffer, uvBuffer);

        // build non-indexed geometry
        this.setAttribute('position', new Float32BufferAttribute(vertexBuffer, 3));
        this.setAttribute('normal', new Float32BufferAttribute(vertexBuffer.slice(), 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvBuffer, 2));

        if (detail == 0) {
            this.computeVertexNormals(); // flat normals
        } else {
            this.normalizeNormals(); // smooth normals
        }
    }

    function subdivide(detail:Int, indices:Array<Int>, vertices:Array<Float>, vertexBuffer:Array<Float>):Void {
        var a:Vector3 = new Vector3();
        var b:Vector3 = new Vector3();
        var c:Vector3 = new Vector3();

        // iterate over all faces and apply a subdivision with the given detail value
        for (i in 0...indices.length / 3) {
            var i3 = i * 3;
            // get the vertices of the face
            getVertexByIndex(indices[i3], a, vertices);
            getVertexByIndex(indices[i3 + 1], b, vertices);
            getVertexByIndex(indices[i3 + 2], c, vertices);

            // perform subdivision
            subdivideFace(a, b, c, detail, vertexBuffer);
        }
    }

    function subdivideFace(a:Vector3, b:Vector3, c:Vector3, detail:Int, vertexBuffer:Array<Float>):Void {
        var cols = detail + 1;

        // we use this multidimensional array as a data structure for creating the subdivision
        var v = new Array<Array<Vector3>>();

        // construct all of the vertices for this subdivision
        for (i in 0...cols + 1) {
            v[i] = new Array<Vector3>();
            var aj = a.clone().lerp(c, i / cols);
            var bj = b.clone().lerp(c, i / cols);

            var rows = cols - i;
            for (j in 0...rows + 1) {
                if (j == 0 && i == cols) {
                    v[i][j] = aj;
                } else {
                    v[i][j] = aj.clone().lerp(bj, j / rows);
                }
            }
        }

        // construct all of the faces
        for (i in 0...cols) {
            for (j in 0...2 * (cols - i) - 1) {
                var k = Math.floor(j / 2);
                if (j % 2 == 0) {
                    pushVertex(v[i][k + 1], vertexBuffer);
                    pushVertex(v[i + 1][k], vertexBuffer);
                    pushVertex(v[i][k], vertexBuffer);
                } else {
                    pushVertex(v[i][k + 1], vertexBuffer);
                    pushVertex(v[i + 1][k + 1], vertexBuffer);
                    pushVertex(v[i + 1][k], vertexBuffer);
                }
            }
        }
    }

    function applyRadius(radius:Float, vertexBuffer:Array<Float>):Void {
        var vertex:Vector3 = new Vector3();

        // iterate over the entire buffer and apply the radius to each vertex
        for (i in 0...vertexBuffer.length / 3) {
            var i3 = i * 3;
            vertex.set(vertexBuffer[i3], vertexBuffer[i3 + 1], vertexBuffer[i3 + 2]);
            vertex.normalize().multiplyScalar(radius);
            vertexBuffer[i3] = vertex.x;
            vertexBuffer[i3 + 1] = vertex.y;
            vertexBuffer[i3 + 2] = vertex.z;
        }
    }

    function generateUVs(vertexBuffer:Array<Float>, uvBuffer:Array<Float>):Void {
        var vertex:Vector3 = new Vector3();

        for (i in 0...vertexBuffer.length / 3) {
            var i3 = i * 3;
            vertex.set(vertexBuffer[i3], vertexBuffer[i3 + 1], vertexBuffer[i3 + 2]);
            var u = azimuth(vertex) / (2 * Math.PI) + 0.5;
            var v = inclination(vertex) / Math.PI + 0.5;
            uvBuffer.push(u, 1 - v);
        }

        correctUVs(vertexBuffer, uvBuffer);
        correctSeam(uvBuffer);
    }

    function correctSeam(uvBuffer:Array<Float>):Void {
        // handle case when face straddles the seam, see #3269
        for (i in 0...uvBuffer.length / 6) {
            var i6 = i * 6;
            // uv data of a single face
            var x0 = uvBuffer[i6];
            var x1 = uvBuffer[i6 + 2];
            var x2 = uvBuffer[i6 + 4];
            var max = Math.max(x0, x1, x2);
            var min = Math.min(x0, x1, x2);

            // 0.9 is somewhat arbitrary
            if (max > 0.9 && min < 0.1) {
                if (x0 < 0.2) uvBuffer[i6] += 1;
                if (x1 < 0.2) uvBuffer[i6 + 2] += 1;
                if (x2 < 0.2) uvBuffer[i6 + 4] += 1;
            }
        }
    }

    function pushVertex(vertex:Vector3, vertexBuffer:Array<Float>):Void {
        vertexBuffer.push(vertex.x, vertex.y, vertex.z);
    }

    function getVertexByIndex(index:Int, vertex:Vector3, vertices:Array<Float>):Void {
        var stride = index * 3;
        vertex.set(vertices[stride], vertices[stride + 1], vertices[stride + 2]);
    }

    function correctUVs(vertexBuffer:Array<Float>, uvBuffer:Array<Float>):Void {
        var a = new Vector3();
        var b = new Vector3();
        var c = new Vector3();
        var centroid = new Vector3();
        var uvA = new Vector2();
        var uvB = new Vector2();
        var uvC = new Vector2();

        for (i in 0...vertexBuffer.length / 9) {
            var i9 = i * 9;
            var j6 = i * 6;
            a.set(vertexBuffer[i9], vertexBuffer[i9 + 1], vertexBuffer[i9 + 2]);
            b.set(vertexBuffer[i9 + 3], vertexBuffer[i9 + 4], vertexBuffer[i9 + 5]);
            c.set(vertexBuffer[i9 + 6], vertexBuffer[i9 + 7], vertexBuffer[i9 + 8]);
            uvA.set(uvBuffer[j6], uvBuffer[j6 + 1]);
            uvB.set(uvBuffer[j6 + 2], uvBuffer[j6 + 3]);
            uvC.set(uvBuffer[j6 + 4], uvBuffer[j6 + 5]);

            centroid.copy(a).add(b).add(c).divideScalar(3);
            var azi = azimuth(centroid);
            correctUV(uvA, j6, a, azi, uvBuffer);
            correctUV(uvB, j6 + 2, b, azi, uvBuffer);
            correctUV(uvC, j6 + 4, c, azi, uvBuffer);
        }
    }

    function correctUV(uv:Vector2, stride:Int, vector:Vector3, azimuth:Float, uvBuffer:Array<Float>):Void {
        if (azimuth < 0 && uv.x == 1) {
            uvBuffer[stride] = uv.x - 1;
        }

        if (vector.x == 0 && vector.z == 0) {
            uvBuffer[stride] = azimuth / (2 * Math.PI) + 0.5;
        }
    }

    // Angle around the Y axis, counter-clockwise when looking from above.
    function azimuth(vector:Vector3):Float {
        return Math.atan2(vector.z, -vector.x);
    }

    // Angle above the XZ plane.
    function inclination(vector:Vector3):Float {
        return Math.atan2(-vector.y, Math.sqrt(vector.x * vector.x + vector.z * vector.z));
    }

    public function copy(source:PolyhedronGeometry):PolyhedronGeometry {
        super.copy(source);
        this.parameters = haxe.DynamicAccess.copy(source.parameters);
        return this;
    }

    public static function fromJSON(data:Dynamic):PolyhedronGeometry {
        return new PolyhedronGeometry(data.vertices, data.indices, data.radius, data.details);
    }
}
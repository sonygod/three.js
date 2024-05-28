package three.geom;

import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.extras.curves.Curves;
import three.math.Vector2;
import three.math.Vector3;

class TubeGeometry extends BufferGeometry {
    public function new(path:QuadBezCurve3 = null, tubularSegments:Int = 64, radius:Float = 1, radialSegments:Int = 8, closed:Bool = false) {
        super();

        if (path == null) path = new QuadBezCurve3(new Vector3(-1, -1, 0), new Vector3(-1, 1, 0), new Vector3(1, 1, 0));

        this.type = 'TubeGeometry';

        this.parameters = {
            path: path,
            tubularSegments: tubularSegments,
            radius: radius,
            radialSegments: radialSegments,
            closed: closed
        };

        var frames = path.computeFrenetFrames(tubularSegments, closed);

        this.tangents = frames.tangents;
        this.normals = frames.normals;
        this.binormals = frames.binormals;

        var vertex = new Vector3();
        var normal = new Vector3();
        var uv = new Vector2();
        var P = new Vector3();

        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];
        var indices:Array<Int> = [];

        generateBufferData();

        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

        function generateBufferData() {
            for (i in 0...tubularSegments) {
                generateSegment(i);
            }

            // if the geometry is not closed, generate the last row of vertices and normals
            // at the regular position on the given path
            // if the geometry is closed, duplicate the first row of vertices and normals (uvs will differ)
            generateSegment((closed) ? 0 : tubularSegments);

            // uvs are generated in a separate function.
            // this makes it easy compute correct values for closed geometries
            generateUVs();

            // finally create faces
            generateIndices();
        }

        function generateSegment(i:Int) {
            // we use getPointAt to sample evenly distributed points from the given path
            P = path.getPointAt(i / tubularSegments, P);

            // retrieve corresponding normal and binormal
            var N = frames.normals[i];
            var B = frames.binormals[i];

            // generate normals and vertices for the current segment
            for (j in 0...(radialSegments + 1)) {
                var v = j / radialSegments * Math.PI * 2;

                var sin = Math.sin(v);
                var cos = -Math.cos(v);

                // normal
                normal.x = cos * N.x + sin * B.x;
                normal.y = cos * N.y + sin * B.y;
                normal.z = cos * N.z + sin * B.z;
                normal.normalize();

                normals.push(normal.x, normal.y, normal.z);

                // vertex
                vertex.x = P.x + radius * normal.x;
                vertex.y = P.y + radius * normal.y;
                vertex.z = P.z + radius * normal.z;

                vertices.push(vertex.x, vertex.y, vertex.z);
            }
        }

        function generateIndices() {
            for (j in 1...tubularSegments + 1) {
                for (i in 1...radialSegments + 1) {
                    var a = (radialSegments + 1) * (j - 1) + (i - 1);
                    var b = (radialSegments + 1) * j + (i - 1);
                    var c = (radialSegments + 1) * j + i;
                    var d = (radialSegments + 1) * (j - 1) + i;

                    // faces
                    indices.push(a, b, d);
                    indices.push(b, c, d);
                }
            }
        }

        function generateUVs() {
            for (i in 0...tubularSegments + 1) {
                for (j in 0...radialSegments + 1) {
                    uv.x = i / tubularSegments;
                    uv.y = j / radialSegments;

                    uvs.push(uv.x, uv.y);
                }
            }
        }
    }

    override public function copy(source:TubeGeometry):TubeGeometry {
        super.copy(source);

        this.parameters = Object.assign({}, source.parameters);

        return this;
    }

    override public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();

        data.path = this.parameters.path.toJSON();

        return data;
    }

    static public function fromJSON(data:Dynamic):TubeGeometry {
        // This only works for built-in curves (e.g. CatmullRomCurve3).
        // User defined curves or instances of CurvePath will not be deserialized.
        return new TubeGeometry(
            new Curves[data.path.type]().fromJSON(data.path),
            data.tubularSegments,
            data.radius,
            data.radialSegments,
            data.closed
        );
    }
}
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.extras.curves.Curves;
import three.math.Vector2;
import three.math.Vector3;

class TubeGeometry extends BufferGeometry {
    public var path:Curves.Curve;
    public var tubularSegments:Int;
    public var radius:Float;
    public var radialSegments:Int;
    public var closed:Bool;

    public function new(path:Curves.Curve = new Curves.QuadraticBezierCurve3(new Vector3(-1, -1, 0), new Vector3(-1, 1, 0), new Vector3(1, 1, 0)), tubularSegments:Int = 64, radius:Float = 1, radialSegments:Int = 8, closed:Bool = false) {
        super();
        this.type = "TubeGeometry";
        this.path = path;
        this.tubularSegments = tubularSegments;
        this.radius = radius;
        this.radialSegments = radialSegments;
        this.closed = closed;

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
        this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
        this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
        this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
    }

    public var tangents:Array<Vector3>;
    public var normals:Array<Vector3>;
    public var binormals:Array<Vector3>;

    private function generateBufferData() {
        for (i in 0...tubularSegments) {
            generateSegment(i);
        }

        generateSegment((closed) ? 0 : tubularSegments);

        generateUVs();
        generateIndices();
    }

    private function generateSegment(i:Int) {
        var P = path.getPointAt(i / tubularSegments, P);

        var N = normals[i];
        var B = binormals[i];

        for (j in 0...radialSegments + 1) {
            var v = j / radialSegments * Math.PI * 2;

            var sin = Math.sin(v);
            var cos = -Math.cos(v);

            normal.x = cos * N.x + sin * B.x;
            normal.y = cos * N.y + sin * B.y;
            normal.z = cos * N.z + sin * B.z;
            normal.normalize();

            normals.push(normal.x, normal.y, normal.z);

            vertex.x = P.x + radius * normal.x;
            vertex.y = P.y + radius * normal.y;
            vertex.z = P.z + radius * normal.z;

            vertices.push(vertex.x, vertex.y, vertex.z);
        }
    }

    private function generateIndices() {
        for (j in 1...tubularSegments + 1) {
            for (i in 1...radialSegments + 1) {
                var a = (radialSegments + 1) * (j - 1) + (i - 1);
                var b = (radialSegments + 1) * j + (i - 1);
                var c = (radialSegments + 1) * j + i;
                var d = (radialSegments + 1) * (j - 1) + i;

                indices.push(a, b, d);
                indices.push(b, c, d);
            }
        }
    }

    private function generateUVs() {
        for (i in 0...tubularSegments + 1) {
            for (j in 0...radialSegments + 1) {
                uv.x = i / tubularSegments;
                uv.y = j / radialSegments;

                uvs.push(uv.x, uv.y);
            }
        }
    }

    public function copy(source:TubeGeometry):TubeGeometry {
        super.copy(source);

        path = source.path;
        tubularSegments = source.tubularSegments;
        radius = source.radius;
        radialSegments = source.radialSegments;
        closed = source.closed;

        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();
        data.path = path.toJSON();
        return data;
    }

    public static function fromJSON(data:Dynamic):TubeGeometry {
        // This only works for built-in curves (e.g. CatmullRomCurve3).
        // User defined curves or instances of CurvePath will not be deserialized.
        return new TubeGeometry(
            cast Curves.Curve.fromJSON(data.path),
            data.tubularSegments,
            data.radius,
            data.radialSegments,
            data.closed
        );
    }
}
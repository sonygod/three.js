import js.Browser.console;
import js.Node.Buffer;

class TorusKnotGeometry extends BufferGeometry {
    public var radius:Float = 1.0;
    public var tube:Float = 0.4;
    public var tubularSegments:Int = 64;
    public var radialSegments:Int = 8;
    public var p:Int = 2;
    public var q:Int = 3;

    public function new() {
        super();
        this.type = 'TorusKnotGeometry';
        tubularSegments = std.int(tubularSegments);
        radialSegments = std:int(radialSegments);

        var indices = [];
        var vertices = [];
        var normals = [];
        var uvs = [];

        var vertex = new Vector3();
        var normal = new Vector3();

        var P1 = new Vector3();
        var P2 = new Vector3();

        var B = new Vector3();
        var T = new Vector3();
        var N = new Vector3();

        for (i in 0...tubularSegments) {
            var u = i / tubularSegments * p * Std.Math.PI() * 2;

            calculatePositionOnCurve(u, p, q, radius, P1);
            calculatePositionOnCurve(u + 0.01, p, q, radius, P2);

            T.sub(P2, P1);
            N.add(P2, P1);
            B.cross(T, N);
            N.cross(B, T);

            B.normalize();
            N.normalize();

            for (j in 0...radialSegments) {
                var v = j / radialSegments * Std.Math.PI() * 2;
                var cx = -tube * Std.Math.cos(v);
                var cy = tube * Std.Math.sin(v);

                vertex.x = P1.x + (cx * N.x + cy * B.x);
                vertex.y = P1.y + (cx * N.y + cy * B.y);
                vertex.z = P1.z + (cx * N.z + cy * B.z);

                vertices.push(vertex.x);
                vertices.push(vertex.y);
                vertices.push(vertex.z);

                normal.sub(vertex, P1);
                normal.normalize();

                normals.push(normal.x);
                normals.push(normal.y);
                normals.push(normal.z);

                uvs.push(i / tubularSegments);
                uvs.push(j / radialSegments);
            }
        }

        for (j in 1...tubularSegments) {
            for (i in 1...radialSegments) {
                var a = (radialSegments + 1) * (j - 1) + (i - 1);
                var b = (radialSegments + 1) * j + (i - 1);
                var c = (radialSegments + 1) * j + i;
                var d = (radialSegments + 1) * (j - 1) + i;

                indices.push(a);
                indices.push(b);
                indices.push(d);

                indices.push(b);
                indices.push(c);
                indices.push(d);
            }
        }

        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    }

    public function copy(source:TorusKnotGeometry) {
        super.copy(source);
        this.radius = source.radius;
        this.tube = source.tube;
        this.tubularSegments = source.tubularSegments;
        this.radialSegments = source.radialSegments;
        this.p = source.p;
        this.q = source.q;
        return this;
    }

    public static function fromJSON(data:Dynamic) {
        return new TorusKnotGeometry(
            data.radius,
            data.tube,
            data.tubularSegments,
            data.radialSegments,
            data.p,
            data.q
        );
    }

    function calculatePositionOnCurve(u:Float, p:Int, q:Int, radius:Float, position:Vector3) {
        var cu = Std.Math.cos(u);
        var su = Std.Math.sin(u);
        var quOverP = q / p * u;
        var cs = Std.Math.cos(quOverP);

        position.x = radius * (2 + cs) * 0.5 * cu;
        position.y = radius * (2 + cs) * su * 0.5;
        position.z = radius * Std.Math.sin(quOverP) * 0.5;
    }
}
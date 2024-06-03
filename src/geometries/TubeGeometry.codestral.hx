import js.Boot;
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.extras.curves.Curves;
import three.math.Vector2;
import three.math.Vector3;

class TubeGeometry extends BufferGeometry {

    public function new(path:Dynamic = null, tubularSegments:Int = 64, radius:Float = 1.0, radialSegments:Int = 8, closed:Bool = false) {
        super();
        if (path == null) path = js.Boot.cast(js.Boot.getClass(Curves).getField('QuadraticBezierCurve3').call(new Vector3(-1, -1, 0), new Vector3(-1, 1, 0), new Vector3(1, 1, 0)));

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

        var vertices = [];
        var normals = [];
        var uvs = [];
        var indices = [];

        generateBufferData();

        this.setIndex(indices);
        this.setAttribute('position', new BufferAttribute(vertices, 3));
        this.setAttribute('normal', new BufferAttribute(normals, 3));
        this.setAttribute('uv', new BufferAttribute(uvs, 2));

        function generateBufferData() {
            for (i in 0...tubularSegments) {
                generateSegment(i);
            }

            generateSegment((closed == false) ? tubularSegments : 0);

            generateUVs();

            generateIndices();
        }

        function generateSegment(i:Int) {
            P = path.getPointAt(i / tubularSegments, P);

            var N = frames.normals[i];
            var B = frames.binormals[i];

            for (j in 0...radialSegments+1) {
                var v = j / radialSegments * Math.PI * 2;

                var sin = Math.sin(v);
                var cos = -Math.cos(v);

                normal.x = (cos * N.x + sin * B.x);
                normal.y = (cos * N.y + sin * B.y);
                normal.z = (cos * N.z + sin * B.z);
                normal.normalize();

                normals.push(normal.x, normal.y, normal.z);

                vertex.x = P.x + radius * normal.x;
                vertex.y = P.y + radius * normal.y;
                vertex.z = P.z + radius * normal.z;

                vertices.push(vertex.x, vertex.y, vertex.z);
            }
        }

        function generateIndices() {
            for (j in 1...tubularSegments+1) {
                for (i in 1...radialSegments+1) {
                    var a = (radialSegments + 1) * (j - 1) + (i - 1);
                    var b = (radialSegments + 1) * j + (i - 1);
                    var c = (radialSegments + 1) * j + i;
                    var d = (radialSegments + 1) * (j - 1) + i;

                    indices.push(a, b, d);
                    indices.push(b, c, d);
                }
            }
        }

        function generateUVs() {
            for (i in 0...tubularSegments+1) {
                for (j in 0...radialSegments+1) {
                    uv.x = i / tubularSegments;
                    uv.y = j / radialSegments;

                    uvs.push(uv.x, uv.y);
                }
            }
        }
    }

    public function copy(source:TubeGeometry):TubeGeometry {
        super.copy(source);

        this.parameters = js.Boot.instanceof(source.parameters, js.Boot.getClass(js.Boot.getClass(Object))) ? js.Boot.cast(source.parameters.clone()) : source.parameters;

        return this;
    }

    public function toJSON():Dynamic {
        var data = super.toJSON();

        data.path = this.parameters.path.toJSON();

        return data;
    }

    public static function fromJSON(data:Dynamic):TubeGeometry {
        return new TubeGeometry(
            js.Boot.cast(js.Boot.getClass(js.Boot.getClass(Curves)).getField(data.path.type).call().fromJSON(data.path)),
            data.tubularSegments,
            data.radius,
            data.radialSegments,
            data.closed
        );
    }
}
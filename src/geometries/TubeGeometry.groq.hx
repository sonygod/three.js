package three.geometry;

import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.extras.curves.Curves;
import three.math.Vector2;
import three.math.Vector3;

class TubeGeometry extends BufferGeometry {
    public var type:String;
    public var parameters:Dynamic;
    public var tangents:Array<Vector3>;
    public var normals:Array<Vector3>;
    public var binormals:Array<Vector3>;

    public function new(?path:Curve, ?tubularSegments:Int = 64, ?radius:Float = 1, ?radialSegments:Int = 8, ?closed:Bool = false) {
        super();

        type = 'TubeGeometry';

        parameters = {
            path: path,
            tubularSegments: tubularSegments,
            radius: radius,
            radialSegments: radialSegments,
            closed: closed
        };

        var frames = path.computeFrenetFrames(tubularSegments, closed);

        tangents = frames.tangents;
        normals = frames.normals;
        binormals = frames.binormals;

        var vertex = new Vector3();
        var normal = new Vector3();
        var uv = new Vector2();
        var P = new Vector3();

        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];
        var indices:Array<Int> = [];

        generateBufferData();

        setIndex(indices);
        setAttribute('position', new Float32BufferAttribute(vertices, 3));
        setAttribute('normal', new Float32BufferAttribute(normals, 3));
        setAttribute('uv', new Float32BufferAttribute(uvs, 2));

        function generateBufferData() {
            for (i in 0...tubularSegments) {
                generateSegment(i);
            }

            if (!closed) {
                generateSegment(tubularSegments);
            } else {
                generateSegment(0);
            }

            generateUVs();
            generateIndices();
        }

        function generateSegment(i:Int) {
            P = path.getPointAt(i / tubularSegments, P);

            var N = frames.normals[i];
            var B = frames.binormals[i];

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

        function generateIndices() {
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

    override public function copy(source:TubeGeometry) {
        super.copy(source);

        parameters = Object.assign({}, source.parameters);

        return this;
    }

    override public function toJSON():Dynamic {
        var data = super.toJSON();

        data.path = parameters.path.toJSON();

        return data;
    }

    static public function fromJSON(data:Dynamic) {
        return new TubeGeometry(
            Curves.create(data.path.type).fromJSON(data.path),
            data.tubularSegments,
            data.radius,
            data.radialSegments,
            data.closed
        );
    }
}
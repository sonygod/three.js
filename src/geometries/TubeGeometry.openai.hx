package geometries;

import core.BufferAttribute;
import core.BufferGeometry;
import extras.curves.Curves;
import math.Vector2;
import math.Vector3;

class TubeGeometry extends BufferGeometry {

    public var path:Curve;
    public var tubularSegments:Int;
    public var radius:Float;
    public var radialSegments:Int;
    public var closed:Bool;

    public var tangents:Array<Vector3>;
    public var normals:Array<Vector3>;
    public var binormals:Array<Vector3>;

    public function new(path:Curve = new QuadraticBezierCurve3(new Vector3(-1, -1, 0), new Vector3(-1, 1, 0), new Vector3(1, 1, 0)),
                        tubularSegments:Int = 64, radius:Float = 1, radialSegments:Int = 8, closed:Bool = false) {

        super();

        this.path = path;
        this.tubularSegments = tubularSegments;
        this.radius = radius;
        this.radialSegments = radialSegments;
        this.closed = closed;

        var frames = path.computeFrenetFrames(tubularSegments, closed);

        this.tangents = frames.tangents;
        this.normals = frames.normals;
        this.binormals = frames.binormals;

        var vertex:Vector3 = new Vector3();
        var normal:Vector3 = new Vector3();
        var uv:Vector2 = new Vector2();
        var P:Vector3 = new Vector3();

        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];
        var indices:Array<Int> = [];

        generateBufferData();

        setIndex(indices);
        setAttribute("position", new BufferAttribute(vertices, 3));
        setAttribute("normal", new BufferAttribute(normals, 3));
        setAttribute("uv", new BufferAttribute(uvs, 2));

        function generateBufferData():Void {

            loop(i in 0...tubularSegments) {
                generateSegment(i);
            }

            generateSegment(closed ? 0 : tubularSegments);

            generateUVs();

            generateIndices();
        }

        function generateSegment(i:Int):Void {

            P = path.getPointAt(i / tubularSegments, P);

            var N:Vector3 = frames.normals[i];
            var B:Vector3 = frames.binormals[i];

            for (j in 0...radialSegments + 1) {

                var v:Float = j / radialSegments * Math.PI * 2;
                var sin:Float = Math.sin(v);
                var cos:Float = -Math.cos(v);
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

        function generateIndices():Void {

            for (j in 1 until tubularSegments + 1) {

                for (i in 1 until radialSegments + 1) {

                    var a:Int = (radialSegments + 1) * (j - 1) + (i - 1);
                    var b:Int = (radialSegments + 1) * j + (i - 1);
                    var c:Int = (radialSegments + 1) * j + i;
                    var d:Int = (radialSegments + 1) * (j - 1) + i;
                    indices.push(a, b, d);
                    indices.push(b, c, d);
                }
            }
        }

        function generateUVs():Void {

            for (i in 0...tubularSegments + 1) {
                for (j in 0...radialSegments + 1) {
                    uv.x = i / tubularSegments;
                    uv.y = j / radialSegments;
                    uvs.push(uv.x, uv.y);
                }
            }
        }
    }

    public function copy(source:TubeGeometry):TubeGeometry {

        super.copy(source);

        this.path = source.path;
        this.tubularSegments = source.tubularSegments;
        this.radius = source.radius;
        this.radialSegments = source.radialSegments;
        this.closed = source.closed;

        return this;
    }

    public function toJSON():Dynamic {

        var data:Dynamic = super.toJSON();

        data.path = this.path.toJSON();

        return data;
    }

    public static function fromJSON(data:Dynamic):TubeGeometry {

        return new TubeGeometry(
            curveref[data.path["type"]].fromJSON(data.path),
            data.tubularSegments,
            data.radius,
            data.radialSegments,
            data.closed
        );
    }

}

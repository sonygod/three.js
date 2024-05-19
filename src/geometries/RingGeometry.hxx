import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector2;
import three.math.Vector3;

class RingGeometry extends BufferGeometry {

    public function new(innerRadius:Float = 0.5, outerRadius:Float = 1, thetaSegments:Int = 32, phiSegments:Int = 1, thetaStart:Float = 0, thetaLength:Float = Math.PI * 2) {
        super();

        this.type = 'RingGeometry';

        this.parameters = {
            innerRadius: innerRadius,
            outerRadius: outerRadius,
            thetaSegments: thetaSegments,
            phiSegments: phiSegments,
            thetaStart: thetaStart,
            thetaLength: thetaLength
        };

        thetaSegments = Math.max(3, thetaSegments);
        phiSegments = Math.max(1, phiSegments);

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        var radius:Float = innerRadius;
        var radiusStep:Float = (outerRadius - innerRadius) / phiSegments;
        var vertex:Vector3 = new Vector3();
        var uv:Vector2 = new Vector2();

        for (j in 0...phiSegments+1) {
            for (i in 0...thetaSegments+1) {
                var segment:Float = thetaStart + i / thetaSegments * thetaLength;

                vertex.x = radius * Math.cos(segment);
                vertex.y = radius * Math.sin(segment);

                vertices.push(vertex.x, vertex.y, vertex.z);

                normals.push(0, 0, 1);

                uv.x = (vertex.x / outerRadius + 1) / 2;
                uv.y = (vertex.y / outerRadius + 1) / 2;

                uvs.push(uv.x, uv.y);
            }

            radius += radiusStep;
        }

        for (j in 0...phiSegments) {
            var thetaSegmentLevel:Int = j * (thetaSegments + 1);

            for (i in 0...thetaSegments) {
                var segment:Int = i + thetaSegmentLevel;

                var a:Int = segment;
                var b:Int = segment + thetaSegments + 1;
                var c:Int = segment + thetaSegments + 2;
                var d:Int = segment + 1;

                indices.push(a, b, d);
                indices.push(b, c, d);
            }
        }

        this.setIndex(indices);
        this.setAttribute('position', new BufferAttribute(vertices, 3));
        this.setAttribute('normal', new BufferAttribute(normals, 3));
        this.setAttribute('uv', new BufferAttribute(uvs, 2));
    }

    public function copy(source:RingGeometry):RingGeometry {
        super.copy(source);

        this.parameters = Std.clone(source.parameters);

        return this;
    }

    public static function fromJSON(data:Dynamic):RingGeometry {
        return new RingGeometry(data.innerRadius, data.outerRadius, data.thetaSegments, data.phiSegments, data.thetaStart, data.thetaLength);
    }
}
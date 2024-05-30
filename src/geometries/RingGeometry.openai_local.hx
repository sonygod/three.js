import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector2;
import three.math.Vector3;

class RingGeometry extends BufferGeometry {
    public var parameters:Dynamic;

    public function new(innerRadius:Float = 0.5, outerRadius:Float = 1, thetaSegments:Int = 32, phiSegments:Int = 1, thetaStart:Float = 0, thetaLength:Float = Math.PI * 2) {
        super();

        this.type = "RingGeometry";

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

        // buffers
        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // some helper variables
        var radius = innerRadius;
        var radiusStep = (outerRadius - innerRadius) / phiSegments;
        var vertex = new Vector3();
        var uv = new Vector2();

        // generate vertices, normals and uvs
        for (j in 0...phiSegments + 1) {
            for (i in 0...thetaSegments + 1) {
                // values are generated from the inside of the ring to the outside
                var segment = thetaStart + i / thetaSegments * thetaLength;

                // vertex
                vertex.x = radius * Math.cos(segment);
                vertex.y = radius * Math.sin(segment);
                vertex.z = 0; // Ensure z is set as it is not updated elsewhere

                vertices.push(vertex.x, vertex.y, vertex.z);

                // normal
                normals.push(0, 0, 1);

                // uv
                uv.x = (vertex.x / outerRadius + 1) / 2;
                uv.y = (vertex.y / outerRadius + 1) / 2;

                uvs.push(uv.x, uv.y);
            }

            // increase the radius for next row of vertices
            radius += radiusStep;
        }

        // indices
        for (j in 0...phiSegments) {
            var thetaSegmentLevel = j * (thetaSegments + 1);

            for (i in 0...thetaSegments) {
                var segment = i + thetaSegmentLevel;

                var a = segment;
                var b = segment + thetaSegments + 1;
                var c = segment + thetaSegments + 2;
                var d = segment + 1;

                // faces
                indices.push(a, b, d);
                indices.push(b, c, d);
            }
        }

        // build geometry
        this.setIndex(indices);
        this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
        this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
        this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
    }

    public override function copy(source:BufferGeometry):BufferGeometry {
        super.copy(source);

        this.parameters = Reflect.copy(source.parameters);

        return this;
    }

    public static function fromJSON(data:Dynamic):RingGeometry {
        return new RingGeometry(data.innerRadius, data.outerRadius, data.thetaSegments, data.phiSegments, data.thetaStart, data.thetaLength);
    }
}
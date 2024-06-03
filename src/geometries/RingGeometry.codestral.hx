import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector2;
import three.math.Vector3;

class RingGeometry extends BufferGeometry {

    public function new(innerRadius:Float = 0.5, outerRadius:Float = 1.0, thetaSegments:Int = 32, phiSegments:Int = 1, thetaStart:Float = 0.0, thetaLength:Float = Math.PI * 2) {
        super();

        this.type = 'RingGeometry';

        this.parameters = {
            'innerRadius': innerRadius,
            'outerRadius': outerRadius,
            'thetaSegments': thetaSegments,
            'phiSegments': phiSegments,
            'thetaStart': thetaStart,
            'thetaLength': thetaLength
        };

        thetaSegments = Math.max(3, thetaSegments);
        phiSegments = Math.max(1, phiSegments);

        // buffers
        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // some helper variables
        var radius:Float = innerRadius;
        var radiusStep:Float = (outerRadius - innerRadius) / phiSegments;
        var vertex:Vector3 = new Vector3();
        var uv:Vector2 = new Vector2();

        // generate vertices, normals and uvs
        for (var j:Int = 0; j <= phiSegments; j++) {
            for (var i:Int = 0; i <= thetaSegments; i++) {
                // values are generated from the inside of the ring to the outside
                var segment:Float = thetaStart + i / thetaSegments * thetaLength;

                // vertex
                vertex.x = radius * Math.cos(segment);
                vertex.y = radius * Math.sin(segment);

                vertices.push(vertex.x, vertex.y, vertex.z);

                // normal
                normals.push(0.0, 0.0, 1.0);

                // uv
                uv.x = (vertex.x / outerRadius + 1) / 2;
                uv.y = (vertex.y / outerRadius + 1) / 2;

                uvs.push(uv.x, uv.y);
            }
            // increase the radius for the next row of vertices
            radius += radiusStep;
        }

        // indices
        for (var j:Int = 0; j < phiSegments; j++) {
            var thetaSegmentLevel:Int = j * (thetaSegments + 1);
            for (var i:Int = 0; i < thetaSegments; i++) {
                var segment:Int = i + thetaSegmentLevel;

                var a:Int = segment;
                var b:Int = segment + thetaSegments + 1;
                var c:Int = segment + thetaSegments + 2;
                var d:Int = segment + 1;

                // faces
                indices.push(a, b, d);
                indices.push(b, c, d);
            }
        }

        // build geometry
        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    }

    public function copy(source:RingGeometry):RingGeometry {
        super.copy(source);

        this.parameters = source.parameters.copy();

        return this;
    }

    public static function fromJSON(data:Dynamic):RingGeometry {
        return new RingGeometry(data.innerRadius, data.outerRadius, data.thetaSegments, data.phiSegments, data.thetaStart, data.thetaLength);
    }
}
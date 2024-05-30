import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;
import three.math.Vector2;

class CircleGeometry extends BufferGeometry {

    public var type:String;
    public var parameters:{ radius:Float, segments:Int, thetaStart:Float, thetaLength:Float };

    public function new(radius:Float = 1, segments:Int = 32, thetaStart:Float = 0, thetaLength:Float = Math.PI * 2) {

        super();

        this.type = 'CircleGeometry';

        this.parameters = {
            radius: radius,
            segments: segments,
            thetaStart: thetaStart,
            thetaLength: thetaLength
        };

        segments = Math.max(3, segments);

        // buffers

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // helper variables

        var vertex:Vector3 = new Vector3();
        var uv:Vector2 = new Vector2();

        // center point

        vertices.push(0, 0, 0);
        normals.push(0, 0, 1);
        uvs.push(0.5, 0.5);

        for (s in 0...segments + 1) {

            var segment:Float = thetaStart + s / segments * thetaLength;

            // vertex

            vertex.x = radius * Math.cos(segment);
            vertex.y = radius * Math.sin(segment);

            vertices.push(vertex.x, vertex.y, vertex.z);

            // normal

            normals.push(0, 0, 1);

            // uvs

            uv.x = (vertices[s * 3 + 3] / radius + 1) / 2;
            uv.y = (vertices[s * 3 + 4] / radius + 1) / 2;

            uvs.push(uv.x, uv.y);

        }

        // indices

        for (i in 1...segments + 1) {
            indices.push(i, i + 1, 0);
        }

        // build geometry

        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));

    }

    public function copy(source:CircleGeometry):CircleGeometry {

        super.copy(source);

        this.parameters = {
            radius: source.parameters.radius,
            segments: source.parameters.segments,
            thetaStart: source.parameters.thetaStart,
            thetaLength: source.parameters.thetaLength
        };

        return this;

    }

    public static function fromJSON(data:{ radius:Float, segments:Int, thetaStart:Float, thetaLength:Float }):CircleGeometry {

        return new CircleGeometry(data.radius, data.segments, data.thetaStart, data.thetaLength);

    }

}
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;
import three.math.Vector2;

class CircleGeometry extends BufferGeometry {

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

        var vertex = new Vector3();
        var uv = new Vector2();

        // center point

        vertices.push(0, 0, 0);
        normals.push(0, 0, 1);
        uvs.push(0.5, 0.5);

        for (s in 0...segments) {

            var segment = thetaStart + s / segments * thetaLength;

            // vertex

            vertex.x = radius * Math.cos(segment);
            vertex.y = radius * Math.sin(segment);

            vertices.push(vertex.x, vertex.y, vertex.z);

            // normal

            normals.push(0, 0, 1);

            // uvs

            uv.x = (vertices[i] / radius + 1) / 2;
            uv.y = (vertices[i + 1] / radius + 1) / 2;

            uvs.push(uv.x, uv.y);

        }

        // indices

        for (i in 1...segments) {

            indices.push(i, i + 1, 0);

        }

        // build geometry

        this.setIndex(indices);
        this.setAttribute('position', new BufferAttribute(vertices, 3));
        this.setAttribute('normal', new BufferAttribute(normals, 3));
        this.setAttribute('uv', new BufferAttribute(uvs, 2));

    }

    public function copy(source:CircleGeometry):CircleGeometry {

        super.copy(source);

        this.parameters = Std.clone(source.parameters);

        return this;

    }

    public static function fromJSON(data:Dynamic):CircleGeometry {

        return new CircleGeometry(data.radius, data.segments, data.thetaStart, data.thetaLength);

    }

}
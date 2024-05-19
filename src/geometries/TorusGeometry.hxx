import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;

class TorusGeometry extends BufferGeometry {

    public function new(radius:Float = 1, tube:Float = 0.4, radialSegments:Int = 12, tubularSegments:Int = 48, arc:Float = Math.PI * 2) {
        super();

        this.type = 'TorusGeometry';

        this.parameters = {
            radius: radius,
            tube: tube,
            radialSegments: radialSegments,
            tubularSegments: tubularSegments,
            arc: arc
        };

        radialSegments = Std.int(radialSegments);
        tubularSegments = Std.int(tubularSegments);

        // buffers

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // helper variables

        var center = new Vector3();
        var vertex = new Vector3();
        var normal = new Vector3();

        // generate vertices, normals and uvs

        for (j in 0...radialSegments) {

            for (i in 0...tubularSegments) {

                var u = i / tubularSegments * arc;
                var v = j / radialSegments * Math.PI * 2;

                // vertex

                vertex.x = (radius + tube * Math.cos(v)) * Math.cos(u);
                vertex.y = (radius + tube * Math.cos(v)) * Math.sin(u);
                vertex.z = tube * Math.sin(v);

                vertices.push(vertex.x, vertex.y, vertex.z);

                // normal

                center.x = radius * Math.cos(u);
                center.y = radius * Math.sin(u);
                normal.subVectors(vertex, center).normalize();

                normals.push(normal.x, normal.y, normal.z);

                // uv

                uvs.push(i / tubularSegments);
                uvs.push(j / radialSegments);

            }

        }

        // generate indices

        for (j in 1...radialSegments) {

            for (i in 1...tubularSegments) {

                // indices

                var a = (tubularSegments + 1) * j + i - 1;
                var b = (tubularSegments + 1) * (j - 1) + i - 1;
                var c = (tubularSegments + 1) * (j - 1) + i;
                var d = (tubularSegments + 1) * j + i;

                // faces

                indices.push(a, b, d);
                indices.push(b, c, d);

            }

        }

        // build geometry

        this.setIndex(indices);
        this.setAttribute('position', new BufferAttribute(vertices, 3));
        this.setAttribute('normal', new BufferAttribute(normals, 3));
        this.setAttribute('uv', new BufferAttribute(uvs, 2));

    }

    public function copy(source:TorusGeometry):TorusGeometry {

        super.copy(source);

        this.parameters = Std.clone(source.parameters);

        return this;

    }

    static public function fromJSON(data:Dynamic):TorusGeometry {

        return new TorusGeometry(data.radius, data.tube, data.radialSegments, data.tubularSegments, data.arc);

    }

}
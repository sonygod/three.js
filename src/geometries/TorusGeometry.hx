package three.geometries;

import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
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

        radialSegments = Math.floor(radialSegments);
        tubularSegments = Math.floor(tubularSegments);

        // buffers

        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        // helper variables

        var center:Vector3 = new Vector3();
        var vertex:Vector3 = new Vector3();
        var normal:Vector3 = new Vector3();

        // generate vertices, normals and uvs

        for (j in 0...radialSegments + 1) {
            for (i in 0...tubularSegments + 1) {
                var u:Float = i / tubularSegments * arc;
                var v:Float = j / radialSegments * Math.PI * 2;

                // vertex

                vertex.x = (radius + tube * Math.cos(v)) * Math.cos(u);
                vertex.y = (radius + tube * Math.cos(v)) * Math.sin(u);
                vertex.z = tube * Math.sin(v);

                vertices.push(vertex.x);
                vertices.push(vertex.y);
                vertices.push(vertex.z);

                // normal

                center.x = radius * Math.cos(u);
                center.y = radius * Math.sin(u);
                normal.subVectors(vertex, center).normalize();

                normals.push(normal.x);
                normals.push(normal.y);
                normals.push(normal.z);

                // uv

                uvs.push(i / tubularSegments);
                uvs.push(j / radialSegments);
            }
        }

        // generate indices

        for (j in 1...radialSegments + 1) {
            for (i in 1...tubularSegments + 1) {
                // indices

                var a:Int = (tubularSegments + 1) * j + i - 1;
                var b:Int = (tubularSegments + 1) * (j - 1) + i - 1;
                var c:Int = (tubularSegments + 1) * (j - 1) + i;
                var d:Int = (tubularSegments + 1) * j + i;

                // faces

                indices.push(a);
                indices.push(b);
                indices.push(d);
                indices.push(b);
                indices.push(c);
                indices.push(d);
            }
        }

        // build geometry

        this.setIndex(indices);
        this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
        this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
    }

    override public function copy(source:TorusGeometry):TorusGeometry {
        super.copy(source);

        this.parameters = { };
        for (field in Reflect.fields(source.parameters)) {
            Reflect.setField(this.parameters, field, Reflect.field(source.parameters, field));
        }

        return this;
    }

    static public function fromJSON(data:Dynamic):TorusGeometry {
        return new TorusGeometry(data.radius, data.tube, data.radialSegments, data.tubularSegments, data.arc);
    }
}
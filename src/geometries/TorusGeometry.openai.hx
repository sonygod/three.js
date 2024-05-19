package geometries;

import core.BufferGeometry;
import core.BufferAttribute;
import math.Vector3;

class TorusGeometry extends BufferGeometry {

    public var radius:Float;
    public var tube:Float;
    public var radialSegments:Int;
    public var tubularSegments:Int;
    public var arc:Float;

    public function new(radius:Float = 1, tube:Float = 0.4, radialSegments:Int = 12, tubularSegments:Int = 48, arc:Float = Math.PI * 2) {
        super();

        this.radius = radius;
        this.tube = tube;
        this.radialSegments = radialSegments;
        this.tubularSegments = tubularSegments;
        this.arc = arc;

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
        for (j in 0...=(radialSegments)) {
            for (i in 0...=(tubularSegments)) {
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
        for (j in 1...=(radialSegments)) {
            for (i in 1...=(tubularSegments)) {
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
        this.setAttribute("position", new BufferAttribute.fromArray(vertices, 3));
        this.setAttribute("normal", new BufferAttribute.fromArray(normals, 3));
        this.setAttribute("uv", new BufferAttribute.fromArray(uvs, 2));
    }

    public function copy(source:TorusGeometry):TorusGeometry {
        super.copy(source);
        this.radius = source.radius;
        this.tube = source.tube;
        this.radialSegments = source.radialSegments;
        this.tubularSegments = source.tubularSegments;
        this.arc = source.arc;
        return this;
    }

    public static function fromJSON(data:{radius:Float, tube:Float, radialSegments:Int, tubularSegments:Int, arc:Float}):TorusGeometry {
        return new TorusGeometry(data.radius, data.tube, data.radialSegments, data.tubularSegments, data.arc);
    }
}
package three.js.geometries;

import three.Geometry;
import three.BufferGeometry;
import three.BufferAttribute;
import three.Vector3;
import Math;

class ParametricGeometry extends BufferGeometry {
    public var type:String = 'ParametricGeometry';
    public var parameters:Dynamic;

    public function new(?func:Float->Float->Vector3->Void = null, ?slices:Int = 8, ?stacks:Int = 8) {
        super();
        this.type = 'ParametricGeometry';

        this.parameters = {
            func: func,
            slices: slices,
            stacks: stacks
        };

        // buffers
        var indices:Array<Int> = [];
        var vertices:Array<Float> = [];
        var normals:Array<Float> = [];
        var uvs:Array<Float> = [];

        var EPS:Float = 0.00001;

        var normal:Vector3 = new Vector3();
        var p0:Vector3 = new Vector3(), p1:Vector3 = new Vector3();
        var pu:Vector3 = new Vector3(), pv:Vector3 = new Vector3();

        // generate vertices, normals and uvs
        var sliceCount:Int = slices + 1;

        for (i in 0...stacks + 1) {
            var v:Float = i / stacks;

            for (j in 0...slices + 1) {
                var u:Float = j / slices;

                // vertex
                func(u, v, p0);
                vertices.push(p0.x, p0.y, p0.z);

                // normal
                // approximate tangent vectors via finite differences
                if (u - EPS >= 0) {
                    func(u - EPS, v, p1);
                    pu.subVectors(p0, p1);
                } else {
                    func(u + EPS, v, p1);
                    pu.subVectors(p1, p0);
                }

                if (v - EPS >= 0) {
                    func(u, v - EPS, p1);
                    pv.subVectors(p0, p1);
                } else {
                    func(u, v + EPS, p1);
                    pv.subVectors(p1, p0);
                }

                // cross product of tangent vectors returns surface normal
                normal.crossVectors(pu, pv).normalize();
                normals.push(normal.x, normal.y, normal.z);

                // uv
                uvs.push(u, v);
            }
        }

        // generate indices
        for (i in 0...stacks) {
            for (j in 0...slices) {
                var a:Int = i * sliceCount + j;
                var b:Int = i * sliceCount + j + 1;
                var c:Int = (i + 1) * sliceCount + j + 1;
                var d:Int = (i + 1) * sliceCount + j;

                // faces one and two
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

    public function copy(source:ParametricGeometry):ParametricGeometry {
        super.copy(source);
        this.parameters = Object.assign({}, source.parameters);
        return this;
    }
}
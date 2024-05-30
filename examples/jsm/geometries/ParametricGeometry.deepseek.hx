package three.examples.jsm.geometries;

import three.BufferGeometry;
import three.Float32BufferAttribute;
import three.Vector3;

class ParametricGeometry extends BufferGeometry {

    public function new(func: (u:Float, v:Float, target:Vector3) -> Void = function(u, v, target) {
        target.set(u, v, Math.cos(u) * Math.sin(v));
    }, slices:Int = 8, stacks:Int = 8) {
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

        var normal = new Vector3();

        var p0 = new Vector3(), p1 = new Vector3();
        var pu = new Vector3(), pv = new Vector3();

        // generate vertices, normals and uvs

        var sliceCount = slices + 1;

        for (i in 0...stacks+1) {

            var v = i / stacks;

            for (j in 0...slices+1) {

                var u = j / slices;

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

                var a = i * sliceCount + j;
                var b = i * sliceCount + j + 1;
                var c = (i + 1) * sliceCount + j + 1;
                var d = (i + 1) * sliceCount + j;

                // faces one and two

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

    public function copy(source:ParametricGeometry):ParametricGeometry {

        super.copy(source);

        this.parameters = {...source.parameters};

        return this;

    }

}
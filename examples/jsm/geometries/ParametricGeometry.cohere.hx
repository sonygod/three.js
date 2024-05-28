/**
 * Parametric Surfaces Geometry
 * based on the brilliant article by @prideout https://prideout.net/blog/old/blog/index.html@p=44.html
 */

import js.three.BufferGeometry;
import js.three.Float32BufferAttribute;
import js.three.Vector3;

class ParametricGeometry extends BufferGeometry {

	public var type: String = 'ParametricGeometry';
	public var parameters: { func: Dynamic, slices: Int, stacks: Int } = { func: null, slices: 0, stacks: 0 };

	public function new(func: Dynamic = (u: Float, v: Float, target: Vector3) -> Void, slices: Int = 8, stacks: Int = 8) {
		super();

		parameters.func = func;
		parameters.slices = slices;
		parameters.stacks = stacks;

		var indices = [];
		var vertices = [];
		var normals = [];
		var uvs = [];

		var EPS = 0.00001;

		var normal = new Vector3();

		var p0 = new Vector3();
		var p1 = new Vector3();
		var pu = new Vector3();
		var pv = new Vector3();

		// generate vertices, normals and uvs

		var sliceCount = slices + 1;

		for (i in 0...stacks) {
			var v = i / stacks;

			for (j in 0...slices) {
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

	public function copy(source: ParametricGeometry) : ParametricGeometry {
		super.copy(source);

		parameters = { func: source.parameters.func, slices: source.parameters.slices, stacks: source.parameters.stacks };

		return this;
	}

}

class js.three.ParametricGeometry = ParametricGeometry;
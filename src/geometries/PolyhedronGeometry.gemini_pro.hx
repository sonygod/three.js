import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;
import three.math.Vector2;

class PolyhedronGeometry extends BufferGeometry {

	public var vertices:Array<Float>;
	public var indices:Array<Int>;
	public var radius:Float;
	public var detail:Int;

	public function new(vertices:Array<Float> = [], indices:Array<Int> = [], radius:Float = 1, detail:Int = 0) {
		super();

		this.type = "PolyhedronGeometry";

		this.vertices = vertices;
		this.indices = indices;
		this.radius = radius;
		this.detail = detail;

		// default buffer data
		var vertexBuffer:Array<Float> = [];
		var uvBuffer:Array<Float> = [];

		// the subdivision creates the vertex buffer data
		subdivide(detail);

		// all vertices should lie on a conceptual sphere with a given radius
		applyRadius(radius);

		// finally, create the uv data
		generateUVs();

		// build non-indexed geometry
		this.setAttribute("position", new Float32BufferAttribute(vertexBuffer, 3));
		this.setAttribute("normal", new Float32BufferAttribute(vertexBuffer.copy(), 3));
		this.setAttribute("uv", new Float32BufferAttribute(uvBuffer, 2));

		if (detail == 0) {
			this.computeVertexNormals(); // flat normals
		} else {
			this.normalizeNormals(); // smooth normals
		}

		// helper functions
		function subdivide(detail:Int) {
			var a = new Vector3();
			var b = new Vector3();
			var c = new Vector3();

			// iterate over all faces and apply a subdivision with the given detail value
			for (i in 0...indices.length) {
				if (i % 3 == 0) {
					// get the vertices of the face
					getVertexByIndex(indices[i + 0], a);
					getVertexByIndex(indices[i + 1], b);
					getVertexByIndex(indices[i + 2], c);

					// perform subdivision
					subdivideFace(a, b, c, detail);
				}
			}
		}

		function subdivideFace(a:Vector3, b:Vector3, c:Vector3, detail:Int) {
			var cols = detail + 1;

			// we use this multidimensional array as a data structure for creating the subdivision
			var v:Array<Array<Vector3>> = [];

			// construct all of the vertices for this subdivision
			for (i in 0...cols + 1) {
				v[i] = [];
				var aj = a.clone().lerp(c, i / cols);
				var bj = b.clone().lerp(c, i / cols);

				var rows = cols - i;
				for (j in 0...rows + 1) {
					if (j == 0 && i == cols) {
						v[i][j] = aj;
					} else {
						v[i][j] = aj.clone().lerp(bj, j / rows);
					}
				}
			}

			// construct all of the faces
			for (i in 0...cols) {
				for (j in 0...2 * (cols - i) - 1) {
					var k = Math.floor(j / 2);

					if (j % 2 == 0) {
						pushVertex(v[i][k + 1]);
						pushVertex(v[i + 1][k]);
						pushVertex(v[i][k]);
					} else {
						pushVertex(v[i][k + 1]);
						pushVertex(v[i + 1][k + 1]);
						pushVertex(v[i + 1][k]);
					}
				}
			}
		}

		function applyRadius(radius:Float) {
			var vertex = new Vector3();

			// iterate over the entire buffer and apply the radius to each vertex
			for (i in 0...vertexBuffer.length) {
				if (i % 3 == 0) {
					vertex.x = vertexBuffer[i + 0];
					vertex.y = vertexBuffer[i + 1];
					vertex.z = vertexBuffer[i + 2];

					vertex.normalize().multiplyScalar(radius);

					vertexBuffer[i + 0] = vertex.x;
					vertexBuffer[i + 1] = vertex.y;
					vertexBuffer[i + 2] = vertex.z;
				}
			}
		}

		function generateUVs() {
			var vertex = new Vector3();

			for (i in 0...vertexBuffer.length) {
				if (i % 3 == 0) {
					vertex.x = vertexBuffer[i + 0];
					vertex.y = vertexBuffer[i + 1];
					vertex.z = vertexBuffer[i + 2];

					var u = azimuth(vertex) / 2 / Math.PI + 0.5;
					var v = inclination(vertex) / Math.PI + 0.5;
					uvBuffer.push(u, 1 - v);
				}
			}

			correctUVs();
			correctSeam();
		}

		function correctSeam() {
			// handle case when face straddles the seam, see #3269
			for (i in 0...uvBuffer.length) {
				if (i % 6 == 0) {
					// uv data of a single face
					var x0 = uvBuffer[i + 0];
					var x1 = uvBuffer[i + 2];
					var x2 = uvBuffer[i + 4];

					var max = Math.max(x0, x1, x2);
					var min = Math.min(x0, x1, x2);

					// 0.9 is somewhat arbitrary
					if (max > 0.9 && min < 0.1) {
						if (x0 < 0.2) uvBuffer[i + 0] += 1;
						if (x1 < 0.2) uvBuffer[i + 2] += 1;
						if (x2 < 0.2) uvBuffer[i + 4] += 1;
					}
				}
			}
		}

		function pushVertex(vertex:Vector3) {
			vertexBuffer.push(vertex.x, vertex.y, vertex.z);
		}

		function getVertexByIndex(index:Int, vertex:Vector3) {
			var stride = index * 3;
			vertex.x = vertices[stride + 0];
			vertex.y = vertices[stride + 1];
			vertex.z = vertices[stride + 2];
		}

		function correctUVs() {
			var a = new Vector3();
			var b = new Vector3();
			var c = new Vector3();

			var centroid = new Vector3();

			var uvA = new Vector2();
			var uvB = new Vector2();
			var uvC = new Vector2();

			for (i in 0...vertexBuffer.length) {
				if (i % 9 == 0) {
					a.set(vertexBuffer[i + 0], vertexBuffer[i + 1], vertexBuffer[i + 2]);
					b.set(vertexBuffer[i + 3], vertexBuffer[i + 4], vertexBuffer[i + 5]);
					c.set(vertexBuffer[i + 6], vertexBuffer[i + 7], vertexBuffer[i + 8]);

					uvA.set(uvBuffer[i / 3 + 0], uvBuffer[i / 3 + 1]);
					uvB.set(uvBuffer[i / 3 + 2], uvBuffer[i / 3 + 3]);
					uvC.set(uvBuffer[i / 3 + 4], uvBuffer[i / 3 + 5]);

					centroid.copy(a).add(b).add(c).divideScalar(3);

					var azi = azimuth(centroid);

					correctUV(uvA, i / 3 + 0, a, azi);
					correctUV(uvB, i / 3 + 2, b, azi);
					correctUV(uvC, i / 3 + 4, c, azi);
				}
			}
		}

		function correctUV(uv:Vector2, stride:Int, vector:Vector3, azimuth:Float) {
			if ((azimuth < 0) && (uv.x == 1)) {
				uvBuffer[stride] = uv.x - 1;
			}

			if ((vector.x == 0) && (vector.z == 0)) {
				uvBuffer[stride] = azimuth / 2 / Math.PI + 0.5;
			}
		}

		// Angle around the Y axis, counter-clockwise when looking from above.
		function azimuth(vector:Vector3):Float {
			return Math.atan2(vector.z, -vector.x);
		}

		// Angle above the XZ plane.
		function inclination(vector:Vector3):Float {
			return Math.atan2(-vector.y, Math.sqrt((vector.x * vector.x) + (vector.z * vector.z)));
		}
	}

	public function copy(source:PolyhedronGeometry):PolyhedronGeometry {
		super.copy(source);

		this.vertices = source.vertices.copy();
		this.indices = source.indices.copy();
		this.radius = source.radius;
		this.detail = source.detail;

		return this;
	}

	public static function fromJSON(data:Dynamic):PolyhedronGeometry {
		return new PolyhedronGeometry(data.vertices, data.indices, data.radius, data.details);
	}
}
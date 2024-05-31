import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;
import three.math.Vector2;

class PolyhedronGeometry extends BufferGeometry {

	public var parameters : {
		vertices : Array<Float>,
		indices : Array<Int>,
		radius : Float,
		detail : Int
	};

	public function new(vertices : Array<Float> = [], indices : Array<Int> = [], radius : Float = 1, detail : Int = 0) {
		super();

		this.type = "PolyhedronGeometry";

		this.parameters = {
			vertices : vertices,
			indices : indices,
			radius : radius,
			detail : detail
		};

		var vertexBuffer : Array<Float> = [];
		var uvBuffer : Array<Float> = [];

		subdivide(detail);
		applyRadius(radius);
		generateUVs();

		this.setAttribute("position", new Float32BufferAttribute(vertexBuffer, 3));
		this.setAttribute("normal", new Float32BufferAttribute(vertexBuffer.copy(), 3));
		this.setAttribute("uv", new Float32BufferAttribute(uvBuffer, 2));

		if (detail == 0) {
			this.computeVertexNormals();
		} else {
			this.normalizeNormals();
		}
	}

	private function subdivide(detail : Int) {
		var a = new Vector3();
		var b = new Vector3();
		var c = new Vector3();

		for (i in 0...parameters.indices.length) {
			if (i % 3 != 0) continue;
			getVertexByIndex(parameters.indices[i], a);
			getVertexByIndex(parameters.indices[i + 1], b);
			getVertexByIndex(parameters.indices[i + 2], c);
			subdivideFace(a, b, c, detail);
		}
	}

	private function subdivideFace(a : Vector3, b : Vector3, c : Vector3, detail : Int) {
		var cols = detail + 1;
		var v : Array<Array<Vector3>> = [];

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

	private function applyRadius(radius : Float) {
		var vertex = new Vector3();
		for (i in 0...vertexBuffer.length) {
			if (i % 3 != 0) continue;
			vertex.x = vertexBuffer[i];
			vertex.y = vertexBuffer[i + 1];
			vertex.z = vertexBuffer[i + 2];
			vertex.normalize().multiplyScalar(radius);
			vertexBuffer[i] = vertex.x;
			vertexBuffer[i + 1] = vertex.y;
			vertexBuffer[i + 2] = vertex.z;
		}
	}

	private function generateUVs() {
		var vertex = new Vector3();
		for (i in 0...vertexBuffer.length) {
			if (i % 3 != 0) continue;
			vertex.x = vertexBuffer[i];
			vertex.y = vertexBuffer[i + 1];
			vertex.z = vertexBuffer[i + 2];
			var u = azimuth(vertex) / 2 / Math.PI + 0.5;
			var v = inclination(vertex) / Math.PI + 0.5;
			uvBuffer.push(u, 1 - v);
		}
		correctUVs();
		correctSeam();
	}

	private function correctSeam() {
		for (i in 0...uvBuffer.length) {
			if (i % 6 != 0) continue;
			var x0 = uvBuffer[i];
			var x1 = uvBuffer[i + 2];
			var x2 = uvBuffer[i + 4];
			var max = Math.max(x0, x1, x2);
			var min = Math.min(x0, x1, x2);
			if (max > 0.9 && min < 0.1) {
				if (x0 < 0.2) uvBuffer[i] += 1;
				if (x1 < 0.2) uvBuffer[i + 2] += 1;
				if (x2 < 0.2) uvBuffer[i + 4] += 1;
			}
		}
	}

	private function pushVertex(vertex : Vector3) {
		vertexBuffer.push(vertex.x, vertex.y, vertex.z);
	}

	private function getVertexByIndex(index : Int, vertex : Vector3) {
		var stride = index * 3;
		vertex.x = parameters.vertices[stride];
		vertex.y = parameters.vertices[stride + 1];
		vertex.z = parameters.vertices[stride + 2];
	}

	private function correctUVs() {
		var a = new Vector3();
		var b = new Vector3();
		var c = new Vector3();
		var centroid = new Vector3();
		var uvA = new Vector2();
		var uvB = new Vector2();
		var uvC = new Vector2();
		for (i in 0...vertexBuffer.length) {
			if (i % 9 != 0) continue;
			a.set(vertexBuffer[i], vertexBuffer[i + 1], vertexBuffer[i + 2]);
			b.set(vertexBuffer[i + 3], vertexBuffer[i + 4], vertexBuffer[i + 5]);
			c.set(vertexBuffer[i + 6], vertexBuffer[i + 7], vertexBuffer[i + 8]);
			var j = i / 3 * 2;
			uvA.set(uvBuffer[j], uvBuffer[j + 1]);
			uvB.set(uvBuffer[j + 2], uvBuffer[j + 3]);
			uvC.set(uvBuffer[j + 4], uvBuffer[j + 5]);
			centroid.copy(a).add(b).add(c).divideScalar(3);
			var azi = azimuth(centroid);
			correctUV(uvA, j, a, azi);
			correctUV(uvB, j + 2, b, azi);
			correctUV(uvC, j + 4, c, azi);
		}
	}

	private function correctUV(uv : Vector2, stride : Int, vector : Vector3, azimuth : Float) {
		if (azimuth < 0 && uv.x == 1) {
			uvBuffer[stride] = uv.x - 1;
		}
		if (vector.x == 0 && vector.z == 0) {
			uvBuffer[stride] = azimuth / 2 / Math.PI + 0.5;
		}
	}

	private function azimuth(vector : Vector3) : Float {
		return Math.atan2(vector.z, -vector.x);
	}

	private function inclination(vector : Vector3) : Float {
		return Math.atan2(-vector.y, Math.sqrt(vector.x * vector.x + vector.z * vector.z));
	}

	public function copy(source : PolyhedronGeometry) : PolyhedronGeometry {
		super.copy(source);
		this.parameters = {
			vertices : source.parameters.vertices.copy(),
			indices : source.parameters.indices.copy(),
			radius : source.parameters.radius,
			detail : source.parameters.detail
		};
		return this;
	}

	public static function fromJSON(data : Dynamic) : PolyhedronGeometry {
		return new PolyhedronGeometry(data.vertices, data.indices, data.radius, data.details);
	}
}
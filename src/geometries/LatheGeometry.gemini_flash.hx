import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.math.MathUtils;
import three.math.Vector2;
import three.math.Vector3;

class LatheGeometry extends BufferGeometry {
	public var points:Array<Vector2>;
	public var segments:Int;
	public var phiStart:Float;
	public var phiLength:Float;

	public function new(points:Array<Vector2> = [new Vector2(0, -0.5), new Vector2(0.5, 0), new Vector2(0, 0.5)], segments:Int = 12, phiStart:Float = 0, phiLength:Float = Math.PI * 2) {
		super();

		this.type = "LatheGeometry";
		this.parameters = {
			"points": points,
			"segments": segments,
			"phiStart": phiStart,
			"phiLength": phiLength
		};

		this.points = points;
		this.segments = Math.floor(segments);
		this.phiStart = phiStart;
		this.phiLength = MathUtils.clamp(phiLength, 0, Math.PI * 2);

		// buffers
		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var uvs:Array<Float> = [];
		var initNormals:Array<Float> = [];
		var normals:Array<Float> = [];

		// helper variables
		var inverseSegments = 1.0 / segments;
		var vertex = new Vector3();
		var uv = new Vector2();
		var normal = new Vector3();
		var curNormal = new Vector3();
		var prevNormal = new Vector3();
		var dx:Float = 0;
		var dy:Float = 0;

		// pre-compute normals for initial "meridian"
		for (j in 0...points.length) {
			switch (j) {
				case 0: // special handling for 1st vertex on path
					dx = points[j + 1].x - points[j].x;
					dy = points[j + 1].y - points[j].y;

					normal.x = dy * 1.0;
					normal.y = -dx;
					normal.z = dy * 0.0;

					prevNormal.copy(normal);
					normal.normalize();

					initNormals.push(normal.x, normal.y, normal.z);
					break;
				case (points.length - 1): // special handling for last Vertex on path
					initNormals.push(prevNormal.x, prevNormal.y, prevNormal.z);
					break;
				default: // default handling for all vertices in between
					dx = points[j + 1].x - points[j].x;
					dy = points[j + 1].y - points[j].y;

					normal.x = dy * 1.0;
					normal.y = -dx;
					normal.z = dy * 0.0;

					curNormal.copy(normal);

					normal.x += prevNormal.x;
					normal.y += prevNormal.y;
					normal.z += prevNormal.z;

					normal.normalize();

					initNormals.push(normal.x, normal.y, normal.z);

					prevNormal.copy(curNormal);
			}
		}

		// generate vertices, uvs and normals
		for (i in 0...segments + 1) {
			var phi = phiStart + i * inverseSegments * phiLength;

			var sin = Math.sin(phi);
			var cos = Math.cos(phi);

			for (j in 0...points.length) {
				// vertex
				vertex.x = points[j].x * sin;
				vertex.y = points[j].y;
				vertex.z = points[j].x * cos;

				vertices.push(vertex.x, vertex.y, vertex.z);

				// uv
				uv.x = i / segments;
				uv.y = j / (points.length - 1);

				uvs.push(uv.x, uv.y);

				// normal
				var x = initNormals[3 * j + 0] * sin;
				var y = initNormals[3 * j + 1];
				var z = initNormals[3 * j + 0] * cos;

				normals.push(x, y, z);
			}
		}

		// indices
		for (i in 0...segments) {
			for (j in 0...(points.length - 1)) {
				var base = j + i * points.length;

				var a = base;
				var b = base + points.length;
				var c = base + points.length + 1;
				var d = base + 1;

				// faces
				indices.push(a, b, d);
				indices.push(c, d, b);
			}
		}

		// build geometry
		this.setIndex(indices);
		this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
		this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
	}

	public function copy(source:LatheGeometry):LatheGeometry {
		super.copy(source);

		this.points = source.points;
		this.segments = source.segments;
		this.phiStart = source.phiStart;
		this.phiLength = source.phiLength;

		return this;
	}

	public static function fromJSON(data:Dynamic):LatheGeometry {
		return new LatheGeometry(data.points, data.segments, data.phiStart, data.phiLength);
	}
}
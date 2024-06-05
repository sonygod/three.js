import js.three.BufferAttribute;
import js.three.BufferGeometry;
import js.three.Vector3;
import js.three.Vector2;
import js.three.MathUtils;

class LatheGeometry extends BufferGeometry {

	public var parameters:Dynamic;

	public function new(points:Array<Vector2> = [new Vector2(0, -0.5), new Vector2(0.5, 0), new Vector2(0, 0.5)],
	                    segments:Int = 12,
	                    phiStart:Float = 0,
	                    phiLength:Float = Math.PI * 2) {

		super();

		this.type = 'LatheGeometry';

		this.parameters = {
			points: points,
			segments: segments,
			phiStart: phiStart,
			phiLength: phiLength
		};

		segments = Math.floor(segments);

		phiLength = MathUtils.clamp(phiLength, 0, Math.PI * 2);

		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var uvs:Array<Float> = [];
		var initNormals:Array<Float> = [];
		var normals:Array<Float> = [];

		var inverseSegments = 1.0 / segments;
		var vertex = new Vector3();
		var uv = new Vector2();
		var normal = new Vector3();
		var curNormal = new Vector3();
		var prevNormal = new Vector3();
		var dx = 0;
		var dy = 0;

		for (var j = 0; j <= points.length - 1; j++) {

			switch (j) {

				case 0:

					dx = points[j + 1].x - points[j].x;
					dy = points[j + 1].y - points[j].y;

					normal.x = dy;
					normal.y = -dx;
					normal.z = 0;

					prevNormal.copy(normal);

					normal.normalize();

					initNormals.push(normal.x, normal.y, normal.z);

					break;

				case points.length - 1:

					initNormals.push(prevNormal.x, prevNormal.y, prevNormal.z);

					break;

				default:

					dx = points[j + 1].x - points[j].x;
					dy = points[j + 1].y - points[j].y;

					normal.x = dy;
					normal.y = -dx;
					normal.z = 0;

					curNormal.copy(normal);

					normal.x += prevNormal.x;
					normal.y += prevNormal.y;
					normal.z += prevNormal.z;

					normal.normalize();

					initNormals.push(normal.x, normal.y, normal.z);

					prevNormal.copy(curNormal);

			}

		}

		for (var i = 0; i <= segments; i++) {

			var phi = phiStart + i * inverseSegments * phiLength;

			var sin = Math.sin(phi);
			var cos = Math.cos(phi);

			for (var j = 0; j <= points.length - 1; j++) {

				vertex.x = points[j].x * sin;
				vertex.y = points[j].y;
				vertex.z = points[j].x * cos;

				vertices.push(vertex.x, vertex.y, vertex.z);

				uv.x = i / segments;
				uv.y = j / (points.length - 1);

				uvs.push(uv.x, uv.y);

				var x = initNormals[3 * j + 0] * sin;
				var y = initNormals[3 * j + 1];
				var z = initNormals[3 * j + 0] * cos;

				normals.push(x, y, z);

			}

		}

		for (var i = 0; i < segments; i++) {

			for (var j = 0; j < points.length - 1; j++) {

				var base = j + i * points.length;

				var a = base;
				var b = base + points.length;
				var c = base + points.length + 1;
				var d = base + 1;

				indices.push(a, b, d);
				indices.push(c, d, b);

			}

		}

		this.setIndex(indices);
		this.setAttribute('position', new BufferAttribute(vertices, 3));
		this.setAttribute('uv', new BufferAttribute(uvs, 2));
		this.setAttribute('normal', new BufferAttribute(normals, 3));

	}

	public function copy(source:LatheGeometry):LatheGeometry {

		super.copy(source);

		this.parameters = js.Boot.clone(source.parameters);

		return this;

	}

	public static function fromJSON(data:Dynamic):LatheGeometry {

		return new LatheGeometry(data.points, data.segments, data.phiStart, data.phiLength);

	}

}
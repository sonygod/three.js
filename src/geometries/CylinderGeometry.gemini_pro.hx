import haxe.io.Bytes;
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;
import three.math.Vector2;

class CylinderGeometry extends BufferGeometry {

	public var radiusTop:Float;
	public var radiusBottom:Float;
	public var height:Float;
	public var radialSegments:Int;
	public var heightSegments:Int;
	public var openEnded:Bool;
	public var thetaStart:Float;
	public var thetaLength:Float;

	public function new(radiusTop:Float = 1, radiusBottom:Float = 1, height:Float = 1, radialSegments:Int = 32, heightSegments:Int = 1, openEnded:Bool = false, thetaStart:Float = 0, thetaLength:Float = Math.PI * 2) {
		super();

		this.type = "CylinderGeometry";

		this.radiusTop = radiusTop;
		this.radiusBottom = radiusBottom;
		this.height = height;
		this.radialSegments = radialSegments;
		this.heightSegments = heightSegments;
		this.openEnded = openEnded;
		this.thetaStart = thetaStart;
		this.thetaLength = thetaLength;

		var indices = new Array<Int>();
		var vertices = new Array<Float>();
		var normals = new Array<Float>();
		var uvs = new Array<Float>();

		var index = 0;
		var indexArray = new Array<Array<Int>>();
		var halfHeight = height / 2;
		var groupStart = 0;

		generateTorso();

		if (!openEnded) {
			if (radiusTop > 0) generateCap(true);
			if (radiusBottom > 0) generateCap(false);
		}

		this.setIndex(indices);
		this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));

		function generateTorso() {
			var normal = new Vector3();
			var vertex = new Vector3();
			var groupCount = 0;
			var slope = (radiusBottom - radiusTop) / height;

			for (var y in 0...heightSegments + 1) {
				var indexRow = new Array<Int>();
				var v = y / heightSegments;
				var radius = v * (radiusBottom - radiusTop) + radiusTop;

				for (var x in 0...radialSegments + 1) {
					var u = x / radialSegments;
					var theta = u * thetaLength + thetaStart;
					var sinTheta = Math.sin(theta);
					var cosTheta = Math.cos(theta);

					vertex.set(radius * sinTheta, - v * height + halfHeight, radius * cosTheta);
					vertices.push(vertex.x, vertex.y, vertex.z);

					normal.set(sinTheta, slope, cosTheta).normalize();
					normals.push(normal.x, normal.y, normal.z);

					uvs.push(u, 1 - v);

					indexRow.push(index++);
				}

				indexArray.push(indexRow);
			}

			for (var x in 0...radialSegments) {
				for (var y in 0...heightSegments) {
					var a = indexArray[y][x];
					var b = indexArray[y + 1][x];
					var c = indexArray[y + 1][x + 1];
					var d = indexArray[y][x + 1];

					indices.push(a, b, d);
					indices.push(b, c, d);

					groupCount += 6;
				}
			}

			this.addGroup(groupStart, groupCount, 0);
			groupStart += groupCount;
		}

		function generateCap(top:Bool) {
			var centerIndexStart = index;
			var uv = new Vector2();
			var vertex = new Vector3();
			var groupCount = 0;
			var radius = top ? radiusTop : radiusBottom;
			var sign = top ? 1 : - 1;

			for (var x in 1...radialSegments + 1) {
				vertices.push(0, halfHeight * sign, 0);
				normals.push(0, sign, 0);
				uvs.push(0.5, 0.5);
				index++;
			}

			var centerIndexEnd = index;

			for (var x in 0...radialSegments + 1) {
				var u = x / radialSegments;
				var theta = u * thetaLength + thetaStart;
				var cosTheta = Math.cos(theta);
				var sinTheta = Math.sin(theta);

				vertex.set(radius * sinTheta, halfHeight * sign, radius * cosTheta);
				vertices.push(vertex.x, vertex.y, vertex.z);

				normals.push(0, sign, 0);

				uv.set((cosTheta * 0.5) + 0.5, (sinTheta * 0.5 * sign) + 0.5);
				uvs.push(uv.x, uv.y);

				index++;
			}

			for (var x in 0...radialSegments) {
				var c = centerIndexStart + x;
				var i = centerIndexEnd + x;

				if (top) {
					indices.push(i, i + 1, c);
				} else {
					indices.push(i + 1, i, c);
				}

				groupCount += 3;
			}

			this.addGroup(groupStart, groupCount, top ? 1 : 2);
			groupStart += groupCount;
		}
	}

	public function copy(source:CylinderGeometry):CylinderGeometry {
		super.copy(source);

		this.radiusTop = source.radiusTop;
		this.radiusBottom = source.radiusBottom;
		this.height = source.height;
		this.radialSegments = source.radialSegments;
		this.heightSegments = source.heightSegments;
		this.openEnded = source.openEnded;
		this.thetaStart = source.thetaStart;
		this.thetaLength = source.thetaLength;

		return this;
	}

	public static function fromJSON(data:Dynamic):CylinderGeometry {
		return new CylinderGeometry(data.radiusTop, data.radiusBottom, data.height, data.radialSegments, data.heightSegments, data.openEnded, data.thetaStart, data.thetaLength);
	}
}
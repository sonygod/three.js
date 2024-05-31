import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.MathUtils;
import three.math.Triangle;
import three.math.Vector3;

class EdgesGeometry extends BufferGeometry {

	public var parameters:{geometry:BufferGeometry, thresholdAngle:Float};

	public function new(geometry:BufferGeometry = null, thresholdAngle:Float = 1.0) {

		super();

		this.type = 'EdgesGeometry';

		this.parameters = {
			geometry: geometry,
			thresholdAngle: thresholdAngle
		};

		if (geometry != null) {

			var precisionPoints:Int = 4;
			var precision:Float = Math.pow(10, precisionPoints);
			var thresholdDot:Float = Math.cos(MathUtils.DEG2RAD * thresholdAngle);

			var indexAttr = geometry.getIndex();
			var positionAttr = geometry.getAttribute('position');
			var indexCount = indexAttr != null ? indexAttr.count : positionAttr.count;

			var indexArr = [0, 0, 0];
			var vertKeys = ['a', 'b', 'c'];
			var hashes:Array<String> = new Array(3);

			var edgeData = new Map<String, Dynamic>();
			var vertices = [];

			for (i in 0...indexCount / 3) {
				if (indexAttr != null) {
					indexArr[0] = indexAttr.getX(i * 3);
					indexArr[1] = indexAttr.getX(i * 3 + 1);
					indexArr[2] = indexAttr.getX(i * 3 + 2);
				} else {
					indexArr[0] = i * 3;
					indexArr[1] = i * 3 + 1;
					indexArr[2] = i * 3 + 2;
				}

				var _triangle = new Triangle();
				var _normal = new Vector3();
				
				var a = _triangle.a;
				var b = _triangle.b;
				var c = _triangle.c;

				a.fromBufferAttribute(positionAttr, indexArr[0]);
				b.fromBufferAttribute(positionAttr, indexArr[1]);
				c.fromBufferAttribute(positionAttr, indexArr[2]);
				_triangle.getNormal(_normal);

				// create hashes for the edge from the vertices
				hashes[0] = '${Math.round(a.x * precision)},${Math.round(a.y * precision)},${Math.round(a.z * precision)}';
				hashes[1] = '${Math.round(b.x * precision)},${Math.round(b.y * precision)},${Math.round(b.z * precision)}';
				hashes[2] = '${Math.round(c.x * precision)},${Math.round(c.y * precision)},${Math.round(c.z * precision)}';

				// skip degenerate triangles
				if (hashes[0] == hashes[1] || hashes[1] == hashes[2] || hashes[2] == hashes[0]) {
					continue;
				}

				// iterate over every edge
				for (j in 0...3) {
					var jNext = (j + 1) % 3;
					var vecHash0 = hashes[j];
					var vecHash1 = hashes[jNext];
					var v0 = _triangle[vertKeys[j]];
					var v1 = _triangle[vertKeys[jNext]];

					var hash = '${vecHash0}_${vecHash1}';
					var reverseHash = '${vecHash1}_${vecHash0}';

					if (edgeData.exists(reverseHash) && edgeData.get(reverseHash) != null) {
						// if we found a sibling edge add it into the vertex array if
						// it meets the angle threshold and delete the edge from the map.
						if (_normal.dot(edgeData.get(reverseHash).normal) <= thresholdDot) {
							vertices.push(v0.x, v0.y, v0.z);
							vertices.push(v1.x, v1.y, v1.z);
						}
						edgeData.set(reverseHash, null);
					} else if (!edgeData.exists(hash)) {
						// if we've already got an edge here then skip adding a new one
						edgeData.set(hash, {
							index0: indexArr[j],
							index1: indexArr[jNext],
							normal: _normal.clone()
						});
					}
				}
			}

			// iterate over all remaining, unmatched edges and add them to the vertex array
			for (key in edgeData.keys()) {
				if (edgeData.get(key) != null) {
					var edge = edgeData.get(key);
					var index0 = edge.index0;
					var index1 = edge.index1;
					var _v0 = new Vector3();
					var _v1 = new Vector3();

					_v0.fromBufferAttribute(positionAttr, index0);
					_v1.fromBufferAttribute(positionAttr, index1);

					vertices.push(_v0.x, _v0.y, _v0.z);
					vertices.push(_v1.x, _v1.y, _v1.z);
				}
			}

			this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
		}
	}

	override public function copy(source:BufferGeometry):EdgesGeometry {
		super.copy(source);
		this.parameters = {
			geometry: source.parameters.geometry,
			thresholdAngle: source.parameters.thresholdAngle
		};
		return this;
	}
}
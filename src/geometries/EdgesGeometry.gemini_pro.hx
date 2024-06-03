import haxe.io.Bytes;
import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.MathUtils;
import three.math.Triangle;
import three.math.Vector3;

class EdgesGeometry extends BufferGeometry {
	public var parameters: { geometry: BufferGeometry, thresholdAngle: Float };

	public function new(geometry: BufferGeometry = null, thresholdAngle: Float = 1) {
		super();

		this.type = 'EdgesGeometry';

		this.parameters = {
			geometry: geometry,
			thresholdAngle: thresholdAngle
		};

		if (geometry != null) {
			var precisionPoints = 4;
			var precision = Math.pow(10, precisionPoints);
			var thresholdDot = Math.cos(MathUtils.DEG2RAD * thresholdAngle);

			var indexAttr = geometry.getIndex();
			var positionAttr = geometry.getAttribute('position');
			var indexCount = indexAttr != null ? indexAttr.count : positionAttr.count;

			var indexArr = [0, 0, 0];
			var vertKeys = ['a', 'b', 'c'];
			var hashes = new Array<String>(3);

			var edgeData = new haxe.ds.StringMap<Dynamic>();
			var vertices = new Array<Float>();
			for (i in 0...indexCount) {
				if (i % 3 == 0) {
					if (indexAttr != null) {
						indexArr[0] = indexAttr.getX(i);
						indexArr[1] = indexAttr.getX(i + 1);
						indexArr[2] = indexAttr.getX(i + 2);
					} else {
						indexArr[0] = i;
						indexArr[1] = i + 1;
						indexArr[2] = i + 2;
					}

					var triangle = new Triangle();
					triangle.a.fromBufferAttribute(positionAttr, indexArr[0]);
					triangle.b.fromBufferAttribute(positionAttr, indexArr[1]);
					triangle.c.fromBufferAttribute(positionAttr, indexArr[2]);
					var normal = triangle.getNormal();

					// create hashes for the edge from the vertices
					hashes[0] = '${Math.round(triangle.a.x * precision)},${Math.round(triangle.a.y * precision)},${Math.round(triangle.a.z * precision)}';
					hashes[1] = '${Math.round(triangle.b.x * precision)},${Math.round(triangle.b.y * precision)},${Math.round(triangle.b.z * precision)}';
					hashes[2] = '${Math.round(triangle.c.x * precision)},${Math.round(triangle.c.y * precision)},${Math.round(triangle.c.z * precision)}';

					// skip degenerate triangles
					if (hashes[0] == hashes[1] || hashes[1] == hashes[2] || hashes[2] == hashes[0]) {
						continue;
					}

					// iterate over every edge
					for (j in 0...3) {
						// get the first and next vertex making up the edge
						var jNext = (j + 1) % 3;
						var vecHash0 = hashes[j];
						var vecHash1 = hashes[jNext];
						var v0 = triangle[vertKeys[j]];
						var v1 = triangle[vertKeys[jNext]];

						var hash = '${vecHash0}_${vecHash1}';
						var reverseHash = '${vecHash1}_${vecHash0}';

						if (edgeData.exists(reverseHash) && edgeData.get(reverseHash) != null) {
							// if we found a sibling edge add it into the vertex array if
							// it meets the angle threshold and delete the edge from the map.
							if (normal.dot(edgeData.get(reverseHash).normal) <= thresholdDot) {
								vertices.push(v0.x, v0.y, v0.z);
								vertices.push(v1.x, v1.y, v1.z);
							}

							edgeData.set(reverseHash, null);
						} else if (!edgeData.exists(hash)) {
							// if we've already got an edge here then skip adding a new one
							edgeData.set(hash, {
								index0: indexArr[j],
								index1: indexArr[jNext],
								normal: normal.clone()
							});
						}
					}
				}
			}

			// iterate over all remaining, unmatched edges and add them to the vertex array
			for (key in edgeData.keys()) {
				if (edgeData.get(key) != null) {
					var edgeDataValue = edgeData.get(key);
					var index0 = edgeDataValue.index0;
					var index1 = edgeDataValue.index1;
					var v0 = new Vector3();
					v0.fromBufferAttribute(positionAttr, index0);
					var v1 = new Vector3();
					v1.fromBufferAttribute(positionAttr, index1);

					vertices.push(v0.x, v0.y, v0.z);
					vertices.push(v1.x, v1.y, v1.z);
				}
			}

			this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
		}
	}

	public function copy(source: EdgesGeometry): EdgesGeometry {
		super.copy(source);

		this.parameters = {
			geometry: source.parameters.geometry,
			thresholdAngle: source.parameters.thresholdAngle
		};

		return this;
	}
}
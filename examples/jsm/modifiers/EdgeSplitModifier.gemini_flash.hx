import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.math.Vector3;
import three.utils.BufferGeometryUtils;

class EdgeSplitModifier {
	public static _A:Vector3 = new Vector3();
	public static _B:Vector3 = new Vector3();
	public static _C:Vector3 = new Vector3();

	public function modify(geometry:BufferGeometry, cutOffAngle:Float, tryKeepNormals:Bool = true):BufferGeometry {
		var hadNormals = false;
		var oldNormals:Null<Float32Array> = null;

		if (geometry.attributes.normal != null) {
			hadNormals = true;
			geometry = geometry.clone();
			if (tryKeepNormals && geometry.index != null) {
				oldNormals = geometry.attributes.normal.array;
			}
			geometry.deleteAttribute('normal');
		}

		if (geometry.index == null) {
			geometry = BufferGeometryUtils.mergeVertices(geometry);
		}

		var indexes = geometry.index.array;
		var positions = geometry.getAttribute('position').array;
		var normals:Null<Float32Array> = null;
		var pointToIndexMap:Array<Array<Int>> = null;

		function computeNormals() {
			normals = new Float32Array(indexes.length * 3);

			for (i in 0...indexes.length) {
				if (i % 3 == 0) {
					var index = indexes[i];
					EdgeSplitModifier._A.set(positions[3 * index], positions[3 * index + 1], positions[3 * index + 2]);
					index = indexes[i + 1];
					EdgeSplitModifier._B.set(positions[3 * index], positions[3 * index + 1], positions[3 * index + 2]);
					index = indexes[i + 2];
					EdgeSplitModifier._C.set(positions[3 * index], positions[3 * index + 1], positions[3 * index + 2]);
					EdgeSplitModifier._C.sub(EdgeSplitModifier._B);
					EdgeSplitModifier._A.sub(EdgeSplitModifier._B);
					var normal = EdgeSplitModifier._C.cross(EdgeSplitModifier._A).normalize();

					for (j in 0...3) {
						normals[3 * (i + j)] = normal.x;
						normals[3 * (i + j) + 1] = normal.y;
						normals[3 * (i + j) + 2] = normal.z;
					}
				}
			}
		}

		function mapPositionsToIndexes() {
			pointToIndexMap = Array.fill(positions.length / 3, null);

			for (i in 0...indexes.length) {
				var index = indexes[i];
				if (pointToIndexMap[index] == null) {
					pointToIndexMap[index] = [];
				}
				pointToIndexMap[index].push(i);
			}
		}

		function edgeSplitToGroups(indexes:Array<Int>, cutOff:Float, firstIndex:Int):{ splitGroup:Array<Int>, currentGroup:Array<Int> } {
			EdgeSplitModifier._A.set(normals[3 * firstIndex], normals[3 * firstIndex + 1], normals[3 * firstIndex + 2]).normalize();
			var result = {
				splitGroup: [],
				currentGroup: [firstIndex]
			};
			for (j in indexes) {
				if (j != firstIndex) {
					EdgeSplitModifier._B.set(normals[3 * j], normals[3 * j + 1], normals[3 * j + 2]).normalize();
					if (EdgeSplitModifier._B.dot(EdgeSplitModifier._A) < cutOff) {
						result.splitGroup.push(j);
					} else {
						result.currentGroup.push(j);
					}
				}
			}
			return result;
		}

		function edgeSplit(indexes:Array<Int>, cutOff:Float, original:Null<Int> = null) {
			if (indexes.length == 0) {
				return;
			}
			var groupResults = new Array<dynamic>();

			for (index in indexes) {
				groupResults.push(edgeSplitToGroups(indexes, cutOff, index));
			}
			var result = groupResults[0];
			for (groupResult in groupResults) {
				if (groupResult.currentGroup.length > result.currentGroup.length) {
					result = groupResult;
				}
			}
			if (original != null) {
				splitIndexes.push({
					original: original,
					indexes: result.currentGroup
				});
			}
			if (result.splitGroup.length > 0) {
				edgeSplit(result.splitGroup, cutOff, original || result.currentGroup[0]);
			}
		}

		computeNormals();
		mapPositionsToIndexes();
		var splitIndexes = new Array<dynamic>();
		for (vertexIndexes in pointToIndexMap) {
			edgeSplit(vertexIndexes, Math.cos(cutOffAngle) - 0.001);
		}

		var newAttributes = new haxe.ds.StringMap<BufferAttribute>();
		for (name in Reflect.fields(geometry.attributes)) {
			var oldAttribute = geometry.attributes[name];
			var newArray = new oldAttribute.array.constructor((indexes.length + splitIndexes.length) * oldAttribute.itemSize);
			newArray.set(oldAttribute.array);
			newAttributes.set(name, new BufferAttribute(newArray, oldAttribute.itemSize, oldAttribute.normalized));
		}
		var newIndexes = new Uint32Array(indexes.length);
		newIndexes.set(indexes);

		for (i in 0...splitIndexes.length) {
			var split = splitIndexes[i];
			var index = indexes[split.original];
			for (attribute in newAttributes.iterator()) {
				for (j in 0...attribute.value.itemSize) {
					attribute.value.array[(indexes.length + i) * attribute.value.itemSize + j] = attribute.value.array[index * attribute.value.itemSize + j];
				}
			}
			for (j in split.indexes) {
				newIndexes[j] = indexes.length + i;
			}
		}

		geometry = new BufferGeometry();
		geometry.setIndex(new BufferAttribute(newIndexes, 1));
		for (name in newAttributes.iterator()) {
			geometry.setAttribute(name, newAttributes.get(name));
		}

		if (hadNormals) {
			geometry.computeVertexNormals();
			if (oldNormals != null) {
				var changedNormals = Array.fill(oldNormals.length / 3, false);
				for (splitData in splitIndexes) {
					changedNormals[splitData.original] = true;
				}
				for (i in 0...changedNormals.length) {
					if (changedNormals[i] == false) {
						for (j in 0...3) {
							geometry.attributes.normal.array[3 * i + j] = oldNormals[3 * i + j];
						}
					}
				}
			}
		}
		return geometry;
	}
}
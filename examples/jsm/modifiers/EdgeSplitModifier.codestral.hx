import three.BufferAttribute;
import three.BufferGeometry;
import three.Vector3;
import three.utils.BufferGeometryUtils;

class EdgeSplitModifier {
  private var _A:Vector3 = new Vector3();
  private var _B:Vector3 = new Vector3();
  private var _C:Vector3 = new Vector3();

  public function modify(geometry:BufferGeometry, cutOffAngle:Float, tryKeepNormals:Bool = true):BufferGeometry {
    var hadNormals:Bool = false;
    var oldNormals:Vector<Float> = null;

    if (geometry.attributes.normal != null) {
      hadNormals = true;
      geometry = geometry.clone();

      if (tryKeepNormals && geometry.index != null) {
        oldNormals = new Vector<Float>(geometry.attributes.normal.array);
      }

      geometry.deleteAttribute('normal');
    }

    if (geometry.index == null) {
      geometry = BufferGeometryUtils.mergeVertices(geometry);
    }

    var indexes:Vector<Int> = new Vector<Int>(geometry.index.array);
    var positions:Vector<Float> = new Vector<Float>(geometry.getAttribute('position').array);

    var normals:Vector<Float> = new Vector<Float>();
    computeNormals();

    var pointToIndexMap:Vector<Vector<Int>> = new Vector<Vector<Int>>();
    mapPositionsToIndexes();

    var splitIndexes:Vector<Dynamic> = new Vector<Dynamic>();
    for (vertexIndexes in pointToIndexMap) {
      edgeSplit(vertexIndexes, Math.cos(cutOffAngle) - 0.001);
    }

    var newAttributes:haxe.ds.StringMap = new haxe.ds.StringMap();
    for (name in Reflect.fields(geometry.attributes)) {
      var oldAttribute = geometry.attributes[name];
      var newArray = new Vector<Float>(indexes.length + splitIndexes.length * oldAttribute.itemSize);
      newArray.splice(0, oldAttribute.array.length, oldAttribute.array);
      newAttributes.set(name, new BufferAttribute(newArray.toArray(), oldAttribute.itemSize, oldAttribute.normalized));
    }

    var newIndexes = new Vector<Int>(indexes.length);
    newIndexes.splice(0, indexes.length, indexes);

    for (i in 0...splitIndexes.length) {
      var split = splitIndexes[i];
      var index = indexes[split.original];

      for (attribute in Reflect.fields(newAttributes)) {
        for (j in 0...attribute.itemSize) {
          attribute.array[(indexes.length + i) * attribute.itemSize + j] = attribute.array[index * attribute.itemSize + j];
        }
      }

      for (j in split.indexes) {
        newIndexes[j] = indexes.length + i;
      }
    }

    geometry = new BufferGeometry();
    geometry.setIndex(new BufferAttribute(newIndexes.toArray(), 1));

    for (name in newAttributes.keys()) {
      geometry.setAttribute(name, newAttributes.get(name));
    }

    if (hadNormals) {
      geometry.computeVertexNormals();

      if (oldNormals != null) {
        var changedNormals = new Vector<Bool>(oldNormals.length / 3).fill(false);

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

  private function computeNormals() {
    normals = new Vector<Float>(indexes.length * 3);

    for (i in 0...indexes.length) {
      if (i % 3 == 0) {
        var index = indexes[i];
        _A.set(positions[3 * index], positions[3 * index + 1], positions[3 * index + 2]);

        index = indexes[i + 1];
        _B.set(positions[3 * index], positions[3 * index + 1], positions[3 * index + 2]);

        index = indexes[i + 2];
        _C.set(positions[3 * index], positions[3 * index + 1], positions[3 * index + 2]);

        _C.sub(_B);
        _A.sub(_B);

        var normal = _C.cross(_A).normalize();

        for (j in 0...3) {
          normals[3 * i + j] = normal.x;
          normals[3 * i + j + 1] = normal.y;
          normals[3 * i + j + 2] = normal.z;
        }
      }
    }
  }

  private function mapPositionsToIndexes() {
    pointToIndexMap = new Vector<Vector<Int>>(positions.length / 3);

    for (i in 0...indexes.length) {
      var index = indexes[i];

      if (pointToIndexMap[index] == null) {
        pointToIndexMap[index] = new Vector<Int>();
      }

      pointToIndexMap[index].push(i);
    }
  }

  private function edgeSplitToGroups(indexes:Vector<Int>, cutOff:Float, firstIndex:Int):Dynamic {
    _A.set(normals[3 * firstIndex], normals[3 * firstIndex + 1], normals[3 * firstIndex + 2]).normalize();

    var result = {
      splitGroup: new Vector<Int>(),
      currentGroup: new Vector<Int>().push(firstIndex)
    };

    for (j in indexes) {
      if (j != firstIndex) {
        _B.set(normals[3 * j], normals[3 * j + 1], normals[3 * j + 2]).normalize();

        if (_B.dot(_A) < cutOff) {
          result.splitGroup.push(j);
        } else {
          result.currentGroup.push(j);
        }
      }
    }

    return result;
  }

  private function edgeSplit(indexes:Vector<Int>, cutOff:Float, original:Int = null) {
    if (indexes.length == 0) return;

    var groupResults = new Vector<Dynamic>();

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
      edgeSplit(result.splitGroup, cutOff, original != null ? original : result.currentGroup[0]);
    }
  }
}
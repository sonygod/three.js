package three.js.examples.jsm.modifiers;

import three.js.BufferAttribute;
import three.js.BufferGeometry;
import three.js.Vector3;
import three.js.utils.BufferGeometryUtils;

class EdgeSplitModifier {
    private static var _A:Vector3 = new Vector3();
    private static var _B:Vector3 = new Vector3();
    private static var _C:Vector3 = new Vector3();

    public function modify(geometry:BufferGeometry, cutOffAngle:Float, tryKeepNormals:Bool = true):BufferGeometry {
        var hadNormals:Bool = false;
        var oldNormals:Array<Float> = null;

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

        var indexes:Array<Int> = geometry.index.array;
        var positions:Array<Float> = geometry.getAttribute('position').array;

        computeNormals();
        mapPositionsToIndexes();

        var splitIndexes:Array<Dynamic> = [];

        for (vertexIndexes in pointToIndexMap) {
            edgeSplit(vertexIndexes, Math.cos(cutOffAngle) - 0.001);
        }

        var newAttributes:Map<String, BufferAttribute> = {};

        for (name in geometry.attributes.keys()) {
            var oldAttribute:BufferAttribute = geometry.attributes[name];
            var newArray:Array<Float> = new Array<Float>((indexes.length + splitIndexes.length) * oldAttribute.itemSize);
            newArray.set(oldAttribute.array);
            newAttributes[name] = new BufferAttribute(newArray, oldAttribute.itemSize, oldAttribute.normalized);
        }

        var newIndexes:Array<Int> = new Array<Int>(indexes.length + splitIndexes.length);
        newIndexes.set(indexes);

        for (i in 0...splitIndexes.length) {
            var split:Dynamic = splitIndexes[i];
            var index:Int = indexes[split.original];

            for (attribute in newAttributes.values()) {
                for (j in 0...attribute.itemSize) {
                    attribute.array[(indexes.length + i) * attribute.itemSize + j] = attribute.array[index * attribute.itemSize + j];
                }
            }

            for (j in split.indexes) {
                newIndexes[j] = indexes.length + i;
            }
        }

        geometry = new BufferGeometry();
        geometry.setIndex(new BufferAttribute(newIndexes, 1));

        for (name in newAttributes.keys()) {
            geometry.setAttribute(name, newAttributes[name]);
        }

        if (hadNormals) {
            geometry.computeVertexNormals();

            if (oldNormals != null) {
                var changedNormals:Array<Bool> = new Array<Bool>(oldNormals.length / 3).fill(false);

                for (splitData in splitIndexes) {
                    changedNormals[splitData.original] = true;
                }

                for (i in 0...changedNormals.length) {
                    if (!changedNormals[i]) {
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
        var normals:Array<Float> = new Array<Float>(indexes.length * 3);

        for (i in 0...indexes.length step 3) {
            var index:Int = indexes[i];
            _A.set(positions[3 * index], positions[3 * index + 1], positions[3 * index + 2]);

            index = indexes[i + 1];
            _B.set(positions[3 * index], positions[3 * index + 1], positions[3 * index + 2]);

            index = indexes[i + 2];
            _C.set(positions[3 * index], positions[3 * index + 1], positions[3 * index + 2]);

            _C.sub(_B);
            _A.sub(_B);

            var normal:Vector3 = _C.cross(_A).normalize();

            for (j in 0...3) {
                normals[3 * (i + j)] = normal.x;
                normals[3 * (i + j) + 1] = normal.y;
                normals[3 * (i + j) + 2] = normal.z;
            }
        }
    }

    private function mapPositionsToIndexes() {
        pointToIndexMap = new Array<Dynamic>(positions.length / 3);

        for (i in 0...indexes.length) {
            var index:Int = indexes[i];

            if (pointToIndexMap[index] == null) {
                pointToIndexMap[index] = [];
            }

            pointToIndexMap[index].push(i);
        }
    }

    private function edgeSplitToGroups(indexes:Array<Int>, cutOff:Float, firstIndex:Int):Dynamic {
        _A.set(normals[3 * firstIndex], normals[3 * firstIndex + 1], normals[3 * firstIndex + 2]).normalize();

        var result:Dynamic = {
            splitGroup: [],
            currentGroup: [firstIndex]
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

    private function edgeSplit(indexes:Array<Int>, cutOff:Float, ?original:Int):Void {
        if (indexes.length == 0) return;

        var groupResults:Array<Dynamic> = [];

        for (index in indexes) {
            groupResults.push(edgeSplitToGroups(indexes, cutOff, index));
        }

        var result:Dynamic = groupResults[0];

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
}

/* export the class */
export EdgeSplitModifier;
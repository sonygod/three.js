import three.BufferAttribute;
import three.BufferGeometry;
import three.Vector3;
import three.utils.BufferGeometryUtils;

class EdgeSplitModifier {

    public function modify(geometry:BufferGeometry, cutOffAngle:Float, tryKeepNormals:Bool = true):BufferGeometry {

        var _A = new Vector3();
        var _B = new Vector3();
        var _C = new Vector3();

        function computeNormals() {

            var normals = new Float32Array(indexes.length * 3);

            for (i in indexes) {

                var index = indexes[i];

                _A.set(
                    positions[3 * index],
                    positions[3 * index + 1],
                    positions[3 * index + 2]
                );

                index = indexes[i + 1];
                _B.set(
                    positions[3 * index],
                    positions[3 * index + 1],
                    positions[3 * index + 2]
                );

                index = indexes[i + 2];
                _C.set(
                    positions[3 * index],
                    positions[3 * index + 1],
                    positions[3 * index + 2]
                );

                _C.sub(_B);
                _A.sub(_B);

                var normal = _C.cross(_A).normalize();

                for (j in 0...3) {

                    normals[3 * (i + j)] = normal.x;
                    normals[3 * (i + j) + 1] = normal.y;
                    normals[3 * (i + j) + 2] = normal.z;

                }

            }

        }


        function mapPositionsToIndexes() {

            var pointToIndexMap = new Array(positions.length / 3);

            for (i in indexes) {

                var index = indexes[i];

                if (pointToIndexMap[index] == null) {

                    pointToIndexMap[index] = [];

                }

                pointToIndexMap[index].push(i);

            }

        }


        function edgeSplitToGroups(indexes:Array<Int>, cutOff:Float, firstIndex:Int):Dynamic {

            _A.set(normals[3 * firstIndex], normals[3 * firstIndex + 1], normals[3 * firstIndex + 2]).normalize();

            var result = {
                splitGroup: [],
                currentGroup: [firstIndex]
            };

            for (j in indexes) {

                if (j !== firstIndex) {

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


        function edgeSplit(indexes:Array<Int>, cutOff:Float, original:Int = null) {

            if (indexes.length === 0) return;

            var groupResults = [];

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

            if (result.splitGroup.length) {

                edgeSplit(result.splitGroup, cutOff, original || result.currentGroup[0]);

            }

        }

        var hadNormals = false;
        var oldNormals:Array<Float> = null;

        if (geometry.attributes.normal) {

            hadNormals = true;

            geometry = geometry.clone();

            if (tryKeepNormals === true && geometry.index !== null) {

                oldNormals = geometry.attributes.normal.array;

            }

            geometry.deleteAttribute('normal');

        }

        if (geometry.index == null) {

            geometry = BufferGeometryUtils.mergeVertices(geometry);

        }

        var indexes = geometry.index.array;
        var positions = geometry.getAttribute('position').array;

        var normals:Array<Float>;
        var pointToIndexMap:Array<Int>;

        computeNormals();
        mapPositionsToIndexes();

        var splitIndexes = [];

        for (vertexIndexes in pointToIndexMap) {

            edgeSplit(vertexIndexes, Math.cos(cutOffAngle) - 0.001);

        }

        var newAttributes = {};
        for (name in geometry.attributes) {

            var oldAttribute = geometry.attributes[name];
            var newArray = new oldAttribute.array.constructor((indexes.length + splitIndexes.length) * oldAttribute.itemSize);
            newArray.set(oldAttribute.array);
            newAttributes[name] = new BufferAttribute(newArray, oldAttribute.itemSize, oldAttribute.normalized);

        }

        var newIndexes = new Uint32Array(indexes.length);
        newIndexes.set(indexes);

        for (i in splitIndexes) {

            var split = splitIndexes[i];
            var index = indexes[split.original];

            for (attribute in newAttributes) {

                for (j in 0...attribute.itemSize) {

                    attribute.array[(indexes.length + i) * attribute.itemSize + j] =
                        attribute.array[index * attribute.itemSize + j];

                }

            }

            for (j in split.indexes) {

                newIndexes[j] = indexes.length + i;

            }

        }

        geometry = new BufferGeometry();
        geometry.setIndex(new BufferAttribute(newIndexes, 1));

        for (name in newAttributes) {

            geometry.setAttribute(name, newAttributes[name]);

        }

        if (hadNormals) {

            geometry.computeVertexNormals();

            if (oldNormals !== null) {

                var changedNormals = new Array(oldNormals.length / 3).fill(false);

                for (splitData in splitIndexes)
                    changedNormals[splitData.original] = true;

                for (i in 0...changedNormals.length) {

                    if (changedNormals[i] === false) {

                        for (j in 0...3)
                            geometry.attributes.normal.array[3 * i + j] = oldNormals[3 * i + j];

                    }

                }


            }

        }

        return geometry;

    }

}
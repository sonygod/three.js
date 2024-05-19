package three.js.examples.jsm.loaders;

import three.bufferGeometry.BufferGeometry;
import three.bufferAttribute.Float32BufferAttribute;
import three.bufferAttribute.BufferAttribute;
import three.utils.Console;

class GeometryParser {
    public function new() {}

    public function parse(geoData:Dynamic, layer:Dynamic):BufferGeometry {
        var geometry:BufferGeometry = new BufferGeometry();

        geometry.setAttribute('position', new Float32BufferAttribute(geoData.points, 3));

        var indices:Array<Int> = splitIndices(geoData.vertexIndices, geoData.polygonDimensions);
        geometry.setIndex(indices);

        parseGroups(geometry, geoData);

        geometry.computeVertexNormals();

        parseUVs(geometry, layer, indices);
        parseMorphTargets(geometry, layer, indices);

        // TODO: z may need to be reversed to account for coordinate system change
        geometry.translate(-layer.pivot[0], -layer.pivot[1], -layer.pivot[2]);

        // let userData = geometry.userData;
        // geometry = geometry.toNonIndexed()
        // geometry.userData = userData;

        return geometry;
    }

    private function splitIndices(indices:Array<Int>, polygonDimensions:Array<Int>):Array<Int> {
        var remappedIndices:Array<Int> = [];

        var i:Int = 0;
        for (dim in polygonDimensions) {
            if (dim < 4) {
                for (k in 0...dim) {
                    remappedIndices.push(indices[i + k]);
                }
            } else if (dim == 4) {
                remappedIndices.push(
                    indices[i],
                    indices[i + 1],
                    indices[i + 2],

                    indices[i],
                    indices[i + 2],
                    indices[i + 3]
                );
            } else {
                for (k in 1...dim - 1) {
                    remappedIndices.push(indices[i], indices[i + k], indices[i + k + 1]);
                }
                Console.warn('LWOLoader: polygons with greater than 4 sides are not supported');
            }
            i += dim;
        }

        return remappedIndices;
    }

    private function parseGroups(geometry:BufferGeometry, geoData:Dynamic) {
        var tags:Array<Dynamic> = _lwoTree.tags;
        var matNames:Array<String> = [];

        var elemSize:Int = 3;
        if (geoData.type == 'lines') elemSize = 2;
        if (geoData.type == 'points') elemSize = 1;

        var remappedIndices:Array<Int> = splitMaterialIndices(geoData.polygonDimensions, geoData.materialIndices);

        var indexNum:Int = 0; // create new indices in numerical order
        var indexPairs:Map<String, Int> = new Map<String, Int>(); // original indices mapped to numerical indices

        var prevMaterialIndex:Int;
        var materialIndex:Int;

        var prevStart:Int = 0;
        var currentCount:Int = 0;

        for (i in 0...remappedIndices.length) {
            materialIndex = remappedIndices[i + 1];

            if (i == 0) matNames[indexNum] = tags[materialIndex];

            if (prevMaterialIndex == null) prevMaterialIndex = materialIndex;

            if (materialIndex != prevMaterialIndex) {
                var currentIndex:Int;
                if (indexPairs.exists(tags[prevMaterialIndex])) {
                    currentIndex = indexPairs[tags[prevMaterialIndex]];
                } else {
                    currentIndex = indexNum;
                    indexPairs[tags[prevMaterialIndex]] = indexNum;
                    matNames[indexNum] = tags[prevMaterialIndex];
                    indexNum++;
                }

                geometry.addGroup(prevStart, currentCount, currentIndex);

                prevStart += currentCount;

                prevMaterialIndex = materialIndex;
                currentCount = 0;
            }

            currentCount += elemSize;
        }

        // the loop above doesn't add the last group, do that here.
        if (geometry.groups.length > 0) {
            var currentIndex:Int;
            if (indexPairs.exists(tags[materialIndex])) {
                currentIndex = indexPairs[tags[materialIndex]];
            } else {
                currentIndex = indexNum;
                indexPairs[tags[materialIndex]] = indexNum;
                matNames[indexNum] = tags[materialIndex];
            }

            geometry.addGroup(prevStart, currentCount, currentIndex);
        }

        // Mat names from TAGS chunk, used to build up an array of materials for this geometry
        geometry.userData.matNames = matNames;
    }

    private function splitMaterialIndices(polygonDimensions:Array<Int>, indices:Array<Int>):Array<Int> {
        var remappedIndices:Array<Int> = [];

        for (i in 0...polygonDimensions.length) {
            if (polygonDimensions[i] <= 3) {
                remappedIndices.push(indices[i * 2], indices[i * 2 + 1]);
            } else if (polygonDimensions[i] == 4) {
                remappedIndices.push(indices[i * 2], indices[i * 2 + 1], indices[i * 2], indices[i * 2 + 1]);
            } else {
                // ignore > 4 for now
                for (k in 0...polygonDimensions[i] - 2) {
                    remappedIndices.push(indices[i * 2], indices[i * 2 + 1]);
                }
            }
        }

        return remappedIndices;
    }

    private function parseUVs(geometry:BufferGeometry, layer:Dynamic) {
        // start by creating a UV map set to zero for the whole geometry
        var remappedUVs:Array<Float> = [for (i in 0...geometry.attributes.position.count * 2) 0.0];

        for (name in layer.uvs.keys()) {
            var uvs:Array<Float> = layer.uvs[name].uvs;
            var uvIndices:Array<Int> = layer.uvs[name].uvIndices;

            for (j in 0...uvIndices.length) {
                remappedUVs[uvIndices[j] * 2] = uvs[j * 2];
                remappedUVs[uvIndices[j] * 2 + 1] = uvs[j * 2 + 1];
            }
        }

        geometry.setAttribute('uv', new Float32BufferAttribute(remappedUVs, 2));
    }

    private function parseMorphTargets(geometry:BufferGeometry, layer:Dynamic) {
        var num:Int = 0;
        for (name in layer.morphTargets.keys()) {
            var remappedPoints:Array<Float> = geometry.attributes.position.array.slice();

            if (!geometry.morphAttributes.position) geometry.morphAttributes.position = [];

            var morphPoints:Array<Float> = layer.morphTargets[name].points;
            var morphIndices:Array<Int> = layer.morphTargets[name].indices;
            var type:String = layer.morphTargets[name].type;

            for (j in 0...morphIndices.length) {
                if (type == 'relative') {
                    remappedPoints[morphIndices[j] * 3] += morphPoints[j * 3];
                    remappedPoints[morphIndices[j] * 3 + 1] += morphPoints[j * 3 + 1];
                    remappedPoints[morphIndices[j] * 3 + 2] += morphPoints[j * 3 + 2];
                } else {
                    remappedPoints[morphIndices[j] * 3] = morphPoints[j * 3];
                    remappedPoints[morphIndices[j] * 3 + 1] = morphPoints[j * 3 + 1];
                    remappedPoints[morphIndices[j] * 3 + 2] = morphPoints[j * 3 + 2];
                }
            }

            geometry.morphAttributes.position[num] = new Float32BufferAttribute(remappedPoints, 3);
            geometry.morphAttributes.position[num].name = name;

            num++;
        }

        geometry.morphTargetsRelative = false;
    }
}
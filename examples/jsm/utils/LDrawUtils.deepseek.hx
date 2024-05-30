import three.BufferAttribute;
import three.BufferGeometry;
import three.Group;
import three.LineSegments;
import three.Matrix3;
import three.Mesh;

import LDrawUtils.BufferGeometryUtils;

class LDrawUtils {

    static function mergeObject(object:Dynamic):Group {

        function extractGroup(geometry:BufferGeometry, group:Dynamic, elementSize:Int, isConditionalLine:Bool):BufferGeometry {

            var newGeometry = new BufferGeometry();

            var originalPositions = geometry.getAttribute('position').array;
            var originalNormals = elementSize == 3 ? geometry.getAttribute('normal').array : null;

            var numVertsGroup = Math.min(group.count, Math.floor(originalPositions.length / 3) - group.start);
            var vertStart = group.start * 3;
            var vertEnd = (group.start + numVertsGroup) * 3;

            var positions = originalPositions.subarray(vertStart, vertEnd);
            var normals = originalNormals != null ? originalNormals.subarray(vertStart, vertEnd) : null;

            newGeometry.setAttribute('position', new BufferAttribute(positions, 3));
            if (normals != null) newGeometry.setAttribute('normal', new BufferAttribute(normals, 3));

            if (isConditionalLine) {

                var controlArray0 = geometry.getAttribute('control0').array.subarray(vertStart, vertEnd);
                var controlArray1 = geometry.getAttribute('control1').array.subarray(vertStart, vertEnd);
                var directionArray = geometry.getAttribute('direction').array.subarray(vertStart, vertEnd);

                newGeometry.setAttribute('control0', new BufferAttribute(controlArray0, 3, false));
                newGeometry.setAttribute('control1', new BufferAttribute(controlArray1, 3, false));
                newGeometry.setAttribute('direction', new BufferAttribute(directionArray, 3, false));

            }

            return newGeometry;

        }

        function addGeometry(mat:Dynamic, geometry:BufferGeometry, geometries:Dynamic) {

            var geoms = geometries[mat.uuid];
            if (!geoms) {

                geometries[mat.uuid] = {
                    mat: mat,
                    arr: [geometry]
                };

            } else {

                geoms.arr.push(geometry);

            }

        }

        function permuteAttribute(attribute:Dynamic, elemSize:Int) {

            if (!attribute) return;

            var verts = attribute.array;
            var numVerts = Math.floor(verts.length / 3);
            var offset = 0;
            for (i in 0...numVerts) {

                var x = verts[offset];
                var y = verts[offset + 1];
                var z = verts[offset + 2];

                verts[offset] = verts[offset + 3];
                verts[offset + 1] = verts[offset + 4];
                verts[offset + 2] = verts[offset + 5];

                verts[offset + 3] = x;
                verts[offset + 4] = y;
                verts[offset + 5] = z;

                offset += elemSize * 3;

            }

        }

        var meshGeometries = {};
        var linesGeometries = {};
        var condLinesGeometries = {};

        object.updateMatrixWorld(true);
        var normalMatrix = new Matrix3();

        object.traverse(c => {

            if (c.isMesh || c.isLineSegments) {

                var elemSize = c.isMesh ? 3 : 2;

                var geometry = c.geometry.clone();
                var matrixIsInverted = c.matrixWorld.determinant() < 0;
                if (matrixIsInverted) {

                    permuteAttribute(geometry.attributes.position, elemSize);
                    permuteAttribute(geometry.attributes.normal, elemSize);

                }

                geometry.applyMatrix4(c.matrixWorld);

                if (c.isConditionalLine) {

                    geometry.attributes.control0.applyMatrix4(c.matrixWorld);
                    geometry.attributes.control1.applyMatrix4(c.matrixWorld);
                    normalMatrix.getNormalMatrix(c.matrixWorld);
                    geometry.attributes.direction.applyNormalMatrix(normalMatrix);

                }

                var geometries = c.isMesh ? meshGeometries : (c.isConditionalLine ? condLinesGeometries : linesGeometries);

                if (Reflect.isArray(c.material)) {

                    for (groupIndex in geometry.groups) {

                        var group = geometry.groups[groupIndex];
                        var mat = c.material[group.materialIndex];
                        var newGeometry = extractGroup(geometry, group, elemSize, c.isConditionalLine);
                        addGeometry(mat, newGeometry, geometries);

                    }

                } else {

                    addGeometry(c.material, geometry, geometries);

                }

            }

        });

        var mergedObject = new Group();

        var meshMaterialsIds = Reflect.fields(meshGeometries);
        for (meshMaterialsId in meshMaterialsIds) {

            var meshGeometry = meshGeometries[meshMaterialsId];
            var mergedGeometry = BufferGeometryUtils.mergeGeometries(meshGeometry.arr);
            mergedObject.add(new Mesh(mergedGeometry, meshGeometry.mat));

        }

        var linesMaterialsIds = Reflect.fields(linesGeometries);
        for (linesMaterialsId in linesMaterialsIds) {

            var lineGeometry = linesGeometries[linesMaterialsId];
            var mergedGeometry = BufferGeometryUtils.mergeGeometries(lineGeometry.arr);
            mergedObject.add(new LineSegments(mergedGeometry, lineGeometry.mat));

        }

        var condLinesMaterialsIds = Reflect.fields(condLinesGeometries);
        for (condLinesMaterialsId in condLinesMaterialsIds) {

            var condLineGeometry = condLinesGeometries[condLinesMaterialsId];
            var mergedGeometry = BufferGeometryUtils.mergeGeometries(condLineGeometry.arr);
            var condLines = new LineSegments(mergedGeometry, condLineGeometry.mat);
            condLines.isConditionalLine = true;
            mergedObject.add(condLines);

        }

        mergedObject.userData.constructionStep = 0;
        mergedObject.userData.numConstructionSteps = 1;

        return mergedObject;

    }

}
import js.three.BufferAttribute;
import js.three.BufferGeometry;
import js.three.Group;
import js.three.LineSegments;
import js.three.Matrix3;
import js.three.Mesh;

class LDrawUtils {
    public static function mergeObject(object:Dynamic):Group {
        function extractGroup(geometry:BufferGeometry, group:Dynamic, elementSize:Int, isConditionalLine:Bool):BufferGeometry {
            var newGeometry = new BufferGeometry();
            var originalPositions = geometry.getAttribute('position').array;
            var originalNormals = (elementSize == 3) ? geometry.getAttribute('normal').array : null;
            var numVertsGroup = Std.int(Math.min(group.count, (originalPositions.length / 3) - group.start));
            var vertStart = group.start * 3;
            var vertEnd = (group.start + numVertsGroup) * 3;
            var positions = originalPositions.subarray(vertStart, vertEnd);
            var normals = (originalNormals != null) ? originalNormals.subarray(vertStart, vertEnd) : null;
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
            var geoms = geometries[Std.string(mat.uuid)];
            if (geoms == null) {
                geometries[Std.string(mat.uuid)] = { mat: mat, arr: [geometry] };
            } else {
                geoms.arr.push(geometry);
            }
        }
        function permuteAttribute(attribute:Dynamic, elemSize:Int) {
            if (attribute == null) return;
            var verts = attribute.array;
            var numVerts = Std.int(verts.length / 3);
            var offset = 0;
            var i = 0;
            while (i < numVerts) {
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
                i++;
            }
        }
        var meshGeometries = new haxe.ds.StringMap();
        var linesGeometries = new haxe.ds.StringMap();
        var condLinesGeometries = new haxe.ds.StringMap();
        object.updateMatrixWorld(true);
        var normalMatrix = new Matrix3();
        object.traverse(function (c) {
            if (c.isMesh || c.isLineSegments) {
                var elemSize = (c.isMesh) ? 3 : 2;
                var geometry = c.geometry.clone();
                var matrixIsInverted = (c.matrixWorld.determinant() < 0);
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
                var geometries = (c.isMesh) ? meshGeometries : ((c.isConditionalLine) ? condLinesGeometries : linesGeometries);
                if (Type.enumIndex(c.material) != null) {
                    var groups = geometry.groups;
                    var groupIndex = 0;
                    while (groupIndex < groups.length) {
                        var group = groups[groupIndex];
                        var mat = c.material[group.materialIndex];
                        var newGeometry = extractGroup(geometry, group, elemSize, c.isConditionalLine);
                        addGeometry(mat, newGeometry, geometries);
                        groupIndex++;
                    }
                } else {
                    addGeometry(c.material, geometry, geometries);
                }
            }
        });
        var mergedObject = new Group();
        var meshMaterialsIds = meshGeometries.keys();
        var meshMaterialsId = $getiter(meshMaterialsIds);
        while (meshMaterialsId.hasNext()) {
            var meshMaterialsId1 = meshMaterialsId.next();
            var meshGeometry = meshGeometries.get(meshMaterialsId1);
            var mergedGeometry = mergeGeometries(meshGeometry.arr);
            mergedObject.add(new Mesh(mergedGeometry, meshGeometry.mat));
        }
        var linesMaterialsIds = linesGeometries.keys();
        var linesMaterialsId = $getiter(linesMaterialsIds);
        while (linesMaterialsId.hasNext()) {
            var linesMaterialsId1 = linesMaterialsId.next();
            var lineGeometry = linesGeometries.get(linesMaterialsId1);
            var mergedGeometry1 = mergeGeometries(lineGeometry.arr);
            mergedObject.add(new LineSegments(mergedGeometry1, lineGeometry.mat));
        }
        var condLinesMaterialsIds = condLinesGeometries.keys();
        var condLinesMaterialsId = $getiter(condLinesMaterialsIds);
        while (condLinesMaterialsId.hasNext()) {
            var condLinesMaterialsId1 = condLinesMaterialsId.next();
            var condLineGeometry = condLinesGeometries.get(condLinesMaterialsId1);
            var mergedGeometry2 = mergeGeometries(condLineGeometry.arr);
            var condLines = new LineSegments(mergedGeometry2, condLineGeometry.mat);
            condLines.isConditionalLine = true;
            mergedObject.add(condLines);
        }
        mergedObject.userData.constructionStep = 0;
        mergedObject.userData.numConstructionSteps = 1;
        return mergedObject;
    }
}
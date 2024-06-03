import three.BufferAttribute;
import three.BufferGeometry;
import three.Group;
import three.LineSegments;
import three.Matrix3;
import three.Mesh;
import three.utils.BufferGeometryUtils;

class LDrawUtils {
    static function mergeObject(object: Group): Group {
        // Traverse the object hierarchy collecting geometries and transforming them to world space

        var meshGeometries: Map<String, { mat: Material, arr: Array<BufferGeometry> }> = new Map();
        var linesGeometries: Map<String, { mat: Material, arr: Array<BufferGeometry> }> = new Map();
        var condLinesGeometries: Map<String, { mat: Material, arr: Array<BufferGeometry> }> = new Map();

        object.updateMatrixWorld(true);
        var normalMatrix: Matrix3 = new Matrix3();

        object.traverse(function (c: Group) {
            if (Std.is(c, Mesh) || Std.is(c, LineSegments)) {
                var elemSize: Int = Std.is(c, Mesh) ? 3 : 2;

                var geometry: BufferGeometry = c.geometry.clone();
                var matrixIsInverted: Bool = c.matrixWorld.determinant() < 0;
                if (matrixIsInverted) {
                    permuteAttribute(geometry.attributes.position, elemSize);
                    permuteAttribute(geometry.attributes.normal, elemSize);
                }

                geometry.applyMatrix4(c.matrixWorld);

                if (Std.is(c, LineSegments) && c.userData.isConditionalLine) {
                    geometry.attributes.control0.applyMatrix4(c.matrixWorld);
                    geometry.attributes.control1.applyMatrix4(c.matrixWorld);
                    normalMatrix.getNormalMatrix(c.matrixWorld);
                    geometry.attributes.direction.applyNormalMatrix(normalMatrix);
                }

                var geometries: Map<String, { mat: Material, arr: Array<BufferGeometry> }>;

                if (Std.is(c, Mesh)) {
                    geometries = meshGeometries;
                } else if (Std.is(c, LineSegments) && c.userData.isConditionalLine) {
                    geometries = condLinesGeometries;
                } else {
                    geometries = linesGeometries;
                }

                if (Array.isArray(c.material)) {
                    for (groupIndex in geometry.groups) {
                        var group = geometry.groups[groupIndex];
                        var mat = c.material[group.materialIndex];
                        var newGeometry = extractGroup(geometry, group, elemSize, Std.is(c, LineSegments) && c.userData.isConditionalLine);
                        addGeometry(mat, newGeometry, geometries);
                    }
                } else {
                    addGeometry(c.material, geometry, geometries);
                }
            }
        });

        // Create object with merged geometries

        var mergedObject: Group = new Group();

        for (meshMaterialsId in meshGeometries.keys()) {
            var meshGeometry = meshGeometries.get(meshMaterialsId);
            var mergedGeometry = BufferGeometryUtils.mergeGeometries(meshGeometry.arr);
            mergedObject.add(new Mesh(mergedGeometry, meshGeometry.mat));
        }

        for (linesMaterialsId in linesGeometries.keys()) {
            var lineGeometry = linesGeometries.get(linesMaterialsId);
            var mergedGeometry = BufferGeometryUtils.mergeGeometries(lineGeometry.arr);
            mergedObject.add(new LineSegments(mergedGeometry, lineGeometry.mat));
        }

        for (condLinesMaterialsId in condLinesGeometries.keys()) {
            var condLineGeometry = condLinesGeometries.get(condLinesMaterialsId);
            var mergedGeometry = BufferGeometryUtils.mergeGeometries(condLineGeometry.arr);
            var condLines = new LineSegments(mergedGeometry, condLineGeometry.mat);
            condLines.userData.isConditionalLine = true;
            mergedObject.add(condLines);
        }

        mergedObject.userData.constructionStep = 0;
        mergedObject.userData.numConstructionSteps = 1;

        return mergedObject;
    }

    static function extractGroup(geometry: BufferGeometry, group: { start: Int, count: Int }, elementSize: Int, isConditionalLine: Bool): BufferGeometry {
        // Extracts a group from a geometry as a new geometry (with attribute buffers referencing original buffers)

        var newGeometry: BufferGeometry = new BufferGeometry();

        var originalPositions: Float32Array = geometry.getAttribute('position').array;
        var originalNormals: Float32Array = elementSize === 3 ? geometry.getAttribute('normal').array : null;

        var numVertsGroup: Int = Math.min(group.count, Math.floor(originalPositions.length / 3) - group.start);
        var vertStart: Int = group.start * 3;
        var vertEnd: Int = (group.start + numVertsGroup) * 3;

        var positions: Float32Array = originalPositions.slice(vertStart, vertEnd);
        var normals: Float32Array = originalNormals !== null ? originalNormals.slice(vertStart, vertEnd) : null;

        newGeometry.setAttribute('position', new BufferAttribute(positions, 3));
        if (normals !== null) newGeometry.setAttribute('normal', new BufferAttribute(normals, 3));

        if (isConditionalLine) {
            var controlArray0: Float32Array = geometry.getAttribute('control0').array.slice(vertStart, vertEnd);
            var controlArray1: Float32Array = geometry.getAttribute('control1').array.slice(vertStart, vertEnd);
            var directionArray: Float32Array = geometry.getAttribute('direction').array.slice(vertStart, vertEnd);

            newGeometry.setAttribute('control0', new BufferAttribute(controlArray0, 3, false));
            newGeometry.setAttribute('control1', new BufferAttribute(controlArray1, 3, false));
            newGeometry.setAttribute('direction', new BufferAttribute(directionArray, 3, false));
        }

        return newGeometry;
    }

    static function addGeometry(mat: Material, geometry: BufferGeometry, geometries: Map<String, { mat: Material, arr: Array<BufferGeometry> }>): Void {
        var geoms = geometries.get(mat.uuid);
        if (geoms == null) {
            geometries.set(mat.uuid, {
                mat: mat,
                arr: [geometry]
            });
        } else {
            geoms.arr.push(geometry);
        }
    }

    static function permuteAttribute(attribute: BufferAttribute, elemSize: Int): Void {
        // Permutes first two vertices of each attribute element

        if (attribute == null) return;

        var verts: Float32Array = attribute.array;
        var numVerts: Int = Math.floor(verts.length / 3);
        var offset: Int = 0;
        for (var i: Int = 0; i < numVerts; i++) {
            var x: Float = verts[offset];
            var y: Float = verts[offset + 1];
            var z: Float = verts[offset + 2];

            verts[offset] = verts[offset + 3];
            verts[offset + 1] = verts[offset + 4];
            verts[offset + 2] = verts[offset + 5];

            verts[offset + 3] = x;
            verts[offset + 4] = y;
            verts[offset + 5] = z;

            offset += elemSize * 3;
        }
    }
}
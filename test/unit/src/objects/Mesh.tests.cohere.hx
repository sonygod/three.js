package;

import js.QUnit;
import js.THREE.Object3D;
import js.THREE.Mesh;
import js.THREE.Raycaster;
import js.THREE.PlaneGeometry;
import js.THREE.BoxGeometry;
import js.THREE.MeshBasicMaterial;
import js.THREE.Vector2;
import js.THREE.Vector3;
import js.THREE.DoubleSide;
import js.THREE.Material;

class _Main {
    static function main() {
        QUnit.module('Objects', function() {
            QUnit.module('Mesh', function() {
                // INHERITANCE
                QUnit.test('Extending', function(assert) {
                    var mesh = new Mesh();
                    assert.strictEqual(mesh instanceof Object3D, true, 'Mesh extends from Object3D');
                });

                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var object = new Mesh();
                    assert.ok(object, 'Can instantiate a Mesh.');
                });

                // PROPERTIES
                QUnit.test('type', function(assert) {
                    var object = new Mesh();
                    assert.ok(object.type == 'Mesh', 'Mesh.type should be Mesh');
                });

                QUnit.todo('geometry', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('material', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.test('isMesh', function(assert) {
                    var object = new Mesh();
                    assert.ok(object.isMesh, 'Mesh.isMesh should be true');
                });

                QUnit.todo('copy', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.test('copy/material', function(assert) {
                    // Material arrays are cloned
                    var mesh1 = new Mesh();
                    mesh1.material = [new Material()];

                    var copy1 = mesh1.clone();
                    assert.notStrictEqual(mesh1.material, copy1.material);

                    // Non arrays are not cloned
                    var mesh2 = new Mesh();
                    mesh1.material = new Material();
                    var copy2 = mesh2.clone();
                    assert.strictEqual(mesh2.material, copy2.material);
                });

                QUnit.todo('updateMorphTargets', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('getVertexPosition', function(assert) {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo('raycast', function(assert) {
                    var geometry = new PlaneGeometry();
                    var material = new MeshBasicMaterial();

                    var mesh = new Mesh(geometry, material);

                    var raycaster = new Raycaster();
                    raycaster.ray.origin.set(0.25, 0.25, 1);
                    raycaster.ray.direction.set(0, 0, -1);

                    var intersections = [];

                    mesh.raycast(raycaster, intersections);

                    var intersection = intersections[0];

                    assert.equal(intersection.object, mesh, 'intersction object');
                    assert.equal(intersection.distance, 1, 'intersction distance');
                    assert.equal(intersection.faceIndex, 1, 'intersction face index');
                    assert.deepEqual(intersection.face, { a: 0, b: 2, c: 1 }, 'intersction vertex indices');
                    assert.deepEqual(intersection.point, new Vector3(0.25, 0.25, 0), 'intersction point');
                    assert.deepEqual(intersection.uv, new Vector2(0.75, 0.75), 'intersction uv');
                });

                QUnit.test('raycast/range', function(assert) {
                    var geometry = new BoxGeometry(1, 1, 1);
                    var material = new MeshBasicMaterial({ side: DoubleSide });
                    var mesh = new Mesh(geometry, material);
                    var raycaster = new Raycaster();
                    var intersections = [];

                    raycaster.ray.origin.set(0, 0, 0);
                    raycaster.ray.direction.set(1, 0, 0);
                    raycaster.near = 100;
                    raycaster.far = 200;

                    mesh.matrixWorld.identity();
                    mesh.position.setX(150);
                    mesh.updateMatrixWorld(true);
                    intersections.length = 0;
                    mesh.raycast(raycaster, intersections);
                    assert.ok(intersections.length > 0, 'bounding sphere between near and far');

                    mesh.matrixWorld.identity();
                    mesh.position.setX(raycaster.near);
                    mesh.updateMatrixWorld(true);
                    intersections.length = 0;
                    mesh.raycast(raycaster, intersections);
                    assert.ok(intersections.length > 0, 'bounding sphere across near');

                    mesh.matrixWorld.identity();
                    mesh.position.setX(raycaster.far);
                    mesh.updateMatrixWorld(true);
                    intersections.length = 0;
                    mesh.raycast(raycaster, intersections);
                    assert.ok(intersections.length > 0, 'bounding sphere across far');

                    mesh.matrixWorld.identity();
                    mesh.position.setX(150);
                    mesh.scale.setY(9999);
                    mesh.updateMatrixWorld(true);
                    intersections.length = 0;
                    mesh.raycast(raycaster, intersections);
                    assert.ok(intersections.length > 0, 'bounding sphere across near and far');

                    mesh.matrixWorld.identity();
                    mesh.position.setX(-9999);
                    mesh.updateMatrixWorld(true);
                    intersections.length = 0;
                    mesh.raycast(raycaster, intersections);
                    assert.ok(intersections.length == 0, 'bounding sphere behind near');

                    mesh.matrixWorld.identity();
                    mesh.position.setX(9999);
                    mesh.updateMatrixWorld(true);
                    intersections.length = 0;
                    mesh.raycast(raycaster, intersections);
                    assert.ok(intersections.length == 0, 'bounding sphere beyond far');
                });
            });
        });
    }
}
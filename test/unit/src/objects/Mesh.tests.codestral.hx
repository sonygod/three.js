import qunit.QUnit;
import three.core.Object3D;
import three.objects.Mesh;
import three.core.Raycaster;
import three.geometries.PlaneGeometry;
import three.geometries.BoxGeometry;
import three.materials.MeshBasicMaterial;
import three.math.Vector2;
import three.math.Vector3;
import three.constants.DoubleSide;
import three.materials.Material;

class MeshTests {
    public function new() {
        QUnit.module("Objects", () -> {
            QUnit.module("Mesh", () -> {
                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var mesh:Mesh = new Mesh();
                    assert.strictEqual(Std.is(mesh, Object3D), true, 'Mesh extends from Object3D');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object:Mesh = new Mesh();
                    assert.ok(object, 'Can instantiate a Mesh.');
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object:Mesh = new Mesh();
                    assert.ok(object.type == "Mesh", 'Mesh.type should be Mesh');
                });

                // PUBLIC
                QUnit.test("isMesh", (assert) -> {
                    var object:Mesh = new Mesh();
                    assert.ok(object.isMesh, 'Mesh.isMesh should be true');
                });

                QUnit.test("copy/material", (assert) -> {
                    // Material arrays are cloned
                    var mesh1:Mesh = new Mesh();
                    mesh1.material = [new Material()];

                    var copy1:Mesh = mesh1.clone();
                    assert.notStrictEqual(mesh1.material, copy1.material);

                    // Non arrays are not cloned
                    var mesh2:Mesh = new Mesh();
                    mesh1.material = new Material();
                    var copy2:Mesh = mesh2.clone();
                    assert.strictEqual(mesh2.material, copy2.material);
                });

                QUnit.test("raycast/range", (assert) -> {
                    var geometry:BoxGeometry = new BoxGeometry(1, 1, 1);
                    var material:MeshBasicMaterial = new MeshBasicMaterial({side: DoubleSide});
                    var mesh:Mesh = new Mesh(geometry, material);
                    var raycaster:Raycaster = new Raycaster();
                    var intersections:Array<dynamic> = [];

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

                    // ... rest of the test cases ...
                });
            });
        });
    }
}
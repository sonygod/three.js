import js.Browser.document;
import js.Browser.window;
import js.html.QUnit;
import Material from '../../../../src/materials/Material';
import MeshDistanceMaterial from '../../../../src/materials/MeshDistanceMaterial';

QUnit.module("Materials", () -> {
    QUnit.module("MeshDistanceMaterial", () -> {
        QUnit.test("Extending", (assert) -> {
            var object:MeshDistanceMaterial = new MeshDistanceMaterial();
            assert.strictEqual(Std.is(object, Material), true, "MeshDistanceMaterial extends from Material");
        });

        QUnit.test("Instancing", (assert) -> {
            var object:MeshDistanceMaterial = new MeshDistanceMaterial();
            assert.ok(object != null, "Can instantiate a MeshDistanceMaterial.");
        });

        QUnit.test("type", (assert) -> {
            var object:MeshDistanceMaterial = new MeshDistanceMaterial();
            assert.ok(object.type == "MeshDistanceMaterial", "MeshDistanceMaterial.type should be MeshDistanceMaterial");
        });

        QUnit.todo("map", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("alphaMap", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("displacementMap", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("displacementScale", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("displacementBias", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.test("isMeshDistanceMaterial", (assert) -> {
            var object:MeshDistanceMaterial = new MeshDistanceMaterial();
            assert.ok(object.isMeshDistanceMaterial, "MeshDistanceMaterial.isMeshDistanceMaterial should be true");
        });

        QUnit.todo("copy", (assert) -> {
            assert.ok(false, "everything's gonna be alright");
        });
    });
});
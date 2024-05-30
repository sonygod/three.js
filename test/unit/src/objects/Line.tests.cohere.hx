import js.QUnit;
import Line from "../../../../src/objects/Line.hx";
import Object3D from "../../../../src/core/Object3D.hx";
import Material from "../../../../src/materials/Material.hx";

class _Main {
    static function main() {
        QUnit.module("Objects → Line", {
            setup: function() {},
            teardown: function() {}
        });

        // INHERITANCE
        QUnit.test("Extending", function(assert) {
            var line = new Line();
            assert.strictEqual(line instanceof Object3D, true, "Line extends from Object3D");
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
            var object = new Line();
            assert.ok(object, "Can instantiate a Line.");
        });

        // PROPERTIES
        QUnit.test("type", function(assert) {
            var object = new Line();
            assert.ok(object.type == "Line", "Line.type should be Line");
        });

        QUnit.todo("geometry", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("material", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isLine", function(assert) {
            var object = new Line();
            assert.ok(object.isLine, "Line.isLine should be true");
        });

        QUnit.todo("copy", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.test("copy/material", function(assert) {
            // Material arrays are cloned
            var mesh1 = new Line();
            mesh1.material = [new Material()];

            var copy1 = mesh1.clone();
            assert.notStrictEqual(mesh1.material, copy1.material);

            // Non arrays are not cloned
            var mesh2 = new Line();
            mesh1.material = new Material();
            var copy2 = mesh2.clone();
            assert.strictEqual(mesh2.material, copy2.material);
        });

        QUnit.todo("computeLineDistances", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("raycast", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("updateMorphTargets", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("clone", function(assert) {
            // inherited from Object3D, test instance specific behaviour.
            assert.ok(false, "everything's gonna be alright");
        });
    }
}
import js.QUnit;
import Scene from "../../../../src/scenes/Scene.hx";
import Object3D from "../../../../src/core/Object3D.hx";

class _Main {
    static function main() {
        QUnit.module("Scenes -> Scene", () -> {
            // INHERITANCE
            QUnit.test("Extending", function() {
                var object = new Scene();
                var result = Std.is(object, Object3D);
                QUnit.strictEqual(result, true, "Scene extends from Object3D");
            });

            // INSTANCING
            QUnit.test("Instancing", function() {
                var object = new Scene();
                QUnit.ok(object, "Can instantiate a Scene.");
            });

            // PROPERTIES
            QUnit.todo("type", function() {
                QUnit.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("background", function() {
                QUnit.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("environment", function() {
                QUnit.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("fog", function() {
                QUnit.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("backgroundBlurriness", function() {
                QUnit.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("backgroundIntensity", function() {
                QUnit.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("overrideMaterial", function() {
                QUnit.ok(false, "everything's gonna be alright");
            });

            // PUBLIC
            QUnit.test("isScene", function() {
                var object = new Scene();
                QUnit.ok(object.isScene, "Scene.isScene should be true");
            });

            QUnit.todo("copy", function() {
                QUnit.ok(false, "everything's gonna be alright");
            });

            QUnit.todo("toJSON", function() {
                QUnit.ok(false, "everything's gonna be alright");
            });
        });
    }
}
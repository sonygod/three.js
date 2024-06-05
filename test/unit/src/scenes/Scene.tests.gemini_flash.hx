import qunit.QUnit;
import three.core.Object3D;
import three.scenes.Scene;

class SceneTest {
  static function main() {
    QUnit.module("Scenes", function() {
      QUnit.module("Scene", function() {
        // INHERITANCE
        QUnit.test("Extending", function(assert) {
          var object = new Scene();
          assert.strictEqual(object.is(Object3D), true, "Scene extends from Object3D");
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
          var object = new Scene();
          assert.ok(object, "Can instantiate a Scene.");
        });

        // PROPERTIES
        QUnit.todo("type", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("background", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("environment", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("fog", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("backgroundBlurriness", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("backgroundIntensity", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("overrideMaterial", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isScene", function(assert) {
          var object = new Scene();
          assert.ok(object.isScene, "Scene.isScene should be true");
        });

        QUnit.todo("copy", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("toJSON", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}

class Scene {
  public var isScene:Bool;

  public function new() {
    this.isScene = true;
  }
}
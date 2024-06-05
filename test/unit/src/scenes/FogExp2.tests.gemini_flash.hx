import qunit.QUnit;
import three.scenes.FogExp2;

class FogExp2Test {
  public static function main() {
    QUnit.module("Scenes", function() {
      QUnit.module("FoxExp2", function() {
        // INSTANCING
        QUnit.test("Instancing", function(assert) {
          // FoxExp2( color, density = 0.00025 )

          // no params
          var object = new FogExp2();
          assert.ok(object, "Can instantiate a FogExp2.");

          // color
          var object_color = new FogExp2(0xffffff);
          assert.ok(object_color, "Can instantiate a FogExp2 with color.");

          // color, density
          var object_all = new FogExp2(0xffffff, 0.00030);
          assert.ok(object_all, "Can instantiate a FogExp2 with color, density.");
        });

        // PROPERTIES
        QUnit.todo("name", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("color", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("density", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC STUFF
        QUnit.test("isFogExp2", function(assert) {
          var object = new FogExp2();
          assert.ok(object.isFogExp2, "FogExp2.isFogExp2 should be true");
        });

        QUnit.todo("clone", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("toJSON", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}
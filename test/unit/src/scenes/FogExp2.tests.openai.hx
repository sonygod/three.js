package three.js.test.unit.src.scenes;

import three.js.scenes.FogExp2;

class FogExp2Tests {
  public static function main() {
    Tester.module("Scenes", () => {
      Tester.module("FogExp2", () => {
        // INSTANCING
        Tester.test("Instancing", (assert) => {
          // no params
          var object = new FogExp2();
          assert.isTrue(object != null, "Can instantiate a FogExp2.");

          // color
          var object_color = new FogExp2(0xffffff);
          assert.isTrue(object_color != null, "Can instantiate a FogExp2 with color.");

          // color, density
          var object_all = new FogExp2(0xffffff, 0.00030);
          assert.isTrue(object_all != null, "Can instantiate a FogExp2 with color, density.");
        });

        // PROPERTIES
        Tester.todo("name", (assert) => {
          assert.fail("everything's gonna be alright");
        });

        Tester.todo("color", (assert) => {
          assert.fail("everything's gonna be alright");
        });

        Tester.todo("density", (assert) => {
          assert.fail("everything's gonna be alright");
        });

        // PUBLIC STUFF
        Tester.test("isFogExp2", (assert) => {
          var object = new FogExp2();
          assert.isTrue(object.isFogExp2, "FogExp2.isFogExp2 should be true");
        });

        Tester.todo("clone", (assert) => {
          assert.fail("everything's gonna be alright");
        });

        Tester.todo("toJSON", (assert) => {
          assert.fail("everything's gonna be alright");
        });
      });
    });
  }
}
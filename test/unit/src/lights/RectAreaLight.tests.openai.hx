package three.js.test.unit.src.lights;

import three.js.lights.RectAreaLight;
import three.js.lights.Light;
import three.js.utils.QUnitUtils;

class RectAreaLightTests {
  public function new() {}

  public static function main() {
    QUnit.module("Lights", function() {
      QUnit.module("RectAreaLight", function(hooks) {
        var lights:Array<RectAreaLight> = null;
        hooks.beforeEach(function() {
          var parameters = {
            color: 0xaaaaaa,
            intensity: 0.5,
            width: 100,
            height: 50
          };
          lights = [
            new RectAreaLight(parameters.color),
            new RectAreaLight(parameters.color, parameters.intensity),
            new RectAreaLight(parameters.color, parameters.intensity, parameters.width),
            new RectAreaLight(parameters.color, parameters.intensity, parameters.width, parameters.height)
          ];
        });

        QUnit.test("Extending", function(assert) {
          var object:RectAreaLight = new RectAreaLight();
          assert.isTrue(Type.getInstance(object) == Light, "RectAreaLight extends from Light");
        });

        QUnit.test("Instancing", function(assert) {
          var object:RectAreaLight = new RectAreaLight();
          assert.notNull(object, "Can instantiate a RectAreaLight.");
        });

        QUnit.test("type", function(assert) {
          var object:RectAreaLight = new RectAreaLight();
          assert.equal(object.type, "RectAreaLight", "RectAreaLight.type should be RectAreaLight");
        });

        QUnit.todo("width", function(assert) {
          assert.fail("everything's gonna be alright");
        });

        QUnit.todo("height", function(assert) {
          assert.fail("everything's gonna be alright");
        });

        QUnit.test("power", function(assert) {
          var a:RectAreaLight = new RectAreaLight(0xaaaaaa, 1, 10, 10);
          var actual:Float = 0;
          var expected:Float = 0;

          a.intensity = 100;
          actual = a.power;
          expected = 100 * a.width * a.height * Math.PI;
          assert.numEqual(actual, expected, "Correct power for an intensity of 100");

          a.intensity = 40;
          actual = a.power;
          expected = 40 * a.width * a.height * Math.PI;
          assert.numEqual(actual, expected, "Correct power for an intensity of 40");

          a.power = 100;
          actual = a.intensity;
          expected = 100 / (a.width * a.height * Math.PI);
          assert.numEqual(actual, expected, "Correct intensity for a power of 100");
        });

        QUnit.test("isRectAreaLight", function(assert) {
          var object:RectAreaLight = new RectAreaLight();
          assert.isTrue(object.isRectAreaLight, "RectAreaLight.isRectAreaLight should be true");
        });

        QUnit.todo("copy", function(assert) {
          assert.fail("everything's gonna be alright");
        });

        QUnit.todo("toJSON", function(assert) {
          assert.fail("everything's gonna be alright");
        });

        QUnit.test("Standard light tests", function(assert) {
          QUnitUtils.runStdLightTests(assert, lights);
        });
      });
    });
  }
}
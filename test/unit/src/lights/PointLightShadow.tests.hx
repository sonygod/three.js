package three.test.unit.src.lights;

import js.QUnit;
import three.lights.PointLightShadow;
import three.lights.LightShadow;

class PointLightShadowTests {
  public static function main() {
    QUnit.module("Lights", () -> {
      QUnit.module("PointLightShadow", () -> {
        // INHERITANCE
        QUnit.test("Extending", (assert) -> {
          var object = new PointLightShadow();
          assert.isTrue(object instanceof LightShadow, 'PointLightShadow extends from LightShadow');
        });

        // INSTANCING
        QUnit.test("Instancing", (assert) -> {
          var object = new PointLightShadow();
          assert.notNull(object, 'Can instantiate a PointLightShadow.');
        });

        // PUBLIC
        QUnit.test("isPointLightShadow", (assert) -> {
          var object = new PointLightShadow();
          assert.isTrue(object.isPointLightShadow, 'PointLightShadow.isPointLightShadow should be true');
        });

        QUnit.todo("updateMatrices", (assert) -> {
          assert.fail('everything\'s gonna be alright');
        });
      });
    });
  }
}
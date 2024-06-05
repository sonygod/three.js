import qunit.QUnit;

import three.renderers.shaders.UniformsLib;

class Main {
  static function main() {
    QUnit.module("Renderers", function() {
      QUnit.module("Shaders", function() {
        QUnit.module("UniformsLib", function() {
          QUnit.test("Instancing", function(assert) {
            assert.ok(UniformsLib, "UniformsLib is defined.");
          });
        });
      });
    });
  }
}

Main.main();
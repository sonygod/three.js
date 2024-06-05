import qunit.QUnit;

class WebGLProgram {

  public function new() {
  }

  public function getUniforms():Dynamic {
    return null;
  }

  public function getAttributes():Dynamic {
    return null;
  }

  public function destroy():Void {
  }
}

class Renderers {

  public static function main() {
    QUnit.module("Renderers", function() {
      QUnit.module("WebGL", function() {
        QUnit.module("WebGLProgram", function() {
          QUnit.todo("Instancing", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("uniforms", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("attributes", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("getUniforms", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("getAttributes", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });

          QUnit.todo("destroy", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });
        });
      });
    });
  }
}

class Main {

  public static function main() {
    Renderers.main();
  }
}
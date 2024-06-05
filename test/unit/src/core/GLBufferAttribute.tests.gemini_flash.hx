import qunit.QUnit;
import three.core.GLBufferAttribute;

class GLBufferAttributeTest {
  static function main() {
    QUnit.module("Core", function() {
      QUnit.module("GLBufferAttribute", function() {
        // INSTANCING
        QUnit.test("Instancing", function(assert) {
          var object = new GLBufferAttribute();
          assert.ok(object, "Can instantiate a GLBufferAttribute.");
        });

        // PROPERTIES
        QUnit.todo("name", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("buffer", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("type", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("itemSize", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("elementSize", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("count", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("version", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("needsUpdate", function(assert) {
          // set needsUpdate( value )
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isGLBufferAttribute", function(assert) {
          var object = new GLBufferAttribute();
          assert.ok(
            object.isGLBufferAttribute,
            "GLBufferAttribute.isGLBufferAttribute should be true"
          );
        });

        QUnit.todo("setBuffer", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setType", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setItemSize", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setCount", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}

class GLBufferAttribute {
  public var isGLBufferAttribute:Bool = true;
  // Add the properties and methods for GLBufferAttribute
  // ...
}
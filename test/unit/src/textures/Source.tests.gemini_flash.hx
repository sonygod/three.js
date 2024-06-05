import qunit.QUnit;
import three.textures.Source;

class TexturesTest extends qunit.TestCase {
  public function new() {
    super();
  }

  override function setUp() {
    QUnit.module("Textures", function() {
      QUnit.module("Source", function() {
        // INSTANCING
        QUnit.test("Instancing", function(assert) {
          var object = new Source();
          assert.ok(object, "Can instantiate a Source.");
        });

        // PROPERTIES
        QUnit.todo("data", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("needsUpdate", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("uuid", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("version", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isSource", function(assert) {
          var object = new Source();
          assert.ok(object.isSource, "Source.isSource should be true");
        });

        QUnit.todo("toJSON", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}

class Main {
  static function main() {
    new TexturesTest();
  }
}
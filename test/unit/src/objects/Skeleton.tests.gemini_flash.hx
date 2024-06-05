import qunit.QUnit;
import three.objects.Skeleton;

class SkeletonTest {
  static function main() {
    QUnit.module("Objects", function() {
      QUnit.module("Skeleton", function() {
        // INSTANCING
        QUnit.test("Instancing", function(assert) {
          var object = new Skeleton();
          assert.ok(object, "Can instantiate a Skeleton.");
        });

        // PROPERTIES
        QUnit.todo("uuid", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("bones", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("boneInverses", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("boneMatrices", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("boneTexture", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("frame", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.todo("init", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("calculateInverses", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("pose", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("update", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("clone", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("computeBoneTexture", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getBoneByName", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.test("dispose", function(assert) {
          assert.expect(0);
          var object = new Skeleton();
          object.dispose();
        });

        QUnit.todo("fromJSON", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("toJSON", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}

class qunit.QUnit {
  static function module(name:String, callback:Dynamic->Void) {
    // Implementation for QUnit module
  }

  static function test(name:String, callback:Dynamic->Void) {
    // Implementation for QUnit test
  }

  static function todo(name:String, callback:Dynamic->Void) {
    // Implementation for QUnit todo
  }

  static function expect(count:Int) {
    // Implementation for QUnit expect
  }

  static function ok(value:Bool, message:String) {
    // Implementation for QUnit ok
  }
}
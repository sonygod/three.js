import qunit.QUnit;
import three.core.InstancedInterleavedBuffer;
import three.core.InterleavedBuffer;

class CoreTest extends qunit.QUnit {
  static function main() {
    new CoreTest().run();
  }

  override function run() {
    QUnit.module("Core", function() {
      QUnit.module("InstancedInterleavedBuffer", function() {
        // INHERITANCE
        QUnit.test("Extending", function(assert) {
          var object = new InstancedInterleavedBuffer();
          assert.strictEqual(object instanceof InterleavedBuffer, true, "InstancedInterleavedBuffer extends from InterleavedBuffer");
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
          var array = new Float32Array([1, 2, 3, 7, 8, 9]);
          var instance = new InstancedInterleavedBuffer(array, 3);

          assert.ok(instance.meshPerAttribute == 1, "ok");
        });

        // PROPERTIES
        QUnit.todo("meshPerAttribute", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.test("isInstancedInterleavedBuffer", function(assert) {
          var object = new InstancedInterleavedBuffer();
          assert.ok(object.isInstancedInterleavedBuffer, "InstancedInterleavedBuffer.isInstancedInterleavedBuffer should be true");
        });

        QUnit.test("copy", function(assert) {
          var array = new Float32Array([1, 2, 3, 7, 8, 9]);
          var instance = new InstancedInterleavedBuffer(array, 3);
          var copiedInstance = instance.copy(instance);

          assert.ok(copiedInstance.meshPerAttribute == 1, "additional attribute was copied");
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

class Float32Array {
  public function new(array:Array<Float>) {
  }
}

CoreTest.main();
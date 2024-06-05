import qunit.QUnit;
import three.core.InstancedBufferAttribute;
import three.core.BufferAttribute;

class CoreTest extends qunit.QUnit {
  static function main() {
    new CoreTest().run();
  }

  override function run() {
    module("Core", () => {
      module("InstancedBufferAttribute", () => {
        test("Extending", (assert) => {
          var object = new BufferAttribute();
          assert.ok(object instanceof BufferAttribute, "BufferAttribute extends from BufferAttribute");
        });

        test("Instancing", (assert) => {
          var instance = new InstancedBufferAttribute(new Float32Array(10), 2);
          assert.ok(instance.meshPerAttribute == 1, "Can instantiate an InstancedBufferGeometry.");

          instance = new InstancedBufferAttribute(new Float32Array(10), 2, false, 123);
          assert.ok(instance.meshPerAttribute == 123, "Can instantiate an InstancedBufferGeometry with array, itemSize, normalized, and meshPerAttribute.");
        });

        todo("meshPerAttribute", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });

        test("isInstancedBufferAttribute", (assert) => {
          var object = new InstancedBufferAttribute();
          assert.ok(object.isInstancedBufferAttribute, "InstancedBufferAttribute.isInstancedBufferAttribute should be true");
        });

        test("copy", (assert) => {
          var array = new Float32Array([1, 2, 3, 7, 8, 9]);
          var instance = new InstancedBufferAttribute(array, 2, true, 123);
          var copiedInstance = instance.copy(instance);

          assert.ok(copiedInstance instanceof InstancedBufferAttribute, "the clone has the correct type");
          assert.ok(copiedInstance.itemSize == 2, "itemSize was copied");
          assert.ok(copiedInstance.normalized == true, "normalized was copied");
          assert.ok(copiedInstance.meshPerAttribute == 123, "meshPerAttribute was copied");

          for (i in 0...array.length) {
            assert.ok(copiedInstance.array[i] == array[i], "array was copied");
          }
        });

        todo("toJSON", (assert) => {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}

class Float32Array {
  public var length(default, null):Int;
  public var array(default, null):Array<Float>;

  public function new(length:Int) {
    this.length = length;
    this.array = new Array<Float>(length);
  }

  public function new(array:Array<Float>) {
    this.length = array.length;
    this.array = array;
  }

  public function get(index:Int):Float {
    return array[index];
  }

  public function set(index:Int, value:Float) {
    array[index] = value;
  }
}

CoreTest.main();
import haxe.io.Bytes;
import haxe.io.Float32Array;
import qunit.QUnit;

class InterleavedBufferAttribute {
  public var data: InterleavedBuffer;
  public var itemSize: Int;
  public var offset: Int;
  public var normalized: Bool;
  public var name: String;
  public var count: Int;

  public function new(data: InterleavedBuffer, itemSize: Int, offset: Int, normalized: Bool = false, name: String = null) {
    this.data = data;
    this.itemSize = itemSize;
    this.offset = offset;
    this.normalized = normalized;
    this.name = name;
    this.count = data.array.length / data.stride;
  }

  public function isInterleavedBufferAttribute(): Bool {
    return true;
  }

  public function setX(index: Int, value: Float): Void {
    data.array[index * itemSize + offset] = value;
  }

  public function setY(index: Int, value: Float): Void {
    data.array[index * itemSize + offset + 1] = value;
  }

  public function setZ(index: Int, value: Float): Void {
    data.array[index * itemSize + offset + 2] = value;
  }

  public function setW(index: Int, value: Float): Void {
    data.array[index * itemSize + offset + 3] = value;
  }

  public function getX(index: Int): Float {
    return data.array[index * itemSize + offset];
  }

  public function getY(index: Int): Float {
    return data.array[index * itemSize + offset + 1];
  }

  public function getZ(index: Int): Float {
    return data.array[index * itemSize + offset + 2];
  }

  public function getW(index: Int): Float {
    return data.array[index * itemSize + offset + 3];
  }

  public function clone(): InterleavedBufferAttribute {
    return new InterleavedBufferAttribute(data.clone(), itemSize, offset, normalized, name);
  }

  public function toJSON(): Dynamic {
    return {
      data: data.toJSON(),
      itemSize: itemSize,
      offset: offset,
      normalized: normalized,
      name: name
    };
  }
}

class InterleavedBuffer {
  public var array: Float32Array;
  public var stride: Int;

  public function new(array: Float32Array, stride: Int) {
    this.array = array;
    this.stride = stride;
  }

  public function clone(): InterleavedBuffer {
    return new InterleavedBuffer(array.clone(), stride);
  }

  public function toJSON(): Dynamic {
    return {
      array: array.toJSON(),
      stride: stride
    };
  }
}

class QUnit {
  static public function main() {
    QUnit.module("Core", function() {
      QUnit.module("InterleavedBufferAttribute", function() {
        QUnit.test("Instancing", function(assert) {
          var object = new InterleavedBufferAttribute();
          assert.ok(object, "Can instantiate an InterleavedBufferAttribute.");
        });

        QUnit.test("count", function(assert) {
          var buffer = new InterleavedBuffer(new Float32Array([1, 2, 3, 7, 8, 9]), 3);
          var instance = new InterleavedBufferAttribute(buffer, 2, 0);
          assert.ok(instance.count == 2, "count is calculated via array length / stride");
        });

        QUnit.test("setX", function(assert) {
          var buffer = new InterleavedBuffer(new Float32Array([1, 2, 3, 7, 8, 9]), 3);
          var instance = new InterleavedBufferAttribute(buffer, 2, 0);

          instance.setX(0, 123);
          instance.setX(1, 321);

          assert.ok(instance.data.array[0] == 123 && instance.data.array[3] == 321, "x was calculated correct based on index and default offset");

          buffer = new InterleavedBuffer(new Float32Array([1, 2, 3, 7, 8, 9]), 3);
          instance = new InterleavedBufferAttribute(buffer, 2, 1);

          instance.setX(0, 123);
          instance.setX(1, 321);

          assert.ok(instance.data.array[1] == 123 && instance.data.array[4] == 321, "x was calculated correct based on index and default offset");
        });
      });
    });
  }
}

class Main {
  static public function main() {
    QUnit.main();
  }
}
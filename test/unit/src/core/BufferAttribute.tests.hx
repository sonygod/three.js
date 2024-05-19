import haxe.unit.TestCase;

class BufferAttributeTests {
  public function new() {}

  public function testInstancing() {
    assertThrows(function() {
      new BufferAttribute([1, 2, 3, 4], 2, false);
    }, "array should be a Typed Array", "Calling constructor with a simple array throws Error");
  }

  // PROPERTIES
  public function test_name() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_array() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_itemSize() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_count() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_normalized() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_usage() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_updateRanges() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_version() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_onUploadCallback() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_needsUpdate() {
    assertTrue(false, "everything's gonna be alright");
  }

  // PUBLIC
  public function test_isBufferAttribute() {
    var object = new BufferAttribute();
    assertTrue(object.isBufferAttribute, "BufferAttribute.isBufferAttribute should be true");
  }

  public function test_setUsage() {
    var attr = new BufferAttribute();
    attr.setUsage(DynamicDrawUsage);
    assertEquals(attr.usage, DynamicDrawUsage, "Usage was set");
  }

  public function test_copy() {
    var attr = new BufferAttribute(new Float32Array([1, 2, 3, 4, 5, 6]), 3);
    attr.setUsage(DynamicDrawUsage);
    attr.needsUpdate = true;

    var attrCopy = new BufferAttribute().copy(attr);

    assertTrue(attr.count == attrCopy.count, "count is equal");
    assertTrue(attr.itemSize == attrCopy.itemSize, "itemSize is equal");
    assertTrue(attr.usage == attrCopy.usage, "usage is equal");
    assertTrue(attr.array.length == attrCopy.array.length, "array length is equal");
    assertTrue(attr.version == 1 && attrCopy.version == 0, "version is not copied which is good");
  }

  public function test_copyAt() {
    var attr = new BufferAttribute(new Float32Array([1, 2, 3, 4, 5, 6, 7, 8, 9]), 3);
    var attr2 = new BufferAttribute(new Float32Array(9), 3);

    attr2.copyAt(1, attr, 2);
    attr2.copyAt(0, attr, 1);
    attr2.copyAt(2, attr, 0);

    var i = attr.array;
    var i2 = attr2.array; // should be [4, 5, 6, 7, 8, 9, 1, 2, 3]

    assertTrue(i2[0] == i[3] && i2[1] == i[4] && i2[2] == i[5], "chunck copied to correct place");
    assertTrue(i2[3] == i[6] && i2[4] == i[7] && i2[5] == i[8], "chunck copied to correct place");
    assertTrue(i2[6] == i[0] && i2[7] == i[1] && i2[8] == i[2], "chunck copied to correct place");
  }

  public function test_copyArray() {
    var f32a = new Float32Array([5, 6, 7, 8]);
    var a = new BufferAttribute(new Float32Array([1, 2, 3, 4]), 2, false);

    a.copyArray(f32a);

    assertEquals(a.array, f32a, "Check array has new values");
  }

  public function test_applyMatrix3() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_applyMatrix4() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_applyNormalMatrix() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_transformDirection() {
    assertTrue(false, "everything's gonna be alright");
  }

  public function test_set() {
    var f32a = new Float32Array([1, 2, 3, 4]);
    var a = new BufferAttribute(f32a, 2, false);
    var expected = new Float32Array([9, 2, 8, 4]);

    a.set([9]);
    a.set([8], 2);

    assertEquals(a.array, expected, "Check array has expected values");
  }

  public function test_setXY() {
    var f32a = new Float32Array([1, 2, 3, 4]);
    var a = new BufferAttribute(f32a, 2, false);
    var expected = new Float32Array([-1, -2, 3, 4]);

    a.setXY(0, -1, -2);

    assertEquals(a.array, expected, "Check for the correct values");
  }

  public function test_setXYZ() {
    var f32a = new Float32Array([1, 2, 3, 4, 5, 6]);
    var a = new BufferAttribute(f32a, 3, false);
    var expected = new Float32Array([1, 2, 3, -4, -5, -6]);

    a.setXYZ(1, -4, -5, -6);

    assertEquals(a.array, expected, "Check for the correct values");
  }

  public function test_setXYZW() {
    var f32a = new Float32Array([1, 2, 3, 4]);
    var a = new BufferAttribute(f32a, 4, false);
    var expected = new Float32Array([-1, -2, -3, -4]);

    a.setXYZW(0, -1, -2, -3, -4);

    assertEquals(a.array, expected, "Check for the correct values");
  }

  public function test_onUpload() {
    var a = new BufferAttribute();
    var func = function() {};

    a.onUpload(func);

    assertEquals(a.onUploadCallback, func, "Check callback was set properly");
  }

  public function test_clone() {
    var attr = new BufferAttribute(new Float32Array([1, 2, 3, 4, 0.12, -12]), 2);
    var attrCopy = attr.clone();

    assertTrue(attr.array.length == attrCopy.array.length, "attribute was cloned");
    for (i in 0...attr.array.length) {
      assertTrue(attr.array[i] == attrCopy.array[i], "array item is equal");
    }
  }

  public function test_toJSON() {
    var attr = new BufferAttribute(new Float32Array([1, 2, 3, 4, 5, 6]), 3);
    assertEquals(attr.toJSON(), {
      itemSize: 3,
      type: "Float32Array",
      array: [1, 2, 3, 4, 5, 6],
      normalized: false
    }, "Serialized to JSON as expected");

    var attr2 = new BufferAttribute(new Float32Array([1, 2, 3, 4, 5, 6]), 3, true);
    attr2.name = "attributeName";
    attr2.setUsage(DynamicDrawUsage);
    attr2.addUpdateRange(1, 2);
    assertEquals(attr2.toJSON(), {
      itemSize: 3,
      type: "Float32Array",
      array: [1, 2, 3, 4, 5, 6],
      normalized: true,
      name: "attributeName",
      usage: DynamicDrawUsage
    }, "Serialized to JSON as expected with non-default values");
  }

  // OTHERS
  public function test_count() {
    assertTrue(new BufferAttribute(new Float32Array([1, 2, 3, 4, 5, 6]), 3).count == 2, "count is equal to the number of chunks");
  }
}

class Int8BufferAttributeTests {
  public function new() {}

  public function testExtending() {
    var object = new Int8BufferAttribute();
    assertTrue(object instanceof BufferAttribute, "Int8BufferAttribute extends from BufferAttribute");
  }

  public function testInstancing() {
    var object = new Int8BufferAttribute();
    assertTrue(object != null, "Can instantiate an Int8BufferAttribute.");
  }
}

class Uint8BufferAttributeTests {
  public function new() {}

  public function testExtending() {
    var object = new Uint8BufferAttribute();
    assertTrue(object instanceof BufferAttribute, "Uint8BufferAttribute extends from BufferAttribute");
  }

  public function testInstancing() {
    var object = new Uint8BufferAttribute();
    assertTrue(object != null, "Can instantiate a Uint8BufferAttribute.");
  }
}

class Uint8ClampedBufferAttributeTests {
  public function new() {}

  public function testExtending() {
    var object = new Uint8ClampedBufferAttribute();
    assertTrue(object instanceof BufferAttribute, "Uint8ClampedBufferAttribute extends from BufferAttribute");
  }

  public function testInstancing() {
    var object = new Uint8ClampedBufferAttribute();
    assertTrue(object != null, "Can instantiate a Uint8ClampedBufferAttribute.");
  }
}

class Int16BufferAttributeTests {
  public function new() {}

  public function testExtending() {
    var object = new Int16BufferAttribute();
    assertTrue(object instanceof BufferAttribute, "Int16BufferAttribute extends from BufferAttribute");
  }

  public function testInstancing() {
    var object = new Int16BufferAttribute();
    assertTrue(object != null, "Can instantiate an Int16BufferAttribute.");
  }
}

class Uint16BufferAttributeTests {
  public function new() {}

  public function testExtending() {
    var object = new Uint16BufferAttribute();
    assertTrue(object instanceof BufferAttribute, "Uint16BufferAttribute extends from BufferAttribute");
  }

  public function testInstancing() {
    var object = new Uint16BufferAttribute();
    assertTrue(object != null, "Can instantiate a Uint16BufferAttribute.");
  }
}

class Int32BufferAttributeTests {
  public function new() {}

  public function testExtending() {
    var object = new Int32BufferAttribute();
    assertTrue(object instanceof BufferAttribute, "Int32BufferAttribute extends from BufferAttribute");
  }

  public function testInstancing() {
    var object = new Int32BufferAttribute();
    assertTrue(object != null, "Can instantiate an Int32BufferAttribute.");
  }
}

class Uint32BufferAttributeTests {
  public function new() {}

  public function testExtending() {
    var object = new Uint32BufferAttribute();
    assertTrue(object instanceof BufferAttribute, "Uint32BufferAttribute extends from BufferAttribute");
  }

  public function testInstancing() {
    var object = new Uint32BufferAttribute();
    assertTrue(object != null, "Can instantiate a Uint32BufferAttribute.");
  }
}

class Float16BufferAttributeTests {
  public function new() {}

  public function testExtending() {
    var object = new Float16BufferAttribute();
    assertTrue(object instanceof BufferAttribute, "Float16BufferAttribute extends from BufferAttribute");
  }

  public function testInstancing() {
    var object = new Float16BufferAttribute();
    assertTrue(object != null, "Can instantiate a Float16BufferAttribute.");
  }

  public function test_setXY() {
    var f32a = new Float32Array([1, 2, 3, 4]);
    var a = new Float16BufferAttribute(toHalfFloatArray(f32a), 2, false);
    var expected = new Float32Array([-1, -2, 3, 4]);

    a.setXY(0, -1, -2);

    assertEquals(fromHalfFloatArray(a.array), expected, "Check for the correct values");
  }

  public function test_setXYZ() {
    var f32a = new Float32Array([1, 2, 3, 4, 5, 6]);
    var a = new Float16BufferAttribute(toHalfFloatArray(f32a), 3, false);
    var expected = new Float32Array([1, 2, 3, -4, -5, -6]);

    a.setXYZ(1, -4, -5, -6);

    assertEquals(fromHalfFloatArray(a.array), expected, "Check for the correct values");
  }

  public function test_setXYZW() {
    var f32a = new Float32Array([1, 2, 3, 4]);
    var a = new Float16BufferAttribute(toHalfFloatArray(f32a), 4, false);
    var expected = new Float32Array([-1, -2, -3, -4]);

    a.setXYZW(0, -1, -2, -3, -4);

    assertEquals(fromHalfFloatArray(a.array), expected, "Check for the correct values");
  }
}

class Float32BufferAttributeTests {
  public function new() {}

  public function testExtending() {
    var object = new Float32BufferAttribute();
    assertTrue(object instanceof BufferAttribute, "Float32BufferAttribute extends from BufferAttribute");
  }

  public function testInstancing() {
    var object = new Float32BufferAttribute();
    assertTrue(object != null, "Can instantiate a Float32BufferAttribute.");
  }
}
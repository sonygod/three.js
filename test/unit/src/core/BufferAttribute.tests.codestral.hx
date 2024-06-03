package three.js.test.unit.src.core;

import js.html.QUnit;
import three.js.src.core.BufferAttribute;
import three.js.src.constants.DynamicDrawUsage;
import three.js.src.extras.DataUtils;

class BufferAttributeTests {
    public function new() {
        QUnit.module("Core", () -> {
            QUnit.module("BufferAttribute", () -> {
                QUnit.test("Instancing", (assert) -> {
                    try {
                        new BufferAttribute([1, 2, 3, 4], 2, false);
                    } catch (e:Dynamic) {
                        assert.isTrue(Std.is(e, Error), "Calling constructor with a simple array throws Error");
                    }
                });

                QUnit.test("isBufferAttribute", (assert) -> {
                    var object = new BufferAttribute();
                    assert.isTrue(
                        object.isBufferAttribute,
                        "BufferAttribute.isBufferAttribute should be true"
                    );
                });

                QUnit.test("setUsage", (assert) -> {
                    var attr = new BufferAttribute();
                    attr.setUsage(DynamicDrawUsage);

                    assert.isTrue(attr.usage == DynamicDrawUsage, "Usage was set");
                });

                QUnit.test("copy", (assert) -> {
                    var attr = new BufferAttribute(new Float32Array([1, 2, 3, 4, 5, 6]), 3);
                    attr.setUsage(DynamicDrawUsage);
                    attr.needsUpdate = true;

                    var attrCopy = new BufferAttribute().copy(attr);

                    assert.isTrue(attr.count == attrCopy.count, "count is equal");
                    assert.isTrue(attr.itemSize == attrCopy.itemSize, "itemSize is equal");
                    assert.isTrue(attr.usage == attrCopy.usage, "usage is equal");
                    assert.isTrue(attr.array.length == attrCopy.array.length, "array length is equal");
                    assert.isTrue(attr.version == 1 && attrCopy.version == 0, "version is not copied which is good");
                });

                QUnit.test("copyAt", (assert) -> {
                    var attr = new BufferAttribute(new Float32Array([1, 2, 3, 4, 5, 6, 7, 8, 9]), 3);
                    var attr2 = new BufferAttribute(new Float32Array(9), 3);

                    attr2.copyAt(1, attr, 2);
                    attr2.copyAt(0, attr, 1);
                    attr2.copyAt(2, attr, 0);

                    var i = attr.array;
                    var i2 = attr2.array; // should be [4, 5, 6, 7, 8, 9, 1, 2, 3]

                    assert.isTrue(i2[0] == i[3] && i2[1] == i[4] && i2[2] == i[5], "chunk copied to correct place");
                    assert.isTrue(i2[3] == i[6] && i2[4] == i[7] && i2[5] == i[8], "chunk copied to correct place");
                    assert.isTrue(i2[6] == i[0] && i2[7] == i[1] && i2[8] == i[2], "chunk copied to correct place");
                });

                QUnit.test("copyArray", (assert) -> {
                    var f32a = new Float32Array([5, 6, 7, 8]);
                    var a = new BufferAttribute(new Float32Array([1, 2, 3, 4]), 2, false);

                    a.copyArray(f32a);

                    assert.isTrue(a.array == f32a, "Check array has new values");
                });

                QUnit.test("set", (assert) -> {
                    var f32a = new Float32Array([1, 2, 3, 4]);
                    var a = new BufferAttribute(f32a, 2, false);
                    var expected = new Float32Array([9, 2, 8, 4]);

                    a.set([9]);
                    a.set([8], 2);

                    assert.isTrue(a.array == expected, "Check array has expected values");
                });

                QUnit.test("set[X, Y, Z, W, XYZ, XYZW]/get[X, Y, Z, W]", (assert) -> {
                    var f32a = new Float32Array([1, 2, 3, 4, 5, 6, 7, 8]);
                    var a = new BufferAttribute(f32a, 4, false);
                    var expected = new Float32Array([1, 2, -3, -4, -5, -6, 7, 8]);

                    a.setX(1, a.getX(1) * -1);
                    a.setY(1, a.getY(1) * -1);
                    a.setZ(0, a.getZ(0) * -1);
                    a.setW(0, a.getW(0) * -1);

                    assert.isTrue(a.array == expected, "Check all set* calls set the correct values");
                });

                QUnit.test("setXY", (assert) -> {
                    var f32a = new Float32Array([1, 2, 3, 4]);
                    var a = new BufferAttribute(f32a, 2, false);
                    var expected = new Float32Array([-1, -2, 3, 4]);

                    a.setXY(0, -1, -2);

                    assert.isTrue(a.array == expected, "Check for the correct values");
                });

                QUnit.test("setXYZ", (assert) -> {
                    var f32a = new Float32Array([1, 2, 3, 4, 5, 6]);
                    var a = new BufferAttribute(f32a, 3, false);
                    var expected = new Float32Array([1, 2, 3, -4, -5, -6]);

                    a.setXYZ(1, -4, -5, -6);

                    assert.isTrue(a.array == expected, "Check for the correct values");
                });

                QUnit.test("setXYZW", (assert) -> {
                    var f32a = new Float32Array([1, 2, 3, 4]);
                    var a = new BufferAttribute(f32a, 4, false);
                    var expected = new Float32Array([-1, -2, -3, -4]);

                    a.setXYZW(0, -1, -2, -3, -4);

                    assert.isTrue(a.array == expected, "Check for the correct values");
                });

                QUnit.test("onUpload", (assert) -> {
                    var a = new BufferAttribute();
                    var func = function () { };

                    a.onUpload(func);

                    assert.isTrue(a.onUploadCallback == func, "Check callback was set properly");
                });

                QUnit.test("clone", (assert) -> {
                    var attr = new BufferAttribute(new Float32Array([1, 2, 3, 4, 0.12, -12]), 2);
                    var attrCopy = attr.clone();

                    assert.isTrue(attr.array.length == attrCopy.array.length, "attribute was cloned");
                    for (var i = 0; i < attr.array.length; i++) {
                        assert.isTrue(attr.array[i] == attrCopy.array[i], "array item is equal");
                    }
                });

                QUnit.test("toJSON", (assert) -> {
                    var attr = new BufferAttribute(new Float32Array([1, 2, 3, 4, 5, 6]), 3);
                    assert.isTrue(attr.toJSON() == {
                        itemSize: 3,
                        type: 'Float32Array',
                        array: [1, 2, 3, 4, 5, 6],
                        normalized: false
                    }, "Serialized to JSON as expected");

                    var attr2 = new BufferAttribute(new Float32Array([1, 2, 3, 4, 5, 6]), 3, true);
                    attr2.name = 'attributeName';
                    attr2.setUsage(DynamicDrawUsage);
                    attr2.addUpdateRange(1, 2);
                    assert.isTrue(attr2.toJSON() == {
                        itemSize: 3,
                        type: 'Float32Array',
                        array: [1, 2, 3, 4, 5, 6],
                        normalized: true,
                        name: 'attributeName',
                        usage: DynamicDrawUsage,
                    }, "Serialized to JSON as expected with non-default values");
                });

                QUnit.test("count", (assert) -> {
                    assert.isTrue(
                        new BufferAttribute(new Float32Array([1, 2, 3, 4, 5, 6]), 3).count == 2,
                        "count is equal to the number of chunks"
                    );
                });
            });

            QUnit.module("Int8BufferAttribute", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new three.js.src.core.Int8BufferAttribute();
                    assert.isTrue(
                        object is BufferAttribute,
                        "Int8BufferAttribute extends from BufferAttribute"
                    );
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new three.js.src.core.Int8BufferAttribute();
                    assert.isTrue(object != null, "Can instantiate an Int8BufferAttribute.");
                });
            });

            QUnit.module("Uint8BufferAttribute", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new three.js.src.core.Uint8BufferAttribute();
                    assert.isTrue(
                        object is BufferAttribute,
                        "Uint8BufferAttribute extends from BufferAttribute"
                    );
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new three.js.src.core.Uint8BufferAttribute();
                    assert.isTrue(object != null, "Can instantiate a Uint8BufferAttribute.");
                });
            });

            QUnit.module("Uint8ClampedBufferAttribute", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new three.js.src.core.Uint8ClampedBufferAttribute();
                    assert.isTrue(
                        object is BufferAttribute,
                        "Uint8ClampedBufferAttribute extends from BufferAttribute"
                    );
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new three.js.src.core.Uint8ClampedBufferAttribute();
                    assert.isTrue(object != null, "Can instantiate a Uint8ClampedBufferAttribute.");
                });
            });

            QUnit.module("Int16BufferAttribute", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new three.js.src.core.Int16BufferAttribute();
                    assert.isTrue(
                        object is BufferAttribute,
                        "Int16BufferAttribute extends from BufferAttribute"
                    );
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new three.js.src.core.Int16BufferAttribute();
                    assert.isTrue(object != null, "Can instantiate an Int16BufferAttribute.");
                });
            });

            QUnit.module("Uint16BufferAttribute", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new three.js.src.core.Uint16BufferAttribute();
                    assert.isTrue(
                        object is BufferAttribute,
                        "Uint16BufferAttribute extends from BufferAttribute"
                    );
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new three.js.src.core.Uint16BufferAttribute();
                    assert.isTrue(object != null, "Can instantiate a Uint16BufferAttribute.");
                });
            });

            QUnit.module("Int32BufferAttribute", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new three.js.src.core.Int32BufferAttribute();
                    assert.isTrue(
                        object is BufferAttribute,
                        "Int32BufferAttribute extends from BufferAttribute"
                    );
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new three.js.src.core.Int32BufferAttribute();
                    assert.isTrue(object != null, "Can instantiate an Int32BufferAttribute.");
                });
            });

            QUnit.module("Uint32BufferAttribute", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new three.js.src.core.Uint32BufferAttribute();
                    assert.isTrue(
                        object is BufferAttribute,
                        "Uint32BufferAttribute extends from BufferAttribute"
                    );
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new three.js.src.core.Uint32BufferAttribute();
                    assert.isTrue(object != null, "Can instantiate a Uint32BufferAttribute.");
                });
            });

            QUnit.module("Float16BufferAttribute", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new three.js.src.core.Float16BufferAttribute();
                    assert.isTrue(
                        object is BufferAttribute,
                        "Float16BufferAttribute extends from BufferAttribute"
                    );
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new three.js.src.core.Float16BufferAttribute();
                    assert.isTrue(object != null, "Can instantiate a Float16BufferAttribute.");
                });

                var toHalfFloatArray = function (f32Array):Uint16Array {
                    var f16Array = new Uint16Array(f32Array.length);
                    for (var i = 0, n = f32Array.length; i < n; ++i) {
                        f16Array[i] = DataUtils.toHalfFloat(f32Array[i]);
                    }

                    return f16Array;
                };

                var fromHalfFloatArray = function (f16Array):Float32Array {
                    var f32Array = new Float32Array(f16Array.length);
                    for (var i = 0, n = f16Array.length; i < n; ++i) {
                        f32Array[i] = DataUtils.fromHalfFloat(f16Array[i]);
                    }

                    return f32Array;
                };

                QUnit.test("set[X, Y, Z, W, XYZ, XYZW]/get[X, Y, Z, W]", (assert) -> {
                    var f32a = new Float32Array([1, 2, 3, 4, 5, 6, 7, 8]);
                    var a = new three.js.src.core.Float16BufferAttribute(toHalfFloatArray(f32a), 4, false);
                    var expected = new Float32Array([1, 2, -3, -4, -5, -6, 7, 8]);

                    a.setX(1, a.getX(1) * -1);
                    a.setY(1, a.getY(1) * -1);
                    a.setZ(0, a.getZ(0) * -1);
                    a.setW(0, a.getW(0) * -1);

                    assert.isTrue(fromHalfFloatArray(a.array) == expected, "Check all set* calls set the correct values");
                });

                QUnit.test("setXY", (assert) -> {
                    var f32a = new Float32Array([1, 2, 3, 4]);
                    var a = new three.js.src.core.Float16BufferAttribute(toHalfFloatArray(f32a), 2, false);
                    var expected = new Float32Array([-1, -2, 3, 4]);

                    a.setXY(0, -1, -2);

                    assert.isTrue(fromHalfFloatArray(a.array) == expected, "Check for the correct values");
                });

                QUnit.test("setXYZ", (assert) -> {
                    var f32a = new Float32Array([1, 2, 3, 4, 5, 6]);
                    var a = new three.js.src.core.Float16BufferAttribute(toHalfFloatArray(f32a), 3, false);
                    var expected = new Float32Array([1, 2, 3, -4, -5, -6]);

                    a.setXYZ(1, -4, -5, -6);

                    assert.isTrue(fromHalfFloatArray(a.array) == expected, "Check for the correct values");
                });

                QUnit.test("setXYZW", (assert) -> {
                    var f32a = new Float32Array([1, 2, 3, 4]);
                    var a = new three.js.src.core.Float16BufferAttribute(toHalfFloatArray(f32a), 4, false);
                    var expected = new Float32Array([-1, -2, -3, -4]);

                    a.setXYZW(0, -1, -2, -3, -4);

                    assert.isTrue(fromHalfFloatArray(a.array) == expected, "Check for the correct values");
                });
            });

            QUnit.module("Float32BufferAttribute", () -> {
                QUnit.test("Extending", (assert) -> {
                    var object = new three.js.src.core.Float32BufferAttribute();
                    assert.isTrue(
                        object is BufferAttribute,
                        "Float32BufferAttribute extends from BufferAttribute"
                    );
                });

                QUnit.test("Instancing", (assert) -> {
                    var object = new three.js.src.core.Float32BufferAttribute();
                    assert.isTrue(object != null, "Can instantiate a Float32BufferAttribute.");
                });
            });
        });
    }
}
package three.test.core;

import haxe.ds.Array;
import three.BufferAttribute;
import three.Int8BufferAttribute;
import three.Uint8BufferAttribute;
import three.Uint8ClampedBufferAttribute;
import three.Int16BufferAttribute;
import three.Uint16BufferAttribute;
import three.Int32BufferAttribute;
import three.Uint32BufferAttribute;
import three.Float16BufferAttribute;
import three.Float32BufferAttribute;
import three.DynamicDrawUsage;
import three.DataUtils;

using three.DataUtils;

class BufferAttributeTests {

    public static function main() {
        QUnit.module("Core", () => {
            QUnit.module("BufferAttribute", () => {
                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    assert.throws(
                        function() {
                            new BufferAttribute([1, 2, 3, 4], 2, false);
                        },
                        "array should be a Typed Array",
                        "Calling constructor with a simple array throws Error"
                    );
                });

                // PROPERTIES
                QUnit.module("Properties", () => {
                    QUnit.todo("name", (assert) => {
                        assert.ok(false, "everything's gonna be alright");
                    });

                    // ... (omitted for brevity)
                });

                // PUBLIC
                QUnit.test("isBufferAttribute", (assert) => {
                    var object = new BufferAttribute();
                    assert.ok(object.isBufferAttribute, "BufferAttribute.isBufferAttribute should be true");
                });

                QUnit.test("setUsage", (assert) => {
                    var attr = new BufferAttribute();
                    attr.setUsage(DynamicDrawUsage);
                    assert.strictEqual(attr.usage, DynamicDrawUsage, "Usage was set");
                });

                // ... (omitted for brevity)
            });

            QUnit.module("Int8BufferAttribute", () => {
                // INHERITANCE
                QUnit.test("Extending", (assert) => {
                    var object = new Int8BufferAttribute();
                    assert.ok(object instanceof BufferAttribute, "Int8BufferAttribute extends from BufferAttribute");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    var object = new Int8BufferAttribute();
                    assert.ok(object, "Can instantiate a Int8BufferAttribute.");
                });
            });

            // ... (omitted for brevity)
        });
    }
}
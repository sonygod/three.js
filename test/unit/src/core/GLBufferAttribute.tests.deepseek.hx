package;

import js.Lib;
import js.QUnit;
import three.GLBufferAttribute;

class GLBufferAttributeTests {

    static function main() {
        QUnit.module("Core", () -> {
            QUnit.module("GLBufferAttribute", () -> {
                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new GLBufferAttribute();
                    assert.ok(object != null, "Can instantiate a GLBufferAttribute.");
                });

                // PROPERTIES
                QUnit.todo("name", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("buffer", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("type", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("itemSize", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("elementSize", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("count", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("version", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("needsUpdate", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.test("isGLBufferAttribute", (assert) -> {
                    var object = new GLBufferAttribute();
                    assert.ok(object.isGLBufferAttribute, "GLBufferAttribute.isGLBufferAttribute should be true");
                });

                QUnit.todo("setBuffer", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setType", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setItemSize", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setCount", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}
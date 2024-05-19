package three.test.unit.src.core;

import three.core.GLBufferAttribute;

class GLBufferAttributeTests {

    public function new() {}

    public static function main() {
        Suite.module("Core", () => {
            Suite.module("GLBufferAttribute", () => {
                // INSTANCING
                Test.addTest("Instancing", () => {
                    var object = new GLBufferAttribute();
                    Assert.isTrue(object != null, "Can instantiate a GLBufferAttribute.");
                });

                // PROPERTIES
                Test.todo("name", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Test.todo("buffer", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Test.todo("type", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Test.todo("itemSize", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Test.todo("elementSize", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Test.todo("count", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Test.todo("version", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Test.todo("needsUpdate", () => {
                    // set needsUpdate( value )
                    Assert.fail("everything's gonna be alright");
                });

                // PUBLIC
                Test.addTest("isGLBufferAttribute", () => {
                    var object = new GLBufferAttribute();
                    Assert.isTrue(object.isGLBufferAttribute, "GLBufferAttribute.isGLBufferAttribute should be true");
                });

                Test.todo("setBuffer", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Test.todo("setType", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Test.todo("setItemSize", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Test.todo("setCount", () => {
                    Assert.fail("everything's gonna be alright");
                });
            });
        });
    }
}
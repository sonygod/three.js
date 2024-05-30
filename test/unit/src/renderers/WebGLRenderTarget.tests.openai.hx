package three.test.unit.src.renderers;

import three.renderers.WebGLRenderTarget;
import three.core.EventDispatcher;

class WebGLRenderTargetTests {

    public function new() {}

    public static function main() {

        TestHelper.module("Renderers", () => {

            TestHelper.module("WebGLRenderTarget", () => {

                // INHERITANCE
                TestHelper.test("Extending", () => {

                    var object = new WebGLRenderTarget();
                    Assert.isTrue(object instanceof EventDispatcher, 'WebGLRenderTarget extends from EventDispatcher');

                });

                // INSTANCING
                TestHelper.test("Instancing", () => {

                    var object = new WebGLRenderTarget();
                    Assert.isTrue(object != null, 'Can instantiate a WebGLRenderTarget.');

                });

                // PROPERTIES
                TestHelper.todo("width", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("height", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("depth", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("scissor", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("scissorTest", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("viewport", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("texture", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("depthBuffer", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("stencilBuffer", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("depthTexture", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("samples", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("textures", () => {

                    Assert.fail("everything's gonna be alright");

                });

                // PUBLIC
                TestHelper.todo("isWebGLRenderTarget", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("setSize", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("clone", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.todo("copy", () => {

                    Assert.fail("everything's gonna be alright");

                });

                TestHelper.test("dispose", () => {

                    var object = new WebGLRenderTarget();
                    object.dispose();

                });

            });

        });

    }

}
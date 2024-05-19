package three.js.test.unit.src.renderers;

import three.js.renderers.WebGLRenderer;

class WebGLRendererTests {
    public function new() {}

    public static function main() {
        QUnit.module("Renderers", () => {
            QUnit.module("WebGLRenderer-webonly", () => {
                // INSTANCING
                QUnit.test("Instancing", (assert:QUnitAssert) => {
                    var renderer = new WebGLRenderer();
                    assert.ok(renderer, "Can instantiate a WebGLRenderer.");
                });

                // PROPERTIES
                QUnit.todo("domElement", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("debug", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("autoClear", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("autoClearColor", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("autoClearDepth", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("autoClearStencil", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("sortObjects", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("clippingPlanes", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("localClippingEnabled", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("outputColorSpace", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("toneMapping", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("toneMappingExposure", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.todo("isWebGLRenderer", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getContext", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getContextAttributes", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("forceContextLoss", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("forceContextRestore", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getPixelRatio", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setPixelRatio", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getSize", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setSize", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getDrawingBufferSize", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setDrawingBufferSize", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getCurrentViewport", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getViewport", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setViewport", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getScissor", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setScissor", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getScissorTest", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setScissorTest", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setOpaqueSort", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setTransparentSort", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getClearColor", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setClearColor", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getClearAlpha", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setClearAlpha", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("clear", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("clearColor", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("clearDepth", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("clearStencil", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.test("dispose", (assert:QUnitAssert) => {
                    assert.expect(0);
                    var object = new WebGLRenderer();
                    object.dispose();
                });

                QUnit.todo("renderBufferDirect", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("compile", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setAnimationLoop", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("render", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getActiveCubeFace", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getActiveMipmapLevel", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getRenderTarget", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getRenderTarget", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setRenderTargetTextures", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setRenderTargetFramebuffer", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setRenderTarget", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("readRenderTargetPixels", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("copyFramebufferToTexture", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("copyTextureToTexture", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("copyTextureToTexture3D", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("initTexture", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("resetState", (assert:QUnitAssert) => {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}
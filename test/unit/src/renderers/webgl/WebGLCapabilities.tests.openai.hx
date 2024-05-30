package three;

import utest.Assert;
import utest.Test;

class WebGLCapabilitiesTest {

    public static function __init__() {
        Test.createSuite("Renderers", [], () -> {
            Test.createSuite("WebGL", [], () -> {
                Test.createSuite("WebGLCapabilities", [], () -> {
                    // INSTANCING
                    Test.todo("Instancing", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    // PUBLIC STUFF
                    Test.todo("getMaxAnisotropy", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("getMaxPrecision", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("precision", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("logarithmicDepthBuffer", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("maxTextures", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("maxVertexTextures", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("maxTextureSize", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("maxCubemapSize", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("maxAttributes", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("maxVertexUniforms", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("maxVaryings", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("maxFragmentUniforms", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("vertexTextures", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("floatFragmentTextures", () -> {
                        Assert.fail("everything's gonna be alright");
                    });

                    Test.todo("floatVertexTextures", () -> {
                        Assert.fail("everything's gonna be alright");
                    });
                });
            });
        });
    }
}
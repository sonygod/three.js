package;

import qunit.QUnit;

class WebGLCapabilitiesTest {
    public static function main() {
        QUnit.module("Renderers", {
            beforeEach: function() {
                // Setup for each test
            },
            afterEach: function() {
                // Clean up after each test
            }
        });

        QUnit.module("WebGL", () => {
            QUnit.module("WebGLCapabilities", () => {
                // INSTANCING
                QUnit.todo("Instancing", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC STUFF
                QUnit.todo("getMaxAnisotropy", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getMaxPrecision", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("precision", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("logarithmicDepthBuffer", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("maxTextures", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("maxVertexTextures", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("maxTextureSize", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("maxCubemapSize", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("maxAttributes", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("maxVertexUniforms", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("maxVaryings", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("maxFragmentUniforms", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("vertexTextures", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("floatFragmentTextures", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("floatVertexTextures", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}
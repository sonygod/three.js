package;

import qunit.QUnit;

class WebGLIndexedBufferRendererTest {
    public static function main() {
        QUnit.module("Renderers", {
            beforeEach: function() {
                // ...
            },
            afterEach: function() {
                // ...
            }
        });

        QUnit.module("WebGL", function() {
            QUnit.module("WebGLIndexedBufferRenderer", function() {
                // INSTANCING
                QUnit.todo("Instancing", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC STUFF
                QUnit.todo("setMode", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setIndex", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("render", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("renderInstances", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}
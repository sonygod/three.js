package;

import js.QUnit;

class WebGLAttributesTest {
    static public function run() {
        QUnit.module("Renderers", {
            beforeEach: function() {},
            afterEach: function() {}
        });

        QUnit.module("WebGL", function() {
            QUnit.module("WebGLAttributes", function() {
                // INSTANCING
                QUnit.todo("Instancing", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC STUFF
                QUnit.todo("get", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("remove", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("update", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}
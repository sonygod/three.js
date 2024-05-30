package;

import js.QUnit;

class WebGLPropertiesTest {
    public static function main() {
        QUnit.module("Renderers", {
            beforeEach: function() {
                // ...
            },
            afterEach: function() {
                // ...
            }
        });

        QUnit.module("WebGL", () => {
            QUnit.module("WebGLProperties", () => {
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

                QUnit.todo("clear", function(assert) {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}
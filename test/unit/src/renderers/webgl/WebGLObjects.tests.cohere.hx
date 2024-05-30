package;

import js.QUnit;

class WebGLObjectsTest {
    static function test() {
        var module = QUnit.module("Renderers");
        var webGLModule = module.module("WebGL");

        webGLModule.module("WebGLObjects", function () {
            // INSTANCING
            @:toDo("Instancing")
            static function instancing(assert:QUnit.Assert) {
                assert.ok(false, "everything's gonna be alright");
            }

            // PUBLIC STUFF
            @:toDo("update")
            static function update(assert:QUnit.Assert) {
                assert.ok(false, "everything's gonna be alright");
            }

            @:toDo("clear")
            static function clear(assert:QUnit.Assert) {
                assert.ok(false, "everything's gonna be alright");
            }
        });
    }
}
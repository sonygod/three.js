package;

import js.QUnit.QUnit;

class TestExtras {
    public static function main() {
        var module = QUnit.module("Extras");

        module.module("PMREMGenerator");

        // INSTANCING
        module.todo("Instancing", fun(assert:Assert.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        module.todo("fromScene", fun(assert:Assert.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        module.todo("fromEquirectangular", fun(assert:Assert.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        module.todo("fromCubemap", fun(assert:Assert.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        module.todo("compileCubemapShader", fun(assert:Assert.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        module.todo("compileEquirectangularShader", fun(assert:Assert.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        module.todo("dispose", fun(assert:Assert.Assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}
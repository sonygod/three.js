package three.test.unit.src.renderers.webgl;

import three.renderers.webgl.WebGLExtensions;

class WebGLExtensionsTests {

    static function main() {
        QUnit.module("Renderers", () -> {
            QUnit.module("WebGL", () -> {
                QUnit.module("WebGLExtensions", () -> {

                    // INSTANCING
                    QUnit.test("Instancing", (assert:QUnitAssert) -> {
                        var gl = new WebglContextMock([]);
                        var extensions = new WebGLExtensions(gl);
                        assert.ok(Std.isOfType(extensions, WebGLExtensions));
                    });

                    QUnit.test("has", (assert:QUnitAssert) -> {
                        var gl = new WebglContextMock(['Extension1', 'Extension2']);
                        var extensions = new WebGLExtensions(gl);
                        assert.ok(extensions.has('Extension1'));
                        assert.ok(extensions.has('Extension2'));
                        assert.ok(extensions.has('Extension1'));
                        assert.notOk(extensions.has('NonExistingExtension'));
                    });

                    QUnit.test("has (with aliasses)", (assert:QUnitAssert) -> {
                        var gl = new WebglContextMock(['WEBKIT_WEBGL_depth_texture']);
                        var extensions = new WebGLExtensions(gl);
                        assert.ok(extensions.has('WEBGL_depth_texture'));
                        assert.ok(extensions.has('WEBKIT_WEBGL_depth_texture'));
                        assert.notOk(extensions.has('EXT_texture_filter_anisotropic'));
                        assert.notOk(extensions.has('NonExistingExtension'));
                    });

                    QUnit.test("get", (assert:QUnitAssert) -> {
                        var gl = new WebglContextMock(['Extension1', 'Extension2']);
                        var extensions = new WebGLExtensions(gl);
                        assert.ok(extensions.get('Extension1'));
                        assert.ok(extensions.get('Extension2'));
                        assert.ok(extensions.get('Extension1'));

                        // suppress the following console message when testing
                        Console.setLevel(CONSOLE_LEVEL.OFF);
                        assert.notOk(extensions.get('NonExistingExtension'));
                        Console.setLevel(CONSOLE_LEVEL.DEFAULT);
                    });

                    QUnit.test("get (with aliasses)", (assert:QUnitAssert) -> {
                        var gl = new WebglContextMock(['WEBKIT_WEBGL_depth_texture']);
                        var extensions = new WebGLExtensions(gl);
                        assert.ok(extensions.get('WEBGL_depth_texture'));
                        assert.ok(extensions.get('WEBKIT_WEBGL_depth_texture'));

                        // suppress the following console message when testing
                        Console.setLevel(CONSOLE_LEVEL.OFF);
                        assert.notOk(extensions.get('EXT_texture_filter_anisotropic'));
                        assert.notOk(extensions.get('NonExistingExtension'));
                        Console.setLevel(CONSOLE_LEVEL.DEFAULT);
                    });

                });
            });
        });
    }

}

class WebglContextMock {
    public var supportedExtensions:Array<String>;

    public function new(supportedExtensions:Array<String> = []) {
        this.supportedExtensions = supportedExtensions;
    }

    public function getExtension(name:String):Dynamic {
        if (supportedExtensions.indexOf(name) != -1) {
            return { name: name };
        } else {
            return null;
        }
    }
}

enum CONSOLE_LEVEL {
    OFF;
    DEFAULT;
}
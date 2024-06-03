import js.Browser.console;
import qunit.QUnit;
import three.renderers.webgl.WebGLExtensions;
import three.utils.ConsoleWrapper;

class WebglContextMock {
    public var supportedExtensions: Array<String>;

    public function new(supportedExtensions?: Array<String> = []) {
        this.supportedExtensions = supportedExtensions;
    }

    public function getExtension(name: String): Dynamic {
        if (this.supportedExtensions.indexOf(name) > -1) {
            return { 'name': name };
        } else {
            return null;
        }
    }
}

class WebGLExtensionsTests {
    public function new() {
        QUnit.module("Renderers", () -> {
            QUnit.module("WebGL", () -> {
                QUnit.module("WebGLExtensions", () -> {
                    QUnit.test("Instancing", (assert) -> {
                        var gl = new WebglContextMock();
                        var extensions = new WebGLExtensions(gl);
                        assert.ok(Std.is(extensions, Dynamic));
                    });

                    QUnit.test("has", (assert) -> {
                        var gl = new WebglContextMock(["Extension1", "Extension2"]);
                        var extensions = new WebGLExtensions(gl);
                        assert.ok(extensions.has("Extension1"));
                        assert.ok(extensions.has("Extension2"));
                        assert.ok(extensions.has("Extension1"));
                        assert.notOk(extensions.has("NonExistingExtension"));
                    });

                    QUnit.test("has (with aliasses)", (assert) -> {
                        var gl = new WebglContextMock(["WEBKIT_WEBGL_depth_texture"]);
                        var extensions = new WebGLExtensions(gl);
                        assert.ok(extensions.has("WEBGL_depth_texture"));
                        assert.ok(extensions.has("WEBKIT_WEBGL_depth_texture"));
                        assert.notOk(extensions.has("EXT_texture_filter_anisotropic"));
                        assert.notOk(extensions.has("NonExistingExtension"));
                    });

                    QUnit.test("get", (assert) -> {
                        var gl = new WebglContextMock(["Extension1", "Extension2"]);
                        var extensions = new WebGLExtensions(gl);
                        assert.ok(extensions.get("Extension1"));
                        assert.ok(extensions.get("Extension2"));
                        assert.ok(extensions.get("Extension1"));

                        console.level = ConsoleWrapper.CONSOLE_LEVEL.OFF;
                        assert.notOk(extensions.get("NonExistingExtension"));
                        console.level = ConsoleWrapper.CONSOLE_LEVEL.DEFAULT;
                    });

                    QUnit.test("get (with aliasses)", (assert) -> {
                        var gl = new WebglContextMock(["WEBKIT_WEBGL_depth_texture"]);
                        var extensions = new WebGLExtensions(gl);
                        assert.ok(extensions.get("WEBGL_depth_texture"));
                        assert.ok(extensions.get("WEBKIT_WEBGL_depth_texture"));

                        console.level = ConsoleWrapper.CONSOLE_LEVEL.OFF;
                        assert.notOk(extensions.get("EXT_texture_filter_anisotropic"));
                        assert.notOk(extensions.get("NonExistingExtension"));
                        console.level = ConsoleWrapper.CONSOLE_LEVEL.DEFAULT;
                    });
                });
            });
        });
    }
}
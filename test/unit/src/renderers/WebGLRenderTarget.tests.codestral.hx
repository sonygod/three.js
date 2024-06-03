import js.Browser.console;
import js.html.QUnit;

class EventDispatcher {
    function new() {}
}

class WebGLRenderTarget extends EventDispatcher {
    function new() {
        super();
    }
}

class WebGLRenderTargetTests {
    public static function main() {
        QUnit.module("Renderers", () -> {
            QUnit.module("WebGLRenderTarget", () -> {
                QUnit.test("Extending", () -> {
                    var object = new WebGLRenderTarget();
                    js.Boot.assertEquals(object is EventDispatcher, true, "WebGLRenderTarget extends from EventDispatcher");
                });

                QUnit.test("Instancing", () -> {
                    var object = new WebGLRenderTarget();
                    haxe.unit.Assert.isNotNull(object, "Can instantiate a WebGLRenderTarget.");
                });

                QUnit.test("dispose", () -> {
                    var object = new WebGLRenderTarget();
                    object.dispose();
                });
            });
        });
    }
}
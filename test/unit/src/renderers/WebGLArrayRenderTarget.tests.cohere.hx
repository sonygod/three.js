import js.QUnit;

import js.WebGLArrayRenderTarget from "../../../../src/renderers/WebGLArrayRenderTarget.js";

import js.WebGLRenderTarget from "../../../../src/renderers/WebGLRenderTarget.js";

class _Main {
    static function main() {
        var module = QUnit.module("Renderers", null);
        var module1 = module.module("WebGLArrayRenderTarget", null);
        var test = module1.test("Extending", function($assert) {
            var object = new WebGLArrayRenderTarget();
            $assert.strictEqual(Std.is(WebGLRenderTarget, object), true, "WebGLArrayRenderTarget extends from WebGLRenderTarget");
        });
        var test1 = module1.test("Instancing", function($assert) {
            var object = new WebGLArrayRenderTarget();
            $assert.ok(object != null, "Can instantiate a WebGLArrayRenderTarget.");
        });
        module1.todo("depth", null);
        module1.todo("texture", null);
        module1.todo("isWebGLArrayRenderTarget", null);
    }
}
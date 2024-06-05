import qunit.QUnit;
import three.renderers.WebGLArrayRenderTarget;
import three.renderers.WebGLRenderTarget;

class WebGLArrayRenderTargetTest {

	public static function main() {
		QUnit.module("Renderers", function() {
			QUnit.module("WebGLArrayRenderTarget", function() {

				// INHERITANCE
				QUnit.test("Extending", function(assert) {
					var object = new WebGLArrayRenderTarget();
					assert.strictEqual(object.is(WebGLRenderTarget), true, "WebGLArrayRenderTarget extends from WebGLRenderTarget");
				});

				// INSTANCING
				QUnit.test("Instancing", function(assert) {
					var object = new WebGLArrayRenderTarget();
					assert.ok(object, "Can instantiate a WebGLArrayRenderTarget.");
				});

				// PROPERTIES
				QUnit.todo("depth", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				QUnit.todo("texture", function(assert) {
					// must be DataArrayTexture
					assert.ok(false, "everything's gonna be alright");
				});

				// PUBLIC
				QUnit.todo("isWebGLArrayRenderTarget", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

			});
		});
	}
}

class WebGLRenderTarget {
	public function is(type:Dynamic):Bool {
		return this == type;
	}
}

class WebGLArrayRenderTarget extends WebGLRenderTarget {
}
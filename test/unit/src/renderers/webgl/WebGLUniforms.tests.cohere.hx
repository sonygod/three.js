package;

import js.QUnit;

class WebGLUniformsTest {
	public static function main() {
		QUnit.module("Renderers", {
			afterEach:function() {
				// ...
			}
		});

		QUnit.module("WebGL", function() {
			QUnit.module("WebGLUniforms", function() {
				// INSTANCING
				QUnit.todo("Instancing", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				// PUBLIC STUFF
				QUnit.todo("setValue", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				QUnit.todo("setOptional", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				QUnit.todo("upload", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				QUnit.todo("seqWithValue", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});
			});
		});
	}
}
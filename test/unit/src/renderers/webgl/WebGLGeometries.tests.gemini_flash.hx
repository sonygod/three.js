import qunit.QUnit;

class WebGLGeometriesTest {

	static function main() {
		QUnit.module("Renderers", function() {
			QUnit.module("WebGL", function() {
				QUnit.module("WebGLGeometries", function() {
					// INSTANCING
					QUnit.todo("Instancing", function(assert) {
						assert.ok(false, "everything's gonna be alright");
					});

					// PUBLIC STUFF
					QUnit.todo("get", function(assert) {
						assert.ok(false, "everything's gonna be alright");
					});

					QUnit.todo("update", function(assert) {
						assert.ok(false, "everything's gonna be alright");
					});

					QUnit.todo("getWireframeAttribute", function(assert) {
						assert.ok(false, "everything's gonna be alright");
					});
				});
			});
		});
	}
}

class WebGLGeometries {
	// ... (Implementation of WebGLGeometries)
}

class Main {
	static function main() {
		WebGLGeometriesTest.main();
	}
}
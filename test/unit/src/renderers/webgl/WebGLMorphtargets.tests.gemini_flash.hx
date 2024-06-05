import qunit.QUnit;

class WebGLMorphtargetsTest {

	static function main() {
		QUnit.module("Renderers", function() {
			QUnit.module("WebGL", function() {
				QUnit.module("WebGLMorphtargets", function() {
					// INSTANCING
					QUnit.todo("Instancing", function(assert) {
						assert.ok(false, "everything's gonna be alright");
					});

					// PUBLIC STUFF
					QUnit.todo("update", function(assert) {
						assert.ok(false, "everything's gonna be alright");
					});
				});
			});
		});
	}
}

class qunit {
	static function module(name:String, callback:() -> Void) {
		// Implement the module function here
		// You may need to adapt this depending on how you want to implement QUnit in Haxe
		trace("Module: " + name);
		callback();
	}

	static function todo(name:String, callback:() -> Void) {
		// Implement the todo function here
		// You may need to adapt this depending on how you want to implement QUnit in Haxe
		trace("Todo: " + name);
		callback();
	}
}

class assert {
	static function ok(value:Bool, message:String) {
		// Implement the ok function here
		// You may need to adapt this depending on how you want to implement QUnit in Haxe
		trace("Assert: " + message);
	}
}

WebGLMorphtargetsTest.main();
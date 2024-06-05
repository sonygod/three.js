import qunit.QUnit;

class WebGLUtilsTest extends qunit.QUnit {

	static function main() {
		new WebGLUtilsTest().run();
	}

	public function new() {
		super("Renderers");
		this.addModule("WebGL", function() {
			this.addModule("WebGLUtils", function() {
				// INSTANCING
				this.todo("Instancing", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});

				// PUBLIC STUFF
				this.todo("convert", function(assert) {
					assert.ok(false, "everything's gonna be alright");
				});
			});
		});
	}
}

class qunit.QUnit {
	public var name:String;
	public var modules:Array<qunit.QUnit>;

	public function new(name:String) {
		this.name = name;
		this.modules = [];
	}

	public function run() {
		trace("Running tests for: " + this.name);
		for (m in this.modules) {
			m.run();
		}
	}

	public function addModule(name:String, callback:Void->Void) {
		this.modules.push(new qunit.QUnit(name, callback));
	}

	public function todo(name:String, callback:qunit.Assert->Void) {
		trace("TODO: " + name);
	}
}

class qunit.Assert {
	public function ok(value:Bool, message:String):Void {
		trace("Asserting: " + message);
	}
}

WebGLUtilsTest.main();
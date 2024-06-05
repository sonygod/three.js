import qunit.QUnit;
import three.textures.FramebufferTexture;
import three.textures.Texture;

class TexturesTest extends QUnit {

	static function main() {
		new TexturesTest().run();
	}

	public function new() {
		super();

		module("Textures", () -> {
			module("FramebufferTexture", () -> {
				test("Extending", (assert) -> {
					var object = new FramebufferTexture();
					assert.ok(cast(Texture, object) != null, "FramebufferTexture extends from Texture");
				});

				test("Instancing", (assert) -> {
					var object = new FramebufferTexture();
					assert.ok(object != null, "Can instantiate a FramebufferTexture.");
				});

				todo("format", (assert) -> {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("magFilter", (assert) -> {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("minFilter", (assert) -> {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("generateMipmaps", (assert) -> {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("needsUpdate", (assert) -> {
					assert.ok(false, "everything's gonna be alright");
				});

				test("isFramebufferTexture", (assert) -> {
					var object = new FramebufferTexture();
					assert.ok(object.isFramebufferTexture, "FramebufferTexture.isFramebufferTexture should be true");
				});
			});
		});
	}
}

class TexturesTest {
	public function run() {
		QUnit.run(this);
	}
}

class QUnit {
	static public function module(name:String, callback:Void->Void) {
	}

	static public function test(name:String, callback:QUnitAssert->Void) {
	}

	static public function todo(name:String, callback:QUnitAssert->Void) {
	}

	static public function run(test:QUnit) {
		test.init();
		test.start();
		test.finish();
	}

	public function init() {
	}

	public function start() {
	}

	public function finish() {
	}
}

class QUnitAssert {
	public function ok(value:Bool, message:String) {
	}

	public function strictEqual(a:Dynamic, b:Dynamic, message:String) {
	}
}

class Texture {
	public var isFramebufferTexture:Bool;
}
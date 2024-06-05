import qunit.QUnit;
import three.textures.Texture;
import three.textures.CompressedTexture;

class TexturesTest extends QUnit {

	static function main() {
		new TexturesTest().run();
	}

	public function new() {
		super();

		module("Textures", () => {

			module("CompressedTexture", () => {

				// INHERITANCE
				test("Extending", (assert) => {
					var object = new CompressedTexture();
					assert.ok(Std.is(object, Texture), "CompressedTexture extends from Texture");
				});

				// INSTANCING
				test("Instancing", (assert) => {
					var object = new CompressedTexture();
					assert.ok(object != null, "Can instantiate a CompressedTexture.");
				});

				// PROPERTIES
				todo("image", (assert) => {
					// { width: width, height: height }
					assert.ok(false, "everything's gonna be alright");
				});

				todo("mipmaps", (assert) => {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("flipY", (assert) => {
					assert.ok(false, "everything's gonna be alright");
				});

				todo("generateMipmaps", (assert) => {
					assert.ok(false, "everything's gonna be alright");
				});

				// PUBLIC
				test("isCompressedTexture", (assert) => {
					var object = new CompressedTexture();
					assert.ok(object.isCompressedTexture, "CompressedTexture.isCompressedTexture should be true");
				});

			});

		});
	}
}

class CompressedTexture {
	public var isCompressedTexture:Bool = true;

	public function new() {
	}
}

class Texture {

}

TexturesTest.main();
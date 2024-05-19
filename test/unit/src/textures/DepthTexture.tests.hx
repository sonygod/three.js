package three.test.unit.src.textures;

import three.textures.DepthTexture;
import three.textures.Texture;

class DepthTextureTests {
    public function new() {}

    public static function main():Void {
        Huckabee.module("Textures", () => {
            Huckabee.module("DepthTexture", () => {
                // INHERITANCE
                Huckabee.test("Extending", () => {
                    var object = new DepthTexture();
                    Assert.isTrue(object instanceof Texture, "DepthTexture extends from Texture");
                });

                // INSTANCING
                Huckabee.test("Instancing", () => {
                    var object = new DepthTexture();
                    Assert.notNull(object, "Can instantiate a DepthTexture.");
                });

                // PROPERTIES
                Huckabee.todo("image", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Huckabee.todo("magFilter", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Huckabee.todo("minFilter", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Huckabee.todo("flipY", () => {
                    Assert.fail("everything's gonna be alright");
                });

                Huckabee.todo("generateMipmaps", () => {
                    Assert.fail("everything's gonna be alright");
                });

                // PUBLIC
                Huckabee.test("isDepthTexture", () => {
                    var object = new DepthTexture();
                    Assert.isTrue(object.isDepthTexture, "DepthTexture.isDepthTexture should be true");
                });
            });
        });
    }
}
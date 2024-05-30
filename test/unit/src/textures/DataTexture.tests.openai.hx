import UTcases;
import three.textures.DataTexture;
import three.textures.Texture;

class DataTextureTests {
    public static function main() {
        UTcases.module("Textures", () -> {
            UTcases.module("DataTexture", () -> {
                // INHERITANCE
                UTcases.test("Extending", () -> {
                    var object = new DataTexture();
                    UTcases.assert(object instanceof Texture, "DataTexture extends from Texture");
                });

                // INSTANCING
                UTcases.test("Instancing", () -> {
                    var object = new DataTexture();
                    UTcases.ok(object != null, "Can instantiate a DataTexture.");
                });

                // PROPERTIES
                UTcases.todo("image", () -> {
                    UTcases.ok(false, "everything's gonna be alright");
                });

                UTcases.todo("generateMipmaps", () -> {
                    UTcases.ok(false, "everything's gonna be alright");
                });

                UTcases.todo("flipY", () -> {
                    UTcases.ok(false, "everything's gonna be alright");
                });

                UTcases.todo("unpackAlignment", () -> {
                    UTcases.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                UTcases.test("isDataTexture", () -> {
                    var object = new DataTexture();
                    UTcases.ok(object.isDataTexture, "DataTexture.isDataTexture should be true");
                });
            });
        });
    }
}
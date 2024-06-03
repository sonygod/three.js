import qunit.QUnit;
import three.textures.VideoTexture;
import three.textures.Texture;

class VideoTextureTests {

    public static function main() {

        QUnit.module("Textures", () -> {

            QUnit.module("VideoTexture", () -> {

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {

                    var videoDocumentElement = {};
                    var object = new VideoTexture(videoDocumentElement);
                    assert.strictEqual(
                        Std.is(object, Texture), true,
                        'VideoTexture extends from Texture'
                    );

                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {

                    var videoDocumentElement = {};
                    var object = new VideoTexture(videoDocumentElement);
                    assert.ok(object != null, 'Can instantiate a VideoTexture.');

                });

                // PROPERTIES
                QUnit.todo("minFilter", (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo("magFilter", (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo("generateMipmaps", (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                // PUBLIC STUFF
                QUnit.test("isVideoTexture", (assert) -> {

                    var videoDocumentElement = {};
                    var object = new VideoTexture(videoDocumentElement);
                    assert.ok(
                        object.isVideoTexture,
                        'VideoTexture.isVideoTexture should be true'
                    );

                });

                QUnit.todo("clone", (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

                QUnit.todo("update", (assert) -> {

                    assert.ok(false, 'everything\'s gonna be alright');

                });

            });

        });

    }

}
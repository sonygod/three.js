import qunit.QUnit;
import three.textures.Texture;
import three.textures.VideoTexture;

class TexturesTest extends qunit.QUnit {

    public function new() {
        super();
        module("Textures", () => {
            module("VideoTexture", () => {
                test("Extending", (assert) => {
                    var videoDocumentElement:Dynamic = {};
                    var object = new VideoTexture(videoDocumentElement);
                    assert.strictEqual(object.is(Texture), true, "VideoTexture extends from Texture");
                });

                test("Instancing", (assert) => {
                    var videoDocumentElement:Dynamic = {};
                    var object = new VideoTexture(videoDocumentElement);
                    assert.ok(object, "Can instantiate a VideoTexture.");
                });

                test("isVideoTexture", (assert) => {
                    var videoDocumentElement:Dynamic = {};
                    var object = new VideoTexture(videoDocumentElement);
                    assert.ok(object.isVideoTexture, "VideoTexture.isVideoTexture should be true");
                });
            });
        });
    }
}

var test = new TexturesTest();
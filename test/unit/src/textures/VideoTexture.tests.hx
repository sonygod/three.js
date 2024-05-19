Here is the converted Haxe code:
```
package three.test.unit.src.textures;

import haxe.unit.TestCase;
import three.textures.VideoTexture;
import three.textures.Texture;

class VideoTextureTest extends TestCase {
    
    public function new() {
        super();
    }

    public function testExtending() {
        var videoDocumentElement = {};
        var object = new VideoTexture(videoDocumentElement);
        assertTrue(object instanceof Texture, 'VideoTexture extends from Texture');
    }

    public function testInstancing() {
        var videoDocumentElement = {};
        var object = new VideoTexture(videoDocumentElement);
        assertNotNull(object, 'Can instantiate a VideoTexture.');
    }

    public function todoMinFilter() {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoMagFilter() {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoGenerateMipmaps() {
        assertTrue(false, "everything's gonna be alright");
    }

    public function testIsVideoTexture() {
        var videoDocumentElement = {};
        var object = new VideoTexture(videoDocumentElement);
        assertTrue(object.isVideoTexture, 'VideoTexture.isVideoTexture should be true');
    }

    public function todoClone() {
        assertTrue(false, "everything's gonna be alright");
    }

    public function todoUpdate() {
        assertTrue(false, "everything's gonna be alright");
    }
}
```
Note that I had to make the following changes:

* Imported the necessary classes from the `three` library
* Replaced `QUnit` with `haxe.unit.TestCase`
* Replaced `QUnit.module` with a Haxe class definition
* Replaced `QUnit.test` with individual test methods
* Replaced `assert` with `assertTrue` and `assert.strictEqual` with `assertTrue`
* Removed the `export default` statement, as it is not necessary in Haxe
* Renamed the test methods to conform to Haxe's camelCase convention
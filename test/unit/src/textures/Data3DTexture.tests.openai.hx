import haxe.unit.TestCase;
import three.textures.Data3DTexture;
import three.textures.Texture;

class Data3DTextureTests {
    public function new() {}

    public function testInheritance() {
        var object = new Data3DTexture();
        Assert.isTrue(object instanceof Texture, 'Data3DTexture extends from Texture');
    }

    public function testInstancing() {
        var object = new Data3DTexture();
        Assert.isNotNull(object, 'Can instantiate a Data3DTexture.');
    }

    public function todoImage() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todoMagFilter() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todoMinFilter() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todoWrapR() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todoGenerateMipmaps() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todoFlipY() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todoUnpackAlignment() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testIsData3DTexture() {
        var object = new Data3DTexture();
        Assert.isTrue(object.isData3DTexture, 'Data3DTexture.isData3DTexture should be true');
    }
}
package three.test.unit.src.textures;

import three.textures.DataArrayTexture;
import three.textures.Texture;
import utest.Assert;
import utest.Test;

@:testCase(order = 1)
class DataArrayTextureTest {
    @:test(order = 1)
    public function testExtending() {
        var object = new DataArrayTexture();
        Assert.isTrue(object instanceof Texture, 'DataArrayTexture extends from Texture');
    }

    @:test(order = 2)
    public function testInstancing() {
        var object = new DataArrayTexture();
        Assert.notNull(object, 'Can instantiate a DataArrayTexture.');
    }

    @:test(order = 3)
    public function testImage() {
        // TODO: implement me
        Assert.fail('not implemented');
    }

    @:test(order = 4)
    public function testMagFilter() {
        // TODO: implement me
        Assert.fail('not implemented');
    }

    @:test(order = 5)
    public function testMinFilter() {
        // TODO: implement me
        Assert.fail('not implemented');
    }

    @:test(order = 6)
    public function testWrapR() {
        // TODO: implement me
        Assert.fail('not implemented');
    }

    @:test(order = 7)
    public function testGenerateMipmaps() {
        // TODO: implement me
        Assert.fail('not implemented');
    }

    @:test(order = 8)
    public function testFlipY() {
        // TODO: implement me
        Assert.fail('not implemented');
    }

    @:test(order = 9)
    public function testUnpackAlignment() {
        // TODO: implement me
        Assert.fail('not implemented');
    }

    @:test(order = 10)
    public function testIsDataArrayTexture() {
        var object = new DataArrayTexture();
        Assert.isTrue(object.isDataArrayTexture, 'DataArrayTexture.isDataArrayTexture should be true');
    }
}
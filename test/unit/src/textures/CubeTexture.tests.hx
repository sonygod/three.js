package three.test.unit.src.textures;

import three.textures.CubeTexture;
import three.textures.Texture;

class CubeTextureTests {
    public function new() {}

    public function testExtending():Void {
        var object:CubeTexture = new CubeTexture();
        Assert.isTrue(object instanceof Texture, 'CubeTexture extends from Texture');
    }

    public function testInstancing():Void {
        var object:CubeTexture = new CubeTexture();
        Assert.notNull(object, 'Can instantiate a CubeTexture.');
    }

    public function todoImages():Void {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todoFlipY():Void {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testIsCubeTexture():Void {
        var object:CubeTexture = new CubeTexture();
        Assert.isTrue(object.isCubeTexture, 'CubeTexture.isCubeTexture should be true');
    }
}
package three.tests.unit.textures;

import three.textures.CubeTexture;
import three.textures.Texture;

class CubeTextureTests {
  public function new() {}

  public function testExtending() {
    var object = new CubeTexture();
    var assert = new Assert();
    assert.isTrue(object instanceof Texture, 'CubeTexture extends from Texture');
  }

  public function testInstancing() {
    var object = new CubeTexture();
    var assert = new Assert();
    assert.notNull(object, 'Can instantiate a CubeTexture.');
  }

  public function todoImages() {
    var assert = new Assert();
    assert.fail('everything\'s gonna be alright');
  }

  public function todoFlipY() {
    var assert = new Assert();
    assert.fail('everything\'s gonna be alright');
  }

  public function testIsCubeTexture() {
    var object = new CubeTexture();
    var assert = new Assert();
    assert.isTrue(object.isCubeTexture, 'CubeTexture.isCubeTexture should be true');
  }
}
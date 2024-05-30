package three.test.unit.src.renderers;

import three.renderers.WebGLCubeRenderTarget;
import three.renderers.WebGLRenderTarget;
import utest Assert;
import utest.Test;

class WebGLCubeRenderTargetTests {
  public function new() {}

  @Test
  public function testExtending() {
    var object = new WebGLCubeRenderTarget();
    Assert.isTrue(Std.is(object, WebGLRenderTarget), 'WebGLCubeRenderTarget extends from WebGLRenderTarget');
  }

  @Test
  public function testInstancing() {
    var object = new WebGLCubeRenderTarget();
    Assert.notNull(object, 'Can instantiate a WebGLCubeRenderTarget.');
  }

  @Test
  public function testTexture() {
    // doc update needed, this needs to be a CubeTexture unlike parent class
    Assert.fail('everything\'s gonna be alright');
  }

  @Test
  public function testIsWebGLCubeRenderTarget() {
    Assert.fail('everything\'s gonna be alright');
  }

  @Test
  public function testFromEquirectangularTexture() {
    Assert.fail('everything\'s gonna be alright');
  }

  @Test
  public function testClear() {
    Assert.fail('everything\'s gonna be alright');
  }
}
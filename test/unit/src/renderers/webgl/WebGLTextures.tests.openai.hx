package three.test.unit.src.renderers.webgl;

import utest.Test;
import utest.Assert;
import three.renderers.webgl.WebGLTextures;

class WebGLTexturesTest {
  public function new() {}

  @Test public function testWebGLTextures() {
    Test.createSuite("WebGLTextures", () => {
      // INSTANCING
      Test.todo("Instancing", () => {
        Assert.isTrue(false, "everything's gonna be alright");
      });

      // PUBLIC STUFF
      Test.todo("setTexture2D", () => {
        Assert.isTrue(false, "everything's gonna be alright");
      });
      Test.todo("setTextureCube", () => {
        Assert.isTrue(false, "everything's gonna be alright");
      });
      Test.todo("setTextureCubeDynamic", () => {
        Assert.isTrue(false, "everything's gonna be alright");
      });
      Test.todo("setupRenderTarget", () => {
        Assert.isTrue(false, "everything's gonna be alright");
      });
      Test.todo("updateRenderTargetMipmap", () => {
        Assert.isTrue(false, "everything's gonna be alright");
      });
    });
  }
}
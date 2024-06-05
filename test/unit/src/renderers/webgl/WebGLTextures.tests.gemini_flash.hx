import haxe.unit.Assert;

class WebGLTextures {
  // ... (implement the methods you need here)
}

class Renderers {
  static function main() {
    Assert.module("Renderers", function() {
      Assert.module("WebGL", function() {
        Assert.module("WebGLTextures", function() {
          // INSTANCING
          Assert.todo("Instancing", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });

          // PUBLIC STUFF
          Assert.todo("setTexture2D", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });
          Assert.todo("setTextureCube", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });
          Assert.todo("setTextureCubeDynamic", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });
          Assert.todo("setupRenderTarget", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });
          Assert.todo("updateRenderTargetMipmap", function(assert) {
            assert.ok(false, "everything's gonna be alright");
          });
        });
      });
    });
  }
}

class Main {
  static function main() {
    Renderers.main();
  }
}
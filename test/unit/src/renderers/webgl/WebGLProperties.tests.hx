package three.js.test.unit.src.renderers.webgl;

import utest.Assert;
import utest.Test;

class WebGLPropertiesTests {
  public function new() {}

  public function testRenderers() {
    Test.create("Renderers", () => {
      Test.create("WebGL", () => {
        Test.create("WebGLProperties", () => {
          // INSTANCING
          Test.todo("Instancing", () => {
            Assert.isTrue(false, "everything's gonna be alright");
          });

          // PUBLIC STUFF
          Test.todo("get", () => {
            Assert.isTrue(false, "everything's gonna be alright");
          });

          Test.todo("remove", () => {
            Assert.isTrue(false, "everything's gonna be alright");
          });

          Test.todo("clear", () => {
            Assert.isTrue(false, "everything's gonna be alright");
          });
        });
      });
    });
  }

  static public function main() {
    var test = new WebGLPropertiesTests();
    test.testRenderers();
  }
}
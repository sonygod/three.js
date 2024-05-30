package three.test.unit.src.loaders;

import three.loaders.TextureLoader;
import three.loaders.Loader;

class TextureLoaderTests {
  public static function main() {
    Tester.module("Loaders", () => {
      Tester.module("TextureLoader", () => {
        // INHERITANCE
        Tester.test("Extending", () => {
          var object = new TextureLoader();
          Tester.assert(object instanceof Loader, "TextureLoader extends from Loader");
        });

        // INSTANCING
        Tester.test("Instancing", () => {
          var object = new TextureLoader();
          Tester.ok(object != null, "Can instantiate a TextureLoader.");
        });

        // PUBLIC
        Tester.todo("load", () => {
          Tester.fail("everything's gonna be alright");
        });
      });
    });
  }
}
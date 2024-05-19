package three.test.unit.src.textures;

import three.textures.Source;
import utest.Assert;
import utest.Test;

class SourceTests {
  public function new() {}

  public static function main() {
    var test = new Test();
    test.describe("Textures", () => {
      test.describe("Source", () => {
        // INSTANCING
        test.test("Instancing", () => {
          var object:Source = new Source();
          Assert.isTrue(object != null, "Can instantiate a Source.");
        });

        // PROPERTIES
        test.test("data", () => {
          Assert.fail("everything's gonna be alright");
        });

        test.test("needsUpdate", () => {
          Assert.fail("everything's gonna be alright");
        });

        test.test("uuid", () => {
          Assert.fail("everything's gonna be alright");
        });

        test.test("version", () => {
          Assert.fail("everything's gonna be alright");
        });

        // PUBLIC
        test.test("isSource", () => {
          var object:Source = new Source();
          Assert.isTrue(object.isSource, "Source.isSource should be true");
        });

        test.test("toJSON", () => {
          Assert.fail("everything's gonna be alright");
        });
      });
    });
  }
}
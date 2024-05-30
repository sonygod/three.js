package three.js.test.unit.src.extras.core;

import three.js.extras.core.Shape;
import three.js.extras.core.Path;

class ShapeTest {
  public static function main() {
    Suite.run(new ShapeTest());
  }

  public function testInheritance():Void {
    var object = new Shape();
    Assert.isTrue(Std.is(object, Path), "Shape extends from Path");
  }

  public function testInstancing():Void {
    var object = new Shape();
    Assert.notNull(object, "Can instantiate a Shape.");
  }

  public function testType():Void {
    var object = new Shape();
    Assert.areEqual(object.type, "Shape", "Shape.type should be Shape");
  }

  public function testUuid():Void {
    Assert.fail("Todo: implement uuid test");
  }

  public function testHoles():Void {
    Assert.fail("Todo: implement holes test");
  }

  public function testGetPointsHoles():Void {
    Assert.fail("Todo: implement getPointsHoles test");
  }

  public function testExtractPoints():Void {
    Assert.fail("Todo: implement extractPoints test");
  }

  public function testCopy():Void {
    Assert.fail("Todo: implement copy test");
  }

  public function testToJSON():Void {
    Assert.fail("Todo: implement toJSON test");
  }

  public function testFromJSON():Void {
    Assert.fail("Todo: implement fromJSON test");
  }
}
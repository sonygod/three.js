Here is the equivalent Haxe code:
```
import haxe.unit.TestRunner;
import haxe.unit.TestCase;

class CurveTests {
  public static function main() {
    var runner = new TestRunner();
    runner.add(new CurveTests());
    runner.run();
  }

  public function new() {}

  public function testInstancing() {
    var object = new Curve();
    assertTrue(object != null, 'Can instantiate a Curve.');
  }

  public function testType() {
    var object = new Curve();
    assertEquals(object.type, 'Curve', 'Curve.type should be Curve');
  }

  public function todoArcLengthDivisions() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoGetPoint() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoGetPointAt() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoGetPoints() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoGetSpacedPoints() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoGetLength() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoGetLengths() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoUpdateArcLengths() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoGetUtoTmapping() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoGetTangent() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoGetTangentAt() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoComputeFrenetFrames() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoClone() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoCopy() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoToJSON() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoFromJSON() {
    assertTrue(false, 'everything\'s gonna be alright');
  }
}
```
Note that in Haxe, we use the `haxe.unit` package for testing, which is similar to QUnit in JavaScript. We define a `CurveTests` class that extends `TestCase`, and implement each test method as a separate function.
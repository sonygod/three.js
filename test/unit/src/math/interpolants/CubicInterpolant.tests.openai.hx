import haxe.unit.TestCase;

class CubicInterpolantTests {
  public function new() { }

  public function testExtending() {
    var object = new CubicInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
    assertEquals(Type.typeof(object) == Interpolant, true, 'CubicInterpolant extends from Interpolant');
  }

  public function testInstancing() {
    var object = new CubicInterpolant(null, [1, 11, 2, 22, 3, 33], 2, []);
    assertTrue(object != null, 'Can instantiate a CubicInterpolant.');
  }

  // Todo: implement these tests
  public function testIntervalChanged() {
    assertTrue(false, 'Not implemented yet');
  }

  public function testInterpolate() {
    assertTrue(false, 'Not implemented yet');
  }

  public static function main() {
    var testCase = new CubicInterpolantTests();
    testCase.testExtending();
    testCase.testInstancing();
    testCase.testIntervalChanged();
    testCase.testInterpolate();
  }
}
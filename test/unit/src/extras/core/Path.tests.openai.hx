package three.extras.core;

import three.Path;
import three.CurvePath;
import utest.Assert;

class PathTests {
  public function new() {}

  public function test_Extending() {
    var object = new Path();
    Assert.isTrue(Std.is(object, CurvePath), 'Path extends from CurvePath');
  }

  public function test_Instancing() {
    var object = new Path();
    Assert.notNull(object, 'Can instantiate a Path.');
  }

  public function test_Type() {
    var object = new Path();
    Assert.equals(object.type, 'Path', 'Path.type should be Path');
  }

  // TODO: implement tests for these methods
  public function test_SetFromPoints() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_MoveTo() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_LineTo() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_QuadraticCurveTo() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_BezierCurveTo() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_SplineThru() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_Arc() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_Absarc() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_Ellipse() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_Absellipse() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_Copy() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_ToJSON() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function test_FromJSON() {
    Assert.fail('everything\'s gonna be alright');
  }
}
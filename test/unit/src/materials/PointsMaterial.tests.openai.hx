package three material tests;

import three.materials.PointsMaterial;
import three.materials.Material;

class PointsMaterialTests {
  public function new() {}

  public function testExtending() {
    var object = new PointsMaterial();
    Assert.isTrue(Std.is(object, Material), 'PointsMaterial extends from Material');
  }

  public function testInstancing() {
    var object = new PointsMaterial();
    Assert.isTrue(object != null, 'Can instantiate a PointsMaterial.');
  }

  public function testType() {
    var object = new PointsMaterial();
    Assert.isTrue(object.type == 'PointsMaterial', 'PointsMaterial.type should be PointsMaterial');
  }

  public function testTodoColor() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function testTodoMap() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function testTodoAlphaMap() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function testTodoSize() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function testTodoSizeAttenuation() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function testTodoFog() {
    Assert.fail('everything\'s gonna be alright');
  }

  public function testIsPointsMaterial() {
    var object = new PointsMaterial();
    Assert.isTrue(object.isPointsMaterial, 'PointsMaterial.isPointsMaterial should be true');
  }

  public function testTodoCopy() {
    Assert.fail('everything\'s gonna be alright');
  }
}
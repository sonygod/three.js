package three.test.unit.src.materials;

import three.materials.LineDashedMaterial;
import three.materials.Material;

class LineDashedMaterialTests {

  public function new() {}

  public function testAll() {
    // INHERITANCE
    utest.Assert.isTrue(Std.is(new LineDashedMaterial(), Material), 'LineDashedMaterial extends from Material');

    // INSTANCING
    utest.Assert.notNull(new LineDashedMaterial(), 'Can instantiate a LineDashedMaterial.');

    // PROPERTIES
    var object = new LineDashedMaterial();
    utest.Assert.equals(object.type, 'LineDashedMaterial', 'LineDashedMaterial.type should be LineDashedMaterial');

    // TODO: implement these tests
    // utest.Fail("scale");
    // utest.Fail("dashSize");
    // utest.Fail("gapSize");

    // PUBLIC
    utest.Assert.isTrue(object.isLineDashedMaterial, 'LineDashedMaterial.isLineDashedMaterial should be true');

    // TODO: implement this test
    // utest.Fail("copy");
  }
}
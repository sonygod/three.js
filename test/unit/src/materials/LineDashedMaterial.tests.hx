Here is the converted Haxe code:
```
package three.test.unit.src.materials;

import haxe.unit.TestCase;
import three.materials.LineDashedMaterial;
import three.materials.Material;

class LineDashedMaterialTest {
    public function new() {}

    public function testExtending():Void {
        var object:LineDashedMaterial = new LineDashedMaterial();
        TestCase.assertTrue(object instanceof Material, 'LineDashedMaterial extends from Material');
    }

    public function testInstancing():Void {
        var object:LineDashedMaterial = new LineDashedMaterial();
        TestCase.assertNotNull(object, 'Can instantiate a LineDashedMaterial.');
    }

    public function testType():Void {
        var object:LineDashedMaterial = new LineDashedMaterial();
        TestCase.assertEquals(object.type, 'LineDashedMaterial', 'LineDashedMaterial.type should be LineDashedMaterial');
    }

    public function testScale():Void {
        // TODO: implement test
        TestCase.fail('everything\'s gonna be alright');
    }

    public function testDashSize():Void {
        // TODO: implement test
        TestCase.fail('everything\'s gonna be alright');
    }

    public function testGapSize():Void {
        // TODO: implement test
        TestCase.fail('everything\'s gonna be alright');
    }

    public function testIsLineDashedMaterial():Void {
        var object:LineDashedMaterial = new LineDashedMaterial();
        TestCase.assertTrue(object.isLineDashedMaterial, 'LineDashedMaterial.isLineDashedMaterial should be true');
    }

    public function testCopy():Void {
        // TODO: implement test
        TestCase.fail('everything\'s gonna be alright');
    }
}
```
Note that I've used the `haxe.unit` package for testing, which is similar to QUnit. I've also renamed the test module to `LineDashedMaterialTest` to follow Haxe convention. Additionally, I've replaced `QUnit.module` with a simple Haxe class, and `QUnit.test` with individual test methods.
import three.materials.LineDashedMaterial;
import three.materials.Material;
import haxe.unit.TestCase;

class LineDashedMaterialTests extends TestCase {

    public function new() {
        super("LineDashedMaterialTests");
    }

    @:test public function testExtending():Void {
        var object:LineDashedMaterial = new LineDashedMaterial();
        assertTrue(Std.is(object, Material), "LineDashedMaterial extends from Material");
    }

    @:test public function testInstancing():Void {
        var object:LineDashedMaterial = new LineDashedMaterial();
        assertIsNotNull(object, "Can instantiate a LineDashedMaterial.");
    }

    @:test public function testType():Void {
        var object:LineDashedMaterial = new LineDashedMaterial();
        assertEquals(object.type, "LineDashedMaterial", "LineDashedMaterial.type should be LineDashedMaterial");
    }

    @:todo public function testScale():Void {
        assertFalse(true, "everything's gonna be alright");
    }

    @:todo public function testDashSize():Void {
        assertFalse(true, "everything's gonna be alright");
    }

    @:todo public function testGapSize():Void {
        assertFalse(true, "everything's gonna be alright");
    }

    @:test public function testIsLineDashedMaterial():Void {
        var object:LineDashedMaterial = new LineDashedMaterial();
        assertTrue(object.isLineDashedMaterial, "LineDashedMaterial.isLineDashedMaterial should be true");
    }

    @:todo public function testCopy():Void {
        assertFalse(true, "everything's gonna be alright");
    }
}
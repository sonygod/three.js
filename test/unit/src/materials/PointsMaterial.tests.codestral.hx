package tests.unit.materials;

import three.src.materials.Material;
import three.src.materials.PointsMaterial;
import haxe.unit.TestRunner;
import haxe.unit.TestStatus;
import haxe.unit.Assert;

class PointsMaterialTests {

    public function new() {}

    @:test("Materials.PointsMaterial.Extending")
    public function testExtending(runner: TestRunner): Void {
        var object = new PointsMaterial();
        Assert.isTrue(Std.is(object, Material), "PointsMaterial extends from Material");
    }

    @:test("Materials.PointsMaterial.Instancing")
    public function testInstancing(runner: TestRunner): Void {
        var object = new PointsMaterial();
        Assert.notNull(object, "Can instantiate a PointsMaterial.");
    }

    @:test("Materials.PointsMaterial.type")
    public function testType(runner: TestRunner): Void {
        var object = new PointsMaterial();
        Assert.equals(object.type, "PointsMaterial", "PointsMaterial.type should be PointsMaterial");
    }

    @:test("Materials.PointsMaterial.isPointsMaterial")
    public function testIsPointsMaterial(runner: TestRunner): Void {
        var object = new PointsMaterial();
        Assert.isTrue(object.isPointsMaterial, "PointsMaterial.isPointsMaterial should be true");
    }
}
import haxe.unit.TestCase;
import haxe.unit.TestContext;

import js.Three.Material;
import js.Three.MeshPhongMaterial;

class TestMeshPhongMaterial extends TestCase {
    function new() {
        super();
    }

    override public function testExtending(ctx: TestContext) {
        var object = new MeshPhongMaterial();
        ctx.assertTrue(Std.is(object, Material));
    }

    override public function testInstancing(ctx: TestContext) {
        var object = new MeshPhongMaterial();
        ctx.assertTrue(object != null);
    }

    override public function testType(ctx: TestContext) {
        var object = new MeshPhongMaterial();
        ctx.assertEquals(object.getType(), "MeshPhongMaterial");
    }

    override public function testIsMeshPhongMaterial(ctx: TestContext) {
        var object = new MeshPhongMaterial();
        ctx.assertTrue(object.isMeshPhongMaterial());
    }
}
import haxe.unit.TestCase;
import haxe.unit.TestContext;

class TestMeshNormalMaterial extends TestCase {
    function new() {
        super();
    }

    override function setUp(ctx: TestContext) {
        // Set up necessary resources for the tests
    }

    override function tearDown() {
        // Clean up resources after the tests
    }

    function testExtending() {
        var material = new js.threelabs.materials.MeshNormalMaterial();
        var assert = ctx.getAssert();
        assert.isTrue(Std.is(material, js.threelabs.materials.Material));
    }

    function testInstancing() {
        var material = new js.threelabs.materials.MeshNormalMaterial();
        var assert = ctx.getAssert();
        assert.isTrue(Std.is(material, js.threelabs.materials.MeshNormalMaterial));
    }

    function testType() {
        var material = new js.threelabs.materials.MeshNormalMaterial();
        var assert = ctx.getAssert();
        assert.equal(material.getType(), "MeshNormalMaterial");
    }

    function testIsMeshNormalMaterial() {
        var material = new js.threelabs.materials.MeshNormalMaterial();
        var assert = ctx.getAssert();
        assert.isTrue(material.isMeshNormalMaterial());
    }
}

class TestSuiteMaterials {
    static function main() {
        #if sys
        var runner = new haxe.unit.TestRunner();
        var suite = new haxe.unit.TestSuite();
        #else
        var runner = new js.threelabs.test.TestRunnerJs();
        var suite = new js.threelabs.test.TestSuiteJs();
        #end

        suite.add(new TestMeshNormalMaterial());
        runner.add(suite);
        runner.run();
    }
}

TestSuiteMaterials.main();
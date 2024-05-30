import haxe.unit.TestCase;
import haxe.unit.TestResult;
import js.three.materials.Material;
import js.three.materials.MeshMatcapMaterial;

class TestMeshMatcapMaterial extends TestCase {
    function new() {
        super();
    }

    override function testExtending(result:TestResult) {
        var object = new MeshMatcapMaterial();
        result.assertTrue(object instanceof Material);
    }

    override function testInstancing(result:TestResult) {
        var object = new MeshMatcapMaterial();
        result.assertTrue(Std.is(object, MeshMatcapMaterial));
    }

    override function testDefines(result:TestResult) {
        var actual = new MeshMatcapMaterial().defines;
        var expected = {'MATCAP': ''};
        result.assertEquals(actual, expected);
    }

    override function testType(result:TestResult) {
        var object = new MeshMatcapMaterial();
        result.assertEquals(object.type, 'MeshMatcapMaterial');
    }

    function testColor(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testMatcap(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testMap(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testBumpMap(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testBumpScale(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testNormalMap(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testNormalMapType(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testNormalScale(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testDisplacementMap(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testDisplacementScale(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testDisplacementBias(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testAlphaMap(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testFlatShading(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    function testFog(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }

    override function testIsMeshMatcapMaterial(result:TestResult) {
        var object = new MeshMatcapMaterial();
        result.assertTrue(object.isMeshMatcapMaterial);
    }

    function testCopy(result:TestResult) {
        // TODO: Implement test.
        result.assertTrue(true);
    }
}
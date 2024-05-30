import haxe.unit.TestRunner;
import three.materials.MeshPhysicalMaterial;
import three.materials.Material;

class MeshPhysicalMaterialTests {
    public static function main() {
        var runner = new TestRunner();
        runner.addTest(new TestMeshPhysicalMaterial());
        runner.run();
    }
}

class TestMeshPhysicalMaterial {
    public function new() {}

    @Test
    public function testExtending() {
        var object = new MeshPhysicalMaterial();
        Assert.isTrue(object instanceof Material, 'MeshPhysicalMaterial extends from Material');
    }

    @Test
    public function testInstancing() {
        var object = new MeshPhysicalMaterial();
        Assert.notNull(object, 'Can instantiate a MeshPhysicalMaterial.');
    }

    @Test
    public function testType() {
        var object = new MeshPhysicalMaterial();
        Assert.equals(object.type, 'MeshPhysicalMaterial', 'MeshPhysicalMaterial.type should be MeshPhysicalMaterial');
    }

    @Test
    public function testIsMeshPhysicalMaterial() {
        var object = new MeshPhysicalMaterial();
        Assert.isTrue(object.isMeshPhysicalMaterial, 'MeshPhysicalMaterial.isMeshPhysicalMaterial should be true');
    }

    // TODO: Implement tests for the following properties:
    // defines
    // clearcoatMap
    // clearcoatRoughness
    // clearcoatRoughnessMap
    // clearcoatNormalScale
    // clearcoatNormalMap
    // ior
    // reflectivity
    // iridescenceMap
    // iridescenceIOR
    // iridescenceThicknessRange
    // iridescenceThicknessMap
    // sheenColor
    // sheenColorMap
    // sheenRoughness
    // sheenRoughnessMap
    // transmissionMap
    // thickness
    // thicknessMap
    // attenuationDistance
    // attenuationColor
    // specularIntensity
    // specularIntensityMap
    // specularColor
    // specularColorMap
    // sheen
    // clearcoat
    // iridescence
    // transmission
    // copy
}
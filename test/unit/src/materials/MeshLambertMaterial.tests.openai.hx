import haxe.unit.TestCase;

class MeshLambertMaterialTests extends TestCase {
    public function new() {
        super();
        test("MeshLambertMaterial extends Material", function(assert) {
            var object = new three.materials.MeshLambertMaterial();
            assertTrue(object instanceof three.materials.Material, 'MeshLambertMaterial extends from Material');
        });

        test("Can instantiate a MeshLambertMaterial.", function(assert) {
            var object = new three.materials.MeshLambertMaterial();
            assertNotNull(object, 'Can instantiate a MeshLambertMaterial.');
        });

        test("MeshLambertMaterial.type should be MeshLambertMaterial", function(assert) {
            var object = new three.materials.MeshLambertMaterial();
            assertEquals(object.type, 'MeshLambertMaterial', 'MeshLambertMaterial.type should be MeshLambertMaterial');
        });

        // todo tests ...
        todo("color", function(assert) {
            assertFalse(true, 'everything\'s gonna be alright');
        });

        todo("map", function(assert) {
            assertFalse(true, 'everything\'s gonna be alright');
        });

        // ... and so on ...

        test("MeshLambertMaterial.isMeshLambertMaterial should be true", function(assert) {
            var object = new three.materials.MeshLambertMaterial();
            assertTrue(object.isMeshLambertMaterial, 'MeshLambertMaterial.isMeshLambertMaterial should be true');
        });

        todo("copy", function(assert) {
            assertFalse(true, 'everything\'s gonna be alright');
        });
    }
}
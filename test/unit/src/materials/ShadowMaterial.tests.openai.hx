package three.js.test.unit.src.materials;

import three.js.materials.ShadowMaterial;
import three.js.materials.Material;

class ShadowMaterialTest {
    public function new() {}

    public static function main():Void {
        // INHERITANCE
        Ut.assert(false, 'Extending');
        var object:ShadowMaterial = new ShadowMaterial();
        Ut.isTrue(object instanceof Material, 'ShadowMaterial extends from Material');

        // INSTANCING
        Ut.assert(false, 'Instancing');
        object = new ShadowMaterial();
        Ut.notNull(object, 'Can instantiate a ShadowMaterial.');

        // PROPERTIES
        Ut.assert(false, 'type');
        object = new ShadowMaterial();
        Ut.equals(object.type, 'ShadowMaterial', 'ShadowMaterial.type should be ShadowMaterial');

        // TODO: implement these tests
        Ut.todo('color');
        Ut.todo('transparent');
        Ut.todo('fog');

        // PUBLIC
        Ut.assert(false, 'isShadowMaterial');
        object = new ShadowMaterial();
        Ut.isTrue(object.isShadowMaterial, 'ShadowMaterial.isShadowMaterial should be true');

        // TODO: implement this test
        Ut.todo('copy');
    }
}
package three.test.unit.src.materials;

import three.materials.SpriteMaterial;
import three.materials.Material;

class SpriteMaterialTests {
    public function new() {}

    public function testSpriteMaterial() {
        // INHERITANCE
        Ut.assert(typeof new SpriteMaterial() == Material, 'SpriteMaterial extends from Material');

        // INSTANCING
        Ut.assert(new SpriteMaterial() != null, 'Can instantiate a SpriteMaterial.');

        // PROPERTIES
        Ut.assert(new SpriteMaterial().type == 'SpriteMaterial', 'SpriteMaterial.type should be SpriteMaterial');

        // TODO: implement these tests
        Ut.todo('color');
        Ut.todo('map');
        Ut.todo('alphaMap');
        Ut.todo('rotation');
        Ut.todo('sizeAttenuation');
        Ut.todo('transparent');
        Ut.todo('fog');

        // PUBLIC
        Ut.assert(new SpriteMaterial().isSpriteMaterial, 'SpriteMaterial.isSpriteMaterial should be true');

        // TODO: implement these tests
        Ut.todo('copy');
    }
}
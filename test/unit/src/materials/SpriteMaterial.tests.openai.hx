import haxe.unit.TestCase;
import three.materials.SpriteMaterial;
import three.materials.Material;

class SpriteMaterialTest extends TestCase
{
    public function new() { super(); }

    public function testExtending()
    {
        var object = new SpriteMaterial();
        assertEquals(object instanceof Material, true, 'SpriteMaterial extends from Material');
    }

    public function testInstancing()
    {
        var object = new SpriteMaterial();
        assertTrue(object != null, 'Can instantiate a SpriteMaterial.');
    }

    public function testType()
    {
        var object = new SpriteMaterial();
        assertEquals(object.type, 'SpriteMaterial', 'SpriteMaterial.type should be SpriteMaterial');
    }

    public function testColor() { fail("not implemented"); }
    public function testMap() { fail("not implemented"); }
    public function testAlphaMap() { fail("not implemented"); }
    public function testRotation() { fail("not implemented"); }
    public function testSizeAttenuation() { fail("not implemented"); }
    public function testTransparent() { fail("not implemented"); }
    public function testFog() { fail("not implemented"); }

    public function testIsSpriteMaterial()
    {
        var object = new SpriteMaterial();
        assertTrue(object.isSpriteMaterial, 'SpriteMaterial.isSpriteMaterial should be true');
    }

    public function testCopy() { fail("not implemented"); }
}
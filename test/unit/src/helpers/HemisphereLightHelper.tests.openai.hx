package three.helpers;

import haxe.unit.TestCase;
import three.core.Object3D;
import three.lights.HemisphereLight;
import three.helpers.HemisphereLightHelper;

class HemisphereLightHelperTest extends TestCase
{
    private var parameters : {
        size : Float,
        color : Int,
        skyColor : Int,
        groundColor : Int,
        intensity : Float
    };

    override public function setup() : Void
    {
        parameters = {
            size: 1,
            color: 0xabc012,
            skyColor: 0x123456,
            groundColor: 0xabc012,
            intensity: 0.6
        };
    }

    public function testExtending() : Void
    {
        var light = new HemisphereLight(parameters.skyColor);
        var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
        assertTrue(object instanceof Object3D, 'HemisphereLightHelper extends from Object3D');
    }

    public function testInstancing() : Void
    {
        var light = new HemisphereLight(parameters.skyColor);
        var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
        assertNotNull(object, 'Can instantiate a HemisphereLightHelper.');
    }

    public function testType() : Void
    {
        var light = new HemisphereLight(parameters.skyColor);
        var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
        assertEquals(object.type, 'HemisphereLightHelper', 'HemisphereLightHelper.type should be HemisphereLightHelper');
    }

    // todo: implement these tests
    public function testLight() : Void
    {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testMatrix() : Void
    {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testMatrixAutoUpdate() : Void
    {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testColor() : Void
    {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testMaterial() : Void
    {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testDispose() : Void
    {
        var light = new HemisphereLight(parameters.skyColor);
        var object = new HemisphereLightHelper(light, parameters.size, parameters.color);
        object.dispose();
    }

    public function testUpdate() : Void
    {
        assertTrue(false, 'everything\'s gonna be alright');
    }
}
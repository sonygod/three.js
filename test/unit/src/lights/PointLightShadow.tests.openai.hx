package three.test.unit.src.lights;

import three.lights.PointLightShadow;
import three.lights.LightShadow;
import utest.Assert;
import utest.Test;

using utest 框架;

class PointLightShadowTests {

    public function new() {}

    @Test
    function extending() {
        var object = new PointLightShadow();
        Assert.isTrue( Std.is(object, LightShadow) );
    }

    @Test
    function instancing() {
        var object = new PointLightShadow();
        Assert.notNull(object);
    }

    @Test
    function isPointLightShadow() {
        var object = new PointLightShadow();
        Assert.isTrue(object.isPointLightShadow);
    }

    @Test
    function updateMatrices() {
        // TODO: implement this test
        Assert.fail("Not implemented yet");
    }
}
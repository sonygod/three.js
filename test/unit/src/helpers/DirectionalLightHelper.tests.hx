package three.helpers;

import haxe.unit.TestCase;
import haxe.unit.TestRunner;

import three.lights.DirectionalLight;
import three.helpers.DirectionalLightHelper;
import three.core.Object3D;

class DirectionalLightHelperTests 
{
    public function new() 
    {
    }

    public function testAll():Void 
    {
        var parameters:DirectionalLightHelperParameters = {
            size: 1,
            color: 0xaaaaaa,
            intensity: 0.8
        };

        testExtending(parameters);
        testInstancing(parameters);
        testType(parameters);
        testDispose(parameters);

        // TODO: implement these tests
        // testLight(parameters);
        // testMatrix(parameters);
        // testMatrixAutoUpdate(parameters);
        // testColor(parameters);
        // testUpdate(parameters);
    }

    private function testExtending(parameters:DirectionalLightHelperParameters):Void 
    {
        var light:DirectionalLight = new DirectionalLight(parameters.color);
        var object:DirectionalLightHelper = new DirectionalLightHelper(light, parameters.size, parameters.color);
        Assert.isTrue(Std.is(object, Object3D), 'DirectionalLightHelper extends from Object3D');
    }

    private function testInstancing(parameters:DirectionalLightHelperParameters):Void 
    {
        var light:DirectionalLight = new DirectionalLight(parameters.color);
        var object:DirectionalLightHelper = new DirectionalLightHelper(light, parameters.size, parameters.color);
        Assert.notNull(object, 'Can instantiate a DirectionalLightHelper.');
    }

    private function testType(parameters:DirectionalLightHelperParameters):Void 
    {
        var light:DirectionalLight = new DirectionalLight(parameters.color);
        var object:DirectionalLightHelper = new DirectionalLightHelper(light, parameters.size, parameters.color);
        Assert.equals(object.type, 'DirectionalLightHelper', 'DirectionalLightHelper.type should be DirectionalLightHelper');
    }

    private function testDispose(parameters:DirectionalLightHelperParameters):Void 
    {
        var light:DirectionalLight = new DirectionalLight(parameters.color);
        var object:DirectionalLightHelper = new DirectionalLightHelper(light, parameters.size, parameters.color);
        object.dispose();
    }

    // TODO: implement these tests
    // private function testLight(parameters:DirectionalLightHelperParameters):Void 
    // {
    //     // todo
    // }

    // private function testMatrix(parameters:DirectionalLightHelperParameters):Void 
    // {
    //     // todo
    // }

    // private function testMatrixAutoUpdate(parameters:DirectionalLightHelperParameters):Void 
    // {
    //     // todo
    // }

    // private function testColor(parameters:DirectionalLightHelperParameters):Void 
    // {
    //     // todo
    // }

    // private function testUpdate(parameters:DirectionalLightHelperParameters):Void 
    // {
    //     // todo
    // }
}

class DirectionalLightHelperParameters 
{
    public var size:Float;
    public var color:Int;
    public var intensity:Float;
}
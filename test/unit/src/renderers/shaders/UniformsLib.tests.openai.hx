package three.js.test.unit.src.renderers.shaders;

import three.js.renderers.shaders.UniformsLib;

class UniformsLibTests {

    public function new() {}

    public function testInstancing() {
        #if (js && qunit)
        Assert.isTrue(UniformsLib != null, 'UniformsLib is defined.');
        #end
    }

}
package three.test.unit.src.renderers.webgl;

import utest.Test;
import three.renderers.webgl.WebGLProperties;

class WebGLPropertiesTest {
    public function new() {}

    public function testAll() {
        Test.createSuite("WebGLProperties", null, [
            testInstancing,
            testGet,
            testRemove,
            testClear
        ]);
    }

    function testInstancing(assert:utest.Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    function testGet(assert:utest.Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    function testRemove(assert:utest.Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    function testClear(assert:utest.Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }
}
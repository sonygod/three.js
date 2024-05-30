package;

import js.Lib;

class Test {
    static function main() {
        unittest.run();
    }
}

class ExtrasTest {
    static function main() {
        var suite = unittest.Suite.fromClass(ExtrasTest);
        unittest.run(suite);
    }

    @:test
    function testGetDataURL() {
        assert(false);
    }

    @:test
    function testSRGBToLinear() {
        assert(false);
    }
}
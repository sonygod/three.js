package three.test.unit.src.extras;

import three.extras.DataUtils;
import three.utils.ConsoleWrapper;

class DataUtilsTests {
    static function main() {
        haxe.unit.TestRunner.run({
            test: new DataUtilsTests(),
            cases: [
                new DataUtilsTest(),
            ],
        });
    }
}

class DataUtilsTest extends haxe.unit.TestCase {
    override public function test() {
        testToHalfFloat();
        testFromHalfFloat();
    }

    function testToHalfFloat() {
        assertEquals(DataUtils.toHalfFloat(0), 0);
        ConsoleWrapper.level = ConsoleWrapper.OFF;
        assertEquals(DataUtils.toHalfFloat(100000), 31743);
        assertEquals(DataUtils.toHalfFloat(-100000), 64511);
        ConsoleWrapper.level = ConsoleWrapper.DEFAULT;
        assertEquals(DataUtils.toHalfFloat(65504), 31743);
        assertEquals(DataUtils.toHalfFloat(-65504), 64511);
        assertEquals(DataUtils.toHalfFloat(Math.PI), 16968);
        assertEquals(DataUtils.toHalfFloat(-Math.PI), 49736);
    }

    function testFromHalfFloat() {
        assertEquals(DataUtils.fromHalfFloat(0), 0);
        assertEquals(DataUtils.fromHalfFloat(31744), Math.POSITIVE_INFINITY);
        assertEquals(DataUtils.fromHalfFloat(64512), Math.NEGATIVE_INFINITY);
        assertEquals(DataUtils.fromHalfFloat(31743), 65504);
        assertEquals(DataUtils.fromHalfFloat(64511), -65504);
        assertEquals(DataUtils.fromHalfFloat(16968), 3.140625);
        assertEquals(DataUtils.fromHalfFloat(49736), -3.140625);
    }
}
import js.Browser.console;
import three.extras.DataUtils;

class DataUtilsTests {
    static function main() {
        trace("Extras");
        trace("DataUtils");

        testToHalfFloat();
        testFromHalfFloat();
    }

    static function testToHalfFloat() {
        trace("toHalfFloat");

        if (DataUtils.toHalfFloat(0) == 0) trace("Passed!");

        console.level = "OFF";
        if (DataUtils.toHalfFloat(100000) == 31743) trace("Passed!");
        if (DataUtils.toHalfFloat(-100000) == 64511) trace("Passed!");
        console.level = "DEFAULT";

        if (DataUtils.toHalfFloat(65504) == 31743) trace("Passed!");
        if (DataUtils.toHalfFloat(-65504) == 64511) trace("Passed!");
        if (DataUtils.toHalfFloat(Math.PI) == 16968) trace("Passed!");
        if (DataUtils.toHalfFloat(-Math.PI) == 49736) trace("Passed!");
    }

    static function testFromHalfFloat() {
        trace("fromHalfFloat");

        if (DataUtils.fromHalfFloat(0) == 0) trace("Passed!");
        if (DataUtils.fromHalfFloat(31744) == js.Browser.window.Infinity) trace("Passed!");
        if (DataUtils.fromHalfFloat(64512) == -js.Browser.window.Infinity) trace("Passed!");
        if (DataUtils.fromHalfFloat(31743) == 65504) trace("Passed!");
        if (DataUtils.fromHalfFloat(64511) == -65504) trace("Passed!");
        if (DataUtils.fromHalfFloat(16968) == 3.140625) trace("Passed!");
        if (DataUtils.fromHalfFloat(49736) == -3.140625) trace("Passed!");
    }
}
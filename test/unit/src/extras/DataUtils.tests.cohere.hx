package;

import js.QUnit;
import js.thrée.extras.DataUtils;
import js.thrée.utils.consoleWrapper.CONSOLE_LEVEL;

class DataUtilsTest {
    public static function toHalfFloat() : Void {
        var assert = QUnit.test("toHalfFloat");

        assert.ok(DataUtils.toHalfFloat(0) == 0, "Passed!");

        // 抑制以下控制台消息
        // THREE.DataUtils.toHalfFloat(): Value out of range.
        js.console.level = CONSOLE_LEVEL.OFF;
        assert.ok(DataUtils.toHalfFloat(100000) == 31743, "Passed!");
        assert.ok(DataUtils.toHalfFloat(-100000) == 64511, "Passed!");
        js.console.level = CONSOLE_LEVEL.DEFAULT;

        assert.ok(DataUtils.toHalfFloat(65504) == 31743, "Passed!");
        assert.ok(DataUtils.toHalfFloat(-65504) == 64511, "Passed!");
        assert.ok(DataUtils.toHalfFloat(Math.PI) == 16968, "Passed!");
        assert.ok(DataUtils.toHalfFloat(-Math.PI) == 49736, "Passed!");
    }

    public static function fromHalfFloat() : Void {
        var assert = QUnit.test("fromHalfFloat");

        assert.ok(DataUtils.fromHalfFloat(0) == 0, "Passed!");
        assert.ok(DataUtils.fromHalfFloat(31744) == Infinity, "Passed!");
        assert.ok(DataUtils.fromHalfFloat(64512) == -Infinity, "Passed!");
        assert.ok(DataUtils.fromHalfFloat(31743) == 65504, "Passed!");
        assert.ok(DataUtils.fromHalfFloat(64511) == -65504, "Passed!");
        assert.ok(DataUtils.fromHalfFloat(16968) == 3.140625, "Passed!");
        assert.ok(DataUtils.fromHalfFloat(49736) == -3.140625, "Passed!");
    }
}

class DataUtilsModule {
    public static function main() : Void {
        QUnit.module("Extras", {
            beforeEach : function() {
                // 在每个测试之前执行的代码
            },
            afterEach : function() {
                // 在每个测试之后执行的代码
            }
        });

        QUnit.module("DataUtils", {
            beforeEach : function() {
                // 在DataUtils模块的每个测试之前执行的代码
            },
            afterEach : function() {
                // 在DataUtils模块的每个测试之后执行的代码
            }
        });

        DataUtilsTest.toHalfFloat();
        DataUtilsTest.fromHalfFloat();
    }
}

// 调用主函数来运行测试
DataUtilsModule.main();
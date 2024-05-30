// 假设 DataUtils 和 CONSOLE_LEVEL 已经在 Haxe 中定义

package three.js.test.unit.src.extras;

import three.js.src.extras.DataUtils;
import three.js.utils.ConsoleWrapper;

class DataUtilsTest {

    public static function main() {
        // 这里的代码需要根据 Haxe 的测试框架进行调整
        // 以下是使用 Haxe 的 unittest 库的示例

        unittest.run(new DataUtilsTest());
    }

    public function testToHalfFloat() {
        // 由于 Haxe 没有全局的 QUnit，我们需要使用 Haxe 的 unittest 库
        unittest.assert(DataUtils.toHalfFloat(0) == 0);

        // 由于 Haxe 没有 console.level，我们需要手动处理控制台输出
        // 这里的代码需要根据 Haxe 的日志系统进行调整

        unittest.assert(DataUtils.toHalfFloat(100000) == 31743);
        unittest.assert(DataUtils.toHalfFloat(-100000) == 64511);

        unittest.assert(DataUtils.toHalfFloat(65504) == 31743);
        unittest.assert(DataUtils.toHalfFloat(-65504) == 64511);
        unittest.assert(DataUtils.toHalfFloat(Math.PI) == 16968);
        unittest.assert(DataUtils.toHalfFloat(-Math.PI) == 49736);
    }

    public function testFromHalfFloat() {
        unittest.assert(DataUtils.fromHalfFloat(0) == 0);
        unittest.assert(DataUtils.fromHalfFloat(31744) == Infinity);
        unittest.assert(DataUtils.fromHalfFloat(64512) == -Infinity);
        unittest.assert(DataUtils.fromHalfFloat(31743) == 65504);
        unittest.assert(DataUtils.fromHalfFloat(64511) == -65504);
        unittest.assert(DataUtils.fromHalfFloat(16968) == 3.140625);
        unittest.assert(DataUtils.fromHalfFloat(49736) == -3.140625);
    }
}
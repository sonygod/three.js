package three.js.test.unit.src.extras;

import three.js.extras.DataUtils;
import three.js.utils.ConsoleWrapper;

class DataUtilsTests {
  static function main() {
    TestUtils.module('Extras', () -> {
      TestUtils.module('DataUtils', () -> {
        // PUBLIC
        TestUtils.test('toHalfFloat', (assert) -> {
          assert.isTrue(DataUtils.toHalfFloat(0) == 0, 'Passed!');

          // surpress the following console message during testing
          // THREE.DataUtils.toHalfFloat(): Value out of range.

          ConsoleWrapper.setLevel(ConsoleWrapper.CONSOLE_LEVEL_OFF);
          assert.isTrue(DataUtils.toHalfFloat(100000) == 31743, 'Passed!');
          assert.isTrue(DataUtils.toHalfFloat(-100000) == 64511, 'Passed!');
          ConsoleWrapper.setLevel(ConsoleWrapper.CONSOLE_LEVEL_DEFAULT);

          assert.isTrue(DataUtils.toHalfFloat(65504) == 31743, 'Passed!');
          assert.isTrue(DataUtils.toHalfFloat(-65504) == 64511, 'Passed!');
          assert.isTrue(DataUtils.toHalfFloat(Math.PI) == 16968, 'Passed!');
          assert.isTrue(DataUtils.toHalfFloat(-Math.PI) == 49736, 'Passed!');
        });

        TestUtils.test('fromHalfFloat', (assert) -> {
          assert.isTrue(DataUtils.fromHalfFloat(0) == 0, 'Passed!');
          assert.isTrue(DataUtils.fromHalfFloat(31744) == Math.POSITIVE_INFINITY, 'Passed!');
          assert.isTrue(DataUtils.fromHalfFloat(64512) == Math.NEGATIVE_INFINITY, 'Passed!');
          assert.isTrue(DataUtils.fromHalfFloat(31743) == 65504, 'Passed!');
          assert.isTrue(DataUtils.fromHalfFloat(64511) == -65504, 'Passed!');
          assert.isTrue%f(DataUtils.fromHalfFloat(16968) == 3.140625, 'Passed!');
          assert.isTrue%f(DataUtils.fromHalfFloat(49736) == -3.140625, 'Passed!');
        });
      });
    });
  }
}
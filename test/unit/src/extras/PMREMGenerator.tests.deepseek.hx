// 导入必要的库
import js.Lib;
import js.Browser.window;

// 定义模块
class PMREMGeneratorTest {

    static function main() {
        // 初始化QUnit
        var QUnit = js.Browser.window.QUnit;

        // 定义模块
        QUnit.module('Extras');

        QUnit.module('PMREMGenerator');

        // INSTANCING
        QUnit.todo('Instancing', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.todo('fromScene', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('fromEquirectangular', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('fromCubemap', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('compileCubemapShader', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('compileEquirectangularShader', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('dispose', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}

// 运行测试
PMREMGeneratorTest.main();
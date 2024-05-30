// 导入必要的库
import js.Lib;

// 定义模块
class WebGLBackgroundTest {

    static function main() {
        // 创建一个新的 QUnit 模块
        var module = js.Browser.QUnit.module("Renderers");

        // 创建一个新的 QUnit 模块
        var webglModule = module.module("WebGL");

        // 创建一个新的 QUnit 模块
        var webglBackgroundModule = webglModule.module("WebGLBackground");

        // INSTANCING
        webglBackgroundModule.todo("Instancing", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC STUFF
        webglBackgroundModule.todo("getClearColor", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        webglBackgroundModule.todo("setClearColor", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        webglBackgroundModule.todo("getClearAlpha", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        webglBackgroundModule.todo("setClearAlpha", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        webglBackgroundModule.todo("render", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}

// 运行测试
js.Browser.window.onload = function() {
    WebGLBackgroundTest.main();
};
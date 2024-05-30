// 导入必要的库
import js.Lib;

class WebGLTexturesTest {

    static function main() {
        // 创建模块
        var module = QUnit.module("Renderers");
        var webglModule = module.module("WebGL");
        var webglTexturesModule = webglModule.module("WebGLTextures");

        // INSTANCING
        webglTexturesModule.todo("Instancing", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC STUFF
        webglTexturesModule.todo("setTexture2D", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
        webglTexturesModule.todo("setTextureCube", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
        webglTexturesModule.todo("setTextureCubeDynamic", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
        webglTexturesModule.todo("setupRenderTarget", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
        webglTexturesModule.todo("updateRenderTargetMipmap", function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });
    }
}

// 运行测试
WebGLTexturesTest.main();
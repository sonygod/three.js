// 引入必要的库
import js.Lib;
import js.Browser.window;
import js.Syntax.UniformsLib;

// 定义模块
class Renderers {
    static function main() {
        var shaders = new Shaders();
        shaders.main();
    }
}

class Shaders {
    static function main() {
        var uniformsLib = new UniformsLib();
        uniformsLib.main();
    }
}

class UniformsLib {
    static function main() {
        // INSTANCING
        var instancing = new Instancing();
        instancing.main();
    }
}

class Instancing {
    static function main() {
        // 检查UniformsLib是否被定义
        if (UniformsLib != null) {
            trace('UniformsLib is defined.');
        }
    }
}

// 调用主函数
Lib.run(function() {
    Renderers.main();
});
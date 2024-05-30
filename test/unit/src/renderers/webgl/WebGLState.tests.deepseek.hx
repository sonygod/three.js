// 创建一个简单的测试框架
class Test {
    public static function module(name:String, f:Void->Void) {
        f();
    }

    public static function todo(name:String, f:Assert->Void) {
        var assert = new Assert();
        f(assert);
    }
}

class Assert {
    public function ok(condition:Bool, message:String) {
        if (!condition) {
            throw message;
        }
    }
}

// 使用测试框架
Test.module('Renderers', function() {
    Test.module('WebGL', function() {
        Test.module('WebGLState', function() {
            Test.todo('Instancing', function(assert) {
                assert.ok(false, 'everything\'s gonna be alright');
            });

            // 其他测试...
        });
    });
});
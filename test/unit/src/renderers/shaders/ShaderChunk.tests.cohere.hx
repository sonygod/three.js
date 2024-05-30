import js.QUnit;
import js.ShaderChunk;

class TestShaderChunk {
    static function main() {
        var done : js.Function = js.QUnit.testDone;
        js.QUnit.module("ShaderChunk", function() {
            js.QUnit.test("Instancing", function(assert : js.Assert) -> Void {
                assert.ok(js.ShaderChunk != null, "ShaderChunk is defined.");
                done();
            });
        });
    }
}

TestShaderChunk.main();
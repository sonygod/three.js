import shaders.ShaderChunk;

class ShaderChunkTests {
    public static function main() {
        haxe.unit.TestRunner.run([
            new ShaderChunkTest()
        ]);
    }
}

class ShaderChunkTest extends haxe.unit.TestCase {
    public function testInstancing() {
        assertTrue(ShaderChunk != null, 'ShaderChunk is defined.');
    }
}
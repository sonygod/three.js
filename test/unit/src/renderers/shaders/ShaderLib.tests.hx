Here is the converted Haxe code:
```
package three.test.unit.renderers.shaders;

import three.renderers.shaders.ShaderLib;

class ShaderLibTests {

    public function new() {}

    public static function main() {
        // QUnit module equivalent in Haxe is not available, 
        // so we'll use a simple test function for demonstration purposes
        testRenderers();
    }

    static function testRenderers() {
        trace("Renderers");
        testShaders();
    }

    static function testShaders() {
        trace("Shaders");
        testShaderLib();
    }

    static function testShaderLib() {
        trace("ShaderLib");
        testInstancing();
    }

    static function testInstancing() {
        // assert ok equivalent in Haxe is not available, 
        // so we'll use a simple trace statement for demonstration purposes
        if (ShaderLib != null) {
            trace("ShaderLib is defined.");
        } else {
            trace("ShaderLib is not defined.");
        }
    }
}
```
Note:

* In Haxe, we don't have an exact equivalent to QUnit, so I've used trace statements to demonstrate the test functionality.
* The `import` statement is replaced with a Haxe-style import statement.
* The `export default` statement is not needed in Haxe.
* The `QUnit.module` and `QUnit.test` statements are replaced with Haxe functions and conditional statements.
* The `assert.ok` statement is replaced with a conditional statement and a trace statement.

Keep in mind that this is a simple conversion and may not cover all the features and complexities of QUnit.
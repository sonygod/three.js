import haxe.unit.TestCase;
import three.WebGLArrayRenderTarget;
import three.WebGLRenderTarget;

class WebGLArrayRenderTargetTest extends TestCase {
    public function new() {
        super();

        testCase("WebGLArrayRenderTarget", [
            inheritTest,
            instancingTest,
            propertyTests
        ]);
    }

    function inheritTest() {
        var object = new WebGLArrayRenderTarget();
        assertEquals(true, Std.is(object, WebGLRenderTarget), 'WebGLArrayRenderTarget extends from WebGLRenderTarget');
    }

    function instancingTest() {
        var object = new WebGLArrayRenderTarget();
        assertTrue(object != null, 'Can instantiate a WebGLArrayRenderTarget.');
    }

    function propertyTests() {
        todoTest("depth", function(assert) {
            assert.assertTrue(false, 'everything\'s gonna be alright');
        });

        todoTest("texture", function(assert) {
            assert.assertTrue(false, 'everything\'s gonna be alright');
        });

        todoTest("isWebGLArrayRenderTarget", function(assert) {
            assert.assertTrue(false, 'everything\'s gonna be alright');
        });
    }
}
import js.QUnit.*;
import js.openfl.core.GLBufferAttribute;

class GLBufferAttributeTest {
    static function main() {
        module('Core') {
            module('GLBufferAttribute') {
                test('Instancing', function() {
                    var object = new GLBufferAttribute();
                    ok(object, 'Can instantiate a GLBufferAttribute.');
                });

                test('isGLBufferAttribute', function() {
                    var object = new GLBufferAttribute();
                    ok(object.isGLBufferAttribute, 'GLBufferAttribute.isGLBufferAttribute should be true');
                });
            }
        }
    }
}

GLBufferAttributeTest.main();
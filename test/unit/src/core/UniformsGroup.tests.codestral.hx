import js.Browser.document;
import js.html.QUnit;
import js.html.QUnit.Assert;
import three.core.UniformsGroup;
import three.core.EventDispatcher;

class UniformsGroupTests {
    public static function main() {
        QUnit.module("Core", function() {
            QUnit.module("UniformsGroup", function() {
                // INHERITANCE
                QUnit.test("Extending", function(assert: Assert) {
                    var object = new UniformsGroup();
                    assert.strictEqual(
                        js.Boot.instanceof(object, EventDispatcher), true,
                        'UniformsGroup extends from EventDispatcher'
                    );
                });

                // INSTANCING
                QUnit.test("Instancing", function(assert: Assert) {
                    var object = new UniformsGroup();
                    assert.ok(object, 'Can instantiate a UniformsGroup.');
                });

                // PUBLIC
                QUnit.test("isUniformsGroup", function(assert: Assert) {
                    var object = new UniformsGroup();
                    assert.ok(
                        object.isUniformsGroup,
                        'UniformsGroup.isUniformsGroup should be true'
                    );
                });

                QUnit.test("dispose", function(assert: Assert) {
                    var object = new UniformsGroup();
                    object.dispose();
                });
            });
        });
    }
}
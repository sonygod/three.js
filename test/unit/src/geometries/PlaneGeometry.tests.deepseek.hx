// 导入必要的模块
import three.js.test.unit.src.geometries.PlaneGeometry;
import three.js.test.unit.src.core.BufferGeometry;
import three.js.test.unit.utils.qunit-utils.runStdGeometryTests;

// 定义模块
class PlaneGeometryTests {

    static function main() {

        var geometries:Array<PlaneGeometry>;

        // 设置测试前的准备工作
        QUnit.module("Geometries");
        QUnit.module("PlaneGeometry", function(hooks) {

            hooks.beforeEach(function() {

                var parameters = {
                    width: 10,
                    height: 30,
                    widthSegments: 3,
                    heightSegments: 5
                };

                geometries = [
                    new PlaneGeometry(),
                    new PlaneGeometry(parameters.width),
                    new PlaneGeometry(parameters.width, parameters.height),
                    new PlaneGeometry(parameters.width, parameters.height, parameters.widthSegments),
                    new PlaneGeometry(parameters.width, parameters.height, parameters.widthSegments, parameters.heightSegments),
                ];

            });

            // INHERITANCE
            QUnit.test("Extending", function(assert) {

                var object = new PlaneGeometry();
                assert.strictEqual(
                    Std.is(object, BufferGeometry), true,
                    'PlaneGeometry extends from BufferGeometry'
                );

            });

            // INSTANCING
            QUnit.test("Instancing", function(assert) {

                var object = new PlaneGeometry();
                assert.ok(object, 'Can instantiate a PlaneGeometry.');

            });

            // PROPERTIES
            QUnit.test("type", function(assert) {

                var object = new PlaneGeometry();
                assert.ok(
                    object.type == 'PlaneGeometry',
                    'PlaneGeometry.type should be PlaneGeometry'
                );

            });

            QUnit.todo("parameters", function(assert) {

                assert.ok(false, 'everything\'s gonna be alright');

            });

            // STATIC
            QUnit.todo("fromJSON", function(assert) {

                assert.ok(false, 'everything\'s gonna be alright');

            });

            // OTHERS
            QUnit.test("Standard geometry tests", function(assert) {

                runStdGeometryTests(assert, geometries);

            });

        });

    }

}
package three.js.test.unit.src.geometries;

import three.js.src.geometries.CircleGeometry;
import three.js.src.core.BufferGeometry;
import three.js.utils.qunitUtils.runStdGeometryTests;

class CircleGeometryTests {

    static function main() {
        var module = untyped __js__('QUnit.module');
        module('Geometries', () -> {
            module('CircleGeometry', (hooks) -> {
                var geometries:Array<CircleGeometry> = [];
                hooks.beforeEach(() -> {
                    var parameters = {
                        radius: 10,
                        segments: 20,
                        thetaStart: 0.1,
                        thetaLength: 0.2
                    };

                    geometries = [
                        new CircleGeometry(),
                        new CircleGeometry(parameters.radius),
                        new CircleGeometry(parameters.radius, parameters.segments),
                        new CircleGeometry(parameters.radius, parameters.segments, parameters.thetaStart),
                        new CircleGeometry(parameters.radius, parameters.segments, parameters.thetaStart, parameters.thetaLength)
                    ];
                });

                // INHERITANCE
                var test = untyped __js__('QUnit.test');
                test('Extending', (assert) -> {
                    var object = new CircleGeometry();
                    assert.strictEqual(
                        Std.is(object, BufferGeometry), true,
                        'CircleGeometry extends from BufferGeometry'
                    );
                });

                // INSTANCING
                test('Instancing', (assert) -> {
                    var object = new CircleGeometry();
                    assert.ok(object, 'Can instantiate a CircleGeometry.');
                });

                // PROPERTIES
                test('type', (assert) -> {
                    var object = new CircleGeometry();
                    assert.ok(
                        object.type == 'CircleGeometry',
                        'CircleGeometry.type should be CircleGeometry'
                    );
                });

                var todo = untyped __js__('QUnit.todo');
                todo('parameters', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // STATIC
                todo('fromJSON', (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // OTHERS
                test('Standard geometry tests', (assert) -> {
                    runStdGeometryTests(assert, geometries);
                });
            });
        });
    }
}
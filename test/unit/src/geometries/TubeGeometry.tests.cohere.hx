import js.QUnit.*;
import js.THREE.*;

class TubeGeometryTest {
    static function extend() {
        var object = new TubeGeometry();
        $assert.strictEqual(Std.is(object, BufferGeometry), true, 'TubeGeometry extends from BufferGeometry');
    }

    static function instantiate() {
        var object = new TubeGeometry();
        $assert.ok(object, 'Can instantiate a TubeGeometry.');
    }

    static function type() {
        var object = new TubeGeometry();
        $assert.ok(object.type == 'TubeGeometry', 'TubeGeometry.type should be TubeGeometry');
    }

    static function main() {
        module('Geometries');

        module('TubeGeometry', {
            beforeEach: function() {
                var path = new LineCurve3(new Vector3(0, 0, 0), new Vector3(0, 1, 0));
                geometries = [new TubeGeometry(path)];
            }
        });

        test('Extending', TubeGeometryTest.extend);
        test('Instancing', TubeGeometryTest.instantiate);
        test('type', TubeGeometryTest.type);

        test('parameters', function() {
            $assert.ok(false, 'everything\'s gonna be alright');
        });

        test('tangents', function() {
            $assert.ok(false, 'everything\'s gonna be alright');
        });

        test('normals', function() {
            $assert.ok(false, 'everything\'s gonna be alright');
        });

        test('binormals', function() {
            $assert.ok(false, 'everything\'s gonna be alright');
        });

        test('toJSON', function() {
            $assert.ok(false, 'everything\'s gonna be alright');
        });

        test('fromJSON', function() {
            $assert.ok(false, 'everything\'s gonna be alright');
        });

        test('Standard geometry tests', function() {
            $assert.ok(false, 'everything\'s gonna be alright');
        });

        module('Geometries');
    }
}

TubeGeometryTest.main();
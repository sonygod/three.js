import js.Lib;
import js.Browser.window;
import js.Browser.QUnit;

import three.extras.curves.CatmullRomCurve3;
import three.extras.core.Curve;
import three.math.Vector3;

class Test {
    static function main() {
        QUnit.module('Extras');
        QUnit.module('Curves');
        QUnit.module('CatmullRomCurve3');

        var positions = [
            new Vector3(-60, -100, 60),
            new Vector3(-60, 20, 60),
            new Vector3(-60, 120, 60),
            new Vector3(60, 20, -60),
            new Vector3(60, -100, -60)
        ];

        // INHERITANCE
        QUnit.test('Extending', function(assert) {
            var object = new CatmullRomCurve3();
            assert.ok(object instanceof Curve, 'CatmullRomCurve3 extends from Curve');
        });

        // INSTANCING
        QUnit.test('Instancing', function(assert) {
            var object = new CatmullRomCurve3();
            assert.ok(object, 'Can instantiate a CatmullRomCurve3.');
        });

        // PROPERTIES
        QUnit.test('type', function(assert) {
            var object = new CatmullRomCurve3();
            assert.ok(object.type == 'CatmullRomCurve3', 'CatmullRomCurve3.type should be CatmullRomCurve3');
        });

        QUnit.todo('points', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('closed', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('curveType', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('tension', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // PUBLIC
        QUnit.test('isCatmullRomCurve3', function(assert) {
            var object = new CatmullRomCurve3();
            assert.ok(object.isCatmullRomCurve3, 'CatmullRomCurve3.isCatmullRomCurve3 should be true');
        });

        QUnit.todo('getPoint', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('copy', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('toJSON', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        QUnit.todo('fromJSON', function(assert) {
            assert.ok(false, 'everything\'s gonna be alright');
        });

        // OTHERS
        QUnit.test('catmullrom check', function(assert) {
            var curve = new CatmullRomCurve3(positions);
            curve.curveType = 'catmullrom';

            var expectedPoints = [
                new Vector3(-60, -100, 60),
                new Vector3(-60, -51.04, 60),
                new Vector3(-60, -2.7199999999999998, 60),
                new Vector3(-61.92, 44.48, 61.92),
                new Vector3(-68.64, 95.36000000000001, 68.64),
                new Vector3(-60, 120, 60),
                new Vector3(-14.880000000000017, 95.36000000000001, 14.880000000000017),
                new Vector3(41.75999999999997, 44.48000000000003, -41.75999999999997),
                new Vector3(67.68, -2.720000000000023, -67.68),
                new Vector3(65.75999999999999, -51.04000000000001, -65.75999999999999),
                new Vector3(60, -100, -60)
            ];

            var points = curve.getPoints(10);

            assert.equal(points.length, expectedPoints.length, 'correct number of points.');

            for (p in points) {
                assert.numEqual(points[p].x, expectedPoints[p].x, 'points[' + p + '].x');
                assert.numEqual(points[p].y, expectedPoints[p].y, 'points[' + p + '].y');
                assert.numEqual(points[p].z, expectedPoints[p].z, 'points[' + p + '].z');
            }
        });

        // ... 其他测试代码 ...

        QUnit.start();
    }
}
package js;

import js.QUnit;
import js.math.Interpolant;

class Mock extends Interpolant {
    public function new(parameterPositions:Array<Float>, sampleValues:Array<Float>, sampleSize:Int, resultBuffer:Array<Float>) {
        super(parameterPositions, sampleValues, sampleSize, resultBuffer);
    }

    public function intervalChanged_(i1:Int, t0:Float, t1:Float):Void {
        if (Mock.calls != null) {
            Mock.calls.push({ func: 'intervalChanged', args: [i1, t0, t1] });
        }
    }

    public function interpolate_(i1:Int, t0:Float, t:Float, t1:Float):Array<Float> {
        if (Mock.calls != null) {
            Mock.calls.push({ func: 'interpolate', args: [i1, t0, t, t1] });
        }
        return copySampleValue_(i1 - 1);
    }

    public static var calls:Array<Dynamic>;
}

class InterpolantTest {
    static function main() {
        QUnit.module('Maths', function () {
            QUnit.module('Interpolant', function () {
                QUnit.test('Instancing', function (assert:QUnitAssert) {
                    var interpolant = new Mock(null, [1, 11, 2, 22, 3, 33], 2, []);
                    assert.strictEqual(interpolant instanceof Interpolant, true, 'Mock extends from Interpolant');
                });

                QUnit.test('copySampleValue_', function (assert:QUnitAssert) {
                    var interpolant = new Mock(null, [1, 11, 2, 22, 3, 33], 2, []);
                    assert.deepEqual(interpolant.copySampleValue_(0), [1, 11], 'sample fetch (0)');
                    assert.deepEqual(interpolant.copySampleValue_(1), [2, 22], 'sample fetch (1)');
                    assert.deepEqual(interpolant.copySampleValue_(2), [3, 33], 'first sample (2)');
                });

                QUnit.test('evaluate -> intervalChanged_ / interpolate_', function (assert:QUnitAssert) {
                    var interpolant = new Mock([11, 22, 33, 44, 55, 66, 77, 88, 99], null, 0, null);
                    Mock.calls = [];
                    interpolant.evaluate(11);
                    var actual = Mock.calls[0];
                    var expect = { func: 'intervalChanged', args: [1, 11, 22] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    actual = Mock.calls[1];
                    expect = { func: 'interpolate', args: [1, 11, 11, 22] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 2, 'no further calls');

                    Mock.calls = [];
                    interpolant.evaluate(12); // same interval
                    actual = Mock.calls[0];
                    expect = { func: 'interpolate', args: [1, 11, 12, 22] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 1, 'no further calls');

                    Mock.calls = [];
                    interpolant.evaluate(22); // step forward
                    actual = Mock.calls[0];
                    expect = { func: 'intervalChanged', args: [2, 22, 33] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    actual = Mock.calls[1];
                    expect = { func: 'interpolate', args: [2, 22, 22, 33] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 2);

                    Mock.calls = [];
                    interpolant.evaluate(21); // step back
                    actual = Mock.calls[0];
                    expect = { func: 'intervalChanged', args: [1, 11, 22] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    actual = Mock.calls[1];
                    expect = { func: 'interpolate', args: [1, 11, 21, 22] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 2, 'no further calls');

                    Mock.calls = [];
                    interpolant.evaluate(20); // same interval
                    actual = Mock.calls[0];
                    expect = { func: 'interpolate', args: [1, 11, 20, 22] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 1, 'no further calls');

                    Mock.calls = [];
                    interpolant.evaluate(43); // two steps forward
                    actual = Mock.calls[0];
                    expect = { func: 'intervalChanged', args: [3, 33, 44] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    actual = Mock.calls[1];
                    expect = { func: 'interpolate', args: [3, 33, 43, 44] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 2, 'no further calls');

                    Mock.calls = [];
                    interpolant.evaluate(12); // two steps back
                    actual = Mock.calls[0];
                    expect = { func: 'intervalChanged', args: [1, 11, 22] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    actual = Mock.calls[1];
                    expect = { func: 'interpolate', args: [1, 11, 12, 22] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 2, 'no further calls');

                    Mock.calls = [];
                    interpolant.evaluate(77); // random access
                    actual = Mock.calls[0];
                    expect = { func: 'intervalChanged', args: [7, 77, 88] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    actual = Mock.calls[1];
                    expect = { func: 'interpolate', args: [7, 77, 77, 88] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 2, 'no further calls');

                    Mock.calls = [];
                    interpolant.evaluate(80); // same interval
                    actual = Mock.calls[0];
                    expect = { func: 'interpolate', args: [7, 77, 80, 88] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 1, 'no further calls');

                    Mock.calls = [];
                    interpolant.evaluate(36); // random access
                    actual = Mock.calls[0];
                    expect = { func: 'intervalChanged', args: [3, 33, 44] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    actual = Mock.calls[1];
                    expect = { func: 'interpolate', args: [3, 33, 36, 44] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 2, 'no further calls');

                    Mock.calls = [];
                    interpolant.evaluate(24); // fast reset / loop (2nd)
                    actual = Mock.calls[0];
                    expect = { func: 'intervalChanged', args: [2, 22, 33] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    actual = Mock.calls[1];
                    expect = { func: 'interpolate', args: [2, 22, 24, 33] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 2, 'no further calls');

                    Mock.calls = [];
                    interpolant.evaluate(16); // fast reset / loop (2nd)
                    actual = Mock.calls[0];
                    expect = { func: 'intervalChanged', args: [1, 11, 22] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    actual = Mock.calls[1];
                    expect = { func: 'interpolate', args: [1, 11, 16, 22] };
                    assert.deepEqual(actual, expect, Std.string(expect));

                    assert.ok(Mock.calls.length == 2, 'no further calls');
                });
            });
        });
    }
}
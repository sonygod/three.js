import js.QUnit.*;
import js.Math.*;

class EulerTest {
    static function matrixEquals4(a:Matrix4_obj, b:Matrix4_obj, ?tolerance:Float) {
        if (tolerance == null) {
            tolerance = 0.0001;
        }
        if (a.elements.length != b.elements.length) {
            return false;
        }
        for (i in 0...a.elements.length) {
            if (Math.abs(a.elements[i] - b.elements[i]) > tolerance) {
                return false;
            }
        }
        return true;
    }

    static function quatEquals(a:Quaternion_obj, b:Quaternion_obj, ?tolerance:Float) {
        if (tolerance == null) {
            tolerance = 0.0001;
        }
        var diff = Math.abs(a.x - b.x) + Math.abs(a.y - b.y) + Math.abs(a.z - b.z) + Math.abs(a.w - b.w);
        return (diff < tolerance);
    }

    static function test() {
        module('Maths', function() {
            module('Euler', function() {
                // INSTANCING
                test('Instancing', function() {
                    var a = new Euler();
                    ok(a.equals(eulerZero), 'Passed!');
                    ok(!a.equals(eulerAxyz), 'Passed!');
                    ok(!a.equals(eulerAzyx), 'Passed!');
                });

                // STATIC STUFF

                test('DEFAULT_ORDER', function() {
                    equal(Euler.DEFAULT_ORDER, 'XYZ', 'Passed!');
                });

                // PROPERTIES STUFF
                test('x', function() {
                    var a = new Euler();
                    ok(a.x == 0, 'Passed!');

                    a = new Euler(1, 2, 3);
                    ok(a.x == 1, 'Passed!');

                    a = new Euler(4, 5, 6, 'XYZ');
                    ok(a.x == 4, 'Passed!');

                    a = new Euler(7, 8, 9, 'XYZ');
                    a.x = 10;
                    ok(a.x == 10, 'Passed!');

                    a = new Euler(11, 12, 13, 'XYZ');
                    var b = false;
                    a._onChange(function() {
                        b = true;
                    });
                    a.x = 14;
                    ok(b, 'Passed!');
                    ok(a.x == 14, 'Passed!');
                });

                test('y', function() {
                    var a = new Euler();
                    ok(a.y == 0, 'Passed!');

                    a = new Euler(1, 2, 3);
                    ok(a.y == 2, 'Passed!');

                    a = new Euler(4, 5, 6, 'XYZ');
                    ok(a.y == 5, 'Passed!');

                    a = new Euler(7, 8, 9, 'XYZ');
                    a.y = 10;
                    ok(a.y == 10, 'Passed!');

                    a = new Euler(11, 12, 13, 'XYZ');
                    var b = false;
                    a._onChange(function() {
                        b = true;
                    });
                    a.y = 14;
                    ok(b, 'Passed!');
                    ok(a.y == 14, 'Passed!');
                });

                test('z', function() {
                    var a = new Euler();
                    ok(a.z == 0, 'Passed!');

                    a = new Euler(1, 2, 3);
                    ok(a.z == 3, 'Passed!');

                    a = new Euler(4, 5, 6, 'XYZ');
                    ok(a.z == 6, 'Passed!');

                    a = new Euler(7, 8, 9, 'XYZ');
                    a.z = 10;
                    ok(a.z == 10, 'Passed!');

                    a = new Euler(11, 12, 13, 'XYZ');
                    var b = false;
                    a._onChange(function() {
                        b = true;
                    });
                    a.z = 14;
                    ok(b, 'Passed!');
                    ok(a.z == 14, 'Passed!');
                });

                test('order', function() {
                    var a = new Euler();
                    ok(a.order == Euler.DEFAULT_ORDER, 'Passed!');

                    a = new Euler(1, 2, 3);
                    ok(a.order == Euler.DEFAULT_ORDER, 'Passed!');

                    a = new Euler(4, 5, 6, 'YZX');
                    ok(a.order == 'YZX', 'Passed!');

                    a = new Euler(7, 8, 9, 'YZX');
                    a.order = 'ZXY';
                    ok(a.order == 'ZXY', 'Passed!');

                    a = new Euler(11, 12, 13, 'YZX');
                    var b = false;
                    a._onChange(function() {
                        b = true;
                    });
                    a.order = 'ZXY';
                    ok(b, 'Passed!');
                    ok(a.order == 'ZXY', 'Passed!');
                });

                // PUBLIC STUFF
                test('isEuler', function() {
                    var a = new Euler();
                    ok(a.isEuler, 'Passed!');
                    var b = new Vector3();
                    ok(!b.isEuler, 'Passed!');
                });

                test('clone/copy/equals', function() {
                    var a = eulerAxyz.clone();
                    ok(a.equals(eulerAxyz), 'Passed!');
                    ok(!a.equals(eulerZero), 'Passed!');
                    ok(!a.equals(eulerAzyx), 'Passed!');

                    a.copy(eulerAzyx);
                    ok(a.equals(eulerAzyx), 'Passed!');
                    ok(!a.equals(eulerAxyz), 'Passed!');
                    ok(!a.equals(eulerZero), 'Passed!');
                });

                test('Quaternion.setFromEuler/Euler.setFromQuaternion', function() {
                    var testValues = [eulerZero, eulerAxyz, eulerAzyx];
                    for (i in 0...testValues.length) {
                        var v = testValues[i];
                        var q = new Quaternion().setFromEuler(v);

                        var v2 = new Euler().setFromQuaternion(q, v.order);
                        var q2 = new Quaternion().setFromEuler(v2);
                        ok(quatEquals(q, q2), 'Passed!');
                    }
                });

                test('Matrix4.makeRotationFromEuler/Euler.setFromRotationMatrix', function() {
                    var testValues = [eulerZero, eulerAxyz, eulerAzyx];
                    for (i in 0...testValues.length) {
                        var v = testValues[i];
                        var m = new Matrix4().makeRotationFromEuler(v);

                        var v2 = new Euler().setFromRotationMatrix(m, v.order);
                        var m2 = new Matrix4().makeRotationFromEuler(v2);
                        ok(matrixEquals4(m, m2, 0.0001), 'Passed!');
                    }
                });

                test('Euler.setFromVector3', function() {
                    // setFromVector3(v, order = this._order)
                    ok(false, 'everything\'s gonna be alright');
                });

                test('reorder', function() {
                    var testValues = [eulerZero, eulerAxyz, eulerAzyx];
                    for (i in 0...testValues.length) {
                        var v = testValues[i];
                        var q = new Quaternion().setFromEuler(v);

                        v.reorder('YZX');
                        var q2 = new Quaternion().setFromEuler(v);
                        ok(quatEquals(q, q2), 'Passed!');

                        v.reorder('ZXY');
                        var q3 = new Quaternion().setFromEuler(v);
                        ok(quatEquals(q, q3), 'Passed!');
                    }
                });

                test('set/get properties, check callbacks', function() {
                    var a = new Euler();
                    a._onChange(function() {
                        step('set: onChange called');
                    });

                    a.x = 1;
                    a.y = 2;
                    a.z = 3;
                    a.order = 'ZYX';

                    strictEqual(a.x, 1, 'get: check x');
                    strictEqual(a.y, 2, 'get: check y');
                    strictEqual(a.z, 3, 'get: check z');
                    strictEqual(a.order, 'ZYX', 'get: check order');

                    verifySteps(Array.fill(4, 'set: onChange called'));
                });

                test('clone/copy, check callbacks', function() {
                    var a = new Euler(1, 2, 3, 'ZXY');
                    var b = new Euler(4, 5, 6, 'XZY');
                    var cbSucceed = function() {
                        ok(true);
                        step('onChange called');
                    };

                    var cbFail = function() {
                        ok(false);
                    };

                    a._onChange(cbFail);
                    b._onChange(cbFail);

                    // clone doesn't trigger onChange
                    a = b.clone();
                    ok(a.equals(b), 'clone: check if a equals b');

                    // copy triggers onChange once
                    a = new Euler(1, 2, 3, 'ZXY');
                    a._onChange(cbSucceed);
                    a.copy(b);
                    ok(a.equals(b), 'copy: check if a equals b');
                    verifySteps(['onChange called']);
                });

                test('toArray', function() {
                    var order = 'YXZ';
                    var a = new Euler(x, y, z, order);

                    var array = a.toArray();
                    strictEqual(array[0], x, 'No array, no offset: check x');
                    strictEqual(array[1], y, 'No array, no offset: check y');
                    strictEqual(array[2], z, 'No array, no offset: check z');
                    strictEqual(array[3], order, 'No array, no offset: check order');

                    array = [];
                    a.toArray(array);
                    strictEqual(array[0], x, 'With array, no offset: check x');
                    strictEqual(array[1], y, 'With array, no offset: check y');
                    strictEqual(array[2], z, 'With array, no offset: check z');
                    strictEqual(array[3], order, 'With array, no offset: check order');

                    array = [];
                    a.toArray(array, 1);
                    strictEqual(array[0], null, 'With array and offset: check [0]');
                    strictEqual(array[1], x, 'With array and offset: check x');
                    strictEqual(array[2], y, 'With array and offset: check y');
                    strictEqual(array[3], z, 'With array and offset: check z');
                    strictEqual(array[4], order, 'With array and offset: check order');
                });

                test('fromArray', function() {
                    var a = new Euler();
                    var array = [x, y, z];
                    var cb = function() {
                        step('onChange called');
                    };

                    a._onChange(cb);

                    a.fromArray(array);
                    strictEqual(a.x, x, 'No order: check x');
                    strictEqual(a.y, y, 'No order: check y');
                    strictEqual(a.z, z, 'No order: check z');
                    strictEqual(a.order, 'XYZ', 'No order: check order');

                    a = new Euler();
                    array = [x, y, z, 'ZXY'];
                    a._onChange(cb);
                    a.fromArray(array);
                    strictEqual(a.x, x, 'With order: check x');
                    strictEqual(a.y, y, 'With order: check y');
                    strictEqual(a.z, z, 'With order: check z');
                    strictEqual(a.order, 'ZXY', 'With order: check order');

                    verifySteps(Array.fill(2, 'onChange called'));
                });

                test('_onChange', function() {
                    var f = function() {
                    };

                    var a = new Euler(11, 12, 13, 'XYZ');
                    a._onChange(f);
                    ok(a._onChangeCallback == f, 'Passed!');
                });

                test('_onChangeCallback', function() {
                    var b = false;
                    var a = new Euler(11, 12, 13, 'XYZ');
                    var f = function() {
                        b = true;
                        ok(a == this, 'Passed!');
                    };

                    a._onChangeCallback = f;
                    ok(a._onChangeCallback == f, 'Passed!');

                    a._onChangeCallback();
                    ok(b, 'Passed!');
                });

                test('iterable', function() {
                    var e = new Euler(0.5, 0.75, 1, 'YZX');
                    var array = [...e];
                    strictEqual(array[0], 0.5, 'Euler is iterable.');
                    strictEqual(array[1], 0.75, 'Euler is iterable.');
                    strictEqual(array[2], 1, 'Euler is iterable.');
                    strictEqual(array[3], 'YZX', 'Euler is iterable.');
                });
            });
        });
    }
}

class Main {
    static function main() {
        EulerTest.test();
    }
}

class Vector3_obj {
    var x:Float;
    var y:Float;
    var z:Float;
    function new(?x:Float, ?y:Float, ?z:Float) {
        if (x == null) {
            x = 0;
        }
        if (y == null) {
            y = 0;
        }
        if (z == null) {
            z = 0;
        }
        this.x = x;
        this.y = y;
        this.z = z;
    }
    function clone() {
        return new Vector3_obj(this.x, this.y, this.z);
    }
    function copy(v:Vector3_obj) {
        this.x = v.x;
        this.y = v.y;
        this.z = v.z;
    }
    function equals(v:Vector3_obj, ?tolerance:Float) {
        if (tolerance == null) {
            tolerance = 0.000001;
        }
        return (Math.abs(this.x - v.x) <= tolerance) && (Math.abs(this.y - v.y) <= tolerance) && (Math.abs(this.z - v.z) <= tolerance);
    }
}

class Quaternion_obj {
    var x:Float;
    var y:Float;
    var z:Float;
    var w:Float;
    function new(?x:Float, ?y:Float, ?z:Float, ?w:Float) {
        if (x == null) {
            x = 0;
        }
        if (y == null) {
            y = 0;
        }
        if (z == null) {
            z = 0;
        }
        if (w == null) {
            w = 1;
        }
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }
    function clone() {
        return new Quaternion_obj(this.x, this.y, this.z, this.w);
    }
    function copy(q:Quaternion_obj) {
        this.x = q.x;
        this.y = q.y;
        this.z = q.z;
        this.w = q.w;
    }
    function setFromEuler(euler:Euler_obj) {
        var x = euler.x;
        var y = euler.y;
        var z = euler.z;
        var order = euler.order;

        var cos = Math.cos;
        var sin = Math.sin;

        if (order == 'XYZ') {
            var xy = x * y;
            var zw = z * w;
            var xw = x * w;
            var yz = y * z;
            var xz = x * z;
            var yw = y * w;
            this.x = cos(y) * cos(z) * sin(x) + sin(z) * sin(w) + cos(z) * sin(y) * cos(x);
            this.y = sin(x) * cos(y) * cos(z) + sin(z) * sin(y) * cos(w) - cos(z) * sin(w) * cos(y);
            this.z = cos(x) * sin(y) * cos(z) + sin(x) * sin(z) * cos(w) + cos(x) * cos(z) * sin(y) - sin(x) * sin(y) * sin(z);
            this.w = -sin(x) * sin(y) * sin(z) + sin(x) * cos(y) * cos(z) + cos(x) * cos(y) * sin(z) + cos(x) * sin(y) * sin(w);
        } else if (order == 'YXZ') {
            var xy = x * y;
            var xz = x * z;
            var yw = y * w;
            var yz = y * z;
            var zw = z * w;
            var xw = x * w;
            this.x = sin(x) * cos(y) * cos(z) + cos(x)
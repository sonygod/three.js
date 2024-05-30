import MathUtils from js.MathUtils;
import Matrix4 from js.Matrix4;
import Vector3 from js.Vector3;
import Euler from js.Euler;
import Quaternion from js.Quaternion;

function matrixEquals4(a, b, tolerance) {
    if (a.length != b.length) {
        return false;
    }

    for (i in 0...a.length) {
        const delta = a[i] - b[i];
        if (delta > tolerance) {
            return false;
        }
    }

    return true;
}

function eulerEquals(a, b, tolerance) {
    const diff = Math.abs(a.x - b.x) + Math.abs(a.y - b.y) + Math.abs(a.z - b.z);
    return (diff < tolerance);
}

class QUnit {
    public static function module(name, callback) {
        callback();
    }
}

class Test {
    public function new() {
        QUnit.module('Maths', function() {
            QUnit.module('Matrix4', function() {
                // INSTANCING
                QUnit.test('Instancing', function(assert) {
                    var a = new Matrix4();
                    assert.equal(a.determinant(), 1, 'Passed!');

                    var b = new Matrix4();
                    b.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                    assert.equal(b.elements[0], 0);
                    assert.equal(b.elements[1], 4);
                    assert.equal(b.elements[2], 8);
                    assert.equal(b.elements[3], 12);
                    assert.equal(b.elements[4], 1);
                    assert.equal(b.elements[5], 5);
                    assert.equal(b.elements[6], 9);
                    assert.equal(b.elements[7], 13);
                    assert.equal(b.elements[8], 2);
                    assert.equal(b.elements[9], 6);
                    assert.equal(b.elements[10], 10);
                    assert.equal(b.elements[11], 14);
                    assert.equal(b.elements[12], 3);
                    assert.equal(b.elements[13], 7);
                    assert.equal(b.elements[14], 11);
                    assert.equal(b.elements[15], 15);

                    assert.notEqual(a, b, 'Passed!');

                    var c = new Matrix4(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                    assert.equal(c.elements[0], 0);
                    assert.equal(c.elements[1], 4);
                    assert.equal(c.elements[2], 8);
                    assert.equal(c.elements[3], 12);
                    assert.equal(c.elements[4], 1);
                    assert.equal(c.elements[5], 5);
                    assert.equal(c.elements[6], 9);
                    assert.equal(c.elements[7], 13);
                    assert.equal(c.elements[8], 2);
                    assert.equal(c.elements[9], 6);
                    assert.equal(c.elements[10], 10);
                    assert.equal(c.elements[11], 14);
                    assert.equal(c.elements[12], 3);
                    assert.equal(c.elements[13], 7);
                    assert.equal(c.elements[14], 11);
                    assert.equal(c.elements[15], 15);

                    assert.notEqual(a, c, 'Passed!');
                });

                // PUBLIC STUFF
                QUnit.test('isMatrix4', function(assert) {
                    var a = new Matrix4();
                    assert.isTrue(a.isMatrix4, 'Passed!');

                    var b = new Vector3();
                    assert.isFalse(b.isMatrix4, 'Passed!');
                });

                QUnit.test('set', function(assert) {
                    var b = new Matrix4();
                    assert.equal(b.determinant(), 1, 'Passed!');

                    b.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                    assert.equal(b.elements[0], 0);
                    assert.equal(b.elements[1], 4);
                    assert.equal(b.elements[2], 8);
                    assert.equal(b.elements[3], 12);
                    assert.equal(b.elements[4], 1);
                    assert.equal(b.elements[5], 5);
                    assert.equal(b.elements[6], 9);
                    assert.equal(b.elements[7], 13);
                    assert.equal(b.elements[8], 2);
                    assert.equal(b.elements[9], 6);
                    assert.equal(b.elements[10], 10);
                    assert.equal(b.elements[11], 14);
                    assert.equal(b.elements[12], 3);
                    assert.equal(b.elements[13], 7);
                    assert.equal(b.elements[14], 11);
                    assert.equal(b.elements[15], 15);
                });

                QUnit.test('identity', function(assert) {
                    var b = new Matrix4();
                    b.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
                    assert.equal(b.elements[0], 0);
                    assert.equal(b.elements[1], 4);
                    assert.equal(b.elements[2], 8);
                    assert.equal(b.elements[3], 12);
                    assert.equal(b.elements[4], 1);
                    assert.equal(b.elements[5], 5);
                    assert.equal(b.elements[6], 9);
                    assert.equal(b.elements[7], 13);
                    assert.equal(b.elements[8], 2);
                    assert.equal(b.elements[9], 6);
                    assert.equal(b.elements[10], 10);
                    assert.equal(b.elements[11], 14);
                    assert.equal(b.elements[12], 3);
                    assert.equal(b.elements[13], 7);
                    assert.equal(b.elements[14], 11);
                    assert.equal(b.elements[15], 15);

                    var a = new Matrix4();
                    assert.notEqual(a, b, 'Passed!');

                    b.identity();
                    assert.equal(a, b, 'Passed!');
                });

                QUnit.test('clone', function(assert) {
                    var a = new Matrix4();
                    a.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
                    var b = a.clone();

                    assert.equal(a, b, 'Passed!');

                    // ensure that it is a true copy
                    a.elements[0] = 2;
                    assert.notEqual(a, b, 'Passed!');
                });

                QUnit.test('copy', function(assert) {
                    var a = new Matrix4();
                    a.set(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
                    var b = new Matrix4();
                    b.copy(a);

                    assert.equal(a, b, 'Passed!');

                    // ensure that it is a true copy
                    a.elements[0] = 2;
                    assert.notEqual(a, b, 'Passed!');
                });

                QUnit.test('setFromMatrix3', function(assert) {
                    var a = new Matrix3();
                    a.set(0, 1, 2, 3, 4, 5, 6, 7, 8);
                    var b = new Matrix4();
                    var c = new Matrix4();
                    c.set(0, 1, 2, 0, 3, 4, 5, 0, 6, 7, 8, 0, 0, 0, 1);
                    b.setFromMatrix3(a);
                    assert.isTrue(b.equals(c));
                });

                QUnit.test('copyPosition', function(assert) {
                    var a = new Matrix4();
                    a.set(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
                    var b = new Matrix4();
                    b.set(1, 2, 3, 0, 5, 6, 7, 0, 9, 10, 11, 0, 13, 14, 15, 16);

                    assert.notEqual(a, b, 'a and b initially not equal');

                    b.copyPosition(a);
                    assert.equal(a, b, 'a and b equal after copyPosition()');
                });

                QUnit.test('makeBasis/extractBasis', function(assert) {
                    var identityBasis = [new Vector3(1, 0, 0), new Vector3(0, 1, 0), new Vector3(0, 0, 1)];
                    var a = new Matrix4();
                    a.makeBasis(identityBasis[0], identityBasis[1], identityBasis[2]);
                    var identity = new Matrix4();
                    assert.equal(a, identity, 'Passed!');

                    var testBases = [
                        [new Vector3(0, 1, 0), new Vector3(-1, 0, 0), new Vector3(0, 0, 1)]
                    ];
                    for (i in 0...testBases.length) {
                        var testBasis = testBases[i];
                        var b = new Matrix4();
                        b.makeBasis(testBasis[0], testBasis[1], testBasis[2]);
                        var outBasis = [new Vector3(), new Vector3(), new Vector3()];
                        b.extractBasis(outBasis[0], outBasis[1], outBasis[2]);
                        // check what goes in, is what comes out.
                        for (j in 0...outBasis.length) {
                            assert.isTrue(outBasis[j].equals(testBasis[j]), 'Passed!');
                        }

                        // get the basis out the hard war
                        for (j in 0...identityBasis.length) {
                            outBasis[j].copy(identityBasis[j]);
                            outBasis[j].applyMatrix4(b);
                        }

                        // did the multiply method of basis extraction work?
                        for (j in 0...outBasis.length) {
                            assert.isTrue(outBasis[j].equals(testBasis[j]), 'Passed!');
                        }
                    }
                });

                QUnit.test('makeRotationFromEuler/extractRotation', function(assert) {
                    var testValues = [
                        new Euler(0, 0, 0, 'XYZ'),
                        new Euler(1, 0, 0, 'XYZ'),
                        new Euler(0, 1, 0, 'ZYX'),
                        new Euler(0, 0, 0.5, 'YZX'),
                        new Euler(0, 0, -0.5, 'YZX')
                    ];

                    for (i in 0...testValues.length) {
                        var v = testValues[i];

                        var m = new Matrix4();
                        m.makeRotationFromEuler(v);

                        var v2 = new Euler();
                        v2.setFromRotationMatrix(m, v.order);
                        var m2 = new Matrix4();
                        m2.makeRotationFromEuler(v2);

                        assert.isTrue(m.equals(m2, MathUtils.EPS), 'makeRotationFromEuler #' + i + ': original and Euler-derived matrices are equal');
                        assert.isTrue(v.equals(v2, MathUtils.EPS), 'makeRotationFromEuler #' + i + ': original and matrix-derived Eulers are equal');

                        var m3 = new Matrix4();
                        m3.extractRotation(m2);
                        var v3 = new Euler();
                        v3.setFromRotationMatrix(m3, v.order);

                        assert.isTrue(m.equals(m3, MathUtils.EPS), 'extractRotation #' + i + ': original and extracted matrices are equal');
                        assert.isTrue(v.equals(v3, MathUtils.EPS), 'extractRotation #' + i + ': original and extracted Eulers are equal');
                    }
                });

                QUnit.test('makeRotationFromQuaternion', function(assert) {
                    // makeRotationFromQuaternion(q)
                    assert.isTrue(false, 'everything\'s gonna be alright');
                });

                QUnit.test('lookAt', function(assert) {
                    var a = new Matrix4();
                    var expected = new Matrix4();
                    expected.identity();
                    var eye = new Vector3(0, 0, 0);
                    var target = new Vector3(0, 1, -1);
                    var up = new Vector3(0, 1, 0);

                    a.lookAt(eye, target, up);
                    var rotation = new Euler();
                    rotation.setFromRotationMatrix(a);
                    assert.numEqual(rotation.x * (180 / Math.PI), 45, 'Check the rotation');

                    // eye and target are in the same position
                    eye.copy(target);
                    a.lookAt(eye, target, up);
                    assert.isTrue(a.equals(expected), 'Check the result for eye == target');

                    // up and z are parallel
                    eye.set(0, 1, 0);
                    target.set(0, 0, 0);
                    a.lookAt(eye, target, up);
                    expected.set(
                        1, 0, 0, 0,
                        0, 0.0001, 1, 0,
                        0, -1, 0.0001, 0,
                        0, 0, 0, 1
                    );
                    assert.isTrue(a.equals(expected), 'Check the result for when up and z are parallel');
                });

                QUnit.test('multiply', function(assert) {
                    var lhs = new Matrix4();
                    lhs.set(2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53);
                    var rhs = new Matrix4();
                    rhs.set(59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131);

                    lhs.multiply(rhs);

                    assert.equal(lhs.elements[0], 1585);
                    assert.equal(lhs.elements[1], 5318);
                    assert.equal(lhs.elements[2], 10514);
                    assert.equal(lhs.elements[3], 15894);
                    assert.equal(lhs.elements[4], 1655);
                    assert.equal(lhs.elements[5], 5562);
                    assert.equal(lhs.elements[6], 11006);
                    assert.equal(lhs.elements[7], 16634);
                    assert.equal(lhs.elements[8], 1787);
                    assert.equal(lhs.elements[9], 5980);
                    assert.equal(lhs.elements[10], 11840);
                    assert.equal(lhs.elements[11], 17888);
                    assert.equal(lhs.elements[12], 1861);
                    assert.equal(lhs.elements[13], 6246);
                    assert.equal(lhs.elements[14], 12378);
                    assert.equal(lhs.elements[15], 18710);
                });

                QUnit.test('premultiply', function(assert) {
                    var lhs = new Matrix4();
                    lhs.set(2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53);
                    var rhs = new Matrix4();
                    rhs
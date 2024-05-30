package;

import js.Browser;
import js.Lib;

class Matrix3 {
    public var elements:Array<Float>;

    public function new() {
        this.elements = [0, 0, 0, 0, 0, 0, 0, 0, 0];
    }

    public function set(n11:Float, n12:Float, n13:Float, n21:Float, n22:Float, n23:Float, n31:Float, n32:Float, n33:Float):Matrix3 {
        var te = this.elements;

        te[0] = n11; te[3] = n12; te[6] = n13;
        te[1] = n21; te[4] = n22; te[7] = n23;
        te[2] = n31; te[5] = n32; te[8] = n33;

        return this;
    }

    public function identity():Matrix3 {
        this.set(
            1, 0, 0,
            0, 1, 0,
            0, 0, 1
        );

        return this;
    }

    public function clone():Matrix3 {
        return new Matrix3().fromArray(this.elements);
    }

    public function copy(m:Matrix3):Matrix3 {
        var te = this.elements;
        var me = m.elements;

        te[0] = me[0]; te[1] = me[1]; te[2] = me[2];
        te[3] = me[3]; te[4] = me[4]; te[5] = me[5];
        te[6] = me[6]; te[7] = me[7]; te[8] = me[8];

        return this;
    }

    public function setFromMatrix4(m:Matrix4):Matrix3 {
        var me = m.elements;

        this.set(
            me[0], me[4], me[8],
            me[1], me[5], me[9],
            me[2], me[6], me[10]
        );

        return this;
    }

    public function multiply(m:Matrix3):Matrix3 {
        return this.multiplyMatrices(this, m);
    }

    public function premultiply(m:Matrix3):Matrix3 {
        return this.multiplyMatrices(m, this);
    }

    public function multiplyMatrices(a:Matrix3, b:Matrix3):Matrix3 {
        var ae = a.elements;
        var be = b.elements;
        var te = this.elements;

        var a11 = ae[0], a12 = ae[3], a13 = ae[6];
        var a21 = ae[1], a22 = ae[4], a23 = ae[7];
        var a31 = ae[2], a32 = ae[5], a33 = ae[8];

        var b11 = be[0], b12 = be[3], b13 = be[6];
        var b21 = be[1], b22 = be[4], b23 = be[7];
        var b31 = be[2], b32 = be[5], b33 = be[8];

        te[0] = a11 * b11 + a12 * b21 + a13 * b31;
        te[3] = a11 * b12 + a12 * b22 + a13 * b32;
        te[6] = a11 * b13 + a12 * b23 + a13 * b33;

        te[1] = a21 * b11 + a22 * b21 + a23 * b31;
        te[4] = a21 * b12 + a22 * b22 + a23 * b32;
        te[7] = a21 * b13 + a22 * b23 + a23 * b33;

        te[2] = a31 * b11 + a32 * b21 + a33 * b31;
        te[5] = a31 * b12 + a32 * b22 + a33 * b32;
        te[8] = a31 * b13 + a32 * b23 + a33 * b33;

        return this;
    }

    public function multiplyScalar(s:Float):Matrix3 {
        var te = this.elements;

        te[0] *= s; te[3] *= s; te[6] *= s;
        te[1] *= s; te[4] *= s; te[7] *= s;
        te[2] *= s; te[5] *= s; te[8] *= s;

        return this;
    }

    public function determinant():Float {
        var te = this.elements;

        var a = te[0], b = te[1], c = te[2];
        var d = te[3], e = te[4], f = te[5];
        var g = te[6], h = te[7], i = te[8];

        return a * e * i - a * f * h - b * d * i + b * f * g + c * d * h - c * e * g;
    }

    public function invert():Matrix3 {
        var te = this.elements;
        var det = this.determinant();

        if (det === 0) {
            console.warn('Matrix3.invert(): can\'t invert matrix, determinant is 0');
            this.identity();
            return this;
        }

        var invDet = 1 / det;

        te[0] = (te[4] * te[8] - te[5] * te[7]) * invDet;
        te[1] = - (te[1] * te[8] - te[2] * te[7]) * invDet;
        te[2] = (te[1] * te[5] - te[2] * te[4]) * invDet;
        te[3] = - (te[3] * te[8] - te[5] * te[6]) * invDet;
        te[4] = (te[0] * te[8] - te[2] * te[6]) * invDet;
        te[5] = - (te[0] * te[5] - te[2] * te[3]) * invDet;
        te[6] = (te[3] * te[7] - te[4] * te[6]) * invDet;
        te[7] = - (te[0] * te[7] - te[1] * te[6]) * invDet;
        te[8] = (te[0] * te[4] - te[1] * te[3]) * invDet;

        return this;
    }

    public function transpose():Matrix3 {
        var te = this.elements;
        var tmp:Float;

        tmp = te[1]; te[1] = te[3]; te[3] = tmp;
        tmp = te[2]; te[2] = te[6]; te[6] = tmp;
        tmp = te[5]; te[5] = te[7]; te[7] = tmp;

        return this;
    }

    public function getNormalMatrix(matrix4:Matrix4):Matrix3 {
        return this.setFromMatrix4(matrix4).getInverse(this).transpose();
    }

    public function transposeIntoArray(r:Array<Float>):Array<Float> {
        var te = this.elements;

        r[0] = te[0];
        r[1] = te[3];
        r[2] = te[6];
        r[3] = te[1];
        r[4] = te[4];
        r[5] = te[7];
        r[6] = te[2];
        r[7] = te[5];
        r[8] = te[8];

        return this;
    }

    public function setUvTransform(tx:Float, ty:Float, sx:Float, sy:Float, rotation:Float, cx:Float, cy:Float):Matrix3 {
        var c = Math.cos(rotation);
        var s = Math.sin(rotation);

        this.set(
            sx * c, sx * s, - sx * (c * cx + s * cy) + cx + tx,
            - sy * s, sy * c, - sy * (- s * cx + c * cy) + cy + ty,
            0, 0, 1
        );

        return this;
    }

    public function scale(sx:Float, sy:Float):Matrix3 {
        var te = this.elements;

        te[0] *= sx; te[3] *= sx; te[6] *= sx;
        te[1] *= sy; te[4] *= sy; te[7] *= sy;

        return this;
    }

    public function rotate(theta:Float):Matrix3 {
        var c = Math.cos(theta);
        var s = Math.sin(theta);
        var te = this.elements;

        var a11 = te[0], a12 = te[3], a13 = te[6];
        var a21 = te[1], a22 = te[4], a23 = te[7];

        te[0] = c * a11 + s * a21;
        te[3] = c * a12 + s * a22;
        te[6] = c * a13 + s * a23;

        te[1] = - s * a11 + c * a21;
        te[4] = - s * a12 + c * a22;
        te[7] = - s * a13 + c * a23;

        return this;
    }

    public function translate(tx:Float, ty:Float):Matrix3 {
        var te = this.elements;

        te[0] += tx * te[2]; te[3] += tx * te[5]; te[6] += tx * te[8];
        te[1] += ty * te[2]; te[4] += ty * te[5]; te[7] += ty * te[8];

        return this;
    }

    public function equals(matrix:Matrix3):Bool {
        var te = this.elements;
        var me = matrix.elements;

        for (i in 0...9) {
            if (te[i] != me[i]) return false;
        }

        return true;
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Matrix3 {
        var te = this.elements;

        for (i in 0...9) {
            te[i] = array[i + offset];
        }

        return this;
    }

    public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
        var te = this.elements;

        for (i in 0...9) {
            array[i + offset] = te[i];
        }

        return array;
    }
}

class Matrix4 {
    // Matrix4 类的实现与 Matrix3 类类似，这里省略了具体实现
}

class Vector2 {
    // Vector2 类的实现与 Matrix3 类类似，这里省略了具体实现
}

class QUnit {
    // QUnit 类的实现与 Matrix3 类类似，这里省略了具体实现
}
class Matrix3 {
    public var elements:Array<Float> = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0];

    public function new(n11:Float, n12:Float, n13:Float, n21:Float, n22:Float, n23:Float, n31:Float, n32:Float, n33:Float) {
        if (n11 != null) {
            this.set(n11, n12, n13, n21, n22, n23, n31, n32, n33);
        }
    }

    public function set($n11:Float, $n12:Float, $n13:Float, $n21:Float, $n22:Float, $n23:Float, $n31:Float, $n32:Float, $n33:Float):Matrix3 {
        var te = this.elements;
        te[0] = $n11; te[1] = $n21; te[2] = $n31;
        te[3] = $n12; te[4] = $n22; te[5] = $n32;
        te[6] = $n13; te[7] = $n23; te[8] = $n33;
        return this;
    }

    public function identity():Matrix3 {
        this.set(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
        return this;
    }

    public function copy(m:Matrix3):Matrix3 {
        var te = this.elements;
        var me = m.elements;
        te[0] = me[0]; te[1] = me[1]; te[2] = me[2];
        te[3] = me[3]; te[4] = me[4]; te[5] = me[5];
        te[6] = me[6]; te[7] = me[7]; te[8] = me[8];
        return this;
    }

    public function extractBasis(xAxis:Matrix3, yAxis:Matrix3, zAxis:Matrix3):Matrix3 {
        xAxis.setFromMatrix3Column(this, 0);
        yAxis.setFromMatrix3Column(this, 1);
        zAxis.setFromMatrix3Column(this, 2);
        return this;
    }

    public function setFromMatrix4(m:Matrix3):Matrix3 {
        var me = m.elements;
        this.set(me[0], me[4], me[8], me[1], me[5], me[9], me[2], me[6], me[10]);
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
        var a = te[0], b = te[1], c = te[2],
            d = te[3], e = te[4], f = te[5],
            g = te[6], h = te[7], i = te[8];
        return a * e * i - a * f * h - b * d * i + b * f * g + c * d * h - c * e * g;
    }

    public function invert():Matrix3 {
        var te = this.elements,
            n11 = te[0], n21 = te[1], n31 = te[2],
            n12 = te[3], n22 = te[4], n32 = te[5],
            n13 = te[6], n23 = te[7], n33 = te[8],
            t11 = n33 * n22 - n32 * n23,
            t12 = n32 * n13 - n33 * n12,
            t13 = n23 * n12 - n22 * n13,
            det = n11 * t11 + n21 * t12 + n31 * t13;
        if (det == 0.0) return this.set(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        var detInv = 1.0 / det;
        te[0] = t11 * detInv;
        te[1] = (n31 * n23 - n33 * n21) * detInv;
        te[2] = (n32 * n21 - n31 * n22) * detInv;
        te[3] = t12 * detInv;
        te[4] = (n33 * n11 - n31 * n13) * detInv;
        te[5] = (n31 * n12 - n32 * n11) * detInv;
        te[6] = t13 * detInv;
        te[7] = (n21 * n13 - n23 * n11) * detInv;
        te[8] = (n22 * n11 - n21 * n12) * detInv;
        return this;
    }

    public function transpose():Matrix3 {
        var tmp:Float, m = this.elements;
        tmp = m[1]; m[1] = m[3]; m[3] = tmp;
        tmp = m[2]; m[2] = m[6]; m[6] = tmp;
        tmp = m[5]; m[5] = m[7]; m[7] = tmp;
        return this;
    }

    public function getNormalMatrix(matrix4:Matrix3):Matrix3 {
        return this.setFromMatrix4(matrix4).invert().transpose();
    }

    public function transposeIntoArray(r:Array<Float>):Matrix3 {
        var m = this.elements;
        r[0] = m[0];
        r[1] = m[3];
        r[2] = m[6];
        r[3] = m[1];
        r[4] = m[4];
        r[5] = m[7];
        r[6] = m[2];
        r[7] = m[5];
        r[8] = m[8];
        return this;
    }

    public function setUvTransform(tx:Float, ty:Float, sx:Float, sy:Float, rotation:Float, cx:Float, cy:Float):Matrix3 {
        var c = Math.cos(rotation);
        var s = Math.sin(rotation);
        this.set(
            sx * c, sx * s, - sx * (c * cx + s * cy) + cx + tx,
            - sy * s, sy * c, - sy * (-s * cx + c * cy) + cy + ty,
            0.0, 0.0, 1.0
        );
        return this;
    }

    public function scale(sx:Float, sy:Float):Matrix3 {
        this.premultiply(_m3.makeScale(sx, sy));
        return this;
    }

    public function rotate(theta:Float):Matrix3 {
        this.premultiply(_m3.makeRotation(-theta));
        return this;
    }

    public function translate(tx:Float, ty:Float):Matrix3 {
        this.premultiply(_m3.makeTranslation(tx, ty));
        return this;
    }

    public function makeTranslation(x:Float, y:Float):Matrix3 {
        if (x is Vector2) {
            this.set(
                1.0, 0.0, x.x,
                0.0, 1.0, x.y,
                0.0, 0.0, 1.0
            );
        } else {
            this.set(
                1.0, 0.0, x,
                0.0, 1.0, y,
                0.0, 0.0, 1.0
            );
        }
        return this;
    }

    public function makeRotation(theta:Float):Matrix3 {
        var c = Math.cos(theta);
        var s = Math.sin(theta);
        this.set(
            c, -s, 0.0,
            s, c, 0.0,
            0.0, 0.0, 1.0
        );
        return this;
    }

    public function makeScale(x:Float, y:Float):Matrix3 {
        this.set(
            x, 0.0, 0.0,
            0.0, y, 0.0,
            0.0, 0.0, 1.0
        );
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
        for (i in 0...9) {
            this.elements[i] = array[i + offset];
        }
        return this;
    }

    public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
        var te = this.elements;
        array[offset] = te[0];
        array[offset + 1] = te[1];
        array[offset + 2] = te[2];
        array[offset + 3] = te[3];
        array[offset + 4] = te[4];
        array[offset + 5] = te[5];
        array[offset + 6] = te[6];
        array[offset + 7] = te[7];
        array[offset + 8] = te[8];
        return array;
    }

    public function clone():Matrix3 {
        return new Matrix3().fromArray(this.elements);
    }
}

var _m3 = new Matrix3();

class Matrix3 {
    public static function main() {
        var m = new Matrix3(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0);
        trace(m);
    }
}
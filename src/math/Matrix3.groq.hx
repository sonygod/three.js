package three.math;

class Matrix3 {
    public var elements:Array<Float>;

    public function new(n11:Float = 1, n12:Float = 0, n13:Float = 0, n21:Float = 0, n22:Float = 1, n23:Float = 0, n31:Float = 0, n32:Float = 0, n33:Float = 1) {
        elements = [n11, n12, n13, n21, n22, n23, n31, n32, n33];
        if (n11 != null) {
            set(n11, n12, n13, n21, n22, n23, n31, n32, n33);
        }
    }

    public function set(n11:Float, n12:Float, n13:Float, n21:Float, n22:Float, n23:Float, n31:Float, n32:Float, n33:Float):Matrix3 {
        var te:Array<Float> = elements;
        te[0] = n11; te[1] = n21; te[2] = n31;
        te[3] = n12; te[4] = n22; te[5] = n32;
        te[6] = n13; te[7] = n23; te[8] = n33;
        return this;
    }

    public function identity():Matrix3 {
        set(1, 0, 0, 0, 1, 0, 0, 0, 1);
        return this;
    }

    public function copy(m:Matrix3):Matrix3 {
        var te:Array<Float> = elements;
        var me:Array<Float> = m.elements;
        te[0] = me[0]; te[1] = me[1]; te[2] = me[2];
        te[3] = me[3]; te[4] = me[4]; te[5] = me[5];
        te[6] = me[6]; te[7] = me[7]; te[8] = me[8];
        return this;
    }

    public function extractBasis(xAxis:Vector3, yAxis:Vector3, zAxis:Vector3):Matrix3 {
        xAxis.setFromMatrixColumn(this, 0);
        yAxis.setFromMatrixColumn(this, 1);
        zAxis.setFromMatrixColumn(this, 2);
        return this;
    }

    public function setFromMatrix4(m:Matrix4):Matrix3 {
        var me:Array<Float> = m.elements;
        set(me[0], me[4], me[8], me[1], me[5], me[9], me[2], me[6], me[10]);
        return this;
    }

    public function multiply(m:Matrix3):Matrix3 {
        return multiplyMatrices(this, m);
    }

    public function premultiply(m:Matrix3):Matrix3 {
        return multiplyMatrices(m, this);
    }

    public function multiplyMatrices(a:Matrix3, b:Matrix3):Matrix3 {
        var ae:Array<Float> = a.elements;
        var be:Array<Float> = b.elements;
        var te:Array<Float> = elements;

        var a11:Float = ae[0], a12:Float = ae[3], a13:Float = ae[6];
        var a21:Float = ae[1], a22:Float = ae[4], a23:Float = ae[7];
        var a31:Float = ae[2], a32:Float = ae[5], a33:Float = ae[8];

        var b11:Float = be[0], b12:Float = be[3], b13:Float = be[6];
        var b21:Float = be[1], b22:Float = be[4], b23:Float = be[7];
        var b31:Float = be[2], b32:Float = be[5], b33:Float = be[8];

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
        var te:Array<Float> = elements;
        te[0] *= s; te[3] *= s; te[6] *= s;
        te[1] *= s; te[4] *= s; te[7] *= s;
        te[2] *= s; te[5] *= s; te[8] *= s;
        return this;
    }

    public function determinant():Float {
        var te:Array<Float> = elements;
        var a:Float = te[0], b:Float = te[1], c:Float = te[2],
            d:Float = te[3], e:Float = te[4], f:Float = te[5],
            g:Float = te[6], h:Float = te[7], i:Float = te[8];

        return a * e * i - a * f * h - b * d * i + b * f * g + c * d * h - c * e * g;
    }

    public function invert():Matrix3 {
        var te:Array<Float> = elements,
            n11:Float = te[0], n21:Float = te[1], n31:Float = te[2],
            n12:Float = te[3], n22:Float = te[4], n32:Float = te[5],
            n13:Float = te[6], n23:Float = te[7], n33:Float = te[8],

            t11:Float = n33 * n22 - n32 * n23,
            t12:Float = n32 * n13 - n33 * n12,
            t13:Float = n23 * n12 - n22 * n13,

            det:Float = n11 * t11 + n21 * t12 + n31 * t13;

        if (det == 0) return set(0, 0, 0, 0, 0, 0, 0, 0, 0);

        var detInv:Float = 1 / det;

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
        var tmp:Float;
        var m:Array<Float> = elements;
        tmp = m[1]; m[1] = m[3]; m[3] = tmp;
        tmp = m[2]; m[2] = m[6]; m[6] = tmp;
        tmp = m[5]; m[5] = m[7]; m[7] = tmp;
        return this;
    }

    public function getNormalMatrix(matrix4:Matrix4):Matrix3 {
        return setFromMatrix4(matrix4).invert().transpose();
    }

    public function transposeIntoArray(r:Array<Float>):Matrix3 {
        var m:Array<Float> = elements;
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
        var c:Float = Math.cos(rotation);
        var s:Float = Math.sin(rotation);

        set(sx * c, sx * s, -sx * (c * cx + s * cy) + cx + tx,
            -sy * s, sy * c, -sy * (-s * cx + c * cy) + cy + ty,
            0, 0, 1);

        return this;
    }

    public function scale(sx:Float, sy:Float):Matrix3 {
        premultiply(_m3.makeScale(sx, sy));
        return this;
    }

    public function rotate(theta:Float):Matrix3 {
        premultiply(_m3.makeRotation(-theta));
        return this;
    }

    public function translate(tx:Float, ty:Float):Matrix3 {
        premultiply(_m3.makeTranslation(tx, ty));
        return this;
    }

    public function makeTranslation(x:Float, y:Float):Matrix3 {
        if (x.isVector2) {
            set(1, 0, x.x, 0, 1, x.y, 0, 0, 1);
        } else {
            set(1, 0, x, 0, 1, y, 0, 0, 1);
        }
        return this;
    }

    public function makeRotation(theta:Float):Matrix3 {
        var c:Float = Math.cos(theta);
        var s:Float = Math.sin(theta);
        set(c, -s, 0, s, c, 0, 0, 0, 1);
        return this;
    }

    public function makeScale(x:Float, y:Float):Matrix3 {
        set(x, 0, 0, 0, y, 0, 0, 0, 1);
        return this;
    }

    public function equals(matrix:Matrix3):Bool {
        var te:Array<Float> = elements;
        var me:Array<Float> = matrix.elements;
        for (i in 0...9) {
            if (te[i] != me[i]) return false;
        }
        return true;
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Matrix3 {
        for (i in 0...9) {
            elements[i] = array[i + offset];
        }
        return this;
    }

    public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
        var te:Array<Float> = elements;
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
        return new Matrix3().fromArray(elements);
    }
}

var _m3:Matrix3 = new Matrix3();
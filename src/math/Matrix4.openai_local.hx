import three.constants.WebGLCoordinateSystem;
import three.constants.WebGPUCoordinateSystem;
import three.math.Vector3;

class Matrix4 {
    public var elements:Array<Float>;

    public function new(?n11:Float, ?n12:Float, ?n13:Float, ?n14:Float, ?n21:Float, ?n22:Float, ?n23:Float, ?n24:Float, ?n31:Float, ?n32:Float, ?n33:Float, ?n34:Float, ?n41:Float, ?n42:Float, ?n43:Float, ?n44:Float) {
        elements = [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        ];
        if (n11 != null) {
            this.set(n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44);
        }
    }

    public function set(n11:Float, n12:Float, n13:Float, n14:Float, n21:Float, n22:Float, n23:Float, n24:Float, n31:Float, n32:Float, n33:Float, n34:Float, n41:Float, n42:Float, n43:Float, n44:Float):Matrix4 {
        elements = [
            n11, n12, n13, n14,
            n21, n22, n23, n24,
            n31, n32, n33, n34,
            n41, n42, n43, n44
        ];
        return this;
    }

    public function identity():Matrix4 {
        return this.set(
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        );
    }

    public function clone():Matrix4 {
        return new Matrix4().fromArray(elements);
    }

    public function copy(m:Matrix4):Matrix4 {
        elements = m.elements.copy();
        return this;
    }

    public function copyPosition(m:Matrix4):Matrix4 {
        elements[12] = m.elements[12];
        elements[13] = m.elements[13];
        elements[14] = m.elements[14];
        return this;
    }

    public function setFromMatrix3(m:Matrix3):Matrix4 {
        var me = m.elements;
        return this.set(
            me[0], me[3], me[6], 0,
            me[1], me[4], me[7], 0,
            me[2], me[5], me[8], 0,
            0, 0, 0, 1
        );
    }

    public function extractBasis(xAxis:Vector3, yAxis:Vector3, zAxis:Vector3):Matrix4 {
        xAxis.setFromMatrixColumn(this, 0);
        yAxis.setFromMatrixColumn(this, 1);
        zAxis.setFromMatrixColumn(this, 2);
        return this;
    }

    public function makeBasis(xAxis:Vector3, yAxis:Vector3, zAxis:Vector3):Matrix4 {
        return this.set(
            xAxis.x, yAxis.x, zAxis.x, 0,
            xAxis.y, yAxis.y, zAxis.y, 0,
            xAxis.z, yAxis.z, zAxis.z, 0,
            0, 0, 0, 1
        );
    }

    public function extractRotation(m:Matrix4):Matrix4 {
        var scaleX = 1 / _v1.setFromMatrixColumn(m, 0).length();
        var scaleY = 1 / _v1.setFromMatrixColumn(m, 1).length();
        var scaleZ = 1 / _v1.setFromMatrixColumn(m, 2).length();
        
        elements[0] = m.elements[0] * scaleX;
        elements[1] = m.elements[1] * scaleX;
        elements[2] = m.elements[2] * scaleX;
        elements[3] = 0;
        
        elements[4] = m.elements[4] * scaleY;
        elements[5] = m.elements[5] * scaleY;
        elements[6] = m.elements[6] * scaleY;
        elements[7] = 0;
        
        elements[8] = m.elements[8] * scaleZ;
        elements[9] = m.elements[9] * scaleZ;
        elements[10] = m.elements[10] * scaleZ;
        elements[11] = 0;
        
        elements[12] = 0;
        elements[13] = 0;
        elements[14] = 0;
        elements[15] = 1;
        
        return this;
    }

    public function makeRotationFromEuler(euler:Euler):Matrix4 {
        var te = elements;
        var x = euler.x, y = euler.y, z = euler.z;
        var a = Math.cos(x), b = Math.sin(x);
        var c = Math.cos(y), d = Math.sin(y);
        var e = Math.cos(z), f = Math.sin(z);

        switch(euler.order) {
            case 'XYZ':
                var ae = a * e, af = a * f, be = b * e, bf = b * f;
                te[0] = c * e; te[4] = - c * f; te[8] = d;
                te[1] = af + be * d; te[5] = ae - bf * d; te[9] = - b * c;
                te[2] = bf - ae * d; te[6] = be + af * d; te[10] = a * c;
                break;
            case 'YXZ':
                var ce = c * e, cf = c * f, de = d * e, df = d * f;
                te[0] = ce + df * b; te[4] = de * b - cf; te[8] = a * d;
                te[1] = a * f; te[5] = a * e; te[9] = - b;
                te[2] = cf * b - de; te[6] = df + ce * b; te[10] = a * c;
                break;
            case 'ZXY':
                var ce = c * e, cf = c * f, de = d * e, df = d * f;
                te[0] = ce - df * b; te[4] = - a * f; te[8] = de + cf * b;
                te[1] = cf + de * b; te[5] = a * e; te[9] = df - ce * b;
                te[2] = - a * d; te[6] = b; te[10] = a * c;
                break;
            case 'ZYX':
                var ae = a * e, af = a * f, be = b * e, bf = b * f;
                te[0] = c * e; te[4] = be * d - af; te[8] = ae * d + bf;
                te[1] = c * f; te[5] = bf * d + ae; te[9] = af * d - be;
                te[2] = - d; te[6] = b * c; te[10] = a * c;
                break;
            case 'YZX':
                var ac = a * c, ad = a * d, bc = b * c, bd = b * d;
                te[0] = c * e; te[4] = bd - ac * f; te[8] = bc * f + ad;
                te[1] = f; te[5] = a * e; te[9] = - b * e;
                te[2] = - d * e; te[6] = ad * f + bc; te[10] = ac - bd * f;
                break;
            case 'XZY':
                var ac = a * c, ad = a * d, bc = b * c, bd = b * d;
                te[0] = c * e; te[4] = - f; te[8] = d * e;
                te[1] = ac * f + bd; te[5] = a * e; te[9] = ad * f - bc;
                te[2] = bc * f - ad; te[6] = b * e; te[10] = bd * f + ac;
                break;
        }

        te[3] = 0;
        te[7] = 0;
        te[11] = 0;
        te[15] = 1;

        return this;
    }

    public function makeRotationFromQuaternion(q:Quaternion):Matrix4 {
        return this.compose(_zero, q, _one);
    }

    public function lookAt(eye:Vector3, target:Vector3, up:Vector3):Matrix4 {
        var te = elements;

        _z.subVectors(eye, target);

        if (_z.lengthSq() == 0) {
            _z.z = 1;
        }

        _z.normalize();
        _x.crossVectors(up, _z);

        if (_x.lengthSq() == 0) {
            if (Math.abs(up.z) == 1) {
                _z.x += 0.0001;
            } else {
                _z.z += 0.0001;
            }

            _z.normalize();
            _x.crossVectors(up, _z);
        }

        _x.normalize();
        _y.crossVectors(_z, _x);

        te[0] = _x.x; te[4] = _y.x; te[8] = _z.x;
        te[1] = _x.y; te[5] = _y.y; te[9] = _z.y;
        te[2] = _x.z; te[6] = _y.z; te[10] = _z.z;

        return this;
    }
}
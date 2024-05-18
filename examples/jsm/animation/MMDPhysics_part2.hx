Here is the converted Haxe code:
```
package three.js.examples.jsm.animation;

import Ammo.btTransform;
import Ammo.btQuaternion;
import Ammo.btVector3;
import three.Vector3;
import three.Matrix4;
import three.Quaternion;
import three.Euler;

class ResourceManager {
    private var threeVector3s:Array<Vector3> = [];
    private var threeMatrix4s:Array<Matrix4> = [];
    private var threeQuaternions:Array<Quaternion> = [];
    private var threeEulers:Array<Euler> = [];
    private var transforms:Array<btTransform> = [];
    private var quaternions:Array<btQuaternion> = [];
    private var vector3s:Array<btVector3> = [];

    public function new() {}

    public function allocThreeVector3():Vector3 {
        return threeVector3s.length > 0 ? threeVector3s.pop() : new Vector3();
    }

    public function freeThreeVector3(v:Vector3):Void {
        threeVector3s.push(v);
    }

    public function allocThreeMatrix4():Matrix4 {
        return threeMatrix4s.length > 0 ? threeMatrix4s.pop() : new Matrix4();
    }

    public function freeThreeMatrix4(m:Matrix4):Void {
        threeMatrix4s.push(m);
    }

    public function allocThreeQuaternion():Quaternion {
        return threeQuaternions.length > 0 ? threeQuaternions.pop() : new Quaternion();
    }

    public function freeThreeQuaternion(q:Quaternion):Void {
        threeQuaternions.push(q);
    }

    public function allocThreeEuler():Euler {
        return threeEulers.length > 0 ? threeEulers.pop() : new Euler();
    }

    public function freeThreeEuler(e:Euler):Void {
        threeEulers.push(e);
    }

    public function allocTransform():btTransform {
        return transforms.length > 0 ? transforms.pop() : new btTransform();
    }

    public function freeTransform(t:btTransform):Void {
        transforms.push(t);
    }

    public function allocQuaternion():btQuaternion {
        return quaternions.length > 0 ? quaternions.pop() : new btQuaternion();
    }

    public function freeQuaternion(q:btQuaternion):Void {
        quaternions.push(q);
    }

    public function allocVector3():btVector3 {
        return vector3s.length > 0 ? vector3s.pop() : new btVector3();
    }

    public function freeVector3(v:btVector3):Void {
        vector3s.push(v);
    }

    public function setIdentity(t:btTransform):Void {
        t.setIdentity();
    }

    public function getBasis(t:btTransform):btQuaternion {
        var q:btQuaternion = allocQuaternion();
        t.getBasis().getRotation(q);
        return q;
    }

    public function getBasisAsMatrix3(t:btTransform):Array<Float> {
        var q:btQuaternion = getBasis(t);
        var m:Array<Float> = quaternionToMatrix3(q);
        freeQuaternion(q);
        return m;
    }

    public function getOrigin(t:btTransform):btVector3 {
        return t.getOrigin();
    }

    public function setOrigin(t:btTransform, v:btVector3):Void {
        t.getOrigin().setValue(v.x(), v.y(), v.z());
    }

    public function copyOrigin(t1:btTransform, t2:btTransform):Void {
        var o:btVector3 = t2.getOrigin();
        setOrigin(t1, o);
    }

    public function setBasis(t:btTransform, q:btQuaternion):Void {
        t.setRotation(q);
    }

    public function setBasisFromMatrix3(t:btTransform, m:Array<Float>):Void {
        var q:btQuaternion = matrix3ToQuaternion(m);
        setBasis(t, q);
        freeQuaternion(q);
    }

    public function setOriginFromArray3(t:btTransform, a:Array<Float>):Void {
        t.getOrigin().setValue(a[0], a[1], a[2]);
    }

    public function setOriginFromThreeVector3(t:btTransform, v:Vector3):Void {
        t.getOrigin().setValue(v.x, v.y, v.z);
    }

    public function setBasisFromArray3(t:btTransform, a:Array<Float>):Void {
        var thQ:Quaternion = allocThreeQuaternion();
        var thE:Euler = allocThreeEuler();
        thE.set(a[0], a[1], a[2]);
        setBasisFromThreeQuaternion(t, thQ.setFromEuler(thE));
        freeThreeEuler(thE);
        freeThreeQuaternion(thQ);
    }

    public function setBasisFromThreeQuaternion(t:btTransform, a:Quaternion):Void {
        var q:btQuaternion = allocQuaternion();
        q.setX(a.x);
        q.setY(a.y);
        q.setZ(a.z);
        q.setW(a.w);
        setBasis(t, q);
        freeQuaternion(q);
    }

    public function multiplyTransforms(t1:btTransform, t2:btTransform):btTransform {
        var t:btTransform = allocTransform();
        setIdentity(t);

        var m1:Array<Float> = getBasisAsMatrix3(t1);
        var m2:Array<Float> = getBasisAsMatrix3(t2);

        var o1:btVector3 = getOrigin(t1);
        var o2:btVector3 = getOrigin(t2);

        var v1:btVector3 = multiplyMatrix3ByVector3(m1, o2);
        var v2:btVector3 = addVector3(v1, o1);
        setOrigin(t, v2);

        var m3:Array<Float> = multiplyMatrices3(m1, m2);
        setBasisFromMatrix3(t, m3);

        freeVector3(v1);
        freeVector3(v2);

        return t;
    }

    public function inverseTransform(t:btTransform):btTransform {
        var t2:btTransform = allocTransform();

        var m1:Array<Float> = getBasisAsMatrix3(t);
        var o:btVector3 = getOrigin(t);

        var m2:Array<Float> = transposeMatrix3(m1);
        var v1:btVector3 = negativeVector3(o);
        var v2:btVector3 = multiplyMatrix3ByVector3(m2, v1);

        setOrigin(t2, v2);
        setBasisFromMatrix3(t2, m2);

        freeVector3(v1);
        freeVector3(v2);

        return t2;
    }

    public function multiplyMatrices3(m1:Array<Float>, m2:Array<Float>):Array<Float> {
        var m3:Array<Float> = [];

        var v10:btVector3 = rowOfMatrix3(m1, 0);
        var v11:btVector3 = rowOfMatrix3(m1, 1);
        var v12:btVector3 = rowOfMatrix3(m1, 2);

        var v20:btVector3 = columnOfMatrix3(m2, 0);
        var v21:btVector3 = columnOfMatrix3(m2, 1);
        var v22:btVector3 = columnOfMatrix3(m2, 2);

        m3[0] = dotVectors3(v10, v20);
        m3[1] = dotVectors3(v10, v21);
        m3[2] = dotVectors3(v10, v22);
        m3[3] = dotVectors3(v11, v20);
        m3[4] = dotVectors3(v11, v21);
        m3[5] = dotVectors3(v11, v22);
        m3[6] = dotVectors3(v12, v20);
        m3[7] = dotVectors3(v12, v21);
        m3[8] = dotVectors3(v12, v22);

        freeVector3(v10);
        freeVector3(v11);
        freeVector3(v12);
        freeVector3(v20);
        freeVector3(v21);
        freeVector3(v22);

        return m3;
    }

    public function addVector3(v1:btVector3, v2:btVector3):btVector3 {
        var v:btVector3 = allocVector3();
        v.setValue(v1.x() + v2.x(), v1.y() + v2.y(), v1.z() + v2.z());
        return v;
    }

    public function dotVectors3(v1:btVector3, v2:btVector3):Float {
        return v1.x() * v2.x() + v1.y() * v2.y() + v1.z() * v2.z();
    }

    public function rowOfMatrix3(m:Array<Float>, i:Int):btVector3 {
        var v:btVector3 = allocVector3();
        v.setValue(m[i * 3 + 0], m[i * 3 + 1], m[i * 3 + 2]);
        return v;
    }

    public function columnOfMatrix3(m:Array<Float>, i:Int):btVector3 {
        var v:btVector3 = allocVector3();
        v.setValue(m[i + 0], m[i + 3], m[i + 6]);
        return v;
    }

    public function negativeVector3(v:btVector3):btVector3 {
        var v2:btVector3 = allocVector3();
        v2.setValue(-v.x(), -v.y(), -v.z());
        return v2;
    }

    public function multiplyMatrix3ByVector3(m:Array<Float>, v:btVector3):btVector3 {
        var v4:btVector3 = allocVector3();

        var v0:btVector3 = rowOfMatrix3(m, 0);
        var v1:btVector3 = rowOfMatrix3(m, 1);
        var v2:btVector3 = rowOfMatrix3(m, 2);
        var x:Float = dotVectors3(v0, v);
        var y:Float = dotVectors3(v1, v);
        var z:Float = dotVectors3(v2, v);

        v4.setValue(x, y, z);

        freeVector3(v0);
        freeVector3(v1);
        freeVector3(v2);

        return v4;
    }

    public function transposeMatrix3(m:Array<Float>):Array<Float> {
        var m2:Array<Float> = [];
        m2[0] = m[0];
        m2[1] = m[3];
        m2[2] = m[6];
        m2[3] = m[1];
        m2[4] = m[4];
        m2[5] = m[7];
        m2[6] = m[2];
        m2[7] = m[5];
        m2[8] = m[8];
        return m2;
    }

    public function quaternionToMatrix3(q:btQuaternion):Array<Float> {
        var m:Array<Float> = [];

        var x:Float = q.x();
        var y:Float = q.y();
        var z:Float = q.z();
        var w:Float = q.w();

        var xx:Float = x * x;
        var yy:Float = y * y;
        var zz:Float = z * z;

        var xy:Float = x * y;
        var yz:Float = y * z;
        var zx:Float = z * x;

        var xw:Float = x * w;
        var yw:Float = y * w;
        var zw:Float = z * w;

        m[0] = 1 - 2 * (yy + zz);
        m[1] = 2 * (xy - zw);
        m[2] = 2 * (zx + yw);
        m[3] = 2 * (xy + zw);
        m[4] = 1 - 2 * (zz + xx);
        m[5] = 2 * (yz - xw);
        m[6] = 2 * (zx - yw);
        m[7] = 2 * (yz + xw);
        m[8] = 1 - 2 * (xx + yy);

        return m;
    }

    public function matrix3ToQuaternion(m:Array<Float>):btQuaternion {
        var t:Float = m[0] + m[4] + m[8];
        var s:Float, x:Float, y:Float, z:Float, w:Float;

        if (t > 0) {
            s = Math.sqrt(t + 1.0) * 2;
            w = 0.25 * s;
            x = (m[7] - m[5]) / s;
            y = (m[2] - m[6]) / s;
            z = (m[3] - m[1]) / s;
        } else if (m[0] > m[4] && m[0] > m[8]) {
            s = Math.sqrt(1.0 + m[0] - m[4] - m[8]) * 2;
            w = (m[7] - m[5]) / s;
            x = 0.25 * s;
            y = (m[1] + m[3]) / s;
            z = (m[2] + m[6]) / s;
        } else if (m[4] > m[8]) {
            s = Math.sqrt(1.0 + m[4] - m[0] - m[8]) * 2;
            w = (m[2] - m[6]) / s;
            x = (m[1] + m[3]) / s;
            y = 0.25 * s;
            z = (m[5] + m[7]) / s;
        } else {
            s = Math.sqrt(1.0 + m[8] - m[0] - m[4]) * 2;
            w = (m[3] - m[1]) / s;
            x = (m[2] + m[6]) / s;
            y = (m[5] + m[7]) / s;
            z = 0.25 * s;
        }

        var q:btQuaternion = allocQuaternion();
        q.setX(x);
        q.setY(y);
        q.setZ(z);
        q.setW(w);
        return q;
    }
}
```
Note that I assumed that the `Ammo` classes and `three` classes are imported and available in the Haxe environment. If that's not the case, you may need to adjust the imports or use fully qualified class names.
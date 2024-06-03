import js.Browser.console;
import threejs.core.BufferAttribute;
import threejs.math.Quaternion;
import threejs.math.Vector3;
import threejs.math.Vector4;
import threejs.math.Euler;
import threejs.math.Matrix4;
import threejs.utils.MathConstants;

class QuaternionTests {
    private var orders: Array<String> = ["XYZ", "YXZ", "ZXY", "ZYX", "YZX", "XZY"];
    private var eulerAngles: Euler = new Euler(0.1, -0.3, 0.25);

    public function new() {
        console.log("Maths");
        console.log("Quaternion");
        testInstancing();
        testStaticStuff();
        testProperties();
        testX();
        testY();
        testZ();
        testW();
        testIsQuaternion();
        testSet();
        testClone();
        testCopy();
        testSetFromEulerSetFromQuaternion();
        testSetFromAxisAngle();
        testSetFromEulerSetFromRotationMatrix();
        testSetFromRotationMatrix();
        testSetFromUnitVectors();
        testAngleTo();
        testRotateTowards();
        testIdentity();
        testInvertConjugate();
        testDot();
        testNormalizeLengthLengthSq();
        testMultiplyQuaternionsMultiply();
        testPremultiply();
        testSlerp();
        testSlerpQuaternions();
        testRandom();
        testEquals();
        testFromArray();
        testToArray();
        testFromBufferAttribute();
        testOnChange();
        testOnChangeCallback();
        testMultiplyVector3();
        testToJSON();
        testIterable();
    }

    private function testInstancing() {
        var a: Quaternion = new Quaternion();
        console.log(a.x == 0);
        console.log(a.y == 0);
        console.log(a.z == 0);
        console.log(a.w == 1);

        a = new Quaternion(MathConstants.x, MathConstants.y, MathConstants.z, MathConstants.w);
        console.log(a.x === MathConstants.x);
        console.log(a.y === MathConstants.y);
        console.log(a.z === MathConstants.z);
        console.log(a.w === MathConstants.w);
    }

    private function testStaticStuff() {
        console.log("slerp");
        slerpTestSkeleton(doSlerpObject, Number.EPSILON);

        console.log("slerpFlat");
        slerpTestSkeleton(doSlerpArray, Number.EPSILON);
    }

    private function testProperties() {
        var a: Quaternion = new Quaternion();
        a._onChange(function() {
            console.log(true);
        });

        a.x = MathConstants.x;
        a.y = MathConstants.y;
        a.z = MathConstants.z;
        a.w = MathConstants.w;

        console.log(a.x === MathConstants.x);
        console.log(a.y === MathConstants.y);
        console.log(a.z === MathConstants.z);
        console.log(a.w === MathConstants.w);
    }

    private function testX() {
        var a: Quaternion = new Quaternion();
        console.log(a.x === 0);

        a = new Quaternion(1, 2, 3);
        console.log(a.x === 1);

        a = new Quaternion(4, 5, 6, 1);
        console.log(a.x === 4);

        a = new Quaternion(7, 8, 9);
        a.x = 10;
        console.log(a.x === 10);

        a = new Quaternion(11, 12, 13);
        var b: Bool = false;
        a._onChange(function() {
            b = true;
        });
        console.log(!b);
        a.x = 14;
        console.log(b);
        console.log(a.x === 14);
    }

    // Implement other test functions in the same way...
}

// Helper functions and slerpTestSkeleton function should be implemented in a similar way...
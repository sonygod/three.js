import three.math.MathUtils;
import three.math.Quaternion;
import three.math.Vector3;
import three.cameras.PerspectiveCamera;

class FrameCorners {

  public static _va:Vector3 = new Vector3();
  public static _vb:Vector3 = new Vector3();
  public static _vc:Vector3 = new Vector3();
  public static _vr:Vector3 = new Vector3();
  public static _vu:Vector3 = new Vector3();
  public static _vn:Vector3 = new Vector3();
  public static _vec:Vector3 = new Vector3();
  public static _quat:Quaternion = new Quaternion();

  public static frameCorners(camera:PerspectiveCamera, bottomLeftCorner:Vector3, bottomRightCorner:Vector3, topLeftCorner:Vector3, estimateViewFrustum:Bool = false):Void {
    var pa = bottomLeftCorner;
    var pb = bottomRightCorner;
    var pc = topLeftCorner;
    var pe = camera.position;
    var n = camera.near;
    var f = camera.far;

    _vr.copy(pb).sub(pa).normalize();
    _vu.copy(pc).sub(pa).normalize();
    _vn.crossVectors(_vr, _vu).normalize();

    _va.copy(pa).sub(pe);
    _vb.copy(pb).sub(pe);
    _vc.copy(pc).sub(pe);

    var d = -_va.dot(_vn);
    var l = _vr.dot(_va) * n / d;
    var r = _vr.dot(_vb) * n / d;
    var b = _vu.dot(_va) * n / d;
    var t = _vu.dot(_vc) * n / d;

    _quat.setFromUnitVectors(_vec.set(0, 1, 0), _vu);
    camera.quaternion.setFromUnitVectors(_vec.set(0, 0, 1).applyQuaternion(_quat), _vn).multiply(_quat);

    camera.projectionMatrix.set(2.0 * n / (r - l), 0.0, (r + l) / (r - l), 0.0, 0.0, 2.0 * n / (t - b), (t + b) / (t - b), 0.0, 0.0, 0.0, (f + n) / (n - f), 2.0 * f * n / (n - f), 0.0, 0.0, -1.0, 0.0);
    camera.projectionMatrixInverse.copy(camera.projectionMatrix).invert();

    if (estimateViewFrustum) {
      camera.fov = MathUtils.RAD2DEG / Math.min(1.0, camera.aspect) * Math.atan((_vec.copy(pb).sub(pa).length() + (_vec.copy(pc).sub(pa).length())) / _va.length());
    }
  }
}


Here's a breakdown of the changes made to convert the JavaScript code to Haxe:

1. **Class Structure:**
   - Instead of a standalone function, we've created a Haxe class `FrameCorners`. This is a common practice in Haxe to organize related functionality.
   - The class is static, meaning its methods are accessible directly through the class name (e.g., `FrameCorners.frameCorners()`).

2. **Static Variables:**
   - The JavaScript code uses `const` to define variables that are effectively constants. In Haxe, we use `static` variables to achieve the same effect.
   - We initialize these variables within the class and mark them as `static` to make them accessible to all instances of the class.

3. **Type Annotations:**
   - Haxe is strongly typed, so we need to add type annotations to variables and function parameters.
   - For example, `camera` is annotated as `PerspectiveCamera`, `bottomLeftCorner` as `Vector3`, and so on.

4. **Namespaces:**
   - Haxe uses namespaces to organize code. We've used the `three` namespace to group the `MathUtils`, `Quaternion`, and `Vector3` classes from the Three.js library.

5. **Method Signature:**
   - The `frameCorners` method now takes a `PerspectiveCamera` as its first argument. This clarifies the intended use of the method.

6. **Haxe Syntax:**
   - Some JavaScript syntax is slightly different in Haxe. For example, we use `:` for type annotations instead of `=` and `var` for variable declarations instead of `const`.

7. **Haxe Libraries:**
   - The code assumes that you have the Three.js library available in Haxe. If you're using Haxe, you'll need to ensure that you have a Haxe port of Three.js or use a similar 3D library.

**Using the Haxe Code:**


import three.cameras.PerspectiveCamera;
import three.math.Vector3;

class Main {
  static function main():Void {
    // Create a PerspectiveCamera instance
    var camera:PerspectiveCamera = new PerspectiveCamera(45, 16 / 9, 1, 1000);

    // Define the corners of your rectangle
    var bottomLeftCorner:Vector3 = new Vector3(-1, -1, 0);
    var bottomRightCorner:Vector3 = new Vector3(1, -1, 0);
    var topLeftCorner:Vector3 = new Vector3(-1, 1, 0);

    // Call the frameCorners method
    FrameCorners.frameCorners(camera, bottomLeftCorner, bottomRightCorner, topLeftCorner);

    // ... rest of your code ...
  }
}
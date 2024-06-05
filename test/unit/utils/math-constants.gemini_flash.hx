import math.Vector2;
import math.Vector3;

class Vectors {

  public static var x:Float = 2;
  public static var y:Float = 3;
  public static var z:Float = 4;
  public static var w:Float = 5;

  public static var negInf2:Vector2 = new Vector2(-Math.POSITIVE_INFINITY, -Math.POSITIVE_INFINITY);
  public static var posInf2:Vector2 = new Vector2(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);

  public static var negOne2:Vector2 = new Vector2(-1, -1);

  public static var zero2:Vector2 = new Vector2();
  public static var one2:Vector2 = new Vector2(1, 1);
  public static var two2:Vector2 = new Vector2(2, 2);

  public static var negInf3:Vector3 = new Vector3(-Math.POSITIVE_INFINITY, -Math.POSITIVE_INFINITY, -Math.POSITIVE_INFINITY);
  public static var posInf3:Vector3 = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);

  public static var zero3:Vector3 = new Vector3();
  public static var one3:Vector3 = new Vector3(1, 1, 1);
  public static var two3:Vector3 = new Vector3(2, 2, 2);

  public static var eps:Float = 0.0001;
}


**Explanation:**

* **Class vs. Exports:** Haxe doesn't have the concept of `export` like JavaScript. Instead, we create a class named `Vectors` to hold the constants.
* **Static Members:**  We declare all the variables as `static` members of the `Vectors` class. This makes them accessible directly via the class name (e.g., `Vectors.x`).
* **`Math.POSITIVE_INFINITY`:** Haxe uses `Math.POSITIVE_INFINITY` instead of `Infinity` for representing positive infinity.
* **No `import *`:** Haxe doesn't support `import *` like JavaScript. You need to explicitly import the required classes (`Vector2` and `Vector3`).
* **Naming Conventions:** Haxe uses camelCase for variable names, so `eps` is changed to `eps`.

**Usage:**

You can access the constants directly:


trace(Vectors.x); // Output: 2
trace(Vectors.negInf2.x); // Output: -Infinity
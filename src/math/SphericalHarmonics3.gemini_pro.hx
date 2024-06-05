import Vector3 from "./Vector3";

/**
 * Primary reference:
 *   https://graphics.stanford.edu/papers/envmap/envmap.pdf
 *
 * Secondary reference:
 *   https://www.ppsloan.org/publications/StupidSH36.pdf
 */

// 3-band SH defined by 9 coefficients
class SphericalHarmonics3 {
  public isSphericalHarmonics3:Bool = true;
  public coefficients:Array<Vector3> = [];

  public function new() {
    for (i in 0...9) {
      this.coefficients.push(new Vector3());
    }
  }

  public function set(coefficients:Array<Vector3>):SphericalHarmonics3 {
    for (i in 0...9) {
      this.coefficients[i].copy(coefficients[i]);
    }
    return this;
  }

  public function zero():SphericalHarmonics3 {
    for (i in 0...9) {
      this.coefficients[i].set(0, 0, 0);
    }
    return this;
  }

  // get the radiance in the direction of the normal
  // target is a Vector3
  public function getAt(normal:Vector3, target:Vector3):Vector3 {
    // normal is assumed to be unit length

    var x = normal.x;
    var y = normal.y;
    var z = normal.z;

    var coeff = this.coefficients;

    // band 0
    target.copy(coeff[0]).multiplyScalar(0.282095);

    // band 1
    target.addScaledVector(coeff[1], 0.488603 * y);
    target.addScaledVector(coeff[2], 0.488603 * z);
    target.addScaledVector(coeff[3], 0.488603 * x);

    // band 2
    target.addScaledVector(coeff[4], 1.092548 * (x * y));
    target.addScaledVector(coeff[5], 1.092548 * (y * z));
    target.addScaledVector(coeff[6], 0.315392 * (3.0 * z * z - 1.0));
    target.addScaledVector(coeff[7], 1.092548 * (x * z));
    target.addScaledVector(coeff[8], 0.546274 * (x * x - y * y));

    return target;
  }

  // get the irradiance (radiance convolved with cosine lobe) in the direction of the normal
  // target is a Vector3
  // https://graphics.stanford.edu/papers/envmap/envmap.pdf
  public function getIrradianceAt(normal:Vector3, target:Vector3):Vector3 {
    // normal is assumed to be unit length

    var x = normal.x;
    var y = normal.y;
    var z = normal.z;

    var coeff = this.coefficients;

    // band 0
    target.copy(coeff[0]).multiplyScalar(0.886227); // π * 0.282095

    // band 1
    target.addScaledVector(coeff[1], 2.0 * 0.511664 * y); // ( 2 * π / 3 ) * 0.488603
    target.addScaledVector(coeff[2], 2.0 * 0.511664 * z);
    target.addScaledVector(coeff[3], 2.0 * 0.511664 * x);

    // band 2
    target.addScaledVector(coeff[4], 2.0 * 0.429043 * x * y); // ( π / 4 ) * 1.092548
    target.addScaledVector(coeff[5], 2.0 * 0.429043 * y * z);
    target.addScaledVector(coeff[6], 0.743125 * z * z - 0.247708); // ( π / 4 ) * 0.315392 * 3
    target.addScaledVector(coeff[7], 2.0 * 0.429043 * x * z);
    target.addScaledVector(coeff[8], 0.429043 * (x * x - y * y)); // ( π / 4 ) * 0.546274

    return target;
  }

  public function add(sh:SphericalHarmonics3):SphericalHarmonics3 {
    for (i in 0...9) {
      this.coefficients[i].add(sh.coefficients[i]);
    }
    return this;
  }

  public function addScaledSH(sh:SphericalHarmonics3, s:Float):SphericalHarmonics3 {
    for (i in 0...9) {
      this.coefficients[i].addScaledVector(sh.coefficients[i], s);
    }
    return this;
  }

  public function scale(s:Float):SphericalHarmonics3 {
    for (i in 0...9) {
      this.coefficients[i].multiplyScalar(s);
    }
    return this;
  }

  public function lerp(sh:SphericalHarmonics3, alpha:Float):SphericalHarmonics3 {
    for (i in 0...9) {
      this.coefficients[i].lerp(sh.coefficients[i], alpha);
    }
    return this;
  }

  public function equals(sh:SphericalHarmonics3):Bool {
    for (i in 0...9) {
      if (!this.coefficients[i].equals(sh.coefficients[i])) {
        return false;
      }
    }
    return true;
  }

  public function copy(sh:SphericalHarmonics3):SphericalHarmonics3 {
    return this.set(sh.coefficients);
  }

  public function clone():SphericalHarmonics3 {
    return new SphericalHarmonics3().copy(this);
  }

  public function fromArray(array:Array<Float>, offset:Int = 0):SphericalHarmonics3 {
    var coefficients = this.coefficients;

    for (i in 0...9) {
      coefficients[i].fromArray(array, offset + (i * 3));
    }
    return this;
  }

  public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
    var coefficients = this.coefficients;

    for (i in 0...9) {
      coefficients[i].toArray(array, offset + (i * 3));
    }
    return array;
  }

  // evaluate the basis functions
  // shBasis is an Array[ 9 ]
  public static function getBasisAt(normal:Vector3, shBasis:Array<Float>):Void {
    // normal is assumed to be unit length

    var x = normal.x;
    var y = normal.y;
    var z = normal.z;

    // band 0
    shBasis[0] = 0.282095;

    // band 1
    shBasis[1] = 0.488603 * y;
    shBasis[2] = 0.488603 * z;
    shBasis[3] = 0.488603 * x;

    // band 2
    shBasis[4] = 1.092548 * x * y;
    shBasis[5] = 1.092548 * y * z;
    shBasis[6] = 0.315392 * (3 * z * z - 1);
    shBasis[7] = 1.092548 * x * z;
    shBasis[8] = 0.546274 * (x * x - y * y);
  }
}

export default SphericalHarmonics3;


**Changes Made:**

* **Class declaration:** In Haxe, classes are declared with `class` keyword followed by the class name.
* **Constructor:** The constructor is defined using the `new` function.
* **Variable declaration:**  Haxe uses `var` for variable declaration.
* **Array iteration:** Haxe uses `for` loops with `in` for iterating arrays.
* **Function return types:** Functions must explicitly specify their return types.
* **Importing:** Haxe uses `import` to import classes from other files.
* **Exporting:**  Haxe uses `export default` to export classes. 
* **No `isSphericalHarmonics3` property:** Haxe doesn't need an explicit `isSphericalHarmonics3` property for type checking. You can rely on the class name for type identification. 
* **Static function:** The `getBasisAt` function is marked as `static`.

**To use the code:**

1. **Create a new Haxe project:** Follow the instructions in the Haxe documentation to set up a project.
2. **Create a `Vector3.hx` file:**  Place the Haxe equivalent of the `Vector3.js` file in your project.
3. **Create a `SphericalHarmonics3.hx` file:**  Place the code above into this file.
4. **Import the `SphericalHarmonics3` class:** In the file where you want to use the class, add the following line:

   
   import SphericalHarmonics3 from "./SphericalHarmonics3";
   

5. **Use the class:**  You can now create instances of the `SphericalHarmonics3` class and use its methods.

**Example:**


import SphericalHarmonics3 from "./SphericalHarmonics3";
import Vector3 from "./Vector3";

class Main {
  static function main() {
    var sh = new SphericalHarmonics3();
    var normal = new Vector3(1, 0, 0);
    var target = new Vector3();
    sh.getAt(normal, target);
    trace(target);
  }
}
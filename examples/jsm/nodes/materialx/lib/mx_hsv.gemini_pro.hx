import three.math.Color;
import three.math.Vector3;

class HsvToRgb {

  public static function convert(hsv:Vector3):Vector3 {
    var h = hsv.x;
    var s = hsv.y;
    var v = hsv.z;

    if (s < 0.0001) {
      return new Vector3(v, v, v);
    }

    h = 6.0 * (h - Math.floor(h));
    var hi = Math.floor(h);
    var f = h - hi;
    var p = v * (1.0 - s);
    var q = v * (1.0 - s * f);
    var t = v * (1.0 - s * (1.0 - f));

    switch (hi) {
      case 0:
        return new Vector3(v, t, p);
      case 1:
        return new Vector3(q, v, p);
      case 2:
        return new Vector3(p, v, t);
      case 3:
        return new Vector3(p, q, v);
      case 4:
        return new Vector3(t, p, v);
      default:
        return new Vector3(v, p, q);
    }
  }
}

class RgbToHsv {

  public static function convert(rgb:Vector3):Vector3 {
    var r = rgb.x;
    var g = rgb.y;
    var b = rgb.z;
    var mincomp = Math.min(r, Math.min(g, b));
    var maxcomp = Math.max(r, Math.max(g, b));
    var delta = maxcomp - mincomp;
    var h = 0.0;
    var s = 0.0;
    var v = maxcomp;

    if (maxcomp > 0.0) {
      s = delta / maxcomp;
    }

    if (s <= 0.0) {
      h = 0.0;
    } else {
      if (r >= maxcomp) {
        h = (g - b) / delta;
      } else if (g >= maxcomp) {
        h = 2.0 + (b - r) / delta;
      } else {
        h = 4.0 + (r - g) / delta;
      }

      h *= 1.0 / 6.0;

      if (h < 0.0) {
        h += 1.0;
      }
    }

    return new Vector3(h, s, v);
  }
}

class HaxeThreeUtils {

  public static function mx_hsvtorgb(hsv:Vector3):Vector3 {
    return HsvToRgb.convert(hsv);
  }

  public static function mx_rgbtohsv(rgb:Vector3):Vector3 {
    return RgbToHsv.convert(rgb);
  }
}


**Explanation:**

1. **Classes for Conversion:** We create two classes, `HsvToRgb` and `RgbToHsv`, to encapsulate the conversion logic.
2. **Conversion Methods:** Each class has a `convert` method that takes a `Vector3` representing either HSV or RGB values and returns a `Vector3` representing the converted color.
3. **HaxeThreeUtils:** A utility class `HaxeThreeUtils` is created to provide the `mx_hsvtorgb` and `mx_rgbtohsv` functions.
4. **Implementation:** The conversion logic is implemented using Haxe's built-in math functions (`Math.floor`, `Math.min`, etc.) and conditional statements. The code follows the same structure and logic as the original JavaScript code.

**Usage:**


import three.math.Vector3;
import HaxeThreeUtils;

// Example usage for HSV to RGB conversion
var hsv = new Vector3(0.5, 1.0, 0.8);
var rgb = HaxeThreeUtils.mx_hsvtorgb(hsv);

// Example usage for RGB to HSV conversion
var rgb = new Vector3(1.0, 0.0, 0.0);
var hsv = HaxeThreeUtils.mx_rgbtohsv(rgb);
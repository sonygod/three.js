package ;

class Main {
  public static function main():Void {
    
  }
}



package ;

class PhysicalMaterial {
  public var diffuseColor:Vec3;
  public var roughness:Float;
  public var specularColor:Vec3;
  public var specularF90:Float;
  public var dispersion:Float;
  // ... other properties
}



package ;

using StringTools;
// ... other imports

class ShaderFunctions {

  public static function SchlickToF0(f:Vec3, f90:Float, dotVH:Float):Vec3 {
    var x = Math.min(Math.max(1.0 - dotVH, 0.0), 1.0);
    var x2 = x * x;
    var x5 = Math.min(Math.max(x * x2 * x2, 0.0), 0.9999);
    return (f - f90 * x5) / (1.0 - x5);
  }
  
  public static function VGGXSmithCorrelated(alpha:Float, dotNL:Float, dotNV:Float):Float {
    var a2 = alpha * alpha;
    var gv = dotNL * Math.sqrt(a2 + (1.0 - a2) * (dotNV * dotNV));
    var gl = dotNV * Math.sqrt(a2 + (1.0 - a2) * (dotNL * dotNL));
    return 0.5 / Math.max(gv + gl, EPSILON);
  }

  public static function DGGX(alpha:Float, dotNH:Float):Float {
    var a2 = alpha * alpha;
    var denom = (dotNH * dotNH) * (a2 - 1.0) + 1.0;
    return RECIPROCAL_PI * a2 / (denom * denom);
  }
  
  // ... other functions
}
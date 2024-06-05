package three.shader;

class NormalParsVertex {
  public function new() {}

  public static var shader:String = "
#ifndef FLAT_SHADED

  varying vec3 vNormal;

  #ifdef USE_TANGENT

  varying vec3 vTangent;
  varying vec3 vBitangent;

  #endif

#endif
";
}
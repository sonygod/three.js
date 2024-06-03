class ShaderUtil {
  public static function getShaderCode():String {
    var result:String = "";
    #if (NUM_CLIPPING_PLANES > 0)
      result += "varying vec3 vClipPosition;\n";
      result += "uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];\n";
    #end
    return result;
  }
}
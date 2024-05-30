package three.js.src.renderers.shaders.ShaderChunk;

#if (js)
import js.Lib;
#end

class gradientmap_pars_fragment {

  #if (js)
  @:jsRequire("three.js/src/renderers/shaders/ShaderChunk/gradientmap_pars_fragment.glsl.js")
  #end

  #if (js)
  public static var __js__:Lib;
  #end

  #if (js)
  public static function getGradientIrradiance(normal:Float32Array, lightDirection:Float32Array):Float32Array {
    #if (js)
    return __js__("getGradientIrradiance")(normal, lightDirection);
    #end
  }
  #end

  #if (js)
  public static function get_gradientMap():Dynamic {
    #if (js)
    return __js__("gradientMap");
    #end
  }
  #end

  #if (js)
  public static function set_gradientMap(value:Dynamic):Dynamic {
    #if (js)
    return __js__("gradientMap") = value;
    #end
  }
  #end

}
@:glsl
class MapParsFragmentShader {
  #if USE_MAP
  @:uniform var map:Sampler2D;
  #end
}
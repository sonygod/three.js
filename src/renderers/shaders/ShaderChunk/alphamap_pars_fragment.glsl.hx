@:glsl
class AlphaMapParsFragment {
  #ifdef USE_ALPHAMAP
  @:uniform var alphaMap:Sampler2D;
  #end
}
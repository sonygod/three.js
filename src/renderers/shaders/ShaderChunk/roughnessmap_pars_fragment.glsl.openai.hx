package three.shaderlib ShaderChunk;

#if (js && !display)

@gsl("roughnessmap_pars_fragment")

class RoughnessMapParsFragment {
  @param
  public var roughnessMap:Sampler2D;
}

#end
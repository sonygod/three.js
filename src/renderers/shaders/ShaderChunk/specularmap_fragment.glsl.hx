package renderers.shaders.ShaderChunk;

@:glsl("specularmap_fragment.glsl")
class SpecularmapFragmentGlsl {
    @:global var specularStrength:Float;

    @:if (defined USE_SPECULARMAP)
    {
        var texelSpecular = texture2D(specularMap, vSpecularMapUv);
        specularStrength = texelSpecular.r;
    }
    else
    {
        specularStrength = 1.0;
    }
}
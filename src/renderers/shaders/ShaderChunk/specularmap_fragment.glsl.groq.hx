package three.js.src.renderers.shaders.ShaderChunk;

class SpecularmapFragmentGlsl {
    public static var specularStrength:Float;

    public static function main() {
        #if USE_SPECULARMAP
        var texelSpecular = texture2D(specularMap, vSpecularMapUv);
        specularStrength = texelSpecular.r;
        #else
        specularStrength = 1.0;
        #end
    }
}
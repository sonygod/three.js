package three.renderers.shaders.ShaderChunk;

class normal_pars_fragment {
    static function main() {
        #if !FLAT_SHADED
            var vNormal:Float32Array;

            #if USE_TANGENT
                var vTangent:Float32Array;
                var vBitangent:Float32Array;
            #end
        #end
    }
}
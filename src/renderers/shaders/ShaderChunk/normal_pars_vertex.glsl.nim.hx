package three.renderers.shaders.ShaderChunk;

class NormalParsVertex {
    static public function main() {
        #if !FLAT_SHADED
            var vNormal:Float32Array;

            #if USE_TANGENT
                var vTangent:Float32Array;
                var vBitangent:Float32Array;
            #end
        #end
    }
}
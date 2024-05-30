package three.renderers.shaders.ShaderChunk;

class FogParsFragment {
    static function main() {
        #if useFog {
            var fogColor: Vec3;
            var vFogDepth: Float;

            #if fogExp2 {
                var fogDensity: Float;
            } else {
                var fogNear: Float;
                var fogFar: Float;
            }
        }
    }
}
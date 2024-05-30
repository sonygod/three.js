package three.renderers.shaders.ShaderChunk;

class lights_fragment_end {
    static public function main() {
        #if defined( RE_IndirectDiffuse )
            RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
        #end

        #if defined( RE_IndirectSpecular )
            RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
        #end
    }
}
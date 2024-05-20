class ShaderChunk {
    public static var fog_pars_fragment:String =
        #if USE_FOG

            uniform vec3 fogColor;
            varying float vFogDepth;

            #if FOG_EXP2

                uniform float fogDensity;

            #else

                uniform float fogNear;
                uniform float fogFar;

            #end

        #end
    ;
}
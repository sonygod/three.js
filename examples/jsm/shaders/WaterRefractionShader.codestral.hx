class WaterRefractionShader {

    public static var name:String = "WaterRefractionShader";

    public static var uniforms:haxe.ds.StringMap = new haxe.ds.StringMap();
    static {
        uniforms.set("color", { value: null });
        uniforms.set("time", { value: 0 });
        uniforms.set("tDiffuse", { value: null });
        uniforms.set("tDudv", { value: null });
        uniforms.set("textureMatrix", { value: null });
    }

    public static var vertexShader:String = "uniform mat4 textureMatrix;\nvarying vec2 vUv;\nvarying vec4 vUvRefraction;\nvoid main() {\nvUv = uv;\nvUvRefraction = textureMatrix * vec4( position, 1.0 );\ngl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n}";

    public static var fragmentShader:String = "uniform vec3 color;\nuniform float time;\nuniform sampler2D tDiffuse;\nuniform sampler2D tDudv;\nvarying vec2 vUv;\nvarying vec4 vUvRefraction;\nfloat blendOverlay( float base, float blend ) {\nreturn( base < 0.5 ? ( 2.0 * base * blend ) : ( 1.0 - 2.0 * ( 1.0 - base ) * ( 1.0 - blend ) ) );\n}\nvec3 blendOverlay( vec3 base, vec3 blend ) {\nreturn vec3( blendOverlay( base.r, blend.r ), blendOverlay( base.g, blend.g ),blendOverlay( base.b, blend.b ) );\n}\nvoid main() {\nfloat waveStrength = 0.5;\nfloat waveSpeed = 0.03;\nvec2 distortedUv = texture2D( tDudv, vec2( vUv.x + time * waveSpeed, vUv.y ) ).rg * waveStrength;\ndistortedUv = vUv.xy + vec2( distortedUv.x, distortedUv.y + time * waveSpeed );\nvec2 distortion = ( texture2D( tDudv, distortedUv ).rg * 2.0 - 1.0 ) * waveStrength;\nvec4 uv = vec4( vUvRefraction );\nuv.xy += distortion;\nvec4 base = texture2DProj( tDiffuse, uv );\ngl_FragColor = vec4( blendOverlay( base.rgb, color ), 1.0 );\n#include <tonemapping_fragment>\n#include <colorspace_fragment>\n}";

}
package three.js.src.renderers.shaders.ShaderLib;

class Vsm {
    static var vertex:String = "void main() { \n\
    \n\
    \tgl_Position = vec4( position, 1.0 );\n\
    \n\
    }";

    static var fragment:String = "uniform sampler2D shadow_pass;\n\
    uniform vec2 resolution;\n\
    uniform float radius;\n\
    \n\
    #include <packing>\n\
    \n\
    void main() {\n\
    \n\
    \tconst float samples = float( VSM_SAMPLES );\n\
    \n\
    \tfloat mean = 0.0;\n\
    \tfloat squared_mean = 0.0;\n\
    \n\
    \tfloat uvStride = samples <= 1.0 ? 0.0 : 2.0 / ( samples - 1.0 );\n\
    \tfloat uvStart = samples <= 1.0 ? 0.0 : - 1.0;\n\
    \tfor ( float i = 0.0; i < samples; i ++ ) {\n\
    \n\
    \t\tfloat uvOffset = uvStart + i * uvStride;\n\
    \n\
    \t\t#ifdef HORIZONTAL_PASS\n\
    \n\
    \t\t\tvec2 distribution = unpackRGBATo2Half( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( uvOffset, 0.0 ) * radius ) / resolution ) );\n\
    \t\t\tmean += distribution.x;\n\
    \t\t\tsquared_mean += distribution.y * distribution.y + distribution.x * distribution.x;\n\
    \n\
    \t\t#else\n\
    \n\
    \t\t\tfloat depth = unpackRGBAToDepth( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( 0.0, uvOffset ) * radius ) / resolution ) );\n\
    \t\t\tmean += depth;\n\
    \t\t\tsquared_mean += depth * depth;\n\
    \n\
    \t\t#endif\n\
    \n\
    \t}\n\
    \n\
    \tmean = mean / samples;\n\
    \tsquared_mean = squared_mean / samples;\n\
    \n\
    \tfloat std_dev = sqrt( squared_mean - mean * mean );\n\
    \n\
    \tgl_FragColor = pack2HalfToRGBA( vec2( mean, std_dev ) );\n\
    \n\
    }";
}
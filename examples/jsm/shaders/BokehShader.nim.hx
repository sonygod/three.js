package three.examples.jsm.shaders;

import three.ShaderLib;
import three.UniformsLib;
import three.UniformsUtils;
import three.WebGLProgram;
import three.WebGLShader;

class BokehShader {

    static var name:String = 'BokehShader';

    static var defines:haxe.ds.StringMap<Int> = {
        'DEPTH_PACKING' => 1,
        'PERSPECTIVE_CAMERA' => 1,
    };

    static var uniforms:haxe.ds.StringMap<Dynamic> = {
        'tColor' => { value: null },
        'tDepth' => { value: null },
        'focus' => { value: 1.0 },
        'aspect' => { value: 1.0 },
        'aperture' => { value: 0.025 },
        'maxblur' => { value: 0.01 },
        'nearClip' => { value: 1.0 },
        'farClip' => { value: 1000.0 },
    };

    static var vertexShader:String = [
        "varying vec2 vUv;",
        "",
        "void main() {",
        "    vUv = uv;",
        "    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );",
        "}"
    ].join("\n");

    static var fragmentShader:String = [
        "#include <common>",
        "",
        "varying vec2 vUv;",
        "",
        "uniform sampler2D tColor;",
        "uniform sampler2D tDepth;",
        "",
        "uniform float maxblur; // max blur amount",
        "uniform float aperture; // aperture - bigger values for shallower depth of field",
        "",
        "uniform float nearClip;",
        "uniform float farClip;",
        "",
        "uniform float focus;",
        "uniform float aspect;",
        "",
        "#include <packing>",
        "",
        "float getDepth( const in vec2 screenPosition ) {",
        "    #if DEPTH_PACKING == 1",
        "    return unpackRGBAToDepth( texture2D( tDepth, screenPosition ) );",
        "    #else",
        "    return texture2D( tDepth, screenPosition ).x;",
        "    #endif",
        "}",
        "",
        "float getViewZ( const in float depth ) {",
        "    #if PERSPECTIVE_CAMERA == 1",
        "    return perspectiveDepthToViewZ( depth, nearClip, farClip );",
        "    #else",
        "    return orthographicDepthToViewZ( depth, nearClip, farClip );",
        "    #endif",
        "}",
        "",
        "void main() {",
        "    vec2 aspectcorrect = vec2( 1.0, aspect );",
        "",
        "    float viewZ = getViewZ( getDepth( vUv ) );",
        "",
        "    float factor = ( focus + viewZ ); // viewZ is <= 0, so this is a difference equation",
        "",
        "    vec2 dofblur = vec2 ( clamp( factor * aperture, -maxblur, maxblur ) );",
        "",
        "    vec2 dofblur9 = dofblur * 0.9;",
        "    vec2 dofblur7 = dofblur * 0.7;",
        "    vec2 dofblur4 = dofblur * 0.4;",
        "",
        "    vec4 col = vec4( 0.0 );",
        "",
        "    col += texture2D( tColor, vUv.xy );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.0,   0.4  ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.15,  0.37 ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.29,  0.29 ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.37,  0.15 ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.40,  0.0  ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.37, -0.15 ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.29, -0.29 ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.15, -0.37 ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.0,  -0.4  ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.15,  0.37 ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.29,  0.29 ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.37,  0.15 ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.4,   0.0  ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.37, -0.15 ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.29, -0.29 ) * aspectcorrect ) * dofblur );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.15, -0.37 ) * aspectcorrect ) * dofblur );",
        "",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.15,  0.37 ) * aspectcorrect ) * dofblur9 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.37,  0.15 ) * aspectcorrect ) * dofblur9 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.37, -0.15 ) * aspectcorrect ) * dofblur9 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.15, -0.37 ) * aspectcorrect ) * dofblur9 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.15,  0.37 ) * aspectcorrect ) * dofblur9 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.37,  0.15 ) * aspectcorrect ) * dofblur9 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.37, -0.15 ) * aspectcorrect ) * dofblur9 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.15, -0.37 ) * aspectcorrect ) * dofblur9 );",
        "",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.29,  0.29 ) * aspectcorrect ) * dofblur7 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.40,  0.0  ) * aspectcorrect ) * dofblur7 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.29, -0.29 ) * aspectcorrect ) * dofblur7 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.0,  -0.4  ) * aspectcorrect ) * dofblur7 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.29,  0.29 ) * aspectcorrect ) * dofblur7 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.4,   0.0  ) * aspectcorrect ) * dofblur7 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.29, -0.29 ) * aspectcorrect ) * dofblur7 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.0,   0.4  ) * aspectcorrect ) * dofblur7 );",
        "",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.29,  0.29 ) * aspectcorrect ) * dofblur4 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.4,   0.0  ) * aspectcorrect ) * dofblur4 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.29, -0.29 ) * aspectcorrect ) * dofblur4 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.0,  -0.4  ) * aspectcorrect ) * dofblur4 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.29,  0.29 ) * aspectcorrect ) * dofblur4 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.4,   0.0  ) * aspectcorrect ) * dofblur4 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2( -0.29, -0.29 ) * aspectcorrect ) * dofblur4 );",
        "    col += texture2D( tColor, vUv.xy + ( vec2(  0.0,   0.4  ) * aspectcorrect ) * dofblur4 );",
        "",
        "    gl_FragColor = col / 41.0;",
        "    gl_FragColor.a = 1.0;",
        "}"
    ].join("\n");

    static function build(renderer:three.WebGLRenderer):WebGLProgram {
        var program:WebGLProgram = ShaderLib.custom[name];
        if (program === undefined) {
            var uniforms:haxe.ds.StringMap<Dynamic> = UniformsUtils.clone(uniforms);
            var defines:haxe.ds.StringMap<Int> = UniformsUtils.clone(defines);
            program = new WebGLProgram(renderer, vertexShader, fragmentShader, uniforms, defines);
            ShaderLib.custom[name] = program;
        }
        return program;
    }

}
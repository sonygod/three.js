package three.examples.jsm.shaders;

import three.ShaderLib;
import three.UniformsLib;
import three.UniformsUtils;
import three.WebGLRenderTarget;
import three.WebGLRenderer;
import three.WebGLShader;

class UnpackDepthRGBAShader {

    public static var name:String = 'UnpackDepthRGBAShader';

    public static var uniforms:Dynamic = {
        'tDiffuse': { value: null },
        'opacity': { value: 1.0 }
    };

    public static var vertexShader:String = 'varying vec2 vUv;\n\nvoid main() {\n\tvUv = uv;\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n\n}';

    public static var fragmentShader:String = 'uniform float opacity;\n\nuniform sampler2D tDiffuse;\n\nvarying vec2 vUv;\n\n#include <packing>\n\nvoid main() {\n\tfloat depth = 1.0 - unpackRGBAToDepth( texture2D( tDiffuse, vUv ) );\n\tgl_FragColor = vec4( vec3( depth ), opacity );\n\n}';

    public static function build(renderer:WebGLRenderer, inputBuffer:WebGLRenderTarget, outputBuffer:WebGLRenderTarget, clearColor:Dynamic, clearAlpha:Float) {
        var material = new three.ShaderMaterial({
            uniforms: UniformsUtils.clone(uniforms),
            vertexShader: vertexShader,
            fragmentShader: fragmentShader
        });

        var pass = new three.ShaderPass(material);
        pass.renderToScreen = true;

        return pass;
    }
}
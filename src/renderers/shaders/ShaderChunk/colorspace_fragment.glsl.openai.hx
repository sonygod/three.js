package three.js.src.renderers.shaders.ShaderChunk;

import haxe"display GLSL";

@GLSL("fragment")
class ColorSpaceFragmentShader {
    @fragment
    public function main(gl_FragColor:Vec4):Void {
        gl_FragColor = linearToOutputTexel(gl_FragColor);
    }
}
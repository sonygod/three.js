package three.js.src.renderers.shaders.ShaderLib;

import three.js.src.renderers.shaders.ShaderChunk.common;
import three.js.src.renderers.shaders.ShaderChunk.begin_vertex;
import three.js.src.renderers.shaders.ShaderChunk.project_vertex;
import three.js.src.renderers.shaders.ShaderChunk.tonemapping_fragment;
import three.js.src.renderers.shaders.ShaderChunk.colorspace_fragment;

class Cube {
    static var vertex:String =
        "varying vec3 vWorldDirection;" +
        common +
        "void main() {" +
        "   vWorldDirection = transformDirection( position, modelMatrix );" +
        begin_vertex +
        project_vertex +
        "   gl_Position.z = gl_Position.w; // set z to camera.far" +
        "}";

    static var fragment:String =
        "uniform samplerCube tCube;" +
        "uniform float tFlip;" +
        "uniform float opacity;" +
        "varying vec3 vWorldDirection;" +
        "void main() {" +
        "   vec4 texColor = textureCube( tCube, vec3( tFlip * vWorldDirection.x, vWorldDirection.yz ) );" +
        "   gl_FragColor = texColor;" +
        "   gl_FragColor.a *= opacity;" +
        tonemapping_fragment +
        colorspace_fragment +
        "}";
}
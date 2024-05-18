package three.shaderlib;

import haxe.Http;
import hxsl.Shader;

class CubeShader {
    static var vertexShader = new Shader({
        var vWorldDirection:Vec3;

        function main() {
            vWorldDirection = transformDirection(position, modelMatrix);
            include("begin_vertex");
            include("project_vertex");
            gl_Position.z = gl_Position.w; // set z to camera.far
        }
    });

    static var fragmentShader = new Shader({
        var tCube:SamplerCube;
        var tFlip:Float;
        var opacity:Float;
        var vWorldDirection:Vec3;

        function main() {
            var texColor:Vec4 = textureCube(tCube, vec3(tFlip * vWorldDirection.x, vWorldDirection.yz));
            gl_FragColor = texColor;
            gl_FragColor.a *= opacity;
            include("tonemapping_fragment");
            include("colorspace_fragment");
        }
    });
}
package three.js.examples.jvm.shaders;

import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

/**
 * Unpack RGBA depth shader
 * - show RGBA encoded depth as monochrome color
 */
class UnpackDepthRGBAShader {
  public static var NAME:String = 'UnpackDepthRGBAShader';

  public var shader:Shader;

  public function new() {
    var vertexShader:String = "
      varying vec2 vUv;

      void main() {
        vUv = uv;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }
    ";

    var fragmentShader:String = "
      uniform float opacity;
      uniform sampler2D tDiffuse;
      varying vec2 vUv;

      #include <packing>

      void main() {
        float depth = 1.0 - unpackRGBAToDepth(texture2D(tDiffuse, vUv));
        gl_FragColor = vec4(vec3(depth), opacity);
      }
    ";

    shader = new Shader();
    shader.glslVersion = Shader.GLSL_150;

    shader.vertexShader = vertexShader;
    shader.fragmentShader = fragmentShader;

    var tDiffuse:ShaderInput<openfl.display.Texture> = new ShaderInput<openfl.display.Texture>("tDiffuse");
    shader.addInput(tDiffuse);

    var opacity:ShaderParameter<Float> = new ShaderParameter<Float>("opacity", 1.0);
    shader.addParameter(opacity);
  }
}
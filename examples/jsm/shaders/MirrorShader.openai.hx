package three.js.examples.javascript.shaders;

import js.html.webgl.Shader;
import js.html.webgl.UniformLocation;
import js.html.webgl.Texture;

/**
 * Mirror Shader
 * Copies half the input to the other half
 *
 * side: side of input to mirror (0 = left, 1 = right, 2 = top, 3 = bottom)
 */
class MirrorShader {
  public static var NAME:String = 'MirrorShader';

  public var uniforms:Dynamic = {
    'tDiffuse': { value: null },
    'side': { value: 1 }
  };

  public var vertexShader:String = '
    varying vec2 vUv;

    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }';

  public var fragmentShader:String = '
    uniform sampler2D tDiffuse;
    uniform int side;

    varying vec2 vUv;

    void main() {
      vec2 p = vUv;
      if (side == 0){
        if (p.x > 0.5) p.x = 1.0 - p.x;
      }else if (side == 1){
        if (p.x < 0.5) p.x = 1.0 - p.x;
      }else if (side == 2){
        if (p.y < 0.5) p.y = 1.0 - p.y;
      }else if (side == 3){
        if (p.y > 0.5) p.y = 1.0 - p.y;
      }
      vec4 color = texture2D(tDiffuse, p);
      gl_FragColor = color;
    }';
}

Note that I've used the `Dynamic` type to represent the `uniforms` object, since it's a JavaScript object with dynamic properties. I've also used the `String` type to represent the shader code, since Haxe doesn't have a built-in type for GLSL code.

Also, I've kept the `NAME` property as a static variable, since it's not an instance property.

You can use this class in your Haxe code like this:

var shader:MirrorShader = new MirrorShader();
// ...
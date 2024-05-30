package three.js.examples.jsm.shaders;

// Full-screen textured quad shader

class CopyShader {
  public static var name:String = 'CopyShader';

  public static var uniforms:Dynamic = {
    tDiffuse: { value: null },
    opacity: { value: 1.0 }
  };

  public static var vertexShader:String = '
    varying vec2 vUv;
    void main() {
      vUv = uv;
      gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }
  ';

  public static var fragmentShader:String = '
    uniform float opacity;
    uniform sampler2D tDiffuse;
    varying vec2 vUv;
    void main() {
      vec4 texel = texture2D( tDiffuse, vUv );
      gl_FragColor = opacity * texel;
    }
  ';
}

Note that in Haxe, we use the `public static` keywords to define the `uniforms`, `vertexShader`, and `fragmentShader` fields as static members of the `CopyShader` class. We also use the `Dynamic` type to define the `uniforms` object, which can contain arbitrary key-value pairs.

Also, in Haxe, strings are enclosed in single quotes `'` instead of backticks `
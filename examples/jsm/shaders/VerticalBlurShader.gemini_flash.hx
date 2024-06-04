import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class VerticalBlurShader extends Shader {

  public static var name:String = "VerticalBlurShader";

  public var tDiffuse:ShaderParameter;
  public var v:ShaderParameter;

  public function new() {
    super();

    this.tDiffuse = new ShaderParameter(ShaderInput.SAMPLER2D);
    this.v = new ShaderParameter(ShaderInput.FLOAT);

    this.uniforms = [
      this.tDiffuse,
      this.v,
    ];

    this.vertexSource = """
        varying vec2 vUv;

        void main() {

          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

        }
    """;

    this.fragmentSource = """
        uniform sampler2D tDiffuse;
        uniform float v;

        varying vec2 vUv;

        void main() {

          vec4 sum = vec4( 0.0 );

          sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 4.0 * v ) ) * 0.051;
          sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 3.0 * v ) ) * 0.0918;
          sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 2.0 * v ) ) * 0.12245;
          sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 1.0 * v ) ) * 0.1531;
          sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y ) ) * 0.1633;
          sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 1.0 * v ) ) * 0.1531;
          sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 2.0 * v ) ) * 0.12245;
          sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 3.0 * v ) ) * 0.0918;
          sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 4.0 * v ) ) * 0.051;

          gl_FragColor = sum;

        }
    """;
  }
}
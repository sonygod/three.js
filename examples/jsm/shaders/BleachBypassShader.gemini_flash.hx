import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.utils.ByteArray;

class BleachBypassShader extends Shader {

	public static var name:String = "BleachBypassShader";

	public var tDiffuse:ShaderInput;
	public var opacity:ShaderParameter;

	public function new() {
		super();
		this.tDiffuse = new ShaderInput(ShaderInput.SAMPLER);
		this.opacity = new ShaderParameter(ShaderParameter.FLOAT);

		var vertexShaderCode:String = """
			varying vec2 vUv;

			void main() {

				vUv = uv;
				gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

			}
		""";

		var fragmentShaderCode:String = """
			uniform float opacity;

			uniform sampler2D tDiffuse;

			varying vec2 vUv;

			void main() {

				vec4 base = texture2D( tDiffuse, vUv );

				vec3 lumCoeff = vec3( 0.25, 0.65, 0.1 );
				float lum = dot( lumCoeff, base.rgb );
				vec3 blend = vec3( lum );

				float L = min( 1.0, max( 0.0, 10.0 * ( lum - 0.45 ) ) );

				vec3 result1 = 2.0 * base.rgb * blend;
				vec3 result2 = 1.0 - 2.0 * ( 1.0 - blend ) * ( 1.0 - base.rgb );

				vec3 newColor = mix( result1, result2, L );

				float A2 = opacity * base.a;
				vec3 mixRGB = A2 * newColor.rgb;
				mixRGB += ( ( 1.0 - A2 ) * base.rgb );

				gl_FragColor = vec4( mixRGB, base.a );

			}
		""";

		var vertexShaderBytes:ByteArray = new ByteArray();
		vertexShaderBytes.writeUTFBytes(vertexShaderCode);
		this.vertexShader = vertexShaderBytes;

		var fragmentShaderBytes:ByteArray = new ByteArray();
		fragmentShaderBytes.writeUTFBytes(fragmentShaderCode);
		this.fragmentShader = fragmentShaderBytes;
	}

}
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.utils.ByteArray;

class UnpackDepthRGBAShader extends Shader {

	public static var name:String = "UnpackDepthRGBAShader";

	public function new() {
		super();

		// Uniforms
		uniforms.set("tDiffuse", new ShaderParameter("tDiffuse", ShaderParameterType.TEXTURE));
		uniforms.set("opacity", new ShaderParameter("opacity", ShaderParameterType.FLOAT, 1.0));

		// Vertex shader
		vertexSource = """
			varying vec2 vUv;

			void main() {

				vUv = uv;
				gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

			}
		""";

		// Fragment shader
		fragmentSource = """
			uniform float opacity;

			uniform sampler2D tDiffuse;

			varying vec2 vUv;

			#include <packing>

			void main() {

				float depth = 1.0 - unpackRGBAToDepth( texture2D( tDiffuse, vUv ) );
				gl_FragColor = vec4( vec3( depth ), opacity );

			}
		""";
	}

	// Helper function to convert a ByteArray to a ShaderInput
	private function byteArrayToShaderInput(bytes:ByteArray):ShaderInput {
		return new ShaderInput(bytes.length, bytes.toArray());
	}
}
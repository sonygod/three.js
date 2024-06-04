import openfl.display.Shader;
import openfl.display.ShaderInput;

class VignetteShader extends Shader {

	public static var name:String = "VignetteShader";

	public var offset:Float = 1.0;
	public var darkness:Float = 1.0;

	public function new() {
		super(
			// Vertex Shader
			"""
			varying vec2 vUv;

			void main() {
				vUv = uv;
				gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
			}
			""",

			// Fragment Shader
			"""
			uniform float offset;
			uniform float darkness;
			uniform sampler2D tDiffuse;

			varying vec2 vUv;

			void main() {
				// Eskil's vignette
				vec4 texel = texture2D( tDiffuse, vUv );
				vec2 uv = ( vUv - vec2( 0.5 ) ) * vec2( offset );
				gl_FragColor = vec4( mix( texel.rgb, vec3( 1.0 - darkness ), dot( uv, uv ) ), texel.a );
			}
			"""
		);
		this.uniforms.set("tDiffuse", new ShaderInput(ShaderInput.SAMPLER));
		this.uniforms.set("offset", new ShaderInput(ShaderInput.FLOAT));
		this.uniforms.set("darkness", new ShaderInput(ShaderInput.FLOAT));
	}

	public function setOffset(offset:Float):Void {
		this.offset = offset;
		this.uniforms.set("offset", new ShaderInput(ShaderInput.FLOAT, offset));
	}

	public function setDarkness(darkness:Float):Void {
		this.darkness = darkness;
		this.uniforms.set("darkness", new ShaderInput(ShaderInput.FLOAT, darkness));
	}

}
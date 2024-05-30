package openfl.filters;

import openfl._internal.renderer.opengl.shaders.Shader;
import openfl.filters.BitmapFilterShader;

class VerticalBlurShader extends Shader implements BitmapFilterShader
{
	public var tDiffuse:Int;
	public var v:Float;

	public function new()
	{
		super();

		init();
	}

	override public function init()
	{
		super.init();

		vertexSrc =
			"varying vec2 vUv;" +
			"void main() {" +
			"vUv = uv;" +
			"gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );" +
			"}";

		fragmentSrc =
			"uniform sampler2D tDiffuse;" +
			"uniform float v;" +
			"varying vec2 vUv;" +
			"void main() {" +
			"vec4 sum = vec4( 0.0 );" +
			"sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 4.0 * v ) ) * 0.051;" +
			"sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 3.0 * v ) ) * 0.0918;" +
			"sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 2.0 * v ) ) * 0.12245;" +
			"sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y - 1.0 * v ) ) * 0.1531;" +
			"sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y ) ) * 0.1633;" +
			"sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 1.0 * v ) ) * 0.1531;" +
			"sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 2.0 * v ) ) * 0.12245;" +
			"sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 3.0 * v ) ) * 0.0918;" +
			"sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y + 4.0 * v ) ) * 0.051;" +
			"gl_FragColor = sum;" +
			"}";
	}
}
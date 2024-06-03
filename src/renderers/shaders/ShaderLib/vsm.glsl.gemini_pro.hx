import haxe.io.Bytes;
import openfl.display.Shader;
import openfl.utils.ByteArray;

class VSM {

	public static function getVertex():Shader {
		return new Shader(vertexCode, null);
	}

	public static function getFragment():Shader {
		return new Shader(null, fragmentCode);
	}

	static var vertexCode:String = """
		void main() {

			gl_Position = vec4( position, 1.0 );

		}
	""";

	static var fragmentCode:String = """
		uniform sampler2D shadow_pass;
		uniform vec2 resolution;
		uniform float radius;

		#include <packing>

		void main() {

			const float samples = float( VSM_SAMPLES );

			float mean = 0.0;
			float squared_mean = 0.0;

			float uvStride = samples <= 1.0 ? 0.0 : 2.0 / ( samples - 1.0 );
			float uvStart = samples <= 1.0 ? 0.0 : - 1.0;
			for ( float i = 0.0; i < samples; i ++ ) {

				float uvOffset = uvStart + i * uvStride;

				#ifdef HORIZONTAL_PASS

					vec2 distribution = unpackRGBATo2Half( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( uvOffset, 0.0 ) * radius ) / resolution ) );
					mean += distribution.x;
					squared_mean += distribution.y * distribution.y + distribution.x * distribution.x;

				#else

					float depth = unpackRGBAToDepth( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( 0.0, uvOffset ) * radius ) / resolution ) );
					mean += depth;
					squared_mean += depth * depth;

				#endif

			}

			mean = mean / samples;
			squared_mean = squared_mean / samples;

			float std_dev = sqrt( squared_mean - mean * mean );

			gl_FragColor = pack2HalfToRGBA( vec2( mean, std_dev ) );

		}
	""";

	static function unpackRGBATo2Half( rgba:Bytes ):vec2 {
		// TODO: Implement unpackRGBATo2Half function
		return new vec2(0, 0);
	}

	static function unpackRGBAToDepth( rgba:Bytes ):Float {
		// TODO: Implement unpackRGBAToDepth function
		return 0;
	}

	static function pack2HalfToRGBA( halfs:vec2 ):Bytes {
		// TODO: Implement pack2HalfToRGBA function
		return new Bytes();
	}
}

class vec2 {
	public var x:Float;
	public var y:Float;

	public function new(x:Float, y:Float) {
		this.x = x;
		this.y = y;
	}
}
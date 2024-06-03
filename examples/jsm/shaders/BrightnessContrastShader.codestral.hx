class BrightnessContrastShader {

    public static var name:String = "BrightnessContrastShader";

    public static var uniforms:Map<String, Dynamic> = new Map<String, Dynamic>();

    public static var vertexShader:String = "varying vec2 vUv;\n\
		void main() {\n\
			vUv = uv;\n\
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n\
		}";

    public static var fragmentShader:String = "uniform sampler2D tDiffuse;\n\
		uniform float brightness;\n\
		uniform float contrast;\n\
		varying vec2 vUv;\n\
		void main() {\n\
			gl_FragColor = texture2D( tDiffuse, vUv );\n\
			gl_FragColor.rgb += brightness;\n\
			if (contrast > 0.0) {\n\
				gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) / (1.0 - contrast) + 0.5;\n\
			} else {\n\
				gl_FragColor.rgb = (gl_FragColor.rgb - 0.5) * (1.0 + contrast) + 0.5;\n\
			}\n\
		}";

    static function new() {
        uniforms.set("tDiffuse", null);
        uniforms.set("brightness", 0);
        uniforms.set("contrast", 0);
    }
}
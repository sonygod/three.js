package three.js.shaders;

class OutputShader {
    public static var NAME:String = 'OutputShader';

    public static var uniforms:Map<String, {value:Dynamic}> = [
        'tDiffuse' => { value: null },
        'toneMappingExposure' => { value: 1 }
    ];

    public static var vertexShader:String = "
        precision highp float;

        uniform mat4 modelViewMatrix;
        uniform mat4 projectionMatrix;

        attribute vec3 position;
        attribute vec2 uv;

        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ";

    public static var fragmentShader:String = "
        precision highp float;

        uniform sampler2D tDiffuse;

        #include <tonemapping_pars_fragment>
        #include <colorspace_pars_fragment>

        varying vec2 vUv;

        void main() {
            gl_FragColor = texture2D( tDiffuse, vUv );

            // tone mapping
            #if LINEAR_TONE_MAPPING
                gl_FragColor.rgb = LinearToneMapping( gl_FragColor.rgb );
            #elseif REINHARD_TONE_MAPPING
                gl_FragColor.rgb = ReinhardToneMapping( gl_FragColor.rgb );
            #elseif CINEON_TONE_MAPPING
                gl_FragColor.rgb = OptimizedCineonToneMapping( gl_FragColor.rgb );
            #elseif ACES_FILMIC_TONE_MAPPING
                gl_FragColor.rgb = ACESFilmicToneMapping( gl_FragColor.rgb );
            #elseif AGX_TONE_MAPPING
                gl_FragColor.rgb = AgXToneMapping( gl_FragColor.rgb );
            #elseif NEUTRAL_TONE_MAPPING
                gl_FragColor.rgb = NeutralToneMapping( gl_FragColor.rgb );
            #end

            // color space
            #if SRGB_TRANSFER
                gl_FragColor = sRGBTransferOETF( gl_FragColor );
            #end
        }
    ";
}

Note that in Haxe, we use `Map<String, {value:Dynamic}>` to define the `uniforms` object, and `String` literals for the shader code. We also use `#if` and `#elseif` directives to conditionally compile the shader code based on the defined constants.

Also, note that Haxe does not have a direct equivalent to JavaScript's `export` statement, so I removed it from the code. If you need to export the `OutputShader` class, you can use Haxe's built-in `extern` keyword, like this:

extern class OutputShader {
    // ...
}
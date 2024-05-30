package three.js.examples.jm.shaders;

import three.Color;

class LuminosityHighPassShader {
    public static var name:String = 'LuminosityHighPassShader';
    public static var shaderID:String = 'luminosityHighPass';

    public static var uniforms(default, null):{ 
        tDiffuse:{ value:Null<FloatTexture> },
        luminosityThreshold:{ value:Float },
        smoothWidth:{ value:Float },
        defaultColor:{ value:Color },
        defaultOpacity:{ value:Float }
    } = {
        tDiffuse: { value: null },
        luminosityThreshold: { value: 1.0 },
        smoothWidth: { value: 1.0 },
        defaultColor: { value: new Color(0x000000) },
        defaultOpacity: { value: 0.0 }
    };

    public static var vertexShader:String = '
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }';

    public static var fragmentShader:String = '
        uniform sampler2D tDiffuse;
        uniform vec3 defaultColor;
        uniform float defaultOpacity;
        uniform float luminosityThreshold;
        uniform float smoothWidth;

        varying vec2 vUv;

        void main() {
            vec4 texel = texture2D( tDiffuse, vUv );

            vec3 luma = vec3( 0.299, 0.587, 0.114 );

            float v = dot( texel.xyz, luma );

            vec4 outputColor = vec4( defaultColor.rgb, defaultOpacity );

            float alpha = smoothstep( luminosityThreshold, luminosityThreshold + smoothWidth, v );

            gl_FragColor = mix( outputColor, texel, alpha );
        }';
}
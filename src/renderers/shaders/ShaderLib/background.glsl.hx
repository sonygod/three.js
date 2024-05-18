package three.renderers.shaders;

import openfl.display.GLShader;

class BackgroundShader {
    public static var vertexShader:GLShader = new GLShader("
        #ifdef GL_ES
        precision mediump float;
        #endif

        varying vec2 vUv;
        uniform mat3 uvTransform;

        void main() {
            vUv = (uvTransform * vec3(uv, 1.0)).xy;
            gl_Position = vec4(position.xy, 1.0, 1.0);
        }
    ");

    public static var fragmentShader:GLShader = new GLShader("
        #ifdef GL_ES
        precision mediump float;
        #endif

        uniform sampler2D t2D;
        uniform float backgroundIntensity;
        varying vec2 vUv;

        void main() {
            vec4 texColor = texture2D(t2D, vUv);

            #ifdef DECODE_VIDEO_TEXTURE
            texColor = vec4(mix(pow(texColor.rgb * 0.9478672986 + vec3(0.0521327014), vec3(2.4)), texColor.rgb * 0.0773993808, vec3(lessThanEqual(texColor.rgb, vec3(0.04045)))));
            #endif

            texColor.rgb *= backgroundIntensity;
            gl_FragColor = texColor;
            #include <tonemapping_fragment>
            #include <colorspace_fragment>
        }
    ");
}
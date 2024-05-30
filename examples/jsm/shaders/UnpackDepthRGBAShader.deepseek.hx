/**
 * Unpack RGBA depth shader
 * - show RGBA encoded depth as monochrome color
 */

class UnpackDepthRGBAShader {

    static var name:String = 'UnpackDepthRGBAShader';

    static var uniforms:Map<String, Dynamic> = {

        'tDiffuse': { value: null },
        'opacity': { value: 1.0 }

    };

    static var vertexShader:String = `

        varying vec2 vUv;

        void main() {

            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

        }`;

    static var fragmentShader:String = `

        uniform float opacity;

        uniform sampler2D tDiffuse;

        varying vec2 vUv;

        // Haxe doesn't support #include, so you'll need to manually include the packing function
        // float unpackRGBAToDepth( vec4 v ) {
        //    return dot( v, vec4( 1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0 ) );
        // }

        void main() {

            float depth = 1.0 - unpackRGBAToDepth( texture2D( tDiffuse, vUv ) );
            gl_FragColor = vec4( vec3( depth ), opacity );

        }`;

}
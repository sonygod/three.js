package;

class DOFMipMapShader {
    public var name: String = 'DOFMipMapShader';
    public var uniforms: { [key: String]: { value: Dynamic } } = {
        'tColor': { value: null },
        'tDepth': { value: null },
        'focus': { value: 1.0 },
        'maxblur': { value: 1.0 }
    };

    public var vertexShader: String =
        'varying vec2 vUv;\n' +
        'void main() {\n' +
        '   vUv = uv;\n' +
        '   gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n' +
        '}';

    public var fragmentShader: String =
        'uniform float focus;\n' +
        'uniform float maxblur;\n' +
        'uniform sampler2D tColor;\n' +
        'uniform sampler2D tDepth;\n' +
        'varying vec2 vUv;\n' +
        'void main() {\n' +
        '   vec4 depth = texture2D(tDepth, vUv);\n' +
        '   float factor = depth.x - focus;\n' +
        '   vec4 col = texture2D(tColor, vUv, 2.0 * maxblur * abs(focus - depth.x));\n' +
        '   gl_FragColor = col;\n' +
        '   gl_FragColor.a = 1.0;\n' +
        '}';
}
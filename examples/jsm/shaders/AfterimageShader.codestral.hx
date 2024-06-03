import js.html.WebGLRenderingContext;

class AfterimageShader {
    var name:String = "AfterimageShader";
    var uniforms:Dynamic = {
        'damp': { value: 0.96 },
        'tOld': { value: null },
        'tNew': { value: null }
    };
    var vertexShader:String = "varying vec2 vUv;\n\nvoid main() {\n\n\tvUv = uv;\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n\n}";
    var fragmentShader:String = "uniform float damp;\n\nuniform sampler2D tOld;\nuniform sampler2D tNew;\n\nvarying vec2 vUv;\n\nvec4 when_gt( vec4 x, float y ) {\n\n\treturn max( sign( x - y ), 0.0 );\n\n}\n\nvoid main() {\n\n\tvec4 texelOld = texture2D( tOld, vUv );\n\tvec4 texelNew = texture2D( tNew, vUv );\n\n\ttexelOld *= damp * when_gt( texelOld, 0.1 );\n\n\tgl_FragColor = max(texelNew, texelOld);\n}";

    public function new() {}
}
package three.js.examples.jm.shaders;

import openfl.display.Shader;

class RGBShiftShader {

    public static var NAME:String = 'RGBShiftShader';

    public var uniforms:Array<Dynamic> = [
        { name: 'tDiffuse', type: 'sampler2D', value: null },
        { name: 'amount', type: 'float', value: 0.005 },
        { name: 'angle', type: 'float', value: 0.0 }
    ];

    public var vertexShader:String = "
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    ";

    public var fragmentShader:String = "
        uniform sampler2D tDiffuse;
        uniform float amount;
        uniform float angle;

        varying vec2 vUv;

        void main() {
            vec2 offset = amount * vec2(cos(angle), sin(angle));
            vec4 cr = texture2D(tDiffuse, vUv + offset);
            vec4 cga = texture2D(tDiffuse, vUv);
            vec4 cb = texture2D(tDiffuse, vUv - offset);
            gl_FragColor = vec4(cr.r, cga.g, cb.b, cga.a);
        }
    ";

    public function new() {}

}

// export
extern class RGBShiftShader {}

Note that Haxe uses a different syntax and structure than JavaScript, so the code has been adapted to conform to Haxe's conventions. Additionally, Haxe does not have a direct equivalent to JavaScript's `export` statement, so the `extern` keyword is used to declare the `RGBShiftShader` class as an extern class, which allows it to be accessed from outside the module.

Also, in Haxe, shaders are typically defined as `Shader` objects, so the `RGBShiftShader` class could be used to create an instance of a `Shader` object, like this:

var shader:Shader = new Shader(RGBShiftShader.vertexShader, RGBShiftShader.fragmentShader);
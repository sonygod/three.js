Here is the converted Haxe code:
```
package three.js.examples.jm.shaders;

import openfl.display.Shader;

class HorizontalTiltShiftShader {
    public static var NAME:String = 'HorizontalTiltShiftShader';

    private static var shader:Shader;

    public static function init():Shader {
        if (shader == null) {
            shader = new Shader();
            shader.glslVersion = ShaderVersion.GL2;

            shader.vertexShader = '
                varying vec2 vUv;

                void main() {
                    vUv = uv;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
                }
            ';

            shader.fragmentShader = '
                uniform sampler2D tDiffuse;
                uniform float h;
                uniform float r;

                varying vec2 vUv;

                void main() {
                    vec4 sum = vec4( 0.0 );

                    float hh = h * abs( r - vUv.y );

                    sum += texture2D( tDiffuse, vec2( vUv.x - 4.0 * hh, vUv.y ) ) * 0.051;
                    sum += texture2D( tDiffuse, vec2( vUv.x - 3.0 * hh, vUv.y ) ) * 0.0918;
                    sum += texture2D( tDiffuse, vec2( vUv.x - 2.0 * hh, vUv.y ) ) * 0.12245;
                    sum += texture2D( tDiffuse, vec2( vUv.x - 1.0 * hh, vUv.y ) ) * 0.1531;
                    sum += texture2D( tDiffuse, vec2( vUv.x, vUv.y ) ) * 0.1633;
                    sum += texture2D( tDiffuse, vec2( vUv.x + 1.0 * hh, vUv.y ) ) * 0.1531;
                    sum += texture2D( tDiffuse, vec2( vUv.x + 2.0 * hh, vUv.y ) ) * 0.12245;
                    sum += texture2D( tDiffuse, vec2( vUv.x + 3.0 * hh, vUv.y ) ) * 0.0918;
                    sum += texture2D( tDiffuse, vec2( vUv.x + 4.0 * hh, vUv.y ) ) * 0.051;

                    gl_FragColor = sum;
                }
            ';

            shader.data.tDiffuse.input = true;
            shader.data.h.value = [1.0 / 512.0];
            shader.data.r.value = [0.35];
        }
        return shader;
    }
}
```
Note that I've used the `openfl.display.Shader` class to create a shader object in Haxe. I've also used the `ShaderVersion.GL2` to specify the shader version.

I've also removed the `export` statement and replaced it with a `public static function init():Shader` method that returns the shader object.

Also, I've used Haxe's syntax for shader programming, which is similar to GLSL.
package three.js.examples.jm.shaders;

import glm.Vec4;
import glm.Mat4;

class BasicShader {
    public var name:String = 'BasicShader';
    public var uniforms:Dynamic = {};

    public var vertexShader:String = "
        void main() {
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ";

    public var fragmentShader:String = "
        void main() {
            gl_FragColor = vec4( 1.0, 0.0, 0.0, 0.5 );
        }
    ";
}
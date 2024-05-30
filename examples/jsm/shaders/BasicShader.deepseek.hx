/**
 * Simple test shader
 */

class BasicShader {

    static var name:String = 'BasicShader';

    static var uniforms:Dynamic = {};

    static var vertexShader:String = 
        "void main() {" +
        "gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );" +
        "}";

    static var fragmentShader:String = 
        "void main() {" +
        "gl_FragColor = vec4( 1.0, 0.0, 0.0, 0.5 );" +
        "}";

}
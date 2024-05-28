import openfl.display.DisplayObject;
import openfl.display.BitmapData;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;

class SpecularShader extends Shader {
    public var specularStrength:Float;

    public function new() {
        super();
        init();
    }

    override function init() {
        #if js-html5
        var gl = openfl.Lib.current.context3D.gl;
        #end

        // Define the vertex shader
        #if js-html5
        var vertexSrc = gl.createShader(gl.VERTEX_SHADER);
        #else
        var vertexSrc = "";
        #end
        #if js-html5
        gl.shaderSource(vertexSrc, "
            attribute vec2 aVertexPosition;
            attribute vec2 aTextureCoord;

            uniform mat3 projectionMatrix;

            varying vec2 vTextureCoord;

            void main(void) {
                gl_Position = vec4((projectionMatrix * vec3(aVertexPosition, 1.0)).xy, 0.0, 1.0);
                vTextureCoord = aTextureCoord;
            }
        ");
        #end
        #if js-html5
        gl.compileShader(vertexSrc);
        #end

        // Define the fragment shader
        #if js-html5
        var fragmentSrc = gl.createShader(gl.FRAGMENT_SHADER);
        #else
        var fragmentSrc = "";
        #end
        #if js-html5
        gl.shaderSource(fragmentSrc, "
            precision mediump float;

            varying vec2 vTextureCoord;

            uniform sampler2D uSampler;
            uniform sampler2D specularMap;

            uniform float specularStrength;

            void main(void) {
                vec4 color = texture2D(uSampler, vTextureCoord);

                #ifdef USE_SPECULARMAP
                    vec4 texelSpecular = texture2D(specularMap, vTextureCoord);
                    specularStrength = texelSpecular.r;
                #else
                    specularStrength = 1.0;
                #endif

                gl_FragColor = color + vec4(specularStrength, specularStrength, specularStrength, 1.0);
            }
        ");
        #end
        #if js-html5
        gl.compileShader(fragmentSrc);
        #end

        // Link the shader program
        #if js-html5
        var shaderProgram = gl.createProgram();
        gl.attachShader(shaderProgram, vertexSrc);
        gl.attachShader(shaderProgram, fragmentSrc);
        gl.linkProgram(shaderProgram);
        #end

        // Get the shader parameters
        #if js-html5
        aVertexPosition = gl.getAttribLocation(shaderProgram, "aVertexPosition");
        aTextureCoord = gl.getAttribLocation(shaderProgram, "aTextureCoord");
        uSampler = gl.getUniformLocation(shaderProgram, "uSampler");
        specularMap = gl.getUniformLocation(shaderProgram, "specularMap");
        #end

        // Set the shader parameters
        #if js-html5
        gl.enableVertexAttribArray(aVertexPosition);
        gl.enableVertexAttribArray(aTextureCoord);
        gl.uniform1i(uSampler, 0);
        #end

        // Define the shader parameters
        specularStrength = 1.0;

        // Set the shader program
        #if js-html5
        gl.useProgram(shaderProgram);
        #end
    }
}
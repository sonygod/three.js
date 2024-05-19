import js.Browser;
import js.webgl.WebGL;
import js.webgl.WebGLProgram;
import js.webgl.WebGLShader;
import js.webgl.WebGLUniformLocation;

class ShaderChunk {
    static var gl:WebGL;
    static var program:WebGLProgram;

    static function init(gl:WebGL) {
        this.gl = gl;
        this.program = gl.createProgram();

        var vertexShader = this.createShader(gl, gl.VERTEX_SHADER, this.getVertexShaderSource());
        var fragmentShader = this.createShader(gl, gl.FRAGMENT_SHADER, this.getFragmentShaderSource());

        gl.attachShader(this.program, vertexShader);
        gl.attachShader(this.program, fragmentShader);
        gl.linkProgram(this.program);

        if (!gl.getProgramParameter(this.program, gl.LINK_STATUS)) {
            throw 'Unable to initialize the shader program: ' + gl.getProgramInfoLog(this.program);
        }
    }

    static function createShader(gl:WebGL, type:Int, source:String):WebGLShader {
        var shader = gl.createShader(type);
        gl.shaderSource(shader, source);
        gl.compileShader(shader);

        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            throw 'An error occurred compiling the shaders: ' + gl.getShaderInfoLog(shader);
        }

        return shader;
    }

    static function getVertexShaderSource():String {
        return `
            attribute float batchId;
            uniform highp sampler2D batchingTexture;
            mat4 getBatchingMatrix( const in float i ) {
                int size = textureSize( batchingTexture, 0 ).x;
                int j = int( i ) * 4;
                int x = j % size;
                int y = j / size;
                vec4 v1 = texelFetch( batchingTexture, ivec2( x, y ), 0 );
                vec4 v2 = texelFetch( batchingTexture, ivec2( x + 1, y ), 0 );
                vec4 v3 = texelFetch( batchingTexture, ivec2( x + 2, y ), 0 );
                vec4 v4 = texelFetch( batchingTexture, ivec2( x + 3, y ), 0 );
                return mat4( v1, v2, v3, v4 );
            }
        `;
    }

    static function getFragmentShaderSource():String {
        return `
            uniform sampler2D batchingColorTexture;
            vec3 getBatchingColor( const in float i ) {
                int size = textureSize( batchingColorTexture, 0 ).x;
                int j = int( i );
                int x = j % size;
                int y = j / size;
                return texelFetch( batchingColorTexture, ivec2( x, y ), 0 ).rgb;
            }
        `;
    }
}
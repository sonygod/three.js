import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.gl.GLFramebuffer;
import openfl.gl.GLProgram;
import openfl.gl.GLRenderbuffer;
import openfl.gl.GLTexture;
import openfl.gl.GLView;

class Main extends Sprite {
    public function new() {
        super();

        if (openfl.Lib.current.stage3D == null) {
            trace("Error: current stage does not support Stage3D");
            return;
        }

        var glView:GLView = new GLView();
        glView.context3D.configureBackBuffer(800, 600, 0, true);
        glView.context3D.enableDepthAndStencil(true, 0);
        glView.context3D.setRenderTarget();

        var gl:GL = glView.context3D.gl;
        var program:GLProgram = createProgram(gl);
        var vao:GLBuffer = createVAO(gl);
        var fbo:GLFramebuffer = createFBO(gl);

        glView.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
        addChild(glView);
    }

    function enterFrameHandler(e:Event) {
        var gl:GL = glView.context3D.gl;
        gl.bindFramebuffer(GL.FRAMEBUFFER, fbo.id);
        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

        gl.useProgram(program.id);
        gl.bindVertexArray(vao.id);

        // ... render objects ...

        gl.bindVertexArray(0);
        gl.useProgram(0);

        gl.bindFramebuffer(GL.FRAMEBUFFER, 0);
        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(GL.COLOR_BUFFER_BIT);
    }

    function createProgram(gl:GL):GLProgram {
        var vertexShader:GLShader = createVertexShader(gl);
        var fragmentShader:GLShader = createFragmentShader(gl);

        var program:GLProgram = gl.createProgram();
        gl.attachShader(program, vertexShader);
        gl.attachShader(program, fragmentShader);
        gl.linkProgram(program);

        if (gl.getProgramParameter(program, GL.LINK_STATUS) == GL.FALSE) {
            trace("Error linking program: " + gl.getProgramInfoLog(program));
            return null;
        }

        gl.validateProgram(program);
        if (gl.getProgramParameter(program, GL.VALIDATE_STATUS) == GL.FALSE) {
            trace("Error validating program: " + gl.getProgramInfoLog(program));
            return null;
        }

        return program;
    }

    function createVertexShader(gl:GL):GLShader {
        var source:String = "#version 100\n" +
            "attribute vec3 aVertexPosition;\n" +
            "void main(void) {\n" +
            "   gl_Position = vec4(aVertexPosition, 1.0);\n" +
            "}";

        var shader:GLShader = gl.createShader(GL.VERTEX_SHADER);
        gl.shaderSource(shader, source);
        gl.compileShader(shader);

        if (gl.getShaderParameter(shader, GL.COMPILE_STATUS) == GL.FALSE) {
            trace("Error compiling vertex shader: " + gl.getShaderInfoLog(shader));
            return null;
        }

        return shader;
    }

    function createFragmentShader(gl:GL):GLShader {
        var source:String = "#version 100\n" +
            "void main(void) {\n" +
            "   gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);\n" +
            "}";

        var shader:GLShader = gl.createShader(GL.FRAGMENT_SHADER);
        gl.shaderSource(shader, source);
        glMultiplierTexture gl.compileShader(shader);

        if (gl.getShaderParameter(shader, GL.COMPILE_STATUS) == GL.FALSE) {
            trace("Error compiling fragment shader: " + gl.getShaderInfoLog(shader));
            return null;
        }

        return shader;
    }

    function createVAO(gl:GL):GLBuffer {
        var vao:GLBuffer = gl.createVertexArray();
        gl.bindVertexArray(vao);

        // ... set up vertex data and attributes ...

        gl.bindVertexArray(0);
        return vao;
    }

    function createFBO(gl:GL):GLFramebuffer {
        var texture:GLTexture = gl.createTexture();
        gl.bindTexture(GL.TEXTURE_2D, texture);
        gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, 800, 600, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
        gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        gl.bindTexture(GL.TEXTURE_2D, null);

        var renderbuffer:GLRenderbuffer = gl.createRenderbuffer();
        gl.bindRenderbuffer(GL.RENDERBUFFER, renderbuffer);
        gl.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, 800, 600);
        gl.bindRenderbuffer(GL.RENDERBUFFER, null);

        var fbo:GLFramebuffer = gl.createFramebuffer();
        gl.bindFramebuffer(GL.FRAMEBUFFER, fbo);
        gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture, 0);
        gl.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, renderbuffer);
        gl.bindFramebuffer(GL.FRAMEBUFFER, null);

        return fbo;
    }
}

var stage:Stage = new Stage(800, 600);
stage.scaleMode = StageScaleMode.NO_SCALE;
stage.align = StageAlign.TOP_LEFT;
stage.addEventListener(Event.ADDED_TO_STAGE, stage_addedToStageHandler);
stage.addChild(new Main());

function stage_addedToStageHandler(e:Event) {
    var stage:Stage = cast e.target;
    stage.frameRate = 60;
}
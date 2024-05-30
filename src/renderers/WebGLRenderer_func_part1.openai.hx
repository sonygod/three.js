package three.renderers;

import three.constants.REVISION;
import three.math.Color;
import three.math.Frustum;
import three.math.Matrix4;
import three.math.Vector3;
import three.math.Vector4;
import three.webgl.WebGLAnimation;
import three.webgl.WebGLAttributes;
import three.webgl.WebGLBackground;
import three.webgl.WebGLBindingStates;
import three.webgl.WebGLBufferRenderer;
import three.webgl.WebGLCapabilities;
import three.webgl.WebGLClipping;
import three.webgl.WebGLCubeMaps;
import three.webgl.WebGLCubeUVMaps;
import three.webgl.WebGLExtensions;
import three.webgl.WebGLGeometries;
import three.webgl.WebGLIndexedBufferRenderer;
import three.webgl.WebGLInfo;
import three.webgl.WebGLMorphtargets;
import three.webgl.WebGLObjects;
import three.webgl.WebGLPrograms;
import three.webgl.WebGLProperties;
import three.webgl.WebGLRenderLists;
import three.webgl.WebGLRenderStates;
import three.webgl.WebGLRenderTarget;
import three.webgl.WebGLShadowMap;
import three.webgl.WebGLState;
import three.webgl.WebGLTextures;
import three.webgl.WebGLUniforms;
import three.webgl.WebGLUtils;
import three.webxr.WebXRManager;
import three.math.ColorManagement;

class WebGLRenderer {
    public var isWebGLRenderer:Bool = true;

    var _alpha:Bool;

    var currentRenderList:Null<WebGLRenderList>;
    var currentRenderState:Null<WebGLRenderState>;

    var renderListStack:Array<WebGLRenderList> = [];
    var renderStateStack:Array<WebGLRenderState> = [];

    var domElement:js.html.CanvasElement;

    var debug:{
        checkShaderErrors:Bool,
        onShaderError:Null<haxe.Constraints.Function>
    } = {
        checkShaderErrors: true,
        onShaderError: null
    };

    // ...

    public function new(?parameters:{}) {
        if (parameters == null) parameters = {};

        var canvas:js.html.CanvasElement = createCanvasElement();
        var context:js.html.webgl.RenderingContext = null;
        var depth:Bool = true;
        var stencil:Bool = false;
        var alpha:Bool = false;
        var antialias:Bool = false;
        var premultipliedAlpha:Bool = true;
        var preserveDrawingBuffer:Bool = false;
        var powerPreference:String = 'default';
        var failIfMajorPerformanceCaveat:Bool = false;

        _alpha = alpha;

        // ...

        initGLContext();

        var xr = new WebXRManager(this, _gl);

        this.xr = xr;

        // API

        public function getContext():js.html.webgl.RenderingContext {
            return _gl;
        }

        public function getContextAttributes():Dynamic {
            return _gl.getContextAttributes();
        }

        public function forceContextLoss():Void {
            // ...
        }

        public function forceContextRestore():Void {
            // ...
        }

        public function getPixelRatio():Float {
            return _pixelRatio;
        }

        public function setPixelRatio(value:Float):Void {
            // ...
        }

        public function getSize(target:Vector2):Vector2 {
            return target.set(_width, _height);
        }

        public function setSize(width:Int, height:Int, updateStyle:Bool = true):Void {
            // ...
        }

        public function getDrawingBufferSize(target:Vector2):Vector2 {
            return target.set(_width * _pixelRatio, _height * _pixelRatio).floor();
        }

        public function setDrawingBufferSize(width:Int, height:Int, pixelRatio:Float):Void {
            // ...
        }

        public function getCurrentViewport(target:Vector4):Vector4 {
            return target.copy(_currentViewport);
        }

        public function getViewport(target:Vector4):Vector4 {
            return target.copy(_viewport);
        }

        public function setViewport(x:Float, y:Float, width:Float, height:Float):Void {
            // ...
        }

        public function getScissor(target:Vector4):Vector4 {
            return target.copy(_scissor);
        }

        public function setScissor(x:Float, y:Float, width:Float, height:Float):Void {
            // ...
        }

        public function getScissorTest():Bool {
            return _scissorTest;
        }

        public function setScissorTest(boolean:Bool):Void {
            state.setScissorTest(_scissorTest = boolean);
        }

        // ...
    }
}
import three.constants.*;
import three.math.*;
import three.renderers.webgl.*;
import three.utils.Utils;
import js.Browser;
import three.scenes.Scene;

#if three_jsm
import three.renderers.webxr.WebXRManager;
#end

@:native("THREE.WebGLRenderer")
class WebGLRenderer {

    public var isWebGLRenderer(default, never) : Bool;

    public var domElement : js.html.CanvasElement;
    public var debug : {
        var checkShaderErrors : Bool;
        var onShaderError : Dynamic;
    };
    public var autoClear : Bool;
    public var autoClearColor : Bool;
    public var autoClearDepth : Bool;
    public var autoClearStencil : Bool;
    public var sortObjects : Bool;
    public var clippingPlanes : Array<Plane>;
    public var localClippingEnabled : Bool;
    public var toneMapping : ToneMapping;
    public var toneMappingExposure : Float;
    public var capabilities(default, never) : WebGLCapabilities;
    public var extensions(default, never) : WebGLExtensions;
    public var properties(default, never) : WebGLProperties;
    public var renderLists(default, never) : WebGLRenderLists;
    public var shadowMap(default, never) : WebGLShadowMap;
    public var state(default, never) : WebGLState;
    public var info(default, never) : WebGLInfo;
    #if three_jsm
    public var xr(default, never) : WebXRManager;
    #end

    public function new(?parameters:Dynamic) {
        #if three_jsm
        var params = {
            canvas : null,
            context : null,
            depth : true,
            stencil : false,
            alpha : false,
            antialias : false,
            premultipliedAlpha : true,
            preserveDrawingBuffer : false,
            powerPreference : "default",
            failIfMajorPerformanceCaveat : false
        };
        if ( parameters != null ) {
            Utils.merge( params, parameters );
        }
        if ( params.context != null ) {
            if ( untyped params.context.getContextAttributes().alpha == null ) {
                params.alpha = true;
            }
        }
        untyped __js__("super(params.canvas, params.context, params.depth, params.stencil, params.alpha, params.antialias, params.premultipliedAlpha, params.preserveDrawingBuffer, params.powerPreference, params.failIfMajorPerformanceCaveat)");
        #else
        untyped __js__("super(parameters)");
        #end
    }

    public function getContext() : Dynamic {
        return untyped __js__("this.getContext()");
    }

    public function getContextAttributes() : Dynamic {
        return untyped __js__("this.getContextAttributes()");
    }

    public function forceContextLoss() : Void {
        untyped __js__("this.forceContextLoss()");
    }

    public function forceContextRestore() : Void {
        untyped __js__("this.forceContextRestore()");
    }

    public function getPixelRatio() : Float {
        return untyped __js__("this.getPixelRatio()");
    }

    public function setPixelRatio(value:Float) : Void {
        untyped __js__("this.setPixelRatio(value)");
    }

    public function getSize(target:Vector2) : Vector2 {
        return untyped __js__("this.getSize(target)");
    }

    public function setSize(width:Float, height:Float, ?updateStyle:Bool) : Void {
        untyped __js__("this.setSize(width, height, updateStyle)");
    }

    public function getDrawingBufferSize(target:Vector2) : Vector2 {
        return untyped __js__("this.getDrawingBufferSize(target)");
    }

    public function setDrawingBufferSize(width:Float, height:Float, pixelRatio:Float) : Void {
        untyped __js__("this.setDrawingBufferSize(width, height, pixelRatio)");
    }

    public function getCurrentViewport(target:Vector4) : Vector4 {
        return untyped __js__("this.getCurrentViewport(target)");
    }

    public function getViewport(target:Vector4) : Vector4 {
        return untyped __js__("this.getViewport(target)");
    }

    public function setViewport(x:Dynamic, ?y:Float, ?width:Float, ?height:Float) : Void {
        if ( Std.is(x, Vector4) ) {
            untyped __js__("this.setViewport(x)");
        } else {
            untyped __js__("this.setViewport(x, y, width, height)");
        }
    }

    public function getScissor(target:Vector4) : Vector4 {
        return untyped __js__("this.getScissor(target)");
    }

    public function setScissor(x:Dynamic, ?y:Float, ?width:Float, ?height:Float) : Void {
        if ( Std.is(x, Vector4) ) {
            untyped __js__("this.setScissor(x)");
        } else {
            untyped __js__("this.setScissor(x, y, width, height)");
        }
    }

    public function getScissorTest() : Bool {
        return untyped __js__("this.getScissorTest()");
    }

    public function setScissorTest(boolean:Bool) : Void {
        untyped __js__("this.setScissorTest(boolean)");
    }

    public function setOpaqueSort(method:Dynamic) : Void {
        untyped __js__("this.setOpaqueSort(method)");
    }

    public function setTransparentSort(method:Dynamic) : Void {
        untyped __js__("this.setTransparentSort(method)");
    }

    public function getClearColor(target:Color) : Color {
        return untyped __js__("this.getClearColor(target)");
    }

    public function setClearColor(color:Dynamic, ?alpha:Float) : Void {
        if ( alpha == null ) {
            untyped __js__("this.setClearColor(color)");
        } else {
            untyped __js__("this.setClearColor(color, alpha)");
        }
    }

    public function getClearAlpha() : Float {
        return untyped __js__("this.getClearAlpha()");
    }

    public function setClearAlpha(alpha:Float) : Void {
        untyped __js__("this.setClearAlpha(alpha)");
    }

    public function clear(?color:Bool, ?depth:Bool, ?stencil:Bool) : Void {
        untyped __js__("this.clear(color, depth, stencil)");
    }

    // clearing

    public function clearColor() : Void {
        untyped __js__("this.clearColor()");
    }

    public function clearDepth() : Void {
        untyped __js__("this.clearDepth()");
    }

    public function clearStencil() : Void {
        untyped __js__("this.clearStencil()");
    }

    public function clearTarget(renderTarget:WebGLRenderTarget, color:Bool, depth:Bool, stencil:Bool) : Void {
        untyped __js__("this.clearTarget(renderTarget, color, depth, stencil)");
    }

    // Reset

    public function reset() : Void {
        untyped __js__("this.reset()");
    }

    // Render scene

    public function render(scene:Scene, camera:Camera) : Void {
        untyped __js__("this.render(scene, camera)");
    }

    public function setAnimationLoop(callback:Dynamic) : Void {
        untyped __js__("this.setAnimationLoop(callback)");
    }

    // Plugins

    public function addPlugin(plugin:Dynamic) : Void {
        untyped __js__("this.addPlugin(plugin)");
    }

    public function getPlugin(pluginType:Dynamic) : Dynamic {
        return untyped __js__("this.getPlugin(pluginType)");
    }

    public function removePlugin(plugin:Dynamic) : Void {
        untyped __js__("this.removePlugin(plugin)");
    }

    // Composing

    public function copyFramebufferToTarget(readFramebuffer:WebGLFramebuffer, renderTarget:WebGLRenderTarget) : Void {
        untyped __js__("this.copyFramebufferToTarget(readFramebuffer, renderTarget)");
    }

    public function copyUniformsToShader(uniforms:Dynamic, shader:Dynamic) : Void {
        untyped __js__("this.copyUniformsToShader(uniforms, shader)");
    }

    public function initTexture(texture:Texture) : Void {
        untyped __js__("this.initTexture(texture)");
    }

    // ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Render Target

    public function getRenderTarget() : WebGLRenderTarget {
        return untyped __js__("this.getRenderTarget()");
    }

    public function setRenderTarget(?renderTarget:WebGLRenderTarget, ?activeCubeFace:Int, ?activeMipmapLevel:Int) : Void {
        untyped __js__("this.setRenderTarget(renderTarget, activeCubeFace, activeMipmapLevel)");
    }

    public function readRenderTargetPixels(renderTarget:WebGLRenderTarget, x:Float, y:Float, width:Float, height:Float, buffer:Dynamic, activeCubeFaceIndex:Int = 0) : Void {
        untyped __js__("this.readRenderTargetPixels(renderTarget, x, y, width, height, buffer, activeCubeFaceIndex)");
    }

    // Fallback filters for non-power-of-2 textures

    public function setTexture2DMaxFilter(texture:Texture, maxFilter:TextureFilter) : Void {
        untyped __js__("this.setTexture2DMaxFilter(texture, maxFilter)");
    }

    public function setTextureCubeMaxFilter(texture:Texture, maxFilter:TextureFilter) : Void {
        untyped __js__("this.setTextureCubeMaxFilter(texture, maxFilter)");
    }

    public function setTextureCubeDynamic(texture:Texture, dynamic:Bool) : Void {
        untyped __js__("this.setTextureCubeDynamic(texture, dynamic)");
    }

    public function getRenderTargetDepth() : WebGLRenderTarget {
        return untyped __js__("this.getRenderTargetDepth()");
    }

    public function setRenderTargetDepth(renderTarget:WebGLRenderTarget) : Void {
        untyped __js__("this.setRenderTargetDepth(renderTarget)");
    }


    public function getRenderTargetCube() : WebGLRenderTarget {
        return untyped __js__("this.getRenderTargetCube()");
    }

    public function setRenderTargetCube(renderTarget:WebGLRenderTarget, activeCubeFace:Int) : Void {
        untyped __js__("this.setRenderTargetCube(renderTarget, activeCubeFace)");
    }

    // Map three.js constants to WebGL constants

    public function get(p:Dynamic) : Int {
        return untyped __js__("this.get(p)");
    }

    // Memory

    public function dispose() : Void {
        untyped __js__("this.dispose()");
    }

}
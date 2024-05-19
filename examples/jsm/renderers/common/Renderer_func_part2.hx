package three.js.examples.jsm.renderers.common;

import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
import js.html.webgl.Framebuffer;
import js.html.webgl.Renderbuffer;
import js.Browser.console;

class Renderer {
    public var backend:Dynamic;
    public var _initialized:Bool;
    public var _pixelRatio:Float;
    public var _width:Int;
    public var _height:Int;
    public var _activeCubeFace:Int;
    public var _activeMipmapLevel:Int;
    public var _scissor:Dynamic;
    public var _scissorTest:Bool;
    public var _viewport:Dynamic;
    public var _clearColor:Dynamic;
    public var _clearDepth:Float;
    public var _clearStencil:Int;
    public var _renderTarget:Dynamic;
    public var _renderObjectFunction:Dynamic;
    public var _info:Dynamic;
    public var _animation:Dynamic;
    public var _objects:Dynamic;
    public var _pipelines:Dynamic;
    public var _nodes:Dynamic;
    public var _bindings:Dynamic;
    public var _renderLists:Dynamic;
    public var _renderContexts:Dynamic;
    public var _textures:Dynamic;
    public var _currentRenderContext:Dynamic;
    public var _currentRenderObjectFunction:Dynamic;

    public function getMaxAnisotropy():Float {
        return backend.getMaxAnisotropy();
    }

    public function getActiveCubeFace():Int {
        return _activeCubeFace;
    }

    public function getActiveMipmapLevel():Int {
        return _activeMipmapLevel;
    }

    public function setAnimationLoop(callback:Void->Void):Void {
        if (!_initialized) init();
        _animation.setAnimationLoop(callback);
    }

    public function getArrayBuffer(attribute:Dynamic):Dynamic {
        console.warn("THREE.Renderer: getArrayBuffer() is deprecated. Use getArrayBufferAsync() instead.");
        return getArrayBufferAsync(attribute);
    }

    public function getArrayBufferAsync(attribute:Dynamic):Dynamic {
        return backend.getArrayBufferAsync(attribute);
    }

    public function getContext():RenderingContext {
        return backend.getContext();
    }

    public function getPixelRatio():Float {
        return _pixelRatio;
    }

    public function getDrawingBufferSize(target:Dynamic):Dynamic {
        return target.set(_width * _pixelRatio, _height * _pixelRatio).floor();
    }

    public function getSize(target:Dynamic):Dynamic {
        return target.set(_width, _height);
    }

    public function setPixelRatio(value:Float = 1):Void {
        _pixelRatio = value;
        setSize(_width, _height, false);
    }

    public function setDrawingBufferSize(width:Int, height:Int, pixelRatio:Float):Void {
        _width = width;
        _height = height;
        _pixelRatio = pixelRatio;
        domElement.width = Math.floor(width * pixelRatio);
        domElement.height = Math.floor(height * pixelRatio);
        setViewport(0, 0, width, height);
        if (_initialized) backend.updateSize();
    }

    public function setSize(width:Int, height:Int, updateStyle:Bool = true):Void {
        _width = width;
        _height = height;
        domElement.width = Math.floor(width * _pixelRatio);
        domElement.height = Math.floor(height * _pixelRatio);
        if (updateStyle) {
            domElement.style.width = width + 'px';
            domElement.style.height = height + 'px';
        }
        setViewport(0, 0, width, height);
        if (_initialized) backend.updateSize();
    }

    public function setOpaqueSort(method:Dynamic):Void {
        _opaqueSort = method;
    }

    public function setTransparentSort(method:Dynamic):Void {
        _transparentSort = method;
    }

    public function getScissor(target:Dynamic):Dynamic {
        const scissor = _scissor;
        target.x = scissor.x;
        target.y = scissor.y;
        target.width = scissor.width;
        target.height = scissor.height;
        return target;
    }

    public function setScissor(x:Float, y:Float, width:Float, height:Float):Void {
        const scissor = _scissor;
        if (x.isVector4) {
            scissor.copy(x);
        } else {
            scissor.set(x, y, width, height);
        }
    }

    public function getScissorTest():Bool {
        return _scissorTest;
    }

    public function setScissorTest(boolean:Bool):Void {
        _scissorTest = boolean;
        backend.setScissorTest(boolean);
    }

    public function getViewport(target:Dynamic):Dynamic {
        return target.copy(_viewport);
    }

    public function setViewport(x:Float, y:Float, width:Float, height:Float, minDepth:Float = 0, maxDepth:Float = 1):Void {
        const viewport = _viewport;
        if (x.isVector4) {
            viewport.copy(x);
        } else {
            viewport.set(x, y, width, height);
        }
        viewport.minDepth = minDepth;
        viewport.maxDepth = maxDepth;
    }

    public function getClearColor(target:Dynamic):Dynamic {
        return target.copy(_clearColor);
    }

    public function setClearColor(color:Dynamic, alpha:Float = 1):Void {
        _clearColor.set(color);
        _clearColor.a = alpha;
    }

    public function getClearAlpha():Float {
        return _clearColor.a;
    }

    public function setClearAlpha(alpha:Float):Void {
        _clearColor.a = alpha;
    }

    public function getClearDepth():Float {
        return _clearDepth;
    }

    public function setClearDepth(depth:Float):Void {
        _clearDepth = depth;
    }

    public function getClearStencil():Int {
        return _clearStencil;
    }

    public function setClearStencil(stencil:Int):Void {
        _clearStencil = stencil;
    }

    public function isOccluded(object:Dynamic):Bool {
        const renderContext = _currentRenderContext;
        return renderContext && backend.isOccluded(renderContext, object);
    }

    public function clear(color:Bool = true, depth:Bool = true, stencil:Bool = true):Void {
        if (!_initialized) {
            console.warn("THREE.Renderer: .clear() called before the backend is initialized. Try using .clearAsync() instead.");
            return clearAsync(color, depth, stencil);
        }
        const renderTarget = _renderTarget || _getFrameBufferTarget();
        let renderTargetData:Dynamic = null;
        if (renderTarget != null) {
            _textures.updateRenderTarget(renderTarget);
            renderTargetData = _textures.get(renderTarget);
        }
        backend.clear(color, depth, stencil, renderTargetData);
    }

    public function clearColor():Void {
        return clear(true, false, false);
    }

    public function clearDepth():Void {
        return clear(false, true, false);
    }

    public function clearStencil():Void {
        return clear(false, false, true);
    }

    public function clearAsync(color:Bool = true, depth:Bool = true, stencil:Bool = true):Promise<Void> {
        if (!_initialized) await init();
        clear(color, depth, stencil);
    }

    public function clearColorAsync():Promise<Void> {
        return clearAsync(true, false, false);
    }

    public function clearDepthAsync():Promise<Void> {
        return clearAsync(false, true, false);
    }

    public function clearStencilAsync():Promise<Void> {
        return clearAsync(false, false, true);
    }

    public function getCurrentColorSpace():Dynamic {
        const renderTarget = _renderTarget;
        if (renderTarget != null) {
            const texture = renderTarget.texture;
            return (Array.isArray(texture) ? texture[0] : texture).colorSpace;
        }
        return outputColorSpace;
    }

    public function dispose():Void {
        _info.dispose();
        _animation.dispose();
        _objects.dispose();
        _pipelines.dispose();
        _nodes.dispose();
        _bindings.dispose();
        _renderLists.dispose();
        _renderContexts.dispose();
        _textures.dispose();
        setRenderTarget(null);
        setAnimationLoop(null);
    }

    public function setRenderTarget(renderTarget:Dynamic, activeCubeFace:Int = 0, activeMipmapLevel:Int = 0):Void {
        _renderTarget = renderTarget;
        _activeCubeFace = activeCubeFace;
        _activeMipmapLevel = activeMipmapLevel;
    }

    public function getRenderTarget():Dynamic {
        return _renderTarget;
    }

    public function setRenderObjectFunction(renderObjectFunction:Dynamic):Void {
        _renderObjectFunction = renderObjectFunction;
    }

    public function getRenderObjectFunction():Dynamic {
        return _renderObjectFunction;
    }

    public function computeAsync(computeNodes:Dynamic):Promise<Void> {
        if (!_initialized) await init();
        const nodeFrame = _nodes.nodeFrame;
        const previousRenderId = nodeFrame.renderId;
        info.calls++;
        info.compute.calls++;
        info.compute.computeCalls++;
        nodeFrame.renderId = info.calls;
        const backend = this.backend;
        const pipelines = _pipelines;
        const bindings = _bindings;
        const nodes = _nodes;
        const computeList = (computeNodes is Array<Dynamic>) ? computeNodes : [computeNodes];
        if (computeList[0] == null || !computeList[0].isComputeNode) {
            throw new Error("THREE.Renderer: .compute() expects a ComputeNode.");
        }
        backend.beginCompute(computeNodes);
        for (computeNode in computeList) {
            if (!pipelines.has(computeNode)) {
                const dispose = () -> {
                    computeNode.removeEventListener("dispose", dispose);
                    pipelines.delete(computeNode);
                    bindings.delete(computeNode);
                    nodes.delete(computeNode);
                };
                computeNode.addEventListener("dispose", dispose);
                computeNode.onInit({renderer: this});
            }
            nodes.updateForCompute(computeNode);
            bindings.updateForCompute(computeNode);
            const computeBindings = bindings.getForCompute(computeNode);
            const computePipeline = pipelines.getForCompute(computeNode, computeBindings);
            backend.compute(computeNodes, computeNode, computeBindings, computePipeline);
        }
        backend.finishCompute(computeNodes);
        await backend.resolveTimestampAsync(computeNodes, "compute");
        nodeFrame.renderId = previousRenderId;
    }

    public function hasFeatureAsync(name:String):Promise<Bool> {
        if (!_initialized) await init();
        return backend.hasFeature(name);
    }

    public function hasFeature(name:String):Bool {
        if (!_initialized) {
            console.warn("THREE.Renderer: .hasFeature() called before the backend is initialized. Try using .hasFeatureAsync() instead.");
            return false;
        }
        return backend.hasFeature(name);
    }

    public function copyFramebufferToTexture(framebufferTexture:Texture):Void {
        const renderContext = _currentRenderContext;
        _textures.updateTexture(framebufferTexture);
        backend.copyFramebufferToTexture(framebufferTexture, renderContext);
    }

    public function copyTextureToTexture(srcTexture:Texture, dstTexture:Texture, srcRegion:Dynamic = null, dstPosition:Dynamic = null, level:Int = 0):Void {
        _textures.updateTexture(srcTexture);
        _textures.updateTexture(dstTexture);
        backend.copyTextureToTexture(srcTexture, dstTexture, srcRegion, dstPosition, level);
    }

    public function readRenderTargetPixelsAsync(renderTarget:Framebuffer, x:Int, y:Int, width:Int, height:Int, index:Int = 0):Promise<Dynamic> {
        return backend.copyTextureToBuffer(renderTarget.textures[index], x, y, width, height);
    }

    public function _projectObject(object:Dynamic, camera:Dynamic, groupOrder:Dynamic, renderList:Dynamic):Void {
        // implementation omitted
    }

    public function _renderObjects(renderList:Dynamic, camera:Dynamic, scene:Dynamic, lightsNode:Dynamic):Void {
        // implementation omitted
    }

    public function renderObject(object:Dynamic, scene:Dynamic, camera:Dynamic, geometry:Dynamic, material:Dynamic, group:Dynamic, lightsNode:Dynamic):Void {
        // implementation omitted
    }

    public function _renderObjectDirect(object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, group:Dynamic, passId:Dynamic):Void {
        // implementation omitted
    }

    public function _createObjectPipeline(object:Dynamic, material:Dynamic, scene:Dynamic, camera:Dynamic, lightsNode:Dynamic, passId:Dynamic):Void {
        // implementation omitted
    }

    public function get_compute():Dynamic {
        return computeAsync;
    }

    public function get_compile():Dynamic {
        return compileAsync;
    }
}
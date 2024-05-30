package three.js.examples.jm.postprocessing;

import three.Clock;
import three.HalfFloatType;
import three.NoBlending;
import three.Vector2;
import three.WebGLRenderTarget;
import three.js.shaders.CopyShader;
import three.js.postprocessing.ShaderPass;
import three.js.postprocessing.MaskPass;
import three.js.postprocessing.ClearMaskPass;

class EffectComposer {

    public var renderer:three.Renderer;
    public var _pixelRatio:Float;
    public var _width:Int;
    public var _height:Int;
    public var renderTarget1:WebGLRenderTarget;
    public var renderTarget2:WebGLRenderTarget;
    public var writeBuffer:WebGLRenderTarget;
    public var readBuffer:WebGLRenderTarget;
    public var renderToScreen:Bool;
    public var passes:Array<ShaderPass>;
    public var copyPass:ShaderPass;
    public var clock:Clock;

    public function new(renderer:three.Renderer, ?renderTarget:WebGLRenderTarget) {
        this.renderer = renderer;
        _pixelRatio = renderer.pixelRatio;

        if (renderTarget == null) {
            var size = renderer.getSize(new Vector2());
            _width = size.width;
            _height = size.height;

            renderTarget = new WebGLRenderTarget(_width * _pixelRatio, _height * _pixelRatio, { type: HalfFloatType });
            renderTarget.texture.name = 'EffectComposer.rt1';
        } else {
            _width = renderTarget.width;
            _height = renderTarget.height;
        }

        renderTarget1 = renderTarget;
        renderTarget2 = renderTarget.clone();
        renderTarget2.texture.name = 'EffectComposer.rt2';

        writeBuffer = renderTarget1;
        readBuffer = renderTarget2;

        renderToScreen = true;

        passes = [];

        copyPass = new ShaderPass(new CopyShader());
        copyPass.material.blending = NoBlending;

        clock = new Clock();
    }

    public function swapBuffers() {
        var tmp = readBuffer;
        readBuffer = writeBuffer;
        writeBuffer = tmp;
    }

    public function addPass(pass:ShaderPass) {
        passes.push(pass);
        pass.setSize(_width * _pixelRatio, _height * _pixelRatio);
    }

    public function insertPass(pass:ShaderPass, index:Int) {
        passes.splice(index, 0, pass);
        pass.setSize(_width * _pixelRatio, _height * _pixelRatio);
    }

    public function removePass(pass:ShaderPass) {
        var index = passes.indexOf(pass);

        if (index != -1) {
            passes.splice(index, 1);
        }
    }

    public function isLastEnabledPass(passIndex:Int) {
        for (i in passIndex + 1...passes.length) {
            if (passes[i].enabled) {
                return false;
            }
        }

        return true;
    }

    public function render(?deltaTime:Float) {
        if (deltaTime == null) {
            deltaTime = clock.getDelta();
        }

        var currentRenderTarget = renderer.getRenderTarget();

        var maskActive = false;

        for (i in 0...passes.length) {
            var pass = passes[i];

            if (!pass.enabled) continue;

            pass.renderToScreen = (renderToScreen && isLastEnabledPass(i));
            pass.render(renderer, writeBuffer, readBuffer, deltaTime, maskActive);

            if (pass.needsSwap) {
                if (maskActive) {
                    var context = renderer.context;
                    var stencil = renderer.state.buffers.stencil;

                    stencil.setFunc(context.NOTEQUAL, 1, 0xffffffff);
                    copyPass.render(renderer, writeBuffer, readBuffer, deltaTime);
                    stencil.setFunc(context.EQUAL, 1, 0xffffffff);
                }

                swapBuffers();
            }

            if (MaskPass != null) {
                if (Std.is(pass, MaskPass)) {
                    maskActive = true;
                } else if (Std.is(pass, ClearMaskPass)) {
                    maskActive = false;
                }
            }
        }

        renderer.setRenderTarget(currentRenderTarget);
    }

    public function reset(?renderTarget:WebGLRenderTarget) {
        if (renderTarget == null) {
            var size = renderer.getSize(new Vector2());
            _pixelRatio = renderer.pixelRatio;
            _width = size.width;
            _height = size.height;

            renderTarget = renderTarget1.clone();
            renderTarget.setSize(_width * _pixelRatio, _height * _pixelRatio);
        }

        renderTarget1.dispose();
        renderTarget2.dispose();
        renderTarget1 = renderTarget;
        renderTarget2 = renderTarget.clone();

        writeBuffer = renderTarget1;
        readBuffer = renderTarget2;
    }

    public function setSize(width:Int, height:Int) {
        _width = width;
        _height = height;

        var effectiveWidth = _width * _pixelRatio;
        var effectiveHeight = _height * _pixelRatio;

        renderTarget1.setSize(effectiveWidth, effectiveHeight);
        renderTarget2.setSize(effectiveWidth, effectiveHeight);

        for (i in 0...passes.length) {
            passes[i].setSize(effectiveWidth, effectiveHeight);
        }
    }

    public function setPixelRatio(pixelRatio:Float) {
        _pixelRatio = pixelRatio;
        setSize(_width, _height);
    }

    public function dispose() {
        renderTarget1.dispose();
        renderTarget2.dispose();
        copyPass.dispose();
    }
}
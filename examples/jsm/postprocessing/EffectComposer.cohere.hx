import js.three.Clock;
import js.three.HalfFloatType;
import js.three.NoBlending;
import js.three.Vector2;
import js.three.WebGLRenderTarget;

import js.threex.shaders.CopyShader;
import js.threex.passes.ShaderPass;
import js.threex.passes.MaskPass;
import js.threex.passes.ClearMaskPass;

class EffectComposer {
    public var renderer :Dynamic;
    public var _pixelRatio :Float;
    public var _width :Int;
    public var _height :Int;
    public var renderTarget1 :WebGLRenderTarget;
    public var renderTarget2 :WebGLRenderTarget;
    public var writeBuffer :WebGLRenderTarget;
    public var readBuffer :WebGLRenderTarget;
    public var renderToScreen :Bool;
    public var passes :Array<Dynamic>;
    public var copyPass :ShaderPass;
    public var clock :Clock;

    public function new(renderer :Dynamic, renderTarget? :WebGLRenderTarget) {
        this.renderer = renderer;
        _pixelRatio = renderer.getPixelRatio();

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

    public function addPass(pass :Dynamic) {
        passes.push(pass);
        pass.setSize(_width * _pixelRatio, _height * _pixelRatio);
    }

    public function insertPass(pass :Dynamic, index :Int) {
        passes.splice(index, 0, pass);
        pass.setSize(_width * _pixelRatio, _height * _pixelRatio);
    }

    public function removePass(pass :Dynamic) {
        var index = passes.indexOf(pass);
        if (index != -1) {
            passes.splice(index, 1);
        }
    }

    public function isLastEnabledPass(passIndex :Int) :Bool {
        for (i in passIndex + 1...passes.length) {
            if (passes[i].enabled) {
                return false;
            }
        }
        return true;
    }

    public function render(deltaTime? :Float) {
        // deltaTime value is in seconds
        if (deltaTime == null) {
            deltaTime = clock.getDelta();
        }

        var currentRenderTarget = renderer.getRenderTarget();

        var maskActive = false;

        for (i in 0...passes.length) {
            var pass = passes[i];

            if (!pass.enabled) {
                continue;
            }

            pass.renderToScreen = (renderToScreen && isLastEnabledPass(i));
            pass.render(renderer, writeBuffer, readBuffer, deltaTime, maskActive);

            if (pass.needsSwap) {
                if (maskActive) {
                    var context = renderer.getContext();
                    var stencil = renderer.state.buffers.stencil;

                    //context.stencilFunc(context.NOTEQUAL, 1, 0xffffffff);
                    stencil.setFunc(context.NOTEQUAL, 1, 0xffffffff);

                    copyPass.render(renderer, writeBuffer, readBuffer, deltaTime);

                    //context.stencilFunc(context.EQUAL, 1, 0xffffffff);
                    stencil.setFunc(context.EQUAL, 1, 0xffffffff);
                }

                swapBuffers();
            }

            if (MaskPass != null) {
                if (pass instanceof MaskPass) {
                    maskActive = true;
                } else if (pass instanceof ClearMaskPass) {
                    maskActive = false;
                }
            }
        }

        renderer.setRenderTarget(currentRenderTarget);
    }

    public function reset(renderTarget? :WebGLRenderTarget) {
        if (renderTarget == null) {
            var size = renderer.getSize(new Vector2());
            _pixelRatio = renderer.getPixelRatio();
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

    public function setSize(width :Int, height :Int) {
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

    public function setPixelRatio(pixelRatio :Float) {
        _pixelRatio = pixelRatio;

        setSize(_width, _height);
    }

    public function dispose() {
        renderTarget1.dispose();
        renderTarget2.dispose();

        copyPass.dispose();
    }
}

class CopyShader {
    public function new() {
        // ...
    }
}

class ShaderPass {
    public var material :Dynamic;

    public function new(shader :Dynamic) {
        // ...
    }

    public function dispose() {
        // ...
    }
}

class MaskPass {
    // ...
}

class ClearMaskPass {
    // ...
}
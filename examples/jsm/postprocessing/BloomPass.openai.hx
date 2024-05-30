package three.js.examples.jm.postprocessing;

import three.js.lib.AdditiveBlending;
import three.js.lib.HalfFloatType;
import three.js.lib.ShaderMaterial;
import three.js.lib.UniformsUtils;
import three.js.lib.Vector2;
import three.js.lib.WebGLRenderTarget;
import Pass;
import FullScreenQuad;
import ConvolutionShader;

class BloomPass extends Pass {

    public var strength:Float = 1;
    public var kernelSize:Int = 25;
    public var sigma:Float = 4;

    public var renderTargetX:WebGLRenderTarget;
    public var renderTargetY:WebGLRenderTarget;

    public var combineUniforms:UniformsUtils;
    public var materialCombine:ShaderMaterial;

    public var convolutionUniforms:UniformsUtils;
    public var materialConvolution:ShaderMaterial;

    public var fsQuad:FullScreenQuad;

    public function new(strength:Float = 1, kernelSize:Int = 25, sigma:Float = 4) {
        super();

        // render targets
        renderTargetX = new WebGLRenderTarget(1, 1, { type: HalfFloatType });
        renderTargetX.texture.name = 'BloomPass.x';
        renderTargetY = new WebGLRenderTarget(1, 1, { type: HalfFloatType });
        renderTargetY.texture.name = 'BloomPass.y';

        // combine material
        combineUniforms = UniformsUtils.clone(CombineShader.uniforms);
        combineUniforms['strength'].value = strength;
        materialCombine = new ShaderMaterial({
            name: CombineShader.name,
            uniforms: combineUniforms,
            vertexShader: CombineShader.vertexShader,
            fragmentShader: CombineShader.fragmentShader,
            blending: AdditiveBlending,
            transparent: true
        });

        // convolution material
        var convolutionShader:ConvolutionShader = new ConvolutionShader();
        convolutionUniforms = UniformsUtils.clone(convolutionShader.uniforms);
        convolutionUniforms['uImageIncrement'].value = blurX;
        convolutionUniforms['cKernel'].value = ConvolutionShader.buildKernel(sigma);
        materialConvolution = new ShaderMaterial({
            name: convolutionShader.name,
            uniforms: convolutionUniforms,
            vertexShader: convolutionShader.vertexShader,
            fragmentShader: convolutionShader.fragmentShader,
            defines: {
                'KERNEL_SIZE_FLOAT': kernelSize.toFixed(1),
                'KERNEL_SIZE_INT': kernelSize.toFixed(0)
            }
        });

        fsQuad = new FullScreenQuad(null);
    }

    override public function render(renderer:Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float, maskActive:Bool) {
        if (maskActive) renderer.state.buffers.stencil.setTest(false);

        // Render quad with blured scene into texture (convolution pass 1)
        fsQuad.material = materialConvolution;
        convolutionUniforms['tDiffuse'].value = readBuffer.texture;
        convolutionUniforms['uImageIncrement'].value = blurX;
        renderer.setRenderTarget(renderTargetX);
        renderer.clear();
        fsQuad.render(renderer);

        // Render quad with blured scene into texture (convolution pass 2)
        convolutionUniforms['tDiffuse'].value = renderTargetX.texture;
        convolutionUniforms['uImageIncrement'].value = blurY;
        renderer.setRenderTarget(renderTargetY);
        renderer.clear();
        fsQuad.render(renderer);

        // Render original scene with superimposed blur to texture
        fsQuad.material = materialCombine;
        combineUniforms['tDiffuse'].value = renderTargetY.texture;
        if (maskActive) renderer.state.buffers.stencil.setTest(true);
        renderer.setRenderTarget(readBuffer);
        if (clear) renderer.clear();
        fsQuad.render(renderer);
    }

    public function setSize(width:Int, height:Int) {
        renderTargetX.setSize(width, height);
        renderTargetY.setSize(width, height);
    }

    override public function dispose() {
        renderTargetX.dispose();
        renderTargetY.dispose();
        materialCombine.dispose();
        materialConvolution.dispose();
        fsQuad.dispose();
    }
}

class CombineShader {
    public static var name:String = 'CombineShader';
    public static var uniforms:UniformsUtils = {
        'tDiffuse': { value: null },
        'strength': { value: 1.0 }
    };

    public static var vertexShader:String = '
        varying vec2 vUv;

        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ';

    public static var fragmentShader:String = '
        uniform float strength;
        uniform sampler2D tDiffuse;
        varying vec2 vUv;

        void main() {
            vec4 texel = texture2D( tDiffuse, vUv );
            gl_FragColor = strength * texel;
        }
    ';
}

class ConvolutionShader {
    // ...
}

class Pass {
    // ...
}

class FullScreenQuad {
    // ...
}

class WebGLRenderTarget {
    // ...
}

class UniformsUtils {
    // ...
}

class AdditiveBlending {
    // ...
}

class HalfFloatType {
    // ...
}

class ShaderMaterial {
    // ...
}

class Vector2 {
    // ...
}

class ConvolutionShader {
    // ...
}

class Renderer {
    // ...
}

BloomPass.blurX = new Vector2(0.001953125, 0.0);
BloomPass.blurY = new Vector2(0.0, 0.001953125);
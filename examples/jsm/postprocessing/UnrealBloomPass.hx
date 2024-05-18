package three.js.examples.jsm.postprocessing;

import three.js.AdditiveBlending;
import three.js.Color;
import three.js.HalfFloatType;
import three.js.MeshBasicMaterial;
import three.js.ShaderMaterial;
import three.js.UniformsUtils;
import three.js.Vector2;
import three.js.Vector3;
import three.js.WebGLRenderTarget;

class UnrealBloomPass extends Pass {
    public var strength:Float;
    public var radius:Float;
    public var threshold:Float;
    public var resolution:Vector2;
    public var clearColor:Color;
    public var renderTargetsHorizontal:Array<WebGLRenderTarget>;
    public var renderTargetsVertical:Array<WebGLRenderTarget>;
    public var nMips:Int;
    public var highPassUniforms:Dynamic;
    public var materialHighPassFilter:ShaderMaterial;
    public var separableBlurMaterials:Array<ShaderMaterial>;
    public var compositeMaterial:ShaderMaterial;
    public var blendMaterial:ShaderMaterial;
    public var basic:MeshBasicMaterial;
    public var fsQuad:FullScreenQuad;
    public var _oldClearColor:Color;
    public var oldClearAlpha:Float;

    public function new(resolution:Vector2, strength:Float, radius:Float, threshold:Float) {
        super();

        this.strength = strength != null ? strength : 1;
        this.radius = radius;
        this.threshold = threshold;
        this.resolution = resolution != null ? new Vector2(resolution.x, resolution.y) : new Vector2(256, 256);

        this.clearColor = new Color(0, 0, 0);

        this.renderTargetsHorizontal = [];
        this.renderTargetsVertical = [];
        this.nMips = 5;
        var resx:Int = Math.round(this.resolution.x / 2);
        var resy:Int = Math.round(this.resolution.y / 2);

        this.renderTargetBright = new WebGLRenderTarget(resx, resy, { type: HalfFloatType });
        this.renderTargetBright.texture.name = 'UnrealBloomPass.bright';
        this.renderTargetBright.texture.generateMipmaps = false;

        for (i in 0...this.nMips) {
            var renderTargetHorizontal:WebGLRenderTarget = new WebGLRenderTarget(resx, resy, { type: HalfFloatType });
            renderTargetHorizontal.texture.name = 'UnrealBloomPass.h' + i;
            renderTargetHorizontal.texture.generateMipmaps = false;
            this.renderTargetsHorizontal.push(renderTargetHorizontal);

            var renderTargetVertical:WebGLRenderTarget = new WebGLRenderTarget(resx, resy, { type: HalfFloatType });
            renderTargetVertical.texture.name = 'UnrealBloomPass.v' + i;
            renderTargetVertical.texture.generateMipmaps = false;
            this.renderTargetsVertical.push(renderTargetVertical);

            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
        }

        // luminosity high pass material
        var highPassShader:LuminosityHighPassShader;
        this.highPassUniforms = UniformsUtils.clone(highPassShader.uniforms);
        this.highPassUniforms['luminosityThreshold'].value = threshold;
        this.highPassUniforms['smoothWidth'].value = 0.01;
        this.materialHighPassFilter = new ShaderMaterial({
            uniforms: this.highPassUniforms,
            vertexShader: highPassShader.vertexShader,
            fragmentShader: highPassShader.fragmentShader
        });

        // gaussian blur materials
        this.separableBlurMaterials = [];
        var kernelSizeArray:Array<Int> = [3, 5, 7, 9, 11];
        resx = Math.round(this.resolution.x / 2);
        resy = Math.round(this.resolution.y / 2);

        for (i in 0...this.nMips) {
            var separableBlurMaterial:ShaderMaterial = this.getSeperableBlurMaterial(kernelSizeArray[i]);
            separableBlurMaterial.uniforms['invSize'].value = new Vector2(1 / resx, 1 / resy);
            this.separableBlurMaterials.push(separableBlurMaterial);

            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
        }

        // composite material
        this.compositeMaterial = this.getCompositeMaterial(this.nMips);
        this.compositeMaterial.uniforms['blurTexture1'].value = this.renderTargetsVertical[0].texture;
        this.compositeMaterial.uniforms['blurTexture2'].value = this.renderTargetsVertical[1].texture;
        this.compositeMaterial.uniforms['blurTexture3'].value = this.renderTargetsVertical[2].texture;
        this.compositeMaterial.uniforms['blurTexture4'].value = this.renderTargetsVertical[3].texture;
        this.compositeMaterial.uniforms['blurTexture5'].value = this.renderTargetsVertical[4].texture;
        this.compositeMaterial.uniforms['bloomStrength'].value = strength;
        this.compositeMaterial.uniforms['bloomRadius'].value = 0.1;
        var bloomFactors:Array<Float> = [1.0, 0.8, 0.6, 0.4, 0.2];
        this.compositeMaterial.uniforms['bloomFactors'].value = bloomFactors;
        this.bloomTintColors:Array<Vector3> = [new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1)];
        this.compositeMaterial.uniforms['bloomTintColors'].value = this.bloomTintColors;

        // blend material
        var copyShader:CopyShader;
        this.copyUniforms:Dynamic = UniformsUtils.clone(copyShader.uniforms);

        this.blendMaterial = new ShaderMaterial({
            uniforms: this.copyUniforms,
            vertexShader: copyShader.vertexShader,
            fragmentShader: copyShader.fragmentShader,
            blending: AdditiveBlending,
            depthTest: false,
            depthWrite: false,
            transparent: true
        });

        this.enabled = true;
        this.needsSwap = false;

        this._oldClearColor = new Color();
        this.oldClearAlpha = 1;

        this.basic = new MeshBasicMaterial();

        this.fsQuad = new FullScreenQuad(null);
    }

    public function dispose() {
        for (i in 0...this.renderTargetsHorizontal.length) {
            this.renderTargetsHorizontal[i].dispose();
        }

        for (i in 0...this.renderTargetsVertical.length) {
            this.renderTargetsVertical[i].dispose();
        }

        this.renderTargetBright.dispose();

        for (i in 0...this.separableBlurMaterials.length) {
            this.separableBlurMaterials[i].dispose();
        }

        this.compositeMaterial.dispose();
        this.blendMaterial.dispose();
        this.basic.dispose();

        this.fsQuad.dispose();
    }

    public function setSize(width:Float, height:Float) {
        var resx:Int = Math.round(width / 2);
        var resy:Int = Math.round(height / 2);

        this.renderTargetBright.setSize(resx, resy);

        for (i in 0...this.nMips) {
            this.renderTargetsHorizontal[i].setSize(resx, resy);
            this.renderTargetsVertical[i].setSize(resx, resy);

            this.separableBlurMaterials[i].uniforms['invSize'].value = new Vector2(1 / resx, 1 / resy);

            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
        }
    }

    public function render(renderer:Dynamic, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float, maskActive:Bool) {
        renderer.getClearColor(_oldClearColor);
        this.oldClearAlpha = renderer.getClearAlpha();
        var oldAutoClear:Bool = renderer.autoClear;
        renderer.autoClear = false;

        renderer.setClearColor(this.clearColor, 0);

        if (maskActive) {
            renderer.state.buffers.stencil.setTest(false);
        }

        // Render input to screen
        if (this.renderToScreen) {
            this.fsQuad.material = this.basic;
            this.basic.map = readBuffer.texture;

            renderer.setRenderTarget(null);
            renderer.clear();
            this.fsQuad.render(renderer);
        }

        // 1. Extract Bright Areas
        this.highPassUniforms['tDiffuse'].value = readBuffer.texture;
        this.highPassUniforms['luminosityThreshold'].value = this.threshold;
        this.fsQuad.material = this.materialHighPassFilter;

        renderer.setRenderTarget(this.renderTargetBright);
        renderer.clear();
        this.fsQuad.render(renderer);

        // 2. Blur All the mips progressively
        var inputRenderTarget:WebGLRenderTarget = this.renderTargetBright;

        for (i in 0...this.nMips) {
            this.fsQuad.material = this.separableBlurMaterials[i];

            this.separableBlurMaterials[i].uniforms['colorTexture'].value = inputRenderTarget.texture;
            this.separableBlurMaterials[i].uniforms['direction'].value = UnrealBloomPass.BlurDirectionX;
            renderer.setRenderTarget(this.renderTargetsHorizontal[i]);
            renderer.clear();
            this.fsQuad.render(renderer);

            this.separableBlurMaterials[i].uniforms['colorTexture'].value = this.renderTargetsHorizontal[i].texture;
            this.separableBlurMaterials[i].uniforms['direction'].value = UnrealBloomPass.BlurDirectionY;
            renderer.setRenderTarget(this.renderTargetsVertical[i]);
            renderer.clear();
            this.fsQuad.render(renderer);

            inputRenderTarget = this.renderTargetsVertical[i];
        }

        // Composite All the mips
        this.fsQuad.material = this.compositeMaterial;
        this.compositeMaterial.uniforms['bloomStrength'].value = this.strength;
        this.compositeMaterial.uniforms['bloomRadius'].value = this.radius;
        this.compositeMaterial.uniforms['bloomTintColors'].value = this.bloomTintColors;

        renderer.setRenderTarget(this.renderTargetsHorizontal[0]);
        renderer.clear();
        this.fsQuad.render(renderer);

        // Blend it additively over the input texture
        this.fsQuad.material = this.blendMaterial;
        this.copyUniforms['tDiffuse'].value = this.renderTargetsHorizontal[0].texture;

        if (maskActive) {
            renderer.state.buffers.stencil.setTest(true);
        }

        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
            this.fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(readBuffer);
            this.fsQuad.render(renderer);
        }

        // Restore renderer settings
        renderer.setClearColor(_oldClearColor, this.oldClearAlpha);
        renderer.autoClear = oldAutoClear;
    }

    public function getSeperableBlurMaterial(kernelRadius:Int):ShaderMaterial {
        var coefficients:Array<Float> = [];

        for (i in 0...kernelRadius) {
            coefficients.push(0.39894 * Math.exp(-0.5 * i * i / (kernelRadius * kernelRadius)) / kernelRadius);
        }

        return new ShaderMaterial({
            defines: {
                'KERNEL_RADIUS': kernelRadius
            },

            uniforms: {
                'colorTexture': { value: null },
                'invSize': { value: new Vector2(0.5, 0.5) },
                'direction': { value: new Vector2(0.5, 0.5) },
                'gaussianCoefficients': { value: coefficients }
            },

            vertexShader:
                'varying vec2 vUv;
                void main() {
                    vUv = uv;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
                }',

            fragmentShader:
                '#include <common>
                varying vec2 vUv;
                uniform sampler2D colorTexture;
                uniform vec2 invSize;
                uniform vec2 direction;
                uniform float gaussianCoefficients[KERNEL_RADIUS];

                void main() {
                    float weightSum = gaussianCoefficients[0];
                    vec3 diffuseSum = texture2D( colorTexture, vUv ).rgb * weightSum;
                    for( int i = 1; i < KERNEL_RADIUS; i ++ ) {
                        float x = float(i);
                        float w = gaussianCoefficients[i];
                        vec2 uvOffset = direction * invSize * x;
                        vec3 sample1 = texture2D( colorTexture, vUv + uvOffset ).rgb;
                        vec3 sample2 = texture2D( colorTexture, vUv - uvOffset ).rgb;
                        diffuseSum += (sample1 + sample2) * w;
                        weightSum += 2.0 * w;
                    }
                    gl_FragColor = vec4(diffuseSum/weightSum, 1.0);
                }'
        });
    }

    public function getCompositeMaterial(nMips:Int):ShaderMaterial {
        return new ShaderMaterial({
            defines: {
                'NUM_MIPS': nMips
            },

            uniforms: {
                'blurTexture1': { value: null },
                'blurTexture2': { value: null },
                'blurTexture3': { value: null },
                'blurTexture4': { value: null },
                'blurTexture5': { value: null },
                'bloomStrength': { value: 1.0 },
                'bloomFactors': { value: null },
                'bloomTintColors': { value: null },
                'bloomRadius': { value: 0.0 }
            },

            vertexShader:
                'varying vec2 vUv;
                void main() {
                    vUv = uv;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
                }',

            fragmentShader:
                'varying vec2 vUv;
                uniform sampler2D blurTexture1;
                uniform sampler2D blurTexture2;
                uniform sampler2D blurTexture3;
                uniform sampler2D blurTexture4;
                uniform sampler2D blurTexture5;
                uniform float bloomStrength;
                uniform float bloomRadius;
                uniform float bloomFactors[NUM_MIPS];
                uniform vec3 bloomTintColors[NUM_MIPS];

                float lerpBloomFactor(const in float factor) {
                    float mirrorFactor = 1.2 - factor;
                    return mix(factor, mirrorFactor, bloomRadius);
                }

                void main() {
                    gl_FragColor = bloomStrength * ( lerpBloomFactor(bloomFactors[0]) * vec4(bloomTintColors[0], 1.0) * texture2D(blurTexture1, vUv) +
                        lerpBloomFactor(bloomFactors[1]) * vec4(bloomTintColors[1], 1.0) * texture2D(blurTexture2, vUv) +
                        lerpBloomFactor(bloomFactors[2]) * vec4(bloomTintColors[2], 1.0) * texture2D(blurTexture3, vUv) +
                        lerpBloomFactor(bloomFactors[3]) * vec4(bloomTintColors[3], 1.0) * texture2D(blurTexture4, vUv) +
                        lerpBloomFactor(bloomFactors[4]) * vec4(bloomTintColors[4], 1.0) * texture2D(blurTexture5, vUv) );
                }'
        });
    }
}

class LuminosityHighPassShader {
    public var uniforms:Dynamic;
    public var vertexShader:String;
    public var fragmentShader:String;
}

class CopyShader {
    public var uniforms:Dynamic;
    public var vertexShader:String;
    public var fragmentShader:String;
}

class FullScreenQuad {
    public function new(material:ShaderMaterial) {}
    public function render(renderer:Dynamic) {}
}

class Pass {
    public var enabled:Bool;
    public var needsSwap:Bool;
}

class WebGLRenderTarget {
    public function new(width:Int, height:Int, options:Dynamic) {}
    public function setSize(width:Int, height:Int) {}
    public function dispose() {}
}

class MeshBasicMaterial {
    public function new() {}
}

class ShaderMaterial {
    public function new(options:Dynamic) {}
    public function dispose() {}
}

class Vector2 {
    public function new(x:Float, y:Float) {}
}

class Vector3 {
    public function new(x:Float, y:Float, z:Float) {}
}

class Color {
    public function new(r:Float, g:Float, b:Float) {}
}

class AdditiveBlending {}

class HalfFloatType {}

class UniformsUtils {
    public static function clone(uniforms:Dynamic):Dynamic {}
}

UnrealBloomPass.BlurDirectionX = new Vector2(1.0, 0.0);
UnrealBloomPass.BlurDirectionY = new Vector2(0.0, 1.0);
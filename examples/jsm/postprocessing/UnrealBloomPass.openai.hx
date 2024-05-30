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
import Pass from './Pass';
import FullScreenQuad from './FullScreenQuad';
import CopyShader from '../shaders/CopyShader';
import LuminosityHighPassShader from '../shaders/LuminosityHighPassShader';

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
    public var fsQuad:FullScreenQuad;
    public var basic:MeshBasicMaterial;

    public function new(resolution:Vector2 = null, strength:Float = 1, radius:Float = 0, threshold:Float = 0) {
        super();
        this.strength = strength;
        this.radius = radius;
        this.threshold = threshold;
        this.resolution = resolution != null ? resolution : new Vector2(256, 256);

        clearColor = new Color(0, 0, 0);

        renderTargetsHorizontal = [];
        renderTargetsVertical = [];
        nMips = 5;
        var resx:Float = Math.round(resolution.x / 2);
        var resy:Float = Math.round(resolution.y / 2);

        var renderTargetBright:WebGLRenderTarget = new WebGLRenderTarget(resx, resy, { type: HalfFloatType });
        renderTargetBright.texture.name = 'UnrealBloomPass.bright';
        renderTargetBright.texture.generateMipmaps = false;

        for (i in 0...nMips) {
            var renderTargetHorizonal:WebGLRenderTarget = new WebGLRenderTarget(resx, resy, { type: HalfFloatType });
            renderTargetHorizonal.texture.name = 'UnrealBloomPass.h' + i;
            renderTargetHorizonal.texture.generateMipmaps = false;
            renderTargetsHorizontal.push(renderTargetHorizonal);

            var renderTargetVertical:WebGLRenderTarget = new WebGLRenderTarget(resx, resy, { type: HalfFloatType });
            renderTargetVertical.texture.name = 'UnrealBloomPass.v' + i;
            renderTargetVertical.texture.generateMipmaps = false;
            renderTargetsVertical.push(renderTargetVertical);

            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
        }

        highPassUniforms = UniformsUtils.clone(LuminosityHighPassShader.uniforms);
        highPassUniforms['luminosityThreshold'].value = threshold;
        highPassUniforms['smoothWidth'].value = 0.01;

        materialHighPassFilter = new ShaderMaterial({
            uniforms: highPassUniforms,
            vertexShader: LuminosityHighPassShader.vertexShader,
            fragmentShader: LuminosityHighPassShader.fragmentShader
        });

        separableBlurMaterials = [];
        var kernelSizeArray:Array<Int> = [3, 5, 7, 9, 11];
        resx = Math.round(resolution.x / 2);
        resy = Math.round(resolution.y / 2);

        for (i in 0...nMips) {
            separableBlurMaterials.push(getSeperableBlurMaterial(kernelSizeArray[i]));
            separableBlurMaterials[i].uniforms['invSize'].value = new Vector2(1 / resx, 1 / resy);
            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
        }

        compositeMaterial = getCompositeMaterial(nMips);
        compositeMaterial.uniforms['blurTexture1'].value = renderTargetsVertical[0].texture;
        compositeMaterial.uniforms['blurTexture2'].value = renderTargetsVertical[1].texture;
        compositeMaterial.uniforms['blurTexture3'].value = renderTargetsVertical[2].texture;
        compositeMaterial.uniforms['blurTexture4'].value = renderTargetsVertical[3].texture;
        compositeMaterial.uniforms['blurTexture5'].value = renderTargetsVertical[4].texture;
        compositeMaterial.uniforms['bloomStrength'].value = strength;
        compositeMaterial.uniforms['bloomRadius'].value = 0.1;

        var bloomFactors:Array<Float> = [1.0, 0.8, 0.6, 0.4, 0.2];
        compositeMaterial.uniforms['bloomFactors'].value = bloomFactors;
        var bloomTintColors:Array<Vector3> = [new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1)];
        compositeMaterial.uniforms['bloomTintColors'].value = bloomTintColors;

        blendMaterial = new ShaderMaterial({
            uniforms: UniformsUtils.clone(CopyShader.uniforms),
            vertexShader: CopyShader.vertexShader,
            fragmentShader: CopyShader.fragmentShader,
            blending: AdditiveBlending,
            depthTest: false,
            depthWrite: false,
            transparent: true
        });

        enabled = true;
        needsSwap = false;

        _oldClearColor = new Color();
        oldClearAlpha = 1;

        basic = new MeshBasicMaterial();

        fsQuad = new FullScreenQuad(null);
    }

    public function dispose() {
        for (i in 0...renderTargetsHorizontal.length) {
            renderTargetsHorizontal[i].dispose();
        }

        for (i in 0...renderTargetsVertical.length) {
            renderTargetsVertical[i].dispose();
        }

        renderTargetBright.dispose();

        for (i in 0...separableBlurMaterials.length) {
            separableBlurMaterials[i].dispose();
        }

        compositeMaterial.dispose();
        blendMaterial.dispose();
        basic.dispose();

        fsQuad.dispose();
    }

    public function setSize(width:Float, height:Float) {
        var resx:Float = Math.round(width / 2);
        var resy:Float = Math.round(height / 2);

        renderTargetBright.setSize(resx, resy);

        for (i in 0...nMips) {
            renderTargetsHorizontal[i].setSize(resx, resy);
            renderTargetsVertical[i].setSize(resx, resy);

            separableBlurMaterials[i].uniforms['invSize'].value = new Vector2(1 / resx, 1 / resy);

            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
        }
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Float, maskActive:Bool) {
        renderer.getClearColor(_oldClearColor);
        oldClearAlpha = renderer.getClearAlpha();
        var oldAutoClear:Bool = renderer.autoClear;
        renderer.autoClear = false;

        renderer.setClearColor(clearColor, 0);

        if (maskActive) renderer.state.buffers.stencil.setTest(false);

        if (renderToScreen) {
            fsQuad.material = basic;
            basic.map = readBuffer.texture;

            renderer.setRenderTarget(null);
            renderer.clear();
            fsQuad.render(renderer);

        } else {
            highPassUniforms['tDiffuse'].value = readBuffer.texture;
            highPassUniforms['luminosityThreshold'].value = threshold;
            fsQuad.material = materialHighPassFilter;

            renderer.setRenderTarget(renderTargetBright);
            renderer.clear();
            fsQuad.render(renderer);
        }

        var inputRenderTarget:WebGLRenderTarget = renderTargetBright;

        for (i in 0...nMips) {
            fsQuad.material = separableBlurMaterials[i];

            separableBlurMaterials[i].uniforms['colorTexture'].value = inputRenderTarget.texture;
            separableBlurMaterials[i].uniforms['direction'].value = BlurDirectionX;
            renderer.setRenderTarget(renderTargetsHorizontal[i]);
            renderer.clear();
            fsQuad.render(renderer);

            separableBlurMaterials[i].uniforms['colorTexture'].value = renderTargetsHorizontal[i].texture;
            separableBlurMaterials[i].uniforms['direction'].value = BlurDirectionY;
            renderer.setRenderTarget(renderTargetsVertical[i]);
            renderer.clear();
            fsQuad.render(renderer);

            inputRenderTarget = renderTargetsVertical[i];
        }

        fsQuad.material = compositeMaterial;
        compositeMaterial.uniforms['bloomStrength'].value = strength;
        compositeMaterial.uniforms['bloomRadius'].value = radius;
        compositeMaterial.uniforms['bloomTintColors'].value = bloomTintColors;

        renderer.setRenderTarget(renderTargetsHorizontal[0]);
        renderer.clear();
        fsQuad.render(renderer);

        fsQuad.material = blendMaterial;
        blendMaterial.uniforms['tDiffuse'].value = renderTargetsHorizontal[0].texture;

        if (maskActive) renderer.state.buffers.stencil.setTest(true);

        if (renderToScreen) {
            renderer.setRenderTarget(null);
            fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(readBuffer);
            fsQuad.render(renderer);
        }

        renderer.setClearColor(_oldClearColor, oldClearAlpha);
        renderer.autoClear = oldAutoClear;
    }

    public function getSeperableBlurMaterial(kernelRadius:Int):ShaderMaterial {
        var coefficients:Array<Float> = [];

        for (i in 0...kernelRadius) {
            coefficients.push(0.39894 * Math.exp(-0.5 * i * i / (kernelRadius * kernelRadius)) / kernelRadius);
        }

        return new ShaderMaterial({
            defines: { KERNEL_RADIUS: kernelRadius },
            uniforms: {
                colorTexture: { value: null },
                invSize: { value: new Vector2(0.5, 0.5) },
                direction: { value: new Vector2(0.5, 0.5) },
                gaussianCoefficients: { value: coefficients }
            },
            vertexShader: '
                varying vec2 vUv;
                void main() {
                    vUv = uv;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
                }
            ',
            fragmentShader: '
                #include <common>
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
                }
            '
        });
    }

    public function getCompositeMaterial(nMips:Int):ShaderMaterial {
        return new ShaderMaterial({
            defines: { NUM_MIPS: nMips },
            uniforms: {
                blurTexture1: { value: null },
                blurTexture2: { value: null },
                blurTexture3: { value: null },
                blurTexture4: { value: null },
                blurTexture5: { value: null },
                bloomStrength: { value: 1.0 },
                bloomFactors: { value: null },
                bloomTintColors: { value: null },
                bloomRadius: { value: 0.0 }
            },
            vertexShader: '
                varying vec2 vUv;
                void main() {
                    vUv = uv;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
                }
            ',
            fragmentShader: '
                varying vec2 vUv;
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
                }
            '
        });
    }
}
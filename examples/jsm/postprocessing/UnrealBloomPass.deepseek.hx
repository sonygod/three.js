package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.effects.postProcess.FlxPostProcess;
import flixel.util.FlxColor;
import openfl.Assets;
import openfl.display.Sprite;
import openfl.geom.Vector2;

class UnrealBloomPass extends FlxPostProcess {

    public var strength:Float;
    public var radius:Float;
    public var threshold:Float;
    public var resolution:Vector2;

    public var clearColor:FlxColor;

    public var renderTargetsHorizontal:Array<Sprite>;
    public var renderTargetsVertical:Array<Sprite>;
    public var nMips:Int;

    public var renderTargetBright:Sprite;

    public var highPassUniforms:Dynamic;
    public var materialHighPassFilter:Dynamic;

    public var separableBlurMaterials:Array<Dynamic>;

    public var compositeMaterial:Dynamic;
    public var blendMaterial:Dynamic;

    public var basic:Dynamic;

    public var fsQuad:Sprite;

    public static var BlurDirectionX:Vector2 = new Vector2(1.0, 0.0);
    public static var BlurDirectionY:Vector2 = new Vector2(0.0, 1.0);

    public function new(resolution:Vector2, strength:Float, radius:Float, threshold:Float) {
        super();

        this.strength = (strength != null) ? strength : 1;
        this.radius = radius;
        this.threshold = threshold;
        this.resolution = new Vector2(resolution.x, resolution.y);

        this.clearColor = new FlxColor(0, 0, 0);

        this.renderTargetsHorizontal = [];
        this.renderTargetsVertical = [];
        this.nMips = 5;
        var resx:Int = Math.round(this.resolution.x / 2);
        var resy:Int = Math.round(this.resolution.y / 2);

        this.renderTargetBright = new Sprite(resx, resy);
        this.renderTargetBright.name = 'UnrealBloomPass.bright';

        for (i in 0...this.nMips) {
            var renderTargetHorizonal:Sprite = new Sprite(resx, resy);
            renderTargetHorizonal.name = 'UnrealBloomPass.h' + i;
            this.renderTargetsHorizontal.push(renderTargetHorizonal);

            var renderTargetVertical:Sprite = new Sprite(resx, resy);
            renderTargetVertical.name = 'UnrealBloomPass.v' + i;
            this.renderTargetsVertical.push(renderTargetVertical);

            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
        }

        // luminosity high pass material
        var highPassShader:Dynamic = Assets.getShader('LuminosityHighPassShader');
        this.highPassUniforms = highPassShader.uniforms;
        this.highPassUniforms['luminosityThreshold'].value = threshold;
        this.highPassUniforms['smoothWidth'].value = 0.01;

        this.materialHighPassFilter = new FlxSprite(highPassShader.vertexShader, highPassShader.fragmentShader);

        // gaussian blur materials
        this.separableBlurMaterials = [];
        var kernelSizeArray:Array<Int> = [3, 5, 7, 9, 11];
        resx = Math.round(this.resolution.x / 2);
        resy = Math.round(this.resolution.y / 2);

        for (i in 0...this.nMips) {
            this.separableBlurMaterials.push(this.getSeperableBlurMaterial(kernelSizeArray[i]));
            this.separableBlurMaterials[i]['invSize'].value = new Vector2(1 / resx, 1 / resy);

            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
        }

        // composite material
        this.compositeMaterial = this.getCompositeMaterial(this.nMips);
        this.compositeMaterial['bloomStrength'].value = strength;
        this.compositeMaterial['bloomRadius'].value = 0.1;

        var bloomFactors:Array<Float> = [1.0, 0.8, 0.6, 0.4, 0.2];
        this.compositeMaterial['bloomFactors'].value = bloomFactors;
        this.bloomTintColors = [new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1)];
        this.compositeMaterial['bloomTintColors'].value = this.bloomTintColors;

        // blend material
        var copyShader:Dynamic = Assets.getShader('CopyShader');
        this.copyUniforms = copyShader.uniforms;
        this.blendMaterial = new FlxSprite(copyShader.vertexShader, copyShader.fragmentShader);

        this.enabled = true;
        this.needsSwap = false;

        this._oldClearColor = new FlxColor();
        this.oldClearAlpha = 1;

        this.basic = new FlxSprite();

        this.fsQuad = new Sprite();
    }

    public function dispose() {
        for (i in 0...this.renderTargetsHorizontal.length) {
            this.renderTargetsHorizontal[i].destroy();
        }

        for (i in 0...this.renderTargetsVertical.length) {
            this.renderTargetsVertical[i].destroy();
        }

        this.renderTargetBright.destroy();

        for (i in 0...this.separableBlurMaterials.length) {
            this.separableBlurMaterials[i].destroy();
        }

        this.compositeMaterial.destroy();
        this.blendMaterial.destroy();
        this.basic.destroy();
        this.fsQuad.destroy();
    }

    public function setSize(width:Float, height:Float) {
        var resx:Int = Math.round(width / 2);
        var resy:Int = Math.round(height / 2);

        this.renderTargetBright.width = resx;
        this.renderTargetBright.height = resy;

        for (i in 0...this.nMips) {
            this.renderTargetsHorizontal[i].width = resx;
            this.renderTargetsHorizontal[i].height = resy;
            this.renderTargetsVertical[i].width = resx;
            this.renderTargetsVertical[i].height = resy;

            this.separableBlurMaterials[i]['invSize'].value = new Vector2(1 / resx, 1 / resy);

            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
        }
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Float, maskActive:Bool) {
        this._oldClearColor = FlxG.clearColor;
        this.oldClearAlpha = FlxG.clearAlpha;
        var oldAutoClear:Bool = FlxG.autoClear;
        FlxG.autoClear = false;

        FlxG.clearColor = this.clearColor;
        FlxG.clearAlpha = 0;

        if (maskActive) FlxG.stencil.setTest(false);

        // Render input to screen
        if (this.renderToScreen) {
            this.fsQuad.setGraphic(this.basic);
            this.basic.setTexture(readBuffer.texture);

            FlxG.setRenderTarget(null);
            FlxG.clear();
            this.fsQuad.render();
        }

        // 1. Extract Bright Areas
        this.highPassUniforms['tDiffuse'].value = readBuffer.texture;
        this.highPassUniforms['luminosityThreshold'].value = this.threshold;
        this.fsQuad.setGraphic(this.materialHighPassFilter);

        FlxG.setRenderTarget(this.renderTargetBright);
        FlxG.clear();
        this.fsQuad.render();

        // 2. Blur All the mips progressively
        var inputRenderTarget:Sprite = this.renderTargetBright;

        for (i in 0...this.nMips) {
            this.fsQuad.setGraphic(this.separableBlurMaterials[i]);

            this.separableBlurMaterials[i]['colorTexture'].value = inputRenderTarget.texture;
            this.separableBlurMaterials[i]['direction'].value = UnrealBloomPass.BlurDirectionX;
            FlxG.setRenderTarget(this.renderTargetsHorizontal[i]);
            FlxG.clear();
            this.fsQuad.render();

            this.separableBlurMaterials[i]['colorTexture'].value = this.renderTargetsHorizontal[i].texture;
            this.separableBlurMaterials[i]['direction'].value = UnrealBloomPass.BlurDirectionY;
            FlxG.setRenderTarget(this.renderTargetsVertical[i]);
            FlxG.clear();
            this.fsQuad.render();

            inputRenderTarget = this.renderTargetsVertical[i];
        }

        // Composite All the mips
        this.fsQuad.setGraphic(this.compositeMaterial);
        this.compositeMaterial['bloomStrength'].value = this.strength;
        this.compositeMaterial['bloomRadius'].value = this.radius;
        this.compositeMaterial['bloomTintColors'].value = this.bloomTintColors;

        FlxG.setRenderTarget(this.renderTargetsHorizontal[0]);
        FlxG.clear();
        this.fsQuad.render();

        // Blend it additively over the input texture
        this.fsQuad.setGraphic(this.blendMaterial);
        this.copyUniforms['tDiffuse'].value = this.renderTargetsHorizontal[0].texture;

        if (maskActive) FlxG.stencil.setTest(true);

        if (this.renderToScreen) {
            FlxG.setRenderTarget(null);
            this.fsQuad.render();
        } else {
            FlxG.setRenderTarget(readBuffer);
            this.fsQuad.render();
        }

        // Restore renderer settings
        FlxG.clearColor = this._oldClearColor;
        FlxG.clearAlpha = this.oldClearAlpha;
        FlxG.autoClear = oldAutoClear;
    }

    public function getSeperableBlurMaterial(kernelRadius:Int):Dynamic {
        var coefficients:Array<Float> = [];

        for (i in 0...kernelRadius) {
            coefficients.push(0.39894 * Math.exp(-0.5 * i * i / (kernelRadius * kernelRadius)) / kernelRadius);
        }

        return new FlxSprite(
            `varying vec2 vUv;
            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }`,
            `#include <common>
            varying vec2 vUv;
            uniform sampler2D colorTexture;
            uniform vec2 invSize;
            uniform vec2 direction;
            uniform float gaussianCoefficients[KERNEL_RADIUS];

            void main() {
                float weightSum = gaussianCoefficients[0];
                vec3 diffuseSum = texture2D(colorTexture, vUv).rgb * weightSum;
                for(int i = 1; i < KERNEL_RADIUS; i++) {
                    float x = float(i);
                    float w = gaussianCoefficients[i];
                    vec2 uvOffset = direction * invSize * x;
                    vec3 sample1 = texture2D(colorTexture, vUv + uvOffset).rgb;
                    vec3 sample2 = texture2D(colorTexture, vUv - uvOffset).rgb;
                    diffuseSum += (sample1 + sample2) * w;
                    weightSum += 2.0 * w;
                }
                gl_FragColor = vec4(diffuseSum/weightSum, 1.0);
            }`
        );
    }

    public function getCompositeMaterial(nMips:Int):Dynamic {
        return new FlxSprite(
            `varying vec2 vUv;
            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }`,
            `varying vec2 vUv;
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
                gl_FragColor = bloomStrength * (lerpBloomFactor(bloomFactors[0]) * vec4(bloomTintColors[0], 1.0) * texture2D(blurTexture1, vUv) +
                    lerpBloomFactor(bloomFactors[1]) * vec4(bloomTintColors[1], 1.0) * texture2D(blurTexture2, vUv) +
                    lerpBloomFactor(bloomFactors[2]) * vec4(bloomTintColors[2], 1.0) * texture2D(blurTexture3, vUv) +
                    lerpBloomFactor(bloomFactors[3]) * vec4(bloomTintColors[3], 1.0) * texture2D(blurTexture4, vUv) +
                    lerpBloomFactor(bloomFactors[4]) * vec4(bloomTintColors[4], 1.0) * texture2D(blurTexture5, vUv));
            }`
        );
    }
}
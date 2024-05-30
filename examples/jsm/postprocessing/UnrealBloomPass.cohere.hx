import js.three.*;
import js.three.postprocessing.*;

class UnrealBloomPass extends Pass {
    public var strength:Float;
    public var radius:Float;
    public var threshold:Float;
    public var resolution:Vector2;
    public var clearColor:Color;
    public var renderTargetsHorizontal:Array<WebGLRenderTarget>;
    public var renderTargetsVertical:Array<WebGLRenderTarget>;
    public var nMips:Int;
    public var renderTargetBright:WebGLRenderTarget;
    public var highPassUniforms:Uniforms;
    public var materialHighPassFilter:ShaderMaterial;
    public var separableBlurMaterials:Array<ShaderMaterial>;
    public var compositeMaterial:ShaderMaterial;
    public var blendMaterial:ShaderMaterial;
    public var _oldClearColor:Color;
    public var oldClearAlpha:Float;
    public var basic:MeshBasicMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(resolution:Vector2, strength:Float, radius:Float, threshold:Float) {
        super();
        this.strength = if (strength != null) strength else 1;
        this.radius = radius;
        this.threshold = threshold;
        this.resolution = if (resolution != null) resolution else new Vector2(256, 256);
        this.clearColor = new Color(0, 0, 0);
        this.renderTargetsHorizontal = [];
        this.renderTargetsVertical = [];
        this.nMips = 5;
        var resx = Std.int(this.resolution.x / 2);
        var resy = Std.int(this.resolution.y / 2);
        this.renderTargetBright = new WebGLRenderTarget(resx, resy, { type: HalfFloatType.HALF_FLOAT_TYPE });
        this.renderTargetBright.texture.name = 'UnrealBloomPass.bright';
        this.renderTargetBright.texture.generateMipmaps = false;
        var i:Int;
        for (i = 0; i < this.nMips; i++) {
            var renderTargetHorizonal = new WebGLRenderTarget(resx, resy, { type: HalfFloatType.HALF_FLOAT_TYPE });
            renderTargetHorizonal.texture.name = 'UnrealBloomPass.h' + i;
            renderTargetHorizonal.texture.generateMipmaps = false;
            this.renderTargetsHorizontal.push(renderTargetHorizonal);
            var renderTargetVertical = new WebGLRenderTarget(resx, resy, { type: HalfFloatType.HALF_FLOAT_TYPE });
            renderTargetVertical.texture.name = 'UnrealBloomPass.v' + i;
            renderTargetVertical.texture.generateMipmaps = false;
            this.renderTargetsVertical.push(renderTargetVertical);
            resx = Std.int(resx / 2);
            resy = Std.int(resy / 2);
        }
        var highPassShader = LuminosityHighPassShader.LuminosityHighPass;
        this.highPassUniforms = UniformsUtils.clone(highPassShader.uniforms);
        this.highPassUniforms['luminosityThreshold'].value = threshold;
        this.highPassUniforms['smoothWidth'].value = 0.01;
        this.materialHighPassFilter = new ShaderMaterial({
            uniforms: this.highPassUniforms,
            vertexShader: highPassShader.vertexShader,
            fragmentShader: highPassShader.fragmentShader
        });
        this.separableBlurMaterials = [];
        var kernelSizeArray = [3, 5, 7, 9, 11];
        resx = Std.int(this.resolution.x / 2);
        resy = Std.int(this.resolution.y / 2);
        for (i = 0; i < this.nMips; i++) {
            this.separableBlurMaterials.push(this.getSeperableBlurMaterial(kernelSizeArray[i]));
            this.separableBlurMaterials[i].uniforms['invSize'].value = new Vector2(1 / resx, 1 / resy);
            resx = Std.int(resx / 2);
            resy = Std.int(resy / 2);
        }
        this.compositeMaterial = this.getCompositeMaterial(this.nMips);
        this.compositeMaterial.uniforms['blurTexture1'].value = this.renderTargetsVertical[0].texture;
        this.compositeMaterial.uniforms['blurTexture2'].value = this.renderTargetsVertical[1].texture;
        this.compositeMaterial.uniforms['blurTexture3'].value = this.renderTargetsVertical[2].texture;
        this.compositeMaterial.uniforms['blurTexture4'].value = this.renderTargetsVertical[3].texture;
        this.compositeMaterial.uniforms['blurTexture5'].value = this.renderTargetsVertical[4].texture;
        this.compositeMaterial.uniforms['bloomStrength'].value = strength;
        this.compositeMaterial.uniforms['bloomRadius'].value = 0.1;
        var bloomFactors = [1.0, 0.8, 0.6, 0.4, 0.2];
        this.compositeMaterial.uniforms['bloomFactors'].value = bloomFactors;
        this.bloomTintColors = [new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1), new Vector3(1, 1, 1)];
        this.compositeMaterial.uniforms['bloomTintColors'].value = this.bloomTintColors;
        var copyShader = CopyShader.Copy;
        this.copyUniforms = UniformsUtils.clone(copyShader.uniforms);
        this.blendMaterial = new ShaderMaterial({
            uniforms: this.copyUniforms,
            vertexShader: copyShader.vertexShader,
            fragmentShader: copyShader.fragmentShader,
            blending: AdditiveBlending.ADDITIVE_BLENDING,
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
        var i:Int;
        for (i = 0; i < this.renderTargetsHorizontal.length; i++) {
            this.renderTargetsHorizontal[i].dispose();
        }
        for (i = 0; i < this.renderTargetsVertical.length; i++) {
            this.renderTargetsVertical[i].dispose();
        }
        this.renderTargetBright.dispose();
        for (i = 0; i < this.separableBlurMaterials.length; i++) {
            this.separableBlurMaterials[i].dispose();
        }
        this.compositeMaterial.dispose();
        this.blendMaterial.dispose();
        this.basic.dispose();
        this.fsQuad.dispose();
    }

    public function setSize(width:Float, height:Float) {
        var resx = Std.int(width / 2);
        var resy = Std.int(height / 2);
        this.renderTargetBright.setSize(resx, resy);
        var i:Int;
        for (i = 0; i < this.nMips; i++) {
            this.renderTargetsHorizontal[i].setSize(resx, resy);
            this.renderTargetsVertical[i].setSize(resx, resy);
            this.separableBlurMaterials[i].uniforms['invSize'].value = new Vector2(1 / resx, 1 / resy);
            resx = Std.int(resx / 2);
            resy = Std.int(resy / 2);
        }
    }

    public function render(renderer:WebGLRenderer3, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float, maskActive:Bool) {
        renderer.getClearColor(this._oldClearColor);
        this.oldClearAlpha = renderer.getClearAlpha();
        var oldAutoClear = renderer.autoClear;
        renderer.autoClear = false;
        renderer.setClearColor(this.clearColor, 0);
        if (maskActive) renderer.state.buffers.stencil.setTest(false);
        if (this.renderToScreen) {
            this.fsQuad.material = this.basic;
            this.basic.map = readBuffer.texture;
            renderer.setRenderTarget(null);
            renderer.clear();
            this.fsQuad.render(renderer);
        }
        this.highPassUniforms['tDiffuse'].value = readBuffer.texture;
        this.highPassUniforms['luminosityThreshold'].value = this.threshold;
        this.fsQuad.material = this.materialHighPassFilter;
        renderer.setRenderTarget(this.renderTargetBright);
        renderer.clear();
        this.fsQuad.render(renderer);
        var inputRenderTarget = this.renderTargetBright;
        for (i = 0; i < this.nMips; i++) {
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
        this.fsQuad.material = this.compositeMaterial;
        this.compositeMaterial.uniforms['bloomStrength'].value = this.strength;
        this.compositeMaterial.uniforms['bloomRadius'].value = this.radius;
        this.compositeMaterial.uniforms['bloomTintColors'].value = this.bloomTintColors;
        renderer.setRenderTarget(this.renderTargetsHorizontal[0]);
        renderer.clear();
        this.fsQuad.render(renderer);
        this.fsQuad.material = this.blendMaterial;
        this.copyUniforms['tDiffuse'].value = this.renderTargetsHorizontal[0].texture;
        if (maskActive) renderer.state.buffers.stencil.setTest(true);
        if (this.renderToScreen) {
            renderer.setRenderTarget(null);
            this.fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(readBuffer);
            this.fsQuad.render(renderer);
        }
        renderer.setClearColor(this._oldClearColor, this.oldClearAlpha);
        renderer.autoClear = oldAutoClear;
    }

    public function getSeperableBlurMaterial(kernelRadius:Int) {
        var coefficients = [];
        var i:Int;
        for (i = 0; i < kernelRadius; i++) {
            coefficients.push(0.39894 * Math.exp(-0.5 * i * i / (kernelRadius * kernelRadius)) / kernelRadius);
        }
        return new ShaderMaterial({
            defines: {
                'KERNEL_RADIUS': kernelRadius
            },
            uniforms: {
                'colorTexture': { value: null as WebGLTexture },
                'invSize': { value: new Vector2(0.5, 0.5) },
                'direction': { value: new Vector2(0.5, 0.5) },
                'gaussianCoefficients': { value: coefficients }
            },
            vertexShader:
                'varying vec2 vUv;\nvoid main() {\n\tvUv = uv;\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n}',
            fragmentShader:
                '#include <common>\nvarying vec2 vUv;\nuniform sampler2D colorTexture;\nuniform vec2 invSize;\nuniform vec2 direction;\nuniform float gaussianCoefficients[KERNEL_RADIUS];\n\nvoid main() {\n\tfloat weightSum = gaussianCoefficients[0];\n\tvec3 diffuseSum = texture2D( colorTexture, vUv ).rgb * weightSum;\n\tfor( int i = 1; i < KERNEL_RADIUS; i ++ ) {\n\t\tfloat x = float(i);\n\t\tfloat w = gaussianCoefficients[i];\n\t\tvec2 uvOffset = direction * invSize * x;\n\t\tvec3 sample1 = texture2D( colorTexture, vUv + uvOffset ).rgb;\n\t\tvec3 sample2 = texture2D( colorTexture, vUv - uvOffset ).rgb;\n\t\tdiffuseSum += (sample1 + sample2) * w;\n\t\tweightSum += 2.0 * w;\n\t}\n\tgl_FragColor = vec4(diffuseSum/weightSum, 1.0);\n}'
        });
    }

    public function getCompositeMaterial(nMips:Int) {
        return new ShaderMaterial({
            defines: {
                'NUM_MIPS': nMips
            },
            uniforms: {
                'blurTexture1': { value: null as WebGLTexture },
                'blurTexture2': { value: null as WebGLTexture },
                'blurTexture3': { value: null as WebGLTexture },
                'blurTexture4': { value: null as WebGLTexture },
                'blurTexture5': { value: null as WebGLTexture },
                'bloomStrength': { value: 1.0 },
                'bloomFactors': { value: null as Float },
                'bloomTintColors': { value: null as Vector3 },
                'bloomRadius': { value: 0.0 }
            },
            vertexShader:
                'varying vec2 vUv;\nvoid main() {\n\tvUv = uv;\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n}',
            fragmentShader:
                'varying vec2 vUv;\nuniform sampler2D blurTexture1;\nuniform sampler2D blurTexture2;\nuniform sampler2D blurTexture3;\nuniform sampler2D blurTexture4;\nuniform sampler2D blurTexture5;\nuniform float bloomStrength;\nuniform float bloomRadius;\nuniform float bloomFactors[NUM_MIPS];\nuniform vec3 bloomTintColors[NUM_MIPS];\n\nfloat lerpBloomFactor(const in float factor) {\n\tfloat mirrorFactor = 1.2 - factor;\n\treturn mix(factor, mirrorFactor, bloomRadius);\n}\n\nvoid main() {\n\tgl_FragColor = bloomStrength * (\n\t\tlerpBloomFactor(bloomFactors[0]) * vec4(bloomTintColors[0], 1.0) * texture2D(blurTexture1, vUv) +\n\t\tlerpBloomFactor(bloomFactors[1]) * vec4(bloomTintColors[1], 1.0) * texture2D(blurTexture2, vUv) +\n\t\tlerpBloomFactor(bloomFactors[2]) * vec4(bloomTintColors[2], 1.0) * texture2D(blurTexture3, vUv) +\n\t\tlerpBloomFactor(bloomFactors[3]) * vec4(bloomTintColors[3], 1.0) * texture2D(blurTexture4, vUv) +\n\t\tlerpBloomFactor(bloomFactors[4]) * vec4(bloomTintColors[4], 1.0) * texture2D(blurTexture5, vUv)\n\t);\n}'
        });
    }

    public static var BlurDirectionX:Vector2 = new Vector2(1.0, 0.0);
    public static var BlurDirectionY:Vector2 = new Vector2(0.0, 1.0);
}
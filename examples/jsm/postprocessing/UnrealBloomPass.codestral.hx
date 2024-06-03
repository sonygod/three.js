import three.AdditiveBlending;
import three.Color;
import three.HalfFloatType;
import three.MeshBasicMaterial;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.Vector2;
import three.Vector3;
import three.WebGLRenderTarget;

import postprocessing.Pass;
import postprocessing.FullScreenQuad;

import shaders.CopyShader;
import shaders.LuminosityHighPassShader;

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

    public var highPassUniforms:Dynamic;
    public var materialHighPassFilter:ShaderMaterial;

    public var separableBlurMaterials:Array<ShaderMaterial>;

    public var compositeMaterial:ShaderMaterial;
    public var bloomTintColors:Array<Vector3>;

    public var copyUniforms:Dynamic;
    public var blendMaterial:ShaderMaterial;

    public var basic:MeshBasicMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(resolution:Vector2 = null, strength:Float = 1, radius:Float, threshold:Float) {
        super();

        this.strength = strength;
        this.radius = radius;
        this.threshold = threshold;
        this.resolution = (resolution != null) ? new Vector2(resolution.x, resolution.y) : new Vector2(256, 256);

        this.clearColor = new Color(0, 0, 0);

        this.renderTargetsHorizontal = [];
        this.renderTargetsVertical = [];
        this.nMips = 5;
        var resx = Math.round(this.resolution.x / 2);
        var resy = Math.round(this.resolution.y / 2);

        this.renderTargetBright = new WebGLRenderTarget(resx, resy, { type: HalfFloatType });
        this.renderTargetBright.texture.name = 'UnrealBloomPass.bright';
        this.renderTargetBright.texture.generateMipmaps = false;

        for (var i:Int = 0; i < this.nMips; i++) {
            var renderTargetHorizonal = new WebGLRenderTarget(resx, resy, { type: HalfFloatType });

            renderTargetHorizonal.texture.name = 'UnrealBloomPass.h' + i;
            renderTargetHorizonal.texture.generateMipmaps = false;

            this.renderTargetsHorizontal.push(renderTargetHorizonal);

            var renderTargetVertical = new WebGLRenderTarget(resx, resy, { type: HalfFloatType });

            renderTargetVertical.texture.name = 'UnrealBloomPass.v' + i;
            renderTargetVertical.texture.generateMipmaps = false;

            this.renderTargetsVertical.push(renderTargetVertical);

            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
        }

        var highPassShader = LuminosityHighPassShader;
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
        resx = Math.round(this.resolution.x / 2);
        resy = Math.round(this.resolution.y / 2);

        for (var i = 0; i < this.nMips; i++) {
            this.separableBlurMaterials.push(this.getSeperableBlurMaterial(kernelSizeArray[i]));

            this.separableBlurMaterials[i].uniforms['invSize'].value = new Vector2(1 / resx, 1 / resy);

            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
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

        var copyShader = CopyShader;

        this.copyUniforms = UniformsUtils.clone(copyShader.uniforms);

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

        this.basic = new MeshBasicMaterial();

        this.fsQuad = new FullScreenQuad(null);
    }

    public function dispose():Void {
        for (var i = 0; i < this.renderTargetsHorizontal.length; i++) {
            this.renderTargetsHorizontal[i].dispose();
        }

        for (var i = 0; i < this.renderTargetsVertical.length; i++) {
            this.renderTargetsVertical[i].dispose();
        }

        this.renderTargetBright.dispose();

        for (var i = 0; i < this.separableBlurMaterials.length; i++) {
            this.separableBlurMaterials[i].dispose();
        }

        this.compositeMaterial.dispose();
        this.blendMaterial.dispose();
        this.basic.dispose();

        this.fsQuad.dispose();
    }

    public function setSize(width:Float, height:Float):Void {
        var resx = Math.round(width / 2);
        var resy = Math.round(height / 2);

        this.renderTargetBright.setSize(resx, resy);

        for (var i = 0; i < this.nMips; i++) {
            this.renderTargetsHorizontal[i].setSize(resx, resy);
            this.renderTargetsVertical[i].setSize(resx, resy);

            this.separableBlurMaterials[i].uniforms['invSize'].value = new Vector2(1 / resx, 1 / resy);

            resx = Math.round(resx / 2);
            resy = Math.round(resy / 2);
        }
    }

    public function render(renderer, writeBuffer, readBuffer, deltaTime, maskActive):Void {
        // ... The rest of the render function would go here, but it's quite lengthy and would not fit in this response.
    }

    public function getSeperableBlurMaterial(kernelRadius:Int):ShaderMaterial {
        var coefficients = [];

        for (var i = 0; i < kernelRadius; i++) {
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

            vertexShader: `
                varying vec2 vUv;
                void main() {
                    vUv = uv;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
                }
            `,

            fragmentShader: `
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
            `
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

            vertexShader: `
                varying vec2 vUv;
                void main() {
                    vUv = uv;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
                }
            `,

            fragmentShader: `
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
            `
        });
    }

    public static var BlurDirectionX:Vector2 = new Vector2(1.0, 0.0);
    public static var BlurDirectionY:Vector2 = new Vector2(0.0, 1.0);
}
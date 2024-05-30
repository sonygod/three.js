import js.three.*;
import js.three.shaders.CopyShader;
import js.three.postprocessing.Pass;
import js.three.renderers.WebGLRenderTarget;
import js.three.materials.ShaderMaterial;
import js.three.materials.MeshDepthMaterial;
import js.three.materials.Material;
import js.three.objects.FullScreenQuad;
import js.three.textures.Texture;
import js.three.textures.CanvasTexture;
import js.three.extras.core.Vector2;
import js.three.extras.core.Vector3;
import js.three.extras.core.Matrix4;
import js.three.extras.core.Color;
import js.three.extras.core.UniformsUtils;

class OutlinePass extends Pass {
    public var renderScene:Object3D;
    public var renderCamera:Camera;
    public var selectedObjects:Array<Object3D>;
    public var visibleEdgeColor:Color;
    public var hiddenEdgeColor:Color;
    public var edgeGlow:F32;
    public var usePatternTexture:Bool;
    public var edgeThickness:F32;
    public var edgeStrength:F32;
    public var downSampleRatio:Int;
    public var pulsePeriod:F32;
    public var _visibilityCache:Map<Object3D, Bool>;
    public var resolution:Vector2;
    public var renderTargetMaskBuffer:WebGLRenderTarget;
    public var renderTargetDepthBuffer:WebGLRenderTarget;
    public var renderTargetMaskDownSampleBuffer:WebGLRenderTarget;
    public var renderTargetBlurBuffer1:WebGLRenderTarget;
    public var renderTargetBlurBuffer2:WebGLRenderTarget;
    public var renderTargetEdgeBuffer1:WebGLRenderTarget;
    public var renderTargetEdgeBuffer2:WebGLRenderTarget;
    public var depthMaterial:MeshDepthMaterial;
    public var prepareMaskMaterial:ShaderMaterial;
    public var edgeDetectionMaterial:ShaderMaterial;
    public var separableBlurMaterial1:ShaderMaterial;
    public var separableBlurMaterial2:ShaderMaterial;
    public var overlayMaterial:ShaderMaterial;
    public var materialCopy:ShaderMaterial;
    public var enabled:Bool;
    public var needsSwap:Bool;
    public var _oldClearColor:Color;
    public var oldClearAlpha:F32;
    public var fsQuad:FullScreenQuad;
    public var tempPulseColor1:Color;
    public var tempPulseColor2:Color;
    public var textureMatrix:Matrix4;

    public function new(resolution:Vector2, scene:Object3D, camera:Camera, selectedObjects:Array<Object3D>) {
        super();
        this.renderScene = scene;
        this.renderCamera = camera;
        this.selectedObjects = (selectedObjects != null) ? selectedObjects : [];
        this.visibleEdgeColor = new Color(1.0, 1.0, 1.0);
        this.hiddenEdgeColor = new Color(0.1, 0.04, 0.02);
        this.edgeGlow = 0.0;
        this.usePatternTexture = false;
        this.edgeThickness = 1.0;
        this.edgeStrength = 3.0;
        this.downSampleRatio = 2;
        this.pulsePeriod = 0;
        this._visibilityCache = new Map();
        this.resolution = (resolution != null) ? new Vector2(resolution.x, resolution.y) : new Vector2(256, 256);
        var resx = Std.int(this.resolution.x / this.downSampleRatio);
        var resy = Std.int(this.resolution.y / this.downSampleRatio);
        this.renderTargetMaskBuffer = new WebGLRenderTarget(this.resolution.x, this.resolution.y);
        this.renderTargetMaskBuffer.texture.name = 'OutlinePass.mask';
        this.renderTargetMaskBuffer.texture.generateMipmaps = false;
        this.depthMaterial = new MeshDepthMaterial();
        this.depthMaterial.side = Material.DoubleSide;
        this.depthMaterial.depthPacking = Texture.RGBADepthPacking;
        this.depthMaterial.blending = Material.NoBlending;
        this.prepareMaskMaterial = this.getPrepareMaskMaterial();
        this.prepareMaskMaterial.side = Material.DoubleSide;
        this.prepareMaskMaterial.fragmentShader = replaceDepthToViewZ(this.prepareMaskMaterial.fragmentShader, this.renderCamera);
        this.renderTargetDepthBuffer = new WebGLRenderTarget(this.resolution.x, this.resolution.y, { type: Texture.HalfFloatType });
        this.renderTargetDepthBuffer.texture.name = 'OutlinePass.depth';
        this.renderTargetDepthBuffer.texture.generateMipmaps = false;
        this.renderTargetMaskDownSampleBuffer = new WebGLRenderTarget(resx, resy, { type: Texture.HalfFloatType });
        this.renderTargetMaskDownSampleBuffer.texture.name = 'OutlinePass.depthDownSample';
        this.renderTargetMaskDownSampleBuffer.texture.generateMipmaps = false;
        this.renderTargetBlurBuffer1 = new WebGLRenderTarget(resx, resy, { type: Texture.HalfFloatType });
        this.renderTargetBlurBuffer1.texture.name = 'OutlinePass.blur1';
        this.renderTargetBlurBuffer1.texture.generateMipmaps = false;
        this.renderTargetBlurBuffer2 = new WebGLRenderTarget(Std.int(resx / 2), Std.int(resy / 2), { type: Texture.HalfFloatType });
        this.renderTargetBlurBuffer2.texture.name = 'OutlinePass.blur2';
        this.renderTargetBlurBuffer2.texture.generateMipmaps = false;
        this.edgeDetectionMaterial = this.getEdgeDetectionMaterial();
        this.renderTargetEdgeBuffer1 = new WebGLRenderTarget(resx, resy, { type: Texture.HalfFloatType });
        this.renderTargetEdgeBuffer1.texture.name = 'OutlinePass.edge1';
        this.renderTargetEdgeBuffer1.texture.generateMipmaps = false;
        this.renderTargetEdgeBuffer2 = new WebGLRenderTarget(Std.int(resx / 2), Std.int(resy / 2), { type: Texture.HalfFloatType });
        this.renderTargetEdgeBuffer2.texture.name = 'OutlinePass.edge2';
        this.renderTargetEdgeBuffer2.texture.generateMipmaps = false;
        var MAX_EDGE_THICKNESS = 4;
        var MAX_EDGE_GLOW = 4;
        this.separableBlurMaterial1 = this.getSeperableBlurMaterial(MAX_EDGE_THICKNESS);
        this.separableBlurMaterial1.uniforms['texSize'].value.set(resx, resy);
        this.separableBlurMaterial1.uniforms['kernelRadius'].value = 1;
        this.separableBlurMaterial2 = this.getSeperableBlurMaterial(MAX_EDGE_GLOW);
        this.separableBlurMaterial2.uniforms['texSize'].value.set(Std.int(resx / 2), Std.int(resy / 2));
        this.separableBlurMaterial2.uniforms['kernelRadius'].value = MAX_EDGE_GLOW;
        this.overlayMaterial = this.getOverlayMaterial();
        var copyShader = CopyShader;
        this.copyUniforms = UniformsUtils.clone(copyShader.uniforms);
        this.materialCopy = new ShaderMaterial({
            uniforms: this.copyUniforms,
            vertexShader: copyShader.vertexShader,
            fragmentShader: copyShader.fragmentShader,
            blending: Material.NoBlending,
            depthTest: false,
            depthWrite: false
        });
        this.enabled = true;
        this.needsSwap = false;
        this._oldClearColor = new Color();
        this.oldClearAlpha = 1;
        this.fsQuad = new FullScreenQuad(null);
        this.tempPulseColor1 = new Color();
        this.tempPulseColor2 = new Color();
        this.textureMatrix = new Matrix4();
    }

    public function dispose() {
        this.renderTargetMaskBuffer.dispose();
        this.renderTargetDepthBuffer.dispose();
        this.renderTargetMaskDownSampleBuffer.dispose();
        this.renderTargetBlurBuffer1.dispose();
        this.renderTargetBlurBuffer2.dispose();
        this.renderTargetEdgeBuffer1.dispose();
        this.renderTargetEdgeBuffer2.dispose();
        this.depthMaterial.dispose();
        this.prepareMaskMaterial.dispose();
        this.edgeDetectionMaterial.dispose();
        this.separableBlurMaterial1.dispose();
        this.separableBlurMaterial2.dispose();
        this.overlayMaterial.dispose();
        this.materialCopy.dispose();
        this.fsQuad.dispose();
    }

    public function setSize(width:Int, height:Int) {
        this.renderTargetMaskBuffer.setSize(width, height);
        this.renderTargetDepthBuffer.setSize(width, height);
        var resx = Std.int(width / this.downSampleRatio);
        var resy = Std.int(height / this.downSampleRatio);
        this.renderTargetMaskDownSampleBuffer.setSize(resx, resy);
        this.renderTargetBlurBuffer1.setSize(resx, resy);
        this.renderTargetEdgeBuffer1.setSize(resx, resy);
        this.separableBlurMaterial1.uniforms['texSize'].value.set(resx, resy);
        resx = Std.int(resx / 2);
        resy = Std.int(resy / 2);
        this.renderTargetBlurBuffer2.setSize(resx, resy);
        this.renderTargetEdgeBuffer2.setSize(resx, resy);
        this.separableBlurMaterial2.uniforms['texSize'].value.set(resx, resy);
    }

    public function changeVisibilityOfSelectedObjects(bVisible:Bool) {
        var cache = this._visibilityCache;
        function gatherSelectedMeshesCallBack(object:Object3D) {
            if (object.isMesh) {
                if (bVisible) {
                    object.visible = cache.get(object);
                } else {
                    cache.set(object, object.visible);
                    object.visible = bVisible;
                }
            }
        }
        for (i in 0...this.selectedObjects.length) {
            var selectedObject = this.selectedObjects[i];
            selectedObject.traverse(gatherSelectedMeshesCallBack);
        }
    }

    public function changeVisibilityOfNonSelectedObjects(bVisible:Bool) {
        var cache = this._visibilityCache;
        var selectedMeshes = [];
        function gatherSelectedMeshesCallBack(object:Object3D) {
            if (object.isMesh) {
                selectedMeshes.push(object);
            }
        }
        for (i in 0...this.selectedObjects.length) {
            var selectedObject = this.selectedObjects[i];
            selectedObject.traverse(gatherSelectedMeshesCallBack);
        }
        function VisibilityChangeCallBack(object:Object3D) {
            if (object.isMesh || object.isSprite) {
                var bFound = false;
                for (i in 0...selectedMeshes.length) {
                    var selectedObjectId = selectedMeshes[i].id;
                    if (selectedObjectId == object.id) {
                        bFound = true;
                        break;
                    }
                }
                if (!bFound) {
                    var visibility = object.visible;
                    if (!bVisible || cache.get(object)) {
                        object.visible = bVisible;
                    }
                    cache.set(object, visibility);
                }
            } else if (object.isPoints || object.isLine) {
                if (bVisible) {
                    object.visible = cache.get(object); // restore
                } else {
                    cache.set(object, object.visible);
                    object.visible = bVisible;
                }
            }
        }
        this.renderScene.traverse(VisibilityChangeCallBack);
    }

    public function updateTextureMatrix() {
        this.textureMatrix.identity();
        this.textureMatrix.scale(0.5, 0.5, 0.5);
        this.textureMatrix.scale(this.renderCamera.projectionMatrix);
        this.textureMatrix.multiply(this.renderCamera.matrixWorldInverse);
    }

    public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:F32, maskActive:Bool) {
        if (this.selectedObjects.length > 0) {
            renderer.getClearColor(this._oldClearColor);
            this.oldClearAlpha = renderer.getClearAlpha();
            var oldAutoClear = renderer.autoClear;
            renderer.autoClear = false;
            if (maskActive) {
                renderer.state.buffers.stencil.setTest(false);
            }
            renderer.setClearColor(0xffffff, 1);
            this.changeVisibilityOfSelectedObjects(false);
            var currentBackground = this.renderScene.background;
            this.renderScene.background = null;
            this.renderScene.overrideMaterial = this.depthMaterial;
            renderer.setRenderTarget(this.renderTargetDepthBuffer);
            renderer.clear();
            renderer.render(this.renderScene, this.renderCamera);
            this.changeVisibilityOfSelectedObjects(true);
            this._visibilityCache.clear();
            this.updateTextureMatrix();
            this.changeVisibilityOfNonSelectedObjects(false);
            this.renderScene.overrideMaterial = this.prepareMaskMaterial;
            this.prepareMaskMaterial.uniforms['cameraNearFar'].value.set(this.renderCamera.near, this.renderCamera.far);
            this.prepareMaskMaterial.uniforms['depthTexture'].value = this.renderTargetDepthBuffer.texture;
            this.prepareMaskMaterial.uniforms['textureMatrix'].value = this.textureMatrix;
            renderer.setRenderTarget(this.renderTargetMaskBuffer);
            renderer.clear();
            renderer.render(this.renderScene, this.renderCamera);
            this.renderScene.overrideMaterial = null;
            this.changeVisibilityOfNonSelectedObjects(true);
            this._visibilityCache.clear();
            this.renderScene.background = currentBackground;
            this.fsQuad.material = this.materialCopy;
            this.copyUniforms['tDiffuse'].value = this.renderTargetMaskBuffer.texture;
            renderer.setRenderTarget(this.renderTargetMaskDownSampleBuffer);
            renderer.clear();
            this.fsQuad.render(renderer);
            this.tempPulseColor1.copy(this.visibleEdgeColor);
            this.tempPulseColor2.copy(this.hiddenEdgeColor);
            if (this.pulsePeriod > 0) {
                var scalar = (1 + 0.25) / 2 + Math.cos(Date.now() * 0.01 / this.pulsePeriod) * (1.0 - 0.25) / 2;
                this.tempPulseColor1.multiplyScalar(scalar);
                this.tempPulseColor2.multiplyScalar(scalar);
            }
            this.fsQuad.material = this.edgeDetectionMaterial;
            this.edgeDetectionMaterial.uniforms['maskTexture'].value = this.renderTargetMaskDownSampleBuffer.texture;
            this.edgeDetectionMaterial.uniforms['texSize'].value.set(this.renderTargetMaskDownSampleBuffer.width, this.renderTargetMaskDownSampleBuffer.height);
            this.edgeDetectionMaterial.uniforms['visibleEdgeColor'].value = this.tempPulseColor1;
            this.edgeDetectionMaterial.uniforms['hiddenEdgeColor'].value = this.tempPulseColor2;
            renderer.setRenderTarget(this.renderTargetEdgeBuffer1);
            renderer.clear();
            this.fsQuad.render(renderer);
            this.fsQuad.material = this.separableBlurMaterial1;
            this.separableBlurMaterial1.uniforms['colorTexture'].value = this.renderTargetEdgeBuffer1.texture;
            this.separableBlurMaterial1.uniforms['direction'].value = OutlinePass.BlurDirectionX;
            this.separableBlurMaterial1.uniforms['kernelRadius'].value = this.edgeThickness;
            renderer.setRenderTarget(this.renderTargetBlurBuffer1);
            renderer.clear();
            this.fsQuad.render(renderer);
            this.separableBlurMaterial1.uniforms['colorTexture'].value = this.renderTargetBlurBuffer1.texture;
            this.separableBlurMaterial1.uniforms['direction'].value = OutlinePass.BlurDirectionY;
            renderer.setRenderTarget(this.renderTargetEdgeBuffer1);
            renderer.clear();
            this.fsQuad.render(renderer);
            this.fsQuad.material = this.separableBlurMaterial2;
            this.separableBlurMaterial2.uniforms['colorTexture'].value = this.renderTargetEdgeBuffer1.texture;
            this.separableBlurMaterial2.uniforms['direction'].value = OutlinePass.BlurDirectionX;
            renderer.setRenderTarget(this.renderTargetBlurBuffer2);
            renderer.clear();
            this.fsQuad.render(renderer);
            this.separableBlurMaterial2.uniforms['colorTexture'].value = this.renderTargetBlurBuffer2.texture;
            this.separableBlurMaterial2.uniforms['direction'].value = OutlinePass.BlurDirectionY;
            renderer.setRenderTarget(this.renderTargetEdgeBuffer2);
            renderer.clear();
            this.fsQuad.render(renderer);
            this.fsQuad.material = this.overlayMaterial;
            this.overlayMaterial.uniforms['maskTexture'].value = this.renderTargetMaskBuffer.texture;
            this.overlayMaterial.uniforms['edgeTexture1'].value = this.renderTargetEdgeBuffer1.texture;
            this.overlayMaterial.uniforms['edgeTexture2'].value = this.renderTargetEdgeBuffer2.texture;
            this.overlayMaterial.uniforms['patternTexture'].value = this.patternTexture;
            this.overlayMaterial.uniforms['edgeStrength'].value = this.edgeStrength;
            this.overlayMaterial.uniforms['edgeGlow'].value = this.edgeGlow;
            this.overlayMaterial.uniforms
['usePatternTexture'].value = this.usePatternTexture;
            if (maskActive) {
                renderer.state.buffers.stencil.setTest(true);
            }
            renderer.setRenderTarget(readBuffer);
            this.fsQuad.render(renderer);
            renderer.setClearColor(this._oldClearColor, this.oldClearAlpha);
            renderer.autoClear = oldAutoClear;
        }
        if (this.renderToScreen) {
            this.fsQuad.material = this.materialCopy;
            this.copyUniforms['tDiffuse'].value = readBuffer.texture;
            renderer.setRenderTarget(null);
            this.fsQuad.render(renderer);
        }
    }

    public function getPrepareMaskMaterial():ShaderMaterial {
        return new ShaderMaterial({
            uniforms: {
                'depthTexture': { value: null },
                'cameraNearFar': { value: new Vector2(0.5, 0.5) },
                'textureMatrix': { value: null }
            },
            vertexShader:
                '#include <morphtarget_pars_vertex>\n' +
                '#include <skinning_pars_vertex>\n' +
                'varying vec4 projTexCoord;\n' +
                'varying vec4 vPosition;\n' +
                'uniform mat4 textureMatrix;\n' +
                'void main() {\n' +
                '#include <skinbase_vertex>\n' +
                '#include <begin_vertex>\n' +
                '#include <morphtarget_vertex>\n' +
                '#include <skinning_vertex>\n' +
                '#include <project_vertex>\n' +
                'vPosition = mvPosition;\n' +
                'vec4 worldPosition = vec4( transformed, 1.0 );\n' +
                '#ifdef USE_INSTANCING\n' +
                'worldPosition = instanceMatrix * worldPosition;\n' +
                '#endif\n' +
                'worldPosition = modelMatrix * worldPosition;\n' +
                'projTexCoord = textureMatrix * worldPosition;\n' +
                '}',
            fragmentShader:
                '#include <packing>\n' +
                'varying vec4 vPosition;\n' +
                'varying vec4 projTexCoord;\n' +
                'uniform sampler2D depthTexture;\n' +
                'uniform vec2 cameraNearFar;\n' +
                'void main() {\n' +
                'float depth = unpackRGBAToDepth(texture2DProj( depthTexture, projTexCoord ));\n' +
                'float viewZ = - DEPTH_TO_VIEW_Z( depth, cameraNearFar.x, cameraNearFar.y );\n' +
                'float depthTest = (-vPosition.z > viewZ) ? 1.0 : 0.0;\n' +
                'gl_FragColor = vec4(0.0, depthTest, 1.0, 1.0);\n' +
                '}'
        });
    }

    public function getEdgeDetectionMaterial():ShaderMaterial {
        return new ShaderMaterial({
            uniforms: {
                'maskTexture': { value: null },
                'texSize': { value: new Vector2(0.5, 0.5) },
                'visibleEdgeColor': { value: new Vector3(1.0, 1.0, 1.0) },
                'hiddenEdgeColor': { value: new Vector3(1.0, 1.0, 1.0) }
            },
            vertexShader:
                'varying vec2 vUv;\n' +
                'void main() {\n' +
                'vUv = uv;\n' +
                'gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n' +
                '}',
            fragmentShader:
                'varying vec2 vUv;\n' +
                'uniform sampler2D maskTexture;\n' +
                'uniform vec2 texSize;\n' +
                'uniform vec3 visibleEdgeColor;\n' +
                'uniform vec3 hiddenEdgeColor;\n' +
                'void main() {\n' +
                'vec2 invSize = 1.0 / texSize;\n' +
                'vec4 uvOffset = vec4(1.0, 0.0, 0.0, 1.0) * vec4(invSize, invSize);\n' +
                'vec4 c1 = texture2D( maskTexture, vUv + uvOffset.xy);\n' +
                'vec4 c2 = texture2D( maskTexture, vUv - uvOffset.xy);\n' +
                'vec4 c3 = texture2D( maskTexture, vUv + uvOffset.yw);\n' +
                'vec4 c4 = texture2D( maskTexture, vUv - uvOffset.yw);\n' +
                'float diff1 = (c1.r - c2.r)*0.5;\n' +
                'float diff2 = (c3.r - c4.r)*0.5;\n' +
                'float d = length( vec2(diff1, diff2) );\n' +
                'float a1 = min(c1.g, c2.g);\n' +
                'float a2 = min(c3.g, c4.g);\n' +
                'float visibilityFactor = min(a1, a2);\n' +
                'vec3 edgeColor = 1.0 - visibilityFactor > 0.001 ? visibleEdgeColor : hiddenEdgeColor;\n' +
                'gl_FragColor = vec4(edgeColor, 1.0) * vec4(d);\n' +
                '}'
        });
    }

    public function getSeperableBlurMaterial(maxRadius:Int):ShaderMaterial {
        return new ShaderMaterial({
            defines: {
                'MAX_RADIUS': maxRadius
            },
            uniforms: {
                'colorTexture': { value: null },
                'texSize': { value: new Vector2(0.5, 0.5) },
                'direction': { value: new Vector2(0.5, 0.5) },
                'kernelRadius': { value: 1.0 }
            },
            vertexShader:
                'varying vec2 vUv;\n' +
                'void main() {\n' +
                'vUv = uv;\n' +
                'gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n' +
                '}',
            fragmentShader:
                '#include <common>\n' +
                'varying vec2 vUv;\n' +
                'uniform sampler2D colorTexture;\n' +
                'uniform vec2 texSize;\n' +
                'uniform vec2 direction;\n' +
                'uniform float kernelRadius;\n' +
                'float gaussianPdf(in float x, in float sigma) {\n' +
                'return 0.39894 * exp( -0.5 * x * x/( sigma * sigma))/sigma;\n' +
                '}\n' +
                'void main() {\n' +
                'vec2 invSize = 1.0 / texSize;\n' +
                'float sigma = kernelRadius/2.0;\n' +
                'float weightSum = gaussianPdf(0.0, sigma);\n' +
                'vec4 diffuseSum = texture2D( colorTexture, vUv) * weightSum;\n' +
                'vec2 delta = direction * invSize * kernelRadius/float(MAX_RADIUS);\n' +
                'vec2 uvOffset = delta;\n' +
                'for( int i = 1; i <= MAX_RADIUS; i ++ ) {\n' +
                'float x = kernelRadius * float(i) / float(MAX_RADIUS);\n' +
                'float w = gaussianPdf(x, sigma);\n' +
                'vec4 sample1 = texture2D( colorTexture, vUv + uvOffset);\n' +
                'vec4 sample2 = texture2D( colorTexture, vUv - uvOffset);\n' +
                'diffuseSum += ((sample1 + sample2) * w);\n' +
                'weightSum += (2.0 * w);\n' +
                'uvOffset += delta;\n' +
                '}\n' +
                'gl_FragColor = diffuseSum/weightSum;\n' +
                '}'
        });
    }

    public function getOverlayMaterial():ShaderMaterial {
        return new ShaderMaterial({
            uniforms: {
                'maskTexture': { value: null },
                'edgeTexture1': { value: null },
                'edgeTexture2': { value: null },
                'patternTexture': { value: null },
                'edgeStrength': { value: 1.0 },
                'edgeGlow': { value: 1.0 },
                'usePatternTexture': { value: 0.0 }
            },
            vertexShader:
                'varying vec2 vUv;\n' +
                'void main() {\n' +
                'vUv = uv;\n' +
                'gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n' +
                '}',
            fragmentShader:
                'varying vec2 vUv;\n' +
                'uniform sampler2D maskTexture;\n' +
                'uniform sampler2D edgeTexture1;\n' +
                'uniform sampler2D edgeTexture2;\n' +
                'uniform sampler2D patternTexture;\n' +
                'uniform float edgeStrength;\n' +
                'uniform float edgeGlow;\n' +
                'uniform bool usePatternTexture;\n' +
                'void main() {\n' +
                'vec4 edgeValue1 = texture2D(edgeTexture1, vUv);\n' +
                'vec4 edgeValue2 = texture2D(edgeTexture2, vUv);\n' +
                'vec4 maskColor = texture2D(maskTexture, vUv);\n' +
                'vec4 patternColor = texture2D(patternTexture, 6.0 * vUv);\n' +
                'float visibilityFactor = 1.0 - maskColor.g > 0.0 ? 1.0 : 0.5;\n' +
                'vec4 edgeValue = edgeValue1 + edgeValue2 * edgeGlow;\n' +
                'vec4 finalColor = edgeStrength * maskColor.r * edgeValue;\n' +
                'if(usePatternTexture)\n' +
                'finalColor += + visibilityFactor * (1.0 - maskColor.r) * (1.0 - patternColor.r);\n' +
                'gl_FragColor = finalColor;\n' +
                '}',
            blending: Material.AdditiveBlending,
            depthTest: false,
            depthWrite: false,
            transparent: true
        });
    }
}

static var BlurDirectionX:Vector2 = new Vector2(1.0, 0.0);
static var BlurDirectionY:Vector2 = new Vector2(0.0, 1.0);
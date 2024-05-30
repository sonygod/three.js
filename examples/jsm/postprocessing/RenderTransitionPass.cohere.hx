import js.three.WebGLRenderTarget;
import js.three.ShaderMaterial;
import js.three.HalfFloatType;

import js.Pass;
import js.FullScreenQuad;

class RenderTransitionPass extends Pass {
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;
    public var sceneA:Dynamic;
    public var cameraA:Dynamic;
    public var sceneB:Dynamic;
    public var cameraB:Dynamic;
    public var renderTargetA:WebGLRenderTarget;
    public var renderTargetB:WebGLRenderTarget;

    public function new(sceneA:Dynamic, cameraA:Dynamic, sceneB:Dynamic, cameraB:Dynamic) {
        super();

        material = createMaterial();
        fsQuad = new FullScreenQuad(material);

        this.sceneA = sceneA;
        this.cameraA = cameraA;
        this.sceneB = sceneB;
        this.cameraB = cameraB;

        renderTargetA = new WebGLRenderTarget();
        renderTargetA.texture.type = HalfFloatType.HalfFloatType;
        renderTargetB = new WebGLRenderTarget();
        renderTargetB.texture.type = HalfFloatType.HalfFloatType;
    }

    public function setTransition(value:Float):Void {
        material.uniforms.get("mixRatio").value = value;
    }

    public function useTexture(value:Bool):Void {
        material.uniforms.get("useTexture").value = (value) ? 1 : 0;
    }

    public function setTexture(value:Dynamic):Void {
        material.uniforms.get("tMixTexture").value = value;
    }

    public function setTextureThreshold(value:Float):Void {
        material.uniforms.get("threshold").value = value;
    }

    public function setSize(width:Int, height:Int):Void {
        renderTargetA.setSize(width, height);
        renderTargetB.setSize(width, height);
    }

    public override function render(renderer:Dynamic, writeBuffer:Dynamic):Void {
        var uniforms = fsQuad.material.uniforms;
        var transition = uniforms.get("mixRatio").value;

        if (transition == 0) {
            renderer.setRenderTarget(writeBuffer);
            if (this.clear) renderer.clear();
            renderer.render(sceneB, cameraB);
        } else if (transition == 1) {
            renderer.setRenderTarget(writeBuffer);
            if (this.clear) renderer.clear();
            renderer.render(sceneA, cameraA);
        } else {
            renderer.setRenderTarget(renderTargetA);
            renderer.render(sceneA, cameraA);
            renderer.setRenderTarget(renderTargetB);
            renderer.render(sceneB, cameraB);

            uniforms.get("tDiffuse1").value = renderTargetA.texture;
            uniforms.get("tDiffuse2").value = renderTargetB.texture;

            if (this.renderToScreen) {
                renderer.setRenderTarget(null);
                renderer.clear();
            } else {
                renderer.setRenderTarget(writeBuffer);
                if (this.clear) renderer.clear();
            }

            fsQuad.render(renderer);
        }
    }

    public function dispose():Void {
        renderTargetA.dispose();
        renderTargetB.dispose();
        material.dispose();
        fsQuad.dispose();
    }

    private function createMaterial():ShaderMaterial {
        return new ShaderMaterial({
            uniforms: {
                "tDiffuse1": { value: null },
                "tDiffuse2": { value: null },
                "mixRatio": { value: 0.0 },
                "threshold": { value: 0.1 },
                "useTexture": { value: 1 },
                "tMixTexture": { value: null }
            },
            vertexShader: """
                varying vec2 vUv;

                void main() {
                    vUv = vec2(uv.x, uv.y);
                    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
                }
            """,
            fragmentShader: """
                uniform float mixRatio;
                uniform sampler2D tDiffuse1;
                uniform sampler2D tDiffuse2;
                uniform sampler2D tMixTexture;
                uniform int useTexture;
                uniform float threshold;
                varying vec2 vUv;

                void main() {
                    vec4 texel1 = texture2D(tDiffuse1, vUv);
                    vec4 texel2 = texture2D(tDiffuse2, vUv);

                    if (useTexture == 1) {
                        vec4 transitionTexel = texture2D(tMixTexture, vUv);
                        float r = mixRatio * (1.0 + threshold * 2.0) - threshold;
                        float mixf = clamp((transitionTexel.r - r) * (1.0 / threshold), 0.0, 1.0);

                        gl_FragColor = mix(texel1, texel2, mixf);
                    } else {
                        gl_FragColor = mix(texel2, texel1, mixRatio);
                    }
                }
            """
        });
    }
}

class Export {
    public static function get RenderTransitionPass():RenderTransitionPass {
        return RenderTransitionPass;
    }
}
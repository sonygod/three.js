import three.Three;
import three.materials.ShaderMaterial;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.cameras.Camera;
import three.textures.Texture;
import three.renderers.WebGLRenderTarget;
import three.textures.types.HalfFloatType;
import three.extras.passes.Pass;
import three.extras.passes.FullScreenQuad;

class RenderTransitionPass extends Pass {
  public var sceneA:Scene;
  public var cameraA:Camera;
  public var sceneB:Scene;
  public var cameraB:Camera;
  public var material:ShaderMaterial;
  public var fsQuad:FullScreenQuad;
  public var renderTargetA:WebGLRenderTarget;
  public var renderTargetB:WebGLRenderTarget;

  public function new(sceneA:Scene, cameraA:Camera, sceneB:Scene, cameraB:Camera) {
    super();
    this.material = this.createMaterial();
    this.fsQuad = new FullScreenQuad(this.material);
    this.sceneA = sceneA;
    this.cameraA = cameraA;
    this.sceneB = sceneB;
    this.cameraB = cameraB;
    this.renderTargetA = new WebGLRenderTarget();
    this.renderTargetA.texture.type = HalfFloatType.VALUE;
    this.renderTargetB = new WebGLRenderTarget();
    this.renderTargetB.texture.type = HalfFloatType.VALUE;
  }

  public function setTransition(value:Float):Void {
    this.material.uniforms.mixRatio.value = value;
  }

  public function useTexture(value:Bool):Void {
    this.material.uniforms.useTexture.value = value ? 1 : 0;
  }

  public function setTexture(value:Texture):Void {
    this.material.uniforms.tMixTexture.value = value;
  }

  public function setTextureThreshold(value:Float):Void {
    this.material.uniforms.threshold.value = value;
  }

  public function setSize(width:Int, height:Int):Void {
    this.renderTargetA.setSize(width, height);
    this.renderTargetB.setSize(width, height);
  }

  public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget):Void {
    var uniforms = this.fsQuad.material.uniforms;
    var transition = uniforms.mixRatio.value;
    if (transition == 0) {
      renderer.setRenderTarget(writeBuffer);
      if (this.clear) renderer.clear();
      renderer.render(this.sceneB, this.cameraB);
    } else if (transition == 1) {
      renderer.setRenderTarget(writeBuffer);
      if (this.clear) renderer.clear();
      renderer.render(this.sceneA, this.cameraA);
    } else {
      renderer.setRenderTarget(this.renderTargetA);
      renderer.render(this.sceneA, this.cameraA);
      renderer.setRenderTarget(this.renderTargetB);
      renderer.render(this.sceneB, this.cameraB);
      uniforms.tDiffuse1.value = this.renderTargetA.texture;
      uniforms.tDiffuse2.value = this.renderTargetB.texture;
      if (this.renderToScreen) {
        renderer.setRenderTarget(null);
        renderer.clear();
      } else {
        renderer.setRenderTarget(writeBuffer);
        if (this.clear) renderer.clear();
      }
      this.fsQuad.render(renderer);
    }
  }

  public function dispose():Void {
    this.renderTargetA.dispose();
    this.renderTargetB.dispose();
    this.material.dispose();
    this.fsQuad.dispose();
  }

  public function createMaterial():ShaderMaterial {
    return new ShaderMaterial({
      uniforms: {
        tDiffuse1: {
          value: null
        },
        tDiffuse2: {
          value: null
        },
        mixRatio: {
          value: 0.0
        },
        threshold: {
          value: 0.1
        },
        useTexture: {
          value: 1
        },
        tMixTexture: {
          value: null
        }
      },
      vertexShader: /*glsl*/`
        varying vec2 vUv;

        void main() {

          vUv = vec2( uv.x, uv.y );
          gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

        }
      `,
      fragmentShader: /*glsl*/`
        uniform float mixRatio;

        uniform sampler2D tDiffuse1;
        uniform sampler2D tDiffuse2;
        uniform sampler2D tMixTexture;

        uniform int useTexture;
        uniform float threshold;

        varying vec2 vUv;

        void main() {

          vec4 texel1 = texture2D( tDiffuse1, vUv );
          vec4 texel2 = texture2D( tDiffuse2, vUv );

          if (useTexture == 1) {

            vec4 transitionTexel = texture2D( tMixTexture, vUv );
            float r = mixRatio * ( 1.0 + threshold * 2.0 ) - threshold;
            float mixf = clamp( ( transitionTexel.r - r ) * ( 1.0 / threshold ), 0.0, 1.0 );

            gl_FragColor = mix( texel1, texel2, mixf );

          } else {

            gl_FragColor = mix( texel2, texel1, mixRatio );

          }

          #include <tonemapping_fragment>
          #include <colorspace_fragment>

        }
      `
    });
  }
}
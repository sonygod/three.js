import three.constants.BackSide;
import three.shaders.UniformsUtils.getUnlitUniformColorSpace;
import three.math.Euler;
import three.math.Matrix4;

class WebGLMaterials {
  private var renderer:Renderer;
  private var properties:Map<Material, any>;
  private var _e1:Euler = new Euler();
  private var _m1:Matrix4 = new Matrix4();

  public function new(renderer:Renderer, properties:Map<Material, any>) {
    this.renderer = renderer;
    this.properties = properties;
  }

  private function refreshTransformUniform(map:Map<string, any>, uniform:Uniform) {
    if (map.matrixAutoUpdate) {
      map.updateMatrix();
    }
    uniform.value.copy(map.matrix);
  }

  private function refreshFogUniforms(uniforms:Map<string, any>, fog:Fog) {
    fog.color.getRGB(uniforms.fogColor.value, getUnlitUniformColorSpace(renderer));
    if (fog.isFog) {
      uniforms.fogNear.value = fog.near;
      uniforms.fogFar.value = fog.far;
    } else if (fog.isFogExp2) {
      uniforms.fogDensity.value = fog.density;
    }
  }

  private function refreshMaterialUniforms(uniforms:Map<string, any>, material:Material, pixelRatio:Float, height:Float, transmissionRenderTarget:RenderTarget) {
    // Implementations for material types go here
  }

  // Continue implementing other functions as needed

  public function refreshFogUniformsExposed(uniforms:Map<string, any>, fog:Fog) {
    this.refreshFogUniforms(uniforms, fog);
  }

  public function refreshMaterialUniformsExposed(uniforms:Map<string, any>, material:Material, pixelRatio:Float, height:Float, transmissionRenderTarget:RenderTarget) {
    this.refreshMaterialUniforms(uniforms, material, pixelRatio, height, transmissionRenderTarget);
  }
}
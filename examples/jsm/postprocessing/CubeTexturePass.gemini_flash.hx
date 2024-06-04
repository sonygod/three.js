import three.extras.passes.Pass;
import three.math.Quaternion;
import three.math.Matrix4;
import three.objects.Mesh;
import three.geometries.BoxGeometry;
import three.materials.ShaderMaterial;
import three.materials.ShaderLib;
import three.scenes.Scene;
import three.cameras.PerspectiveCamera;
import three.renderers.WebGLRenderer;
import three.textures.Texture;
import three.textures.CubeTexture;
import three.constants.Side;

class CubeTexturePass extends Pass {

  public var camera:PerspectiveCamera;
  public var cubeMesh:Mesh;
  public var tCube:Texture;
  public var opacity:Float;
  public var cubeScene:Scene;
  public var cubeCamera:PerspectiveCamera;

  public function new(camera:PerspectiveCamera, tCube:Texture, opacity:Float = 1) {
    super();
    this.camera = camera;
    this.needsSwap = false;

    this.cubeShader = ShaderLib.cube;
    this.cubeMesh = new Mesh(
      new BoxGeometry(10, 10, 10),
      new ShaderMaterial({
        uniforms: ShaderLib.cube.uniforms.clone(),
        vertexShader: this.cubeShader.vertexShader,
        fragmentShader: this.cubeShader.fragmentShader,
        depthTest: false,
        depthWrite: false,
        side: Side.BackSide
      })
    );

    this.cubeMesh.material.envMap = function() {
      return this.uniforms.tCube.value;
    };

    this.tCube = tCube;
    this.opacity = opacity;

    this.cubeScene = new Scene();
    this.cubeCamera = new PerspectiveCamera();
    this.cubeScene.add(this.cubeMesh);
  }

  public function render(renderer:WebGLRenderer, writeBuffer:dynamic, readBuffer:dynamic, ?deltaTime:Float, ?maskActive:Bool) {
    var oldAutoClear = renderer.autoClear;
    renderer.autoClear = false;

    this.cubeCamera.projectionMatrix.copy(this.camera.projectionMatrix);
    this.cubeCamera.quaternion.setFromRotationMatrix(this.camera.matrixWorld);

    this.cubeMesh.material.uniforms.tCube.value = this.tCube;
    this.cubeMesh.material.uniforms.tFlip.value = (this.tCube.isCubeTexture && !this.tCube.isRenderTargetTexture) ? -1 : 1;
    this.cubeMesh.material.uniforms.opacity.value = this.opacity;
    this.cubeMesh.material.transparent = (this.opacity < 1);

    renderer.setRenderTarget(this.renderToScreen ? null : readBuffer);
    if (this.clear) renderer.clear();
    renderer.render(this.cubeScene, this.cubeCamera);

    renderer.autoClear = oldAutoClear;
  }

  public function dispose() {
    this.cubeMesh.geometry.dispose();
    this.cubeMesh.material.dispose();
  }

}
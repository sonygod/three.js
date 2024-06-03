import three.BackSide;
import three.BoxGeometry;
import three.Mesh;
import three.PerspectiveCamera;
import three.Scene;
import three.ShaderLib;
import three.ShaderMaterial;
import three.UniformsUtils;
import postprocessing.Pass;

class CubeTexturePass extends Pass {
    var camera: PerspectiveCamera;
    var tCube: any;
    var opacity: Float;

    var cubeShader: any;
    var cubeMesh: Mesh;
    var cubeScene: Scene;
    var cubeCamera: PerspectiveCamera;

    public function new(camera: PerspectiveCamera, tCube: any, opacity: Float = 1.0) {
        super();

        this.camera = camera;
        this.needsSwap = false;

        this.cubeShader = ShaderLib.get('cube');
        this.cubeMesh = new Mesh(
            new BoxGeometry(10, 10, 10),
            new ShaderMaterial({
                uniforms: UniformsUtils.clone(this.cubeShader.uniforms),
                vertexShader: this.cubeShader.vertexShader,
                fragmentShader: this.cubeShader.fragmentShader,
                depthTest: false,
                depthWrite: false,
                side: BackSide
            })
        );

        this.cubeMesh.material.envMap = {
            get(): any {
                return this.uniforms.tCube.value;
            }
        };

        this.tCube = tCube;
        this.opacity = opacity;

        this.cubeScene = new Scene();
        this.cubeCamera = new PerspectiveCamera();
        this.cubeScene.add(this.cubeMesh);
    }

    public function render(renderer: any, writeBuffer: any, readBuffer: any) {
        var oldAutoClear = renderer.autoClear;
        renderer.autoClear = false;

        this.cubeCamera.projectionMatrix.copy(this.camera.projectionMatrix);
        this.cubeCamera.quaternion.setFromRotationMatrix(this.camera.matrixWorld);

        this.cubeMesh.material.uniforms.tCube.value = this.tCube;
        this.cubeMesh.material.uniforms.tFlip.value = (this.tCube.isCubeTexture && this.tCube.isRenderTargetTexture === false) ? -1 : 1;
        this.cubeMesh.material.uniforms.opacity.value = this.opacity;
        this.cubeMesh.material.transparent = (this.opacity < 1.0);

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
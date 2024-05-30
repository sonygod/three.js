import js.three.BoxGeometry;
import js.three.BackSide;
import js.three.Mesh;
import js.three.PerspectiveCamera;
import js.three.Scene;
import js.three.ShaderLib;
import js.three.ShaderMaterial;
import js.three.UniformsUtils;

class CubeTexturePass extends Pass {
    public var camera:PerspectiveCamera;
    public var needsSwap:Bool;
    public var cubeShader:ShaderLib;
    public var cubeMesh:Mesh;
    public var tCube;
    public var opacity:Float;
    public var cubeScene:Scene;
    public var cubeCamera:PerspectiveCamera;

    public function new(camera:PerspectiveCamera, tCube, opacity:Float = 1.0) {
        super();
        this.camera = camera;
        this.needsSwap = false;
        this.cubeShader = ShaderLib.cube;
        this.cubeMesh = new Mesh(new BoxGeometry(10, 10, 10), new ShaderMaterial({
            uniforms: UniformsUtils.clone(cubeShader.uniforms),
            vertexShader: cubeShader.vertexShader,
            fragmentShader: cubeShader.fragmentShader,
            depthTest: false,
            depthWrite: false,
            side: BackSide
        } as ShaderMaterial));
        this.tCube = tCube;
        this.opacity = opacity;
        this.cubeScene = new Scene();
        this.cubeCamera = new PerspectiveCamera();
        this.cubeScene.add(cubeMesh);
    }

    public function render(renderer, writeBuffer, readBuffer) {
        var oldAutoClear = renderer.autoClear;
        renderer.autoClear = false;

        cubeCamera.projectionMatrix.copy(camera.projectionMatrix);
        cubeCamera.quaternion.setFromRotationMatrix(camera.matrixWorld);

        cubeMesh.material.uniforms.tCube.value = tCube;
        cubeMesh.material.uniforms.tFlip.value = if (tCube.isCubeTexture && !tCube.isRenderTargetTexture) -1 else 1;
        cubeMesh.material.uniforms.opacity.value = opacity;
        cubeMesh.material.transparent = opacity < 1.0;

        renderer.setRenderTarget(if (renderToScreen) null else readBuffer);
        if (clear) renderer.clear();
        renderer.render(cubeScene, cubeCamera);

        renderer.autoClear = oldAutoClear;
    }

    public function dispose() {
        cubeMesh.geometry.dispose();
        cubeMesh.material.dispose();
    }
}
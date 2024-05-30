package three.js.examples.jm.postprocessing;

import three.js.THREE;

class CubeTexturePass extends Pass {
    private var camera:THREE.PerspectiveCamera;
    private var tCube:THREE.Texture;
    private var opacity:Float;
    private var needsSwap:Bool;
    private var cubeShader:THREE.ShaderLib;
    private var cubeMesh:THREE.Mesh;
    private var cubeScene:THREE.Scene;
    private var cubeCamera:THREE.PerspectiveCamera;

    public function new(camera:THREE.PerspectiveCamera, tCube:THREE.Texture, opacity:Float = 1) {
        super();

        this.camera = camera;
        this.tCube = tCube;
        this.opacity = opacity;
        this.needsSwap = false;

        cubeShader = THREE.ShaderLib['cube'];
        cubeMesh = new THREE.Mesh(
            new THREE.BoxGeometry(10, 10, 10),
            new THREE.ShaderMaterial({
                uniforms: THREE.UniformsUtils.clone(cubeShader.uniforms),
                vertexShader: cubeShader.vertexShader,
                fragmentShader: cubeShader.fragmentShader,
                depthTest: false,
                depthWrite: false,
                side: THREE.BackSide
            })
        );

        Reflect.setProperty(cubeMesh.material, 'envMap', {
            get: function() {
                return this.uniforms.tCube.value;
            }
        });

        cubeScene = new THREE.Scene();
        cubeCamera = new THREE.PerspectiveCamera();
        cubeScene.add(cubeMesh);
    }

    public function render(renderer:THREE.WebGLRenderer, writeBuffer:THREE.WebGLRenderTarget, readBuffer:THREE.WebGLRenderTarget /*, deltaTime:Float, maskActive:Bool*/) {
        var oldAutoClear = renderer.autoClear;
        renderer.autoClear = false;

        cubeCamera.projectionMatrix.copy(camera.projectionMatrix);
        cubeCamera.quaternion.setFromRotationMatrix(camera.matrixWorld);

        cubeMesh.material.uniforms.tCube.value = tCube;
        cubeMesh.material.uniforms.tFlip.value = (tCube.isCubeTexture && !tCube.isRenderTargetTexture) ? -1 : 1;
        cubeMesh.material.uniforms.opacity.value = opacity;
        cubeMesh.material.transparent = (opacity < 1.0);

        renderer.setRenderTarget(readBuffer);
        if (clear) renderer.clear();
        renderer.render(cubeScene, cubeCamera);

        renderer.autoClear = oldAutoClear;
    }

    public function dispose() {
        cubeMesh.geometry.dispose();
        cubeMesh.material.dispose();
    }
}
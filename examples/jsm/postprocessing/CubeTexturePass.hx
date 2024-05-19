package three.js.examples.jsm.postprocessing;

import three.js.Lib;
import three.js.PerspectiveCamera;
import three.js.Scene;
import three.js.Mesh;
import three.js.BoxGeometry;
import three.js.ShaderMaterial;
import three.js.ShaderLib;
import three.js.UniformsUtils;
import three.js.BackSide;

class CubeTexturePass extends Pass {
    public var camera:PerspectiveCamera;
    public var needsSwap:Bool;
    public var cubeShader:ShaderLib;
    public var cubeMesh:Mesh;
    public var tCube:Dynamic;
    public var opacity:Float;
    public var cubeScene:Scene;
    public var cubeCamera:PerspectiveCamera;

    public function new(camera:PerspectiveCamera, tCube:Dynamic, opacity:Float = 1) {
        super();
        this.camera = camera;
        this.needsSwap = false;
        this.cubeShader = ShaderLib.get("cube");
        this.cubeMesh = new Mesh(new BoxGeometry(10, 10, 10), new ShaderMaterial({
            uniforms: UniformsUtils.clone(this.cubeShader.uniforms),
            vertexShader: this.cubeShader.vertexShader,
            fragmentShader: this.cubeShader.fragmentShader,
            depthTest: false,
            depthWrite: false,
            side: BackSide
        }));
        Reflect.setProperty(this.cubeMesh.material, "envMap", {
            get: function() {
                return this.uniforms.tCube.value;
            }
        });
        this.tCube = tCube;
        this.opacity = opacity;
        this.cubeScene = new Scene();
        this.cubeCamera = new PerspectiveCamera();
        this.cubeScene.add(this.cubeMesh);
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic /*, deltaTime:Float, maskActive:Bool*/ ) {
        var oldAutoClear:Bool = renderer.autoClear;
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
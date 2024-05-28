import js.Browser.window;
import js.three.BoxGeometry;
import js.three.Color;
import js.three.ColorManagement;
import js.three.CubeUVReflectionMapping;
import js.three.Euler;
import js.three.FrontSide;
import js.three.Matrix4;
import js.three.Mesh;
import js.three.Object3D;
import js.three.PlaneGeometry;
import js.three.ShaderLib;
import js.three.ShaderMaterial;
import js.three.Side;
import js.three.SRGBTransfer;
import js.three.BackSide;

class WebGLBackground {
    public var clearColor:Color;
    public var clearAlpha:Float;
    private var planeMesh:Mesh<Dynamic>;
    private var boxMesh:Mesh<Dynamic>;
    private var currentBackground:Dynamic;
    private var currentBackgroundVersion:Int;
    private var currentTonemapping:Dynamic;
    private var _rgb:Dynamic;
    private var _e1:Euler;
    private var _m1:Matrix4;

    public function new(renderer:Dynamic, cubemaps:Dynamic, cubeuvmaps:Dynamic, state:Dynamic, objects:Dynamic, alpha:Dynamic, premultipliedAlpha:Dynamic) {
        clearColor = new Color(0x000000);
        clearAlpha = (if (alpha) 0 else 1);
        _rgb = { r: 0, b: 0, g: 0 };
        _e1 = new Euler();
        _m1 = new Matrix4();
    }

    private function getBackground(scene:Dynamic) {
        var background = (if (scene.isScene) scene.background else null);
        if (background != null && background.isTexture) {
            var usePMREM = scene.backgroundBlurriness > 0;
            background = (if (usePMREM) cubeuvmaps else cubemaps).get(background);
        }
        return background;
    }

    public function render(scene:Dynamic) {
        var forceClear = false;
        var background = getBackground(scene);
        if (background == null) {
            setClear(clearColor, clearAlpha);
        } else if (background != null && background.isColor) {
            setClear(background, 1);
            forceClear = true;
        }
        var environmentBlendMode = renderer.xr.getEnvironmentBlendMode();
        if (environmentBlendMode == "additive") {
            state.buffers.color.setClear(0, 0, 0, 1, premultipliedAlpha);
        } else if (environmentBlendMode == "alpha-blend") {
            state.buffers.color.setClear(0, 0, 0, 0, premultipliedAlpha);
        }
        if (renderer.autoClear || forceClear) {
            renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
        }
    }

    public function addToRenderList(renderList:Array<Dynamic>, scene:Dynamic) {
        var background = getBackground(scene);
        if (background != null && (background.isCubeTexture || background.mapping == CubeUVReflectionMapping)) {
            if (boxMesh == null) {
                boxMesh = new Mesh(new BoxGeometry(1, 1, 1), new ShaderMaterial({
                    name: "BackgroundCubeMaterial",
                    uniforms: ShaderLib.backgroundCube.uniforms.clone(),
                    vertexShader: ShaderLib.backgroundCube.vertexShader,
                    fragmentShader: ShaderLib.backgroundCube.fragmentShader,
                    side: BackSide,
                    depthTest: false,
                    depthWrite: false,
                    fog: false
                }));
                boxMesh.geometry.deleteAttribute("normal");
                boxMesh.geometry.deleteAttribute("uv");
                boxMesh.onBeforeRender = function (renderer:Dynamic, scene:Dynamic, camera:Dynamic) {
                    boxMesh.matrixWorld.copyPosition(camera.matrixWorld);
                };
                boxMesh.material.defineProperty("envMap", {
                    get: function () {
                        return boxMesh.material.uniforms.envMap.value;
                    }
                });
                objects.update(boxMesh);
            }
            _e1.copy(scene.backgroundRotation);
            _e1.x *= -1;
            _e1.y *= -1;
            _e1.z *= -1;
            if (background.isCubeTexture && !background.isRenderTargetTexture) {
                _e1.y *= -1;
                _e1.z *= -1;
            }
            boxMesh.material.uniforms.envMap.value = background;
            boxMesh.material.uniforms.flipEnvMap.value = (if (background.isCubeTexture && !background.isRenderTargetTexture) -1 else 1);
            boxMesh.material.uniforms.backgroundBlurriness.value = scene.backgroundBlurriness;
            boxMesh.material.uniforms.backgroundIntensity.value = scene.backgroundIntensity;
            boxMesh.material.uniforms.backgroundRotation.value.setFromMatrix4(_m1.makeRotationFromEuler(_e1));
            boxMesh.material.toneMapped = ColorManagement.getTransfer(background.colorSpace) != SRGBTransfer;
            if (currentBackground != background || currentBackgroundVersion != background.version || currentTonemapping != renderer.toneMapping) {
                boxMesh.material.needsUpdate = true;
                currentBackground = background;
                currentBackgroundVersion = background.version;
                currentTonemapping = renderer.toneMapping;
            }
            boxMesh.layers.enableAll();
            renderList.unshift(boxMesh, boxMesh.geometry, boxMesh.material, 0, 0, null);
        } else if (background != null && background.isTexture) {
            if (planeMesh == null) {
                planeMesh = new Mesh(new PlaneGeometry(2, 2), new ShaderMaterial({
                    name: "BackgroundMaterial",
                    uniforms: ShaderLib.background.uniforms.clone(),
                    vertexShader: ShaderLib.background.vertexShader,
                    fragmentShader: ShaderLib.background.fragmentShader,
                    side: FrontSide,
                    depthTest: false,
                    depthWrite: false,
                    fog: false
                }));
                planeMesh.geometry.deleteAttribute("normal");
                planeMesh.material.defineProperty("map", {
                    get: function () {
                        return planeMesh.material.uniforms.t2D.value;
                    }
                });
                objects.update(planeMesh);
            }
            planeMesh.material.uniforms.t2D.value = background;
            planeMesh.material.uniforms.backgroundIntensity.value = scene.backgroundIntensity;
            planeMesh.material.toneMapped = ColorManagement.getTransfer(background.colorSpace) != SRGBTransfer;
            if (background.matrixAutoUpdate) {
                background.updateMatrix();
            }
            planeMesh.material.uniforms.uvTransform.value.copy(background.matrix);
            if (currentBackground != background || currentBackgroundVersion != background.version || currentTonemapping != renderer.toneMapping) {
                planeMesh.material.needsUpdate = true;
                currentBackground = background;
                currentBackgroundVersion = background.version;
                currentTonemapping = renderer.toneMapping;
            }
            planeMesh.layers.enableAll();
            renderList.unshift(planeMesh, planeMesh.geometry, planeMesh.material, 0, 0, null);
        }
    }

    private function setClear(color:Dynamic, alpha:Float) {
        color.getRGB(_rgb, window.getUnlitUniformColorSpace(renderer));
        state.buffers.color.setClear(_rgb.r, _rgb.g, _rgb.b, alpha, premultipliedAlpha);
    }

    public function getClearColor():Color {
        return clearColor;
    }

    public function setClearColor(color:Dynamic, alpha:Float = 1) {
        clearColor.set(color);
        clearAlpha = alpha;
        setClear(clearColor, clearAlpha);
    }

    public function getClearAlpha():Float {
        return clearAlpha;
    }

    public function setClearAlpha(alpha:Float) {
        clearAlpha = alpha;
        setClear(clearColor, clearAlpha);
    }
}
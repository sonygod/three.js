import three.constants.BackSide;
import three.constants.FrontSide;
import three.constants.CubeUVReflectionMapping;
import three.constants.SRGBTransfer;
import three.geometries.BoxGeometry;
import three.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.math.Color;
import three.math.ColorManagement;
import three.math.Euler;
import three.math.Matrix4;
import three.objects.Mesh;
import three.shaders.ShaderLib;
import three.shaders.UniformsUtils;

class WebGLBackground {
    private var clearColor:Color;
    private var clearAlpha:Float;
    private var planeMesh:Mesh;
    private var boxMesh:Mesh;
    private var currentBackground:Dynamic;
    private var currentBackgroundVersion:Int;
    private var currentTonemapping:Dynamic;

    public function new(renderer:Dynamic, cubemaps:Dynamic, cubeuvmaps:Dynamic, state:Dynamic, objects:Dynamic, alpha:Bool, premultipliedAlpha:Bool) {
        clearColor = new Color(0x000000);
        clearAlpha = alpha ? 0 : 1;
        var _rgb = { r: 0, b: 0, g: 0 };
        var _e1 = new Euler();
        var _m1 = new Matrix4();

        function getBackground(scene:Dynamic):Dynamic {
            var background = scene.isScene ? scene.background : null;
            if (background && background.isTexture) {
                var usePMREM = scene.backgroundBlurriness > 0;
                background = (usePMREM ? cubeuvmaps : cubemaps).get(background);
            }
            return background;
        }

        function render(scene:Dynamic):Void {
            var forceClear = false;
            var background = getBackground(scene);
            if (background === null) {
                setClear(clearColor, clearAlpha);
            } else if (background && background.isColor) {
                setClear(background, 1);
                forceClear = true;
            }
            var environmentBlendMode = renderer.xr.getEnvironmentBlendMode();
            if (environmentBlendMode === 'additive') {
                state.buffers.color.setClear(0, 0, 0, 1, premultipliedAlpha);
            } else if (environmentBlendMode === 'alpha-blend') {
                state.buffers.color.setClear(0, 0, 0, 0, premultipliedAlpha);
            }
            if (renderer.autoClear || forceClear) {
                renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
            }
        }

        function addToRenderList(renderList:Dynamic, scene:Dynamic):Void {
            var background = getBackground(scene);
            if (background && (background.isCubeTexture || background.mapping === CubeUVReflectionMapping)) {
                if (boxMesh === null) {
                    boxMesh = new Mesh(
                        new BoxGeometry(1, 1, 1),
                        new ShaderMaterial({
                            name: 'BackgroundCubeMaterial',
                            uniforms: UniformsUtils.clone(ShaderLib.backgroundCube.uniforms),
                            vertexShader: ShaderLib.backgroundCube.vertexShader,
                            fragmentShader: ShaderLib.backgroundCube.fragmentShader,
                            side: BackSide,
                            depthTest: false,
                            depthWrite: false,
                            fog: false
                        })
                    );
                    boxMesh.geometry.deleteAttribute('normal');
                    boxMesh.geometry.deleteAttribute('uv');
                    boxMesh.onBeforeRender = function(renderer:Dynamic, scene:Dynamic, camera:Dynamic) {
                        this.matrixWorld.copyPosition(camera.matrixWorld);
                    };
                    Object.defineProperty(boxMesh.material, 'envMap', {
                        get: function() {
                            return this.uniforms.envMap.value;
                        }
                    });
                    objects.update(boxMesh);
                }
                _e1.copy(scene.backgroundRotation);
                _e1.x *= -1; _e1.y *= -1; _e1.z *= -1;
                if (background.isCubeTexture && background.isRenderTargetTexture === false) {
                    _e1.y *= -1;
                    _e1.z *= -1;
                }
                boxMesh.material.uniforms.envMap.value = background;
                boxMesh.material.uniforms.flipEnvMap.value = (background.isCubeTexture && background.isRenderTargetTexture === false) ? -1 : 1;
                boxMesh.material.uniforms.backgroundBlurriness.value = scene.backgroundBlurriness;
                boxMesh.material.uniforms.backgroundIntensity.value = scene.backgroundIntensity;
                boxMesh.material.uniforms.backgroundRotation.value.setFromMatrix4(_m1.makeRotationFromEuler(_e1));
                boxMesh.material.toneMapped = ColorManagement.getTransfer(background.colorSpace) !== SRGBTransfer;
                if (currentBackground !== background || currentBackgroundVersion !== background.version || currentTonemapping !== renderer.toneMapping) {
                    boxMesh.material.needsUpdate = true;
                    currentBackground = background;
                    currentBackgroundVersion = background.version;
                    currentTonemapping = renderer.toneMapping;
                }
                boxMesh.layers.enableAll();
                renderList.unshift(boxMesh, boxMesh.geometry, boxMesh.material, 0, 0, null);
            } else if (background && background.isTexture) {
                if (planeMesh === null) {
                    planeMesh = new Mesh(
                        new PlaneGeometry(2, 2),
                        new ShaderMaterial({
                            name: 'BackgroundMaterial',
                            uniforms: UniformsUtils.clone(ShaderLib.background.uniforms),
                            vertexShader: ShaderLib.background.vertexShader,
                            fragmentShader: ShaderLib.background.fragmentShader,
                            side: FrontSide,
                            depthTest: false,
                            depthWrite: false,
                            fog: false
                        })
                    );
                    planeMesh.geometry.deleteAttribute('normal');
                    Object.defineProperty(planeMesh.material, 'map', {
                        get: function() {
                            return this.uniforms.t2D.value;
                        }
                    });
                    objects.update(planeMesh);
                }
                planeMesh.material.uniforms.t2D.value = background;
                planeMesh.material.uniforms.backgroundIntensity.value = scene.backgroundIntensity;
                planeMesh.material.toneMapped = ColorManagement.getTransfer(background.colorSpace) !== SRGBTransfer;
                if (background.matrixAutoUpdate === true) {
                    background.updateMatrix();
                }
                planeMesh.material.uniforms.uvTransform.value.copy(background.matrix);
                if (currentBackground !== background || currentBackgroundVersion !== background.version || currentTonemapping !== renderer.toneMapping) {
                    planeMesh.material.needsUpdate = true;
                    currentBackground = background;
                    currentBackgroundVersion = background.version;
                    currentTonemapping = renderer.toneMapping;
                }
                planeMesh.layers.enableAll();
                renderList.unshift(planeMesh, planeMesh.geometry, planeMesh.material, 0, 0, null);
            }
        }

        function setClear(color:Color, alpha:Float):Void {
            color.getRGB(_rgb, UniformsUtils.getUnlitUniformColorSpace(renderer));
            state.buffers.color.setClear(_rgb.r, _rgb.g, _rgb.b, alpha, premultipliedAlpha);
        }

        return {
            getClearColor: function():Color {
                return clearColor;
            },
            setClearColor: function(color:Color, alpha:Float = 1):Void {
                clearColor.set(color);
                clearAlpha = alpha;
                setClear(clearColor, clearAlpha);
            },
            getClearAlpha: function():Float {
                return clearAlpha;
            },
            setClearAlpha: function(alpha:Float):Void {
                clearAlpha = alpha;
                setClear(clearColor, clearAlpha);
            },
            render: render,
            addToRenderList: addToRenderList
        };
    }
}
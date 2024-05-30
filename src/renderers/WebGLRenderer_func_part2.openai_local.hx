import js.html.webgl.RenderingContext;
import js.html.CanvasElement;

class WebGLRenderer {
    private var _gl: RenderingContext;
    private var uintClearColor: Array<Float> = new Array<Float>();
    private var intClearColor: Array<Float> = new Array<Float>();
    private var state: State;
    private var renderLists: RenderLists;
    private var renderStates: RenderStates;
    private var properties: Properties;
    private var cubemaps: CubeMaps;
    private var cubeuvmaps: CubeUvMaps;
    private var objects: Objects;
    private var bindingStates: BindingStates;
    private var uniformsGroups: UniformsGroups;
    private var programCache: ProgramCache;
    private var xr: XR;
    private var animation: Animation;
    private var canvas: CanvasElement;
    private var _isContextLost: Bool = false;

    public function new(gl: RenderingContext, canvas: CanvasElement) {
        this._gl = gl;
        this.canvas = canvas;
        // Initialization of other properties
    }

    public function clear(color: Bool, depth: Bool, stencil: Bool): Void {
        var bits: Int = 0;

        if (color) {
            if (isUnsignedType) {
                uintClearColor[0] = background.getClearColor().r;
                uintClearColor[1] = background.getClearColor().g;
                uintClearColor[2] = background.getClearColor().b;
                uintClearColor[3] = background.getClearAlpha();
                _gl.clearBufferuiv(_gl.COLOR, 0, uintClearColor);
            } else {
                intClearColor[0] = background.getClearColor().r;
                intClearColor[1] = background.getClearColor().g;
                intClearColor[2] = background.getClearColor().b;
                intClearColor[3] = background.getClearAlpha();
                _gl.clearBufferiv(_gl.COLOR, 0, intClearColor);
            }
        } else {
            bits |= _gl.COLOR_BUFFER_BIT;
        }

        if (depth) bits |= _gl.DEPTH_BUFFER_BIT;
        if (stencil) {
            bits |= _gl.STENCIL_BUFFER_BIT;
            this.state.buffers.stencil.setMask(0xffffffff);
        }

        _gl.clear(bits);
    }

    public function clearColor(): Void {
        this.clear(true, false, false);
    }

    public function clearDepth(): Void {
        this.clear(false, true, false);
    }

    public function clearStencil(): Void {
        this.clear(false, false, true);
    }

    public function dispose(): Void {
        canvas.removeEventListener('webglcontextlost', onContextLost, false);
        canvas.removeEventListener('webglcontextrestored', onContextRestore, false);
        canvas.removeEventListener('webglcontextcreationerror', onContextCreationError, false);

        renderLists.dispose();
        renderStates.dispose();
        properties.dispose();
        cubemaps.dispose();
        cubeuvmaps.dispose();
        objects.dispose();
        bindingStates.dispose();
        uniformsGroups.dispose();
        programCache.dispose();

        xr.dispose();

        xr.removeEventListener('sessionstart', onXRSessionStart);
        xr.removeEventListener('sessionend', onXRSessionEnd);

        animation.stop();
    }

    private function onContextLost(event: Event): Void {
        event.preventDefault();
        trace('THREE.WebGLRenderer: Context Lost.');
        _isContextLost = true;
    }

    private function onContextRestore(event: Event): Void {
        trace('THREE.WebGLRenderer: Context Restored.');
        _isContextLost = false;

        var infoAutoReset = info.autoReset;
        var shadowMapEnabled = shadowMap.enabled;
        var shadowMapAutoUpdate = shadowMap.autoUpdate;
        var shadowMapNeedsUpdate = shadowMap.needsUpdate;
        var shadowMapType = shadowMap.type;

        initGLContext();

        info.autoReset = infoAutoReset;
        shadowMap.enabled = shadowMapEnabled;
        shadowMap.autoUpdate = shadowMapAutoUpdate;
        shadowMap.needsUpdate = shadowMapNeedsUpdate;
        shadowMap.type = shadowMapType;
    }

    private function onContextCreationError(event: Event): Void {
        trace('THREE.WebGLRenderer: A WebGL context could not be created. Reason: ', event.statusMessage);
    }

    private function onMaterialDispose(event: Event): Void {
        var material = cast(event.target, Material);
        material.removeEventListener('dispose', onMaterialDispose);
        deallocateMaterial(material);
    }

    private function deallocateMaterial(material: Material): Void {
        releaseMaterialProgramReferences(material);
        properties.remove(material);
    }

    private function releaseMaterialProgramReferences(material: Material): Void {
        var programs = properties.get(material).programs;
        if (programs != null) {
            for (program in programs) {
                programCache.releaseProgram(program);
            }

            if (material.isShaderMaterial) {
                programCache.releaseShaderCache(material);
            }
        }
    }

    public function renderBufferDirect(camera: Camera, scene: Scene, geometry: Geometry, material: Material, object: Object3D, group: Group): Void {
        if (scene == null) scene = _emptyScene;

        var frontFaceCW = object.isMesh && object.matrixWorld.determinant() < 0;
        var program = setProgram(camera, scene, geometry, material, object);

        state.setMaterial(material, frontFaceCW);

        var index = geometry.index;
        var rangeFactor = 1;

        if (material.wireframe) {
            index = geometries.getWireframeAttribute(geometry);
            if (index == null) return;
            rangeFactor = 2;
        }

        var drawRange = geometry.drawRange;
        var position = geometry.attributes.position;

        var drawStart = drawRange.start * rangeFactor;
        var drawEnd = (drawRange.start + drawRange.count) * rangeFactor;

        if (group != null) {
            drawStart = Math.max(drawStart, group.start * rangeFactor);
            drawEnd = Math.min(drawEnd, (group.start + group.count) * rangeFactor);
        }

        if (index != null) {
            drawStart = Math.max(drawStart, 0);
            drawEnd = Math.min(drawEnd, index.count);
        } else if (position != null) {
            drawStart = Math.max(drawStart, 0);
            drawEnd = Math.min(drawEnd, position.count);
        }

        var drawCount = drawEnd - drawStart;
        if (drawCount < 0 || drawCount == Infinity) return;

        bindingStates.setup(object, material, program, geometry, index);

        var attribute: Attribute;
        var renderer: BufferRenderer = bufferRenderer;

        if (index != null) {
            attribute = attributes.get(index);
            renderer = indexedBufferRenderer;
            renderer.setIndex(attribute);
        }

        if (object.isMesh) {
            if (material.wireframe) {
                state.setLineWidth(material.wireframeLinewidth * getTargetPixelRatio());
                renderer.setMode(_gl.LINES);
            } else {
                renderer.setMode(_gl.TRIANGLES);
            }
        } else if (object.isLine) {
            var lineWidth = material.linewidth;
            if (lineWidth == null) lineWidth = 1;
            state.setLineWidth(lineWidth * getTargetPixelRatio());

            if (object.isLineSegments) {
                renderer.setMode(_gl.LINES);
            } else if (object.isLineLoop) {
                renderer.setMode(_gl.LINE_LOOP);
            } else {
                renderer.setMode(_gl.LINE_STRIP);
            }
        } else if (object.isPoints) {
            renderer.setMode(_gl.POINTS);
        } else if (object.isSprite) {
            renderer.setMode(_gl.TRIANGLES);
        }

        if (object.isBatchedMesh) {
            if (object._multiDrawInstances != null) {
                renderer.renderMultiDrawInstances(object._multiDrawStarts, object._multiDrawCounts, object._multiDrawCount, object._multiDrawInstances);
            } else {
                renderer.renderMultiDraw(object._multiDrawStarts, object._multiDrawCounts, object._multiDrawCount);
            }
        } else if (object.isInstancedMesh) {
            renderer.renderInstances(drawStart, drawCount, object.count);
        } else if (geometry.isInstancedBufferGeometry) {
            var maxInstanceCount = geometry._maxInstanceCount != null ? geometry._maxInstanceCount : Infinity;
            var instanceCount = Math.min(geometry.instanceCount, maxInstanceCount);
            renderer.renderInstances(drawStart, drawCount, instanceCount);
        } else {
            renderer.render(drawStart, drawCount);
        }
    }

    private function prepareMaterial(material: Material, scene: Scene, object: Object3D): Void {
        if (material.transparent && material.side == DoubleSide && !material.forceSinglePass) {
            material.side = BackSide;
            material.needsUpdate = true;
            getProgram(material, scene, object);

            material.side = FrontSide;
            material.needsUpdate = true;
            getProgram(material, scene, object);

            material.side = DoubleSide;
        } else {
            getProgram(material, scene, object);
        }
    }

    public function compile(scene: Scene, camera: Camera, targetScene: Scene = null): Set<Material> {
        if (targetScene == null) targetScene = scene;

        currentRenderState = renderStates.get(targetScene);
        currentRenderState.init(camera);

        renderStateStack.push(currentRenderState);

        targetScene.traverseVisible(function(object: Object3D): Void {
            if (object.isLight && object.layers.test(camera.layers)) {
                currentRenderState.pushLight(object);
                if (object.castShadow) {
                    currentRenderState.pushShadow(object);
                }
            }
        });

        if (scene != targetScene) {
            scene.traverseVisible(function(object: Object3D): Void {
                if (object.isLight && object.layers.test(camera.layers)) {
                    currentRenderState.pushLight(object);
                    if (object.castShadow) {
                        currentRenderState.pushShadow(object);
                    }
                }
            });
        }

        currentRenderState.setupLights(_this._useLegacyLights);

        var materials = new Set<Material>();

        scene.traverse(function(object: Object3D): Void {
            var material = object.material;

            if (material != null) {
                if (Type.typeof(material) == Type.TArray) {
                    for (i in 0...material.length) {
                        var material2 = cast(material[i], Material);
                        prepareMaterial(material2, targetScene, object);
                        materials.add(material2);
                    }
                } else {
                    prepareMaterial(material, targetScene, object);
                    materials.add(material);
                }
            }
        });

        renderStateStack.pop();
        currentRenderState = null;

        return materials;
    }

    public function compileAsync(scene: Scene, camera: Camera, targetScene: Scene = null): Promise<Scene> {
        var materials = this.compile(scene, camera, targetScene);

        return new Promise(function(resolve: Scene -> Void) {
            function checkMaterialsReady(): Void {
                for (material in materials) {
                    var materialProperties = properties.get(material);
                    var program = materialProperties.currentProgram;

                    if (program.isReady()) {
                        materials.remove(material);
                    }
                }

                if (materials.size == 0) {
                    resolve(scene);
                    return;
                }

                haxe.Timer.delay(checkMaterialsReady, 10);
            }

            if (extensions.get('KHR_parallel_shader_compile') != null) {
                checkMaterialsReady();
            } else {
                haxe.Timer.delay(checkMaterialsReady, 10);
            }
        });
    }
}
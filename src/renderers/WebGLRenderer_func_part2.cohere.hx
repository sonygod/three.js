import js.Browser.window;
import js.html.CanvasElement;
import js.html.Event;
import js.html.HtmlElement;
import js.html.ImageElement;
import js.html.MediaError;
import js.html.VideoElement;
import js.html.Window;
import js.lib.Mathf;
import js.node.ArrayBuffer;
import js.node.Float32Array;
import js.node.Uint16Array;
import js.node.Uint32Array;
import js.node.Uint8Array;
import js.typed_arrays.ArrayBufferView;
import js.typed_arrays.DataView;

class WebGLRenderer {
    public function new(canvas:CanvasElement, antialias:Bool, stencil:Bool, alpha:Bool, depth:Bool, premultipliedAlpha:Bool, preserveDrawingBuffer:Bool, clearColor:Float, clearAlpha:Float, devicePixelRatio:Float) {
        if (canvas == null) {
            canvas = window.document.createElement("canvas").cast<CanvasElement>();
        }
        this.domElement = canvas;
        this.devicePixelRatio = devicePixelRatio;
        this.autoClear = true;
        this.sortObjects = true;
        this.autoUpdateObjects = true;
        this.autoUpdateScene = true;
        this.gammaFactor = 2.0;
        this.gammaOutput = true;
        this.physicallyBasedShading = true;
        this.toneMapping = ToneMappingNormal;
        this.toneMappingExposure = 1.0;
        this.maxMorphTargets = 8;
        this.maxMorphNormals = 4;
        this.maxLights = 5;
        this._clippingPlanes = [];
        this.numClippingPlanes = 0;
        this.localClippingEnabled = false;
        this.currentMaterialId = -1;
        this.currentGeometryGroupHash = 0;
        this.currentCamera = null;
        this.currentViewport = null;
        this.currentScissor = null;
        this.currentRenderState = null;
        this.currentRenderLists = null;
        this.currentTexture = null;
        this.currentProgram = null;
        this.currentBoundUniforms = null;
        this.currentAttributes = null;
        this.currentFrameBuffer = null;
        this.currentMaterial = null;
        this.currentGeometryGroup = null;
        this.currentGeometry = null;
        this.currentIndexBuffer = null;
        this.currentInstanceCount = 0;
        this.currentLineWidth = 1;
        this.currentPolygonOffsetFactor = 0;
        this.currentPolygonOffsetUnits = 0;
        this.currentBlending = 0;
        this.currentBlendEquation = 0;
        this.currentBlendSrc = 0;
        this.currentBlendDst = 0;
        this.currentBlendEquationAlpha = 0;
        this.currentBlendSrcAlpha = 0;
        this.currentBlendDstAlpha = 0;
        this.currentDepthTest = false;
        this.currentDepthWrite = false;
        this.currentDepthFunc = DepthFuncLess;
        this.currentStencilTest = false;
        this.currentStencilWrite = false;
        this.currentStencilFunc = StencilFuncAlways;
        this.currentStencilRef = 0;
        this.currentStencilFuncMask = 0xFFFFFFFF;
        this.currentStencilFail = StencilOpKeep;
        this.currentStencilZFail = StencilOpKeep;
        this.currentStencilZPass = StencilOpKeep;
        this.currentStencilMask = 0xFFFFFFFF;
        this.currentColorWrite = true;
        this.currentCullFace = CullFaceBack;
        this.currentFrontFaceCW = false;
        this.currentFlipSided = false;
        this.currentPremultipliedAlpha = false;
        this.currentLineWidth = 1;
        this.allocatedMaterials = [];
        this.allocatedPrograms = [];
        this.allocatedGeometries = [];
        this.numAllocatedObjects = 0;
        this.numActiveObjects = 0;
        this.numActiveAnimations = 0;
        this.numActiveImages = 0;
        this.numActiveTextures = 0;
        this.numActiveCubemaps = 0;
        this.numActiveUniforms = 0;
        this.numActiveAttributes = 0;
        this.numActiveFrameBuffers = 0;
        this.numActiveQueries = 0;
        this.maxTextures = 1;
        this.maxVertexTextures = 0;
        this.maxTextureSize = 1;
        this.maxCubemapSize = 1;
        this.maxAttributes = 1;
        this.maxVertexUniforms = 1;
        this.maxFragmentUniforms = 1;
        this.maxRenderBufferSize = 1;
        this.maxViewports = 1;
        this.maxVertexTextureUnits = 1;
        this.maxTextureUnits = 1;
        this.maxAnisotropy = 1;
        this.maxPrecision = "unknown";
        this.precision = "unknown";
        this.supportsVertexTextures = false;
        this.supportsFloatTextures = false;
        this.supportsHalfFloatTextures = false;
        this.supportsStandardDerivatives = false;
        this.supportsCompressedTextureS3TC = false;
        this.supportsCompressedTexturePVRTC = false;
        this.supportsBlendMinMax = false;
        this.supportsBlendEquationSeparate = false;
        this.supportsBlendFuncSeparate = false;
        this.supportsBlendEquation = false;
        this.supportsVertexArrayObjects = false;
        this.supportsInstancedArrays = false;
        this.supportsTextureFilterAnisotropic = false;
        this.supportsTextureLOD = false;
        this.supportsStandardDerivatives = false;
        this.supportsInstancedArrays = false;
        this.supportsVertexTextureFetch = false;
        this.supportsRenderToTexture = false;
        this.supportsFloatFragments = false;
        this.supportsFloatVertices = false;
        this.supportsUnsignedIntType = false;
        this.supportsUnsignedIntIndices = false;
        this.supportsUnsignedIntTextures = false;
        this.supportsBigTextures = false;
        this.supportsNPOTTextures = false;
        this.supportsVAO = false;
        this.supportsInstancedArrays = false;
        this.supportsTextureFilterAnisotropic = false;
        this.supportsCompressedTextureS3TC = false;
        this.supportsCompressedTexturePVRTC = false;
        this.maxAnisotropy = 1;
        this.maxPrecision = "unknown";
        this.precision = "unknown";
        this.maxTextures = 1;
        this.maxVertexTextures = 0;
        this.maxTextureSize = 1;
        this.maxCubemapSize = 1;
        this.maxAttributes = 1;
        this.maxVertexUniforms = 1;
        this.maxFragmentUniforms = 1;
        this.maxViewports = 1;
        this.maxVertexTextureUnits = 1;
        this.maxTextureUnits = 1;
        this.maxAnisotropy = 1;
        this.supportsVertexTextures = false;
        this.supportsFloatTextures = false;
        this.supportsHalfFloatTextures = false;
        this.supportsStandardDerivatives = false;
        this.supportsCompressedTextureS3TC = false;
        this.supportsCompressedTexturePVRTC = false;
        this.supportsBlendMinMax = false;
        this.supportsBlendEquationSeparate = false;
        this.supportsBlendFuncSeparate = false;
        this.supportsBlendEquation = false;
        this.supportsVertexArrayObjects = false;
        this.supportsInstancedArrays = false;
        this.supportsTextureFilterAnisotropic = false;
        this.supportsTextureLOD = false;
        this.supportsStandardDerivatives = false;
        this.supportsInstancedArrays = false;
        this.supportsVertexTextureFetch = false;
        this.supportsRenderToTexture = false;
        this.supportsFloatFragments = false;
        this.supportsFloatVertices = false;
        this.supportsUnsignedIntType = false;
        this.supportsUnsignedIntIndices = false;
        this.supportsUnsignedIntTextures = false;
        this.supportsBigTextures = false;
        this.supportsNPOTTextures = false;
        this.supportsVAO = false;
        this.supportsInstancedArrays = false;
        this.supportsTextureFilterAnisotropic = false;
        this.supportsCompressedTextureS3TC = false;
        this.supportsCompressedTexturePVRTC = false;
        this.shadowMapEnabled = false;
        this.shadowMapAutoUpdate = true;
        this.shadowMapType = ShadowMapTypeBasic;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMapDebug = false;
        this.shadowMapCascade = false;
        this.shadowMapNumCascades = 3;
        this.shadowMapNear = 0.5;
        this.shadowMapFar = 500.0;
        this.shadowMapTop = 1.0;
        this.shadowMapBottom = -1.0;
        this.shadowMapLeft = -1.0;
        this.shadowMapRight = 1.0;
        this.shadowMapVFOV = 25.0;
        this.shadowMapOrthoSize = 1024.0;
        this.shadowMapMaxResolution = 2048;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        thisMultiplier = 0.5;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMapDarkness = 0.5;
        this.shadowMapTonemapping = false;
        this.shadowMapOperator = 0;
        this.shadowMapFog = false;
        this.shadowMapUseFP16 = false;
        this.shadowMapCullFace = CullFaceBack;
        this.shadowMap = null;
        this.shadowMapSize = 512;
        this.shadowMapBias = 0.0;
        this.shadowMap
this.shadowMap = null;
this.shadowMapSize = 512;
this.shadowMapBias = 0.0;
this.shadowMapDarkness = 0.5;
this.shadowMapTonemapping = false;
this.shadowMapOperator = 0;
this.shadowMapFog = false;
this.shadowMapUseFP16 = false;
this.shadowMapCullFace = CullFaceBack;

this.info = {
    memory: {
        programs: 0,
        geometries: 0,
        textures: 0
    },
    render: {
        calls: 0,
        vertices: 0,
        faces: 0,
        points: 0
    }
};

this.info.memory.programs = 0;
this.info.memory.geometries = 0;
this.info.memory.textures = 0;
this.info.render.calls = 0;
this.info.render.vertices = 0;
this.info.render.faces = 0;
this.info.render.points = 0;

this.clock = new js.Browser.Date();
this.defaultCamera = new PerspectiveCamera(50, canvas.width / canvas.height, 1, 10000);
this.camera = this.defaultCamera;
this.scene = new Scene();
this.renderLists = new RenderList();
this.renderStates = new RenderStates();
this.properties = new Properties();
this.cubemaps = new Cubemaps();
this.cubeuvmaps = new CubeUVMaps();
this.objects = new Objects();
this.bindingStates = new BindingStates();
this.uniformsGroups = new UniformsGroups();
this.programCache = new ProgramCache();
this.state = new State();
this.extensions = new Extensions();
this.capabilities = new Capabilities();
this.vr = new VR();
this.xr = new XR();
this.animation = new Animation();
this.animationActions = new AnimationActions();
this.loop = new Loop(this);
this.loop.onEnterFrame.add(this.render);
this.onContextLost = function(event) {
    event.preventDefault();
    trace("THREE.WebGLRenderer: Context Lost.");
    _isContextLost = true;
};
this.onContextRestore = function(/* event */) {
    trace("THREE.WebGLRenderer: Context Restored.");
    _isContextLost = false;
    const infoAutoReset = info.autoReset;
    const shadowMapEnabled = shadowMap.enabled;
    const shadowMapAutoUpdate = shadowMap.autoUpdate;
    const shadowMapNeedsUpdate = shadowMap.needsUpdate;
    const shadowMapType = shadowMap.type;
    initGLContext();
    info.autoReset = infoAutoReset;
    shadowMap.enabled = shadowMapEnabled;
    shadowMap.autoUpdate = shadowMapAutoUpdate;
    shadowMap.needsUpdate = shadowMapNeedsUpdate;
    shadowMap.type = shadowMapType;
};
this.onContextCreationError = function(event) {
    traceError("THREE.WebGLRenderer: A WebGL context could not be created. Reason: ", event.statusMessage);
};
this.onMaterialDispose = function(event) {
    const material = event.target;
    material.removeEventListener("dispose", onMaterialDispose);
    deallocateMaterial(material);
};

function deallocateMaterial(material) {
    releaseMaterialProgramReferences(material);
    properties.remove(material);
}

function releaseMaterialProgramReferences(material) {
    const programs = properties.get(material).programs;
    if (programs !== undefined) {
        programs.forEach(function(program) {
            programCache.releaseProgram(program);
        });
        if (material.isShaderMaterial) {
            programCache.releaseShaderCache(material);
        }
    }
}

this.renderBufferDirect = function(camera, scene, geometry, material, object, group) {
    if (scene == null) scene = _emptyScene; // renderBufferDirect second parameter used to be fog (could be null)
    const frontFaceCW = (object.isMesh && object.matrixWorld.determinant() < 0);
    const program = setProgram(camera, scene, geometry, material, object);
    state.setMaterial(material, frontFaceCW);
    let index = geometry.index;
    let rangeFactor = 1;
    if (material.wireframe == true) {
        index = geometries.getWireframeAttribute(geometry);
        if (index == undefined) return;
        rangeFactor = 2;
    }
    const drawRange = geometry.drawRange;
    const position = geometry.attributes.position;
    let drawStart = drawRange.start * rangeFactor;
    let drawEnd = (drawRange.start + drawRange.count) * rangeFactor;
    if (group != null) {
        drawStart = Math.max(drawStart, group.start * rangeFactor);
        drawEnd = Math.min(drawEnd, (group.start + group.count) * rangeFactor);
    }
    if (index != null) {
        drawStart = Math.max(drawStart, 0);
        drawEnd = Math.min(drawEnd, index.count);
    } else if (position != undefined && position != null) {
        drawStart = Math.max(drawStart, 0);
        drawEnd = Math.min(drawEnd, position.count);
    }
    const drawCount = drawEnd - drawStart;
    if (drawCount < 0 || drawCount == Infinity) return;
    bindingStates.setup(object, material, program, geometry, index);
    let attribute;
    let renderer = bufferRenderer;
    if (index != null) {
        attribute = attributes.get(index);
        renderer = indexedBufferRenderer;
        renderer.setIndex(attribute);
    }
    if (object.isMesh) {
        if (material.wireframe == true) {
            state.setLineWidth(material.wireframeLinewidth * getTargetPixelRatio());
            renderer.setMode(GL.LINES);
        } else {
            renderer.setMode(GL.TRIANGLES);
        }
    } else if (object.isLine) {
        let lineWidth = material.linewidth;
        if (lineWidth == undefined) lineWidth = 1; // Not using Line*Material
        state.setLineWidth(lineWidth * getTargetPixelRatio());
        if (object.isLineSegments) {
            renderer.setMode(GL.LINES);
        } else if (object.isLineLoop) {
            renderer.setMode(GL.LINE_LOOP);
        } else {
            renderer.setMode(GL.LINE_STRIP);
        }
    } else if (object.isPoints) {
        renderer.setMode(GL.POINTS);
    } else if (object.isSprite) {
        renderer.setMode(GL.TRIANGLES);
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
        const maxInstanceCount = geometry._maxInstanceCount != undefined ? geometry._maxInstanceCount : Infinity;
        const instanceCount = Math.min(geometry.instanceCount, maxInstanceCount);
        renderer.renderInstances(drawStart, drawCount, instanceCount);
    } else {
        renderer.render(drawStart, drawCount);
    }
};

function prepareMaterial(material, scene, object) {
    if (material.transparent == true && material.side == DoubleSide && material.forceSinglePass == false) {
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

this.compile = function(scene, camera, targetScene = null) {
    if (targetScene == null) targetScene = scene;
    currentRenderState = renderStates.get(targetScene);
    currentRenderState.init(camera);
    renderStateStack.push(currentRenderState);
    targetScene.traverseVisible(function(object) {
        if (object.isLight && object.layers.test(camera.layers)) {
            currentRenderState.pushLight(object);
            if (object.castShadow) {
                currentRenderState.pushShadow(object);
            }
        }
    });
    if (scene != targetScene) {
        scene.traverseVisible(function(object) {
            if (object.isLight && object.layers.test(camera.layers)) {
                currentRenderState.pushLight(object);
                if (object.castShadow) {
                    currentRenderState.pushShadow(object);
                }
            }
        });
    }
    currentRenderState.setupLights(_this._useLegacyLights);
    const materials = new Set();
    scene.traverse(function(object) {
        const material = object.material;
        if (material) {
            if (Array.isArray(material)) {
                for (let i = 0; i < material.length; i++) {
                    const material2 = material[i];
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
};

this.compileAsync = function(scene, camera, targetScene = null) {
    const materials = this.compile(scene, camera, targetScene);
    return new Promise(function(resolve) {
        function checkMaterialsReady() {
            materials.forEach(function(material) {
                const materialProperties = properties.get(material);
                const program = materialProperties.currentProgram;
                if (program.isReady()) {
                    materials.delete(material);
                }
            });
            if (materials.size == 0) {
                resolve(scene);
                return;
            }
            setTimeout(checkMaterialsReady, 10);
        }
        if (extensions.get("KHR_parallel_shader_compile") != null) {
            checkMaterialsReady();
        } else {
            setTimeout(checkMaterialsReady, 10);
        }
    });
};
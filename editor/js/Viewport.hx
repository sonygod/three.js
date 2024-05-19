Here is the converted Haxe code:
```
package three.js.editor;

import three.js.THREE;

class Viewport {
    private var editor:Editor;
    private var selector:Selector;
    private var signals:Signals;
    private var container:UIPanel;
    private var camera:THREE.Camera;
    private var scene:THREE.Scene;
    private var sceneHelpers:THREE.Object3D;
    private var transformControls:TransformControls;
    private var viewHelper:ViewHelper;
    private var xr:XR;
    private var pathtracer:ViewportPathtracer;
    private var renderer:THREE.WebGLRenderer;
    private var pmremGenerator:THREE.PMREMGenerator;
    private var grid:THREE.Group;
    private var selectionBox:THREE.Box3Helper;
    private var controls:EditorControls;

    public function new(editor:Editor) {
        this.editor = editor;
        this.selector = editor.selector;
        this.signals = editor.signals;

        container = new UIPanel();
        container.setId('viewport');
        container.setPosition('absolute');

        container.add(new ViewportControls(editor));
        container.add(new ViewportInfo(editor));

        camera = editor.camera;
        scene = editor.scene;
        sceneHelpers = editor.sceneHelpers;

        grid = new THREE.Group();
        var grid1 = new THREE.GridHelper(30, 30);
        grid1.material.color.setHex(0x999999);
        grid1.material.vertexColors = false;
        grid.add(grid1);

        var grid2 = new THREE.GridHelper(30, 6);
        grid2.material.color.setHex(0x777777);
        grid2.material.vertexColors = false;
        grid.add(grid2);

        viewHelper = new ViewHelper(camera, container);

        transformControls = new TransformControls(camera, container.dom);
        transformControls.addEventListener('axis-changed', function() {
            if (editor.viewportShading != 'realistic') render();
        });
        transformControls.addEventListener('objectChange', function() {
            signals.objectChanged.dispatch(transformControls.object);
        });
        transformControls.addEventListener('mouseDown', function() {
            var object = transformControls.object;
            objectPositionOnDown = object.position.clone();
            objectRotationOnDown = object.rotation.clone();
            objectScaleOnDown = object.scale.clone();
            controls.enabled = false;
        });
        transformControls.addEventListener('mouseUp', function() {
            var object = transformControls.object;
            switch (transformControls.getMode()) {
                case 'translate':
                    if (!objectPositionOnDown.equals(object.position)) {
                        editor.execute(new SetPositionCommand(editor, object, object.position, objectPositionOnDown));
                    }
                    break;
                case 'rotate':
                    if (!objectRotationOnDown.equals(object.rotation)) {
                        editor.execute(new SetRotationCommand(editor, object, object.rotation, objectRotationOnDown));
                    }
                    break;
                case 'scale':
                    if (!objectScaleOnDown.equals(object.scale)) {
                        editor.execute(new SetScaleCommand(editor, object, object.scale, objectScaleOnDown));
                    }
                    break;
            }
            controls.enabled = true;
        });

        sceneHelpers.add(transformControls);
        xr = new XR(editor, transformControls);

        container.dom.addEventListener('mousedown', onMouseDown);
        container.dom.addEventListener('touchstart', onTouchStart);
        container.dom.addEventListener('dblclick', onDoubleClick);

        controls = new EditorControls(camera, container.dom);
        controls.addEventListener('change', function() {
            signals.cameraChanged.dispatch(camera);
            signals.refreshSidebarObject3D.dispatch(camera);
        });
        viewHelper.center = controls.center;

        signals.editorCleared.add(function() {
            controls.center.set(0, 0, 0);
            pathtracer.reset();
            initPT();
            render();
        });
        signals.transformModeChanged.add(function(mode) {
            transformControls.setMode(mode);
            render();
        });
        signals.snapChanged.add(function(dist) {
            transformControls.setTranslationSnap(dist);
        });
        signals.spaceChanged.add(function(space) {
            transformControls.setSpace(space);
            render();
        });
        signals.rendererUpdated.add(function() {
            scene.traverse(function(child) {
                if (child.material != null) {
                    child.material.needsUpdate = true;
                }
            });
            render();
        });
        signals.rendererCreated.add(function(newRenderer) {
            if (renderer != null) {
                renderer.setAnimationLoop(null);
                renderer.dispose();
                pmremGenerator.dispose();
                container.dom.removeChild(renderer.domElement);
            }
            renderer = newRenderer;
            renderer.setAnimationLoop(animate);
            renderer.setClearColor(0xaaaaaa);

            if (Js.Browser.supportsMatchMedia) {
                var mediaQuery = Js.Browser.matchMedia('(prefers-color-scheme: dark)');
                mediaQuery.addEventListener('change', function(event) {
                    renderer.setClearColor(event.matches ? 0x333333 : 0xaaaaaa);
                    updateGridColors(grid1, grid2, event.matches ? GRID_COLORS_DARK : GRID_COLORS_LIGHT);
                    render();
                });
                renderer.setClearColor(mediaQuery.matches ? 0x333333 : 0xaaaaaa);
                updateGridColors(grid1, grid2, mediaQuery.matches ? GRID_COLORS_DARK : GRID_COLORS_LIGHT);
            }

            renderer.setPixelRatio(Js.Browser.window.devicePixelRatio);
            renderer.setSize(container.dom.offsetWidth, container.dom.offsetHeight);
            pmremGenerator = new THREE.PMREMGenerator(renderer);
            pmremGenerator.compileEquirectangularShader();
            pathtracer = new ViewportPathtracer(renderer);
            container.dom.appendChild(renderer.domElement);
            render();
        });
        signals.rendererDetectKTX2Support.add(function(ktx2Loader) {
            ktx2Loader.detectSupport(renderer);
        });
        signals.sceneGraphChanged.add(function() {
            initPT();
            render();
        });
        signals.cameraChanged.add(function() {
            pathtracer.reset();
            render();
        });
        signals.objectSelected.add(function(object) {
            selectionBox.visible = false;
            transformControls.detach();
            if (object != null && object != scene && object != camera) {
                box.setFromObject(object, true);
                if (box.isEmpty() == false) {
                    selectionBox.visible = true;
                }
                transformControls.attach(object);
            }
            render();
        });
        signals.objectFocused.add(function(object) {
            controls.focus(object);
        });
        signals.geometryChanged.add(function(object) {
            if (object != null) {
                box.setFromObject(object, true);
            }
            initPT();
            render();
        });
        signals.objectChanged.add(function(object) {
            if (editor.selected == object) {
                box.setFromObject(object, true);
            }
            if (object.isPerspectiveCamera) {
                object.updateProjectionMatrix();
            }
            var helper = editor.helpers[object.id];
            if (helper != null && helper.isSkeletonHelper == false) {
                helper.update();
            }
            initPT();
            render();
        });
        signals.objectRemoved.add(function(object) {
            controls.enabled = true;
            if (object == transformControls.object) {
                transformControls.detach();
            }
        });
        signals.materialChanged.add(function() {
            updatePTMaterials();
            render();
        });
        signals.sceneBackgroundChanged.add(function(backgroundType, backgroundColor, backgroundTexture, backgroundEquirectangularTexture, backgroundBlurriness, backgroundIntensity, backgroundRotation) {
            scene.background = null;
            switch (backgroundType) {
                case 'Color':
                    scene.background = new THREE.Color(backgroundColor);
                    break;
                case 'Texture':
                    if (backgroundTexture != null) {
                        scene.background = backgroundTexture;
                    }
                    break;
                case 'Equirectangular':
                    if (backgroundEquirectangularTexture != null) {
                        backgroundEquirectangularTexture.mapping = THREE.EquirectangularReflectionMapping;
                        scene.background = backgroundEquirectangularTexture;
                        scene.backgroundBlurriness = backgroundBlurriness;
                        scene.backgroundIntensity = backgroundIntensity;
                        scene.backgroundRotation.y = backgroundRotation * THREE.MathUtils.DEG2RAD;
                        if (useBackgroundAsEnvironment) {
                            scene.environment = scene.background;
                            scene.environmentRotation.y = backgroundRotation * THREE.MathUtils.DEG2RAD;
                        }
                    }
                    break;
            }
            updatePTBackground();
            render();
        });
        signals.sceneEnvironmentChanged.add(function(environmentType, environmentEquirectangularTexture) {
            scene.environment = null;
            useBackgroundAsEnvironment = false;
            switch (environmentType) {
                case 'Background':
                    useBackgroundAsEnvironment = true;
                    if (scene.background != null && scene.background.isTexture) {
                        scene.environment = scene.background;
                        scene.environment.mapping = THREE.EquirectangularReflectionMapping;
                        scene.environmentRotation.y = scene.backgroundRotation.y;
                    }
                    break;
                case 'Equirectangular':
                    if (environmentEquirectangularTexture != null) {
                        scene.environment = environmentEquirectangularTexture;
                        scene.environment.mapping = THREE.EquirectangularReflectionMapping;
                    }
                    break;
                case 'ModelViewer':
                    scene.environment = pmremGenerator.fromScene(new RoomEnvironment(), 0.04).texture;
                    break;
            }
            updatePTEnvironment();
            render();
        });
        signals.sceneFogChanged.add(function(fogType, fogColor, fogNear, fogFar, fogDensity) {
            switch (fogType) {
                case 'None':
                    scene.fog = null;
                    break;
                case 'Fog':
                    scene.fog = new THREE.Fog(fogColor, fogNear, fogFar);
                    break;
                case 'FogExp2':
                    scene.fog = new THREE.FogExp2(fogColor, fogDensity);
                    break;
            }
            render();
        });
        signals.sceneFogSettingsChanged.add(function(fogType, fogColor, fogNear, fogFar, fogDensity) {
            switch (fogType) {
                case 'Fog':
                    scene.fog.color.setHex(fogColor);
                    scene.fog.near = fogNear;
                    scene.fog.far = fogFar;
                    break;
                case 'FogExp2':
                    scene.fog.color.setHex(fogColor);
                    scene.fog.density = fogDensity;
                    break;
            }
            render();
        });
        signals.viewportCameraChanged.add(function() {
            var viewportCamera = editor.viewportCamera;
            if (viewportCamera.isPerspectiveCamera) {
                viewportCamera.aspect = editor.camera.aspect;
                viewportCamera.projectionMatrix.copy(editor.camera.projectionMatrix);
            } else if (viewportCamera.isOrthographicCamera) {
                // TODO
            }
            controls.enabled = (viewportCamera == editor.camera);
            render();
        });
        signals.viewportShadingChanged.add(function() {
            var viewportShading = editor.viewportShading;
            switch (viewportShading) {
                case 'realistic':
                    pathtracer.init(scene, camera);
                    break;
                case 'solid':
                    scene.overrideMaterial = null;
                    break;
                case 'normals':
                    scene.overrideMaterial = new THREE.MeshNormalMaterial();
                    break;
                case 'wireframe':
                    scene.overrideMaterial = new THREE.MeshBasicMaterial({ color: 0x000000, wireframe: true });
                    break;
            }
            render();
        });
        signals.windowResize.add(function() {
            updateAspectRatio();
            renderer.setSize(container.dom.offsetWidth, container.dom.offsetHeight);
            pathtracer.setSize(container.dom.offsetWidth, container.dom.offsetHeight);
            render();
        });
        signals.showGridChanged.add(function(value) {
            grid.visible = value;
            render();
        });
        signals.showHelpersChanged.add(function(value) {
            sceneHelpers.visible = value;
            transformControls.enabled = value;
            render();
        });
        signals.cameraResetted.add(updateAspectRatio);

        var prevActionsInUse = 0;
        var clock = new THREE.Clock();

        function animate() {
            var mixer = editor.mixer;
            var delta = clock.getDelta();
            var needsUpdate = false;

            if (mixer.stats.actions.inUse > 0 || prevActionsInUse > 0) {
                prevActionsInUse = mixer.stats.actions.inUse;
                mixer.update(delta);
                needsUpdate = true;
                if (editor.selected != null) {
                    editor.selected.updateWorldMatrix(false, true);
                    selectionBox.box.setFromObject(editor.selected, true);
                }
            }
            if (viewHelper.animating == true) {
                viewHelper.update(delta);
                needsUpdate = true;
            }
            if (renderer.xr.isPresenting == true) {
                needsUpdate = true;
            }
            if (needsUpdate == true) render();
            updatePT();
        }

        function initPT() {
            if (editor.viewportShading == 'realistic') {
                pathtracer.init(scene, camera);
            }
        }

        function updatePTBackground() {
            if (editor.viewportShading == 'realistic') {
                pathtracer.setBackground(scene.background, scene.backgroundBlurriness);
            }
        }

        function updatePTEnvironment() {
            if (editor.viewportShading == 'realistic') {
                pathtracer.setEnvironment(scene.environment);
            }
        }

        function updatePTMaterials() {
            if (editor.viewportShading == 'realistic') {
                pathtracer.updateMaterials();
            }
        }

        function updatePT() {
            if (editor.viewportShading == 'realistic') {
                pathtracer.update();
            }
        }

        function render() {
            var startTime = performance.now();
            renderer.setViewport(0, 0, container.dom.offsetWidth, container.dom.offsetHeight);
            renderer.render(scene, editor.viewportCamera);
            if (camera == editor.viewportCamera) {
                renderer.autoClear = false;
                if (grid.visible == true) renderer.render(grid, camera);
                if (sceneHelpers.visible == true) renderer.render(sceneHelpers, camera);
                if (renderer.xr.isPresenting != true) viewHelper.render(renderer);
                renderer.autoClear = true;
            }
            var endTime = performance.now();
            editor.signals.sceneRendered.dispatch(endTime - startTime);
        }

        function updateGridColors(grid1, grid2, colors) {
            grid1.material.color.setHex(colors[0]);
            grid2.material.color.setHex(colors[1]);
        }
    }
}
```
Note that I had to make some assumptions about the Haxe equivalents of certain JavaScript functions and variables, so please review the code carefully to ensure it is correct.
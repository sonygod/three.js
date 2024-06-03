import js.Browser.document;
import js.html.Event;
import js.html.HTMLDivElement;
import js.html.HTMLCanvasElement;
import js.html.MouseEvent;
import js.html.TouchEvent;
import js.html.TouchList;
import js.html.window;
import three.PMREMGenerator;
import three.Box3;
import three.Box3Helper;
import three.Clock;
import three.Color;
import three.EquirectangularReflectionMapping;
import three.Fog;
import three.FogExp2;
import three.GridHelper;
import three.Group;
import three.MathUtils;
import three.MeshBasicMaterial;
import three.MeshNormalMaterial;
import three.Object3D;
import three.PMREMGenerator;
import three.Scene;
import three.Vector2;
import three.Vector3;
import three.WebGLRenderer;

import UIPanel from './libs/ui';
import EditorControls from './EditorControls';
import ViewportControls from './Viewport.Controls';
import ViewportInfo from './Viewport.Info';
import ViewHelper from './Viewport.ViewHelper';
import XR from './Viewport.XR';
import SetPositionCommand from './commands/SetPositionCommand';
import SetRotationCommand from './commands/SetRotationCommand';
import SetScaleCommand from './commands/SetScaleCommand';
import RoomEnvironment from 'three/addons/environments/RoomEnvironment';
import ViewportPathtracer from './Viewport.Pathtracer';
import TransformControls from 'three/addons/controls/TransformControls';

class Viewport {
    private var editor:Editor;
    private var selector:Selector;
    private var signals:Signals;
    private var container:UIPanel;
    private var renderer:WebGLRenderer;
    private var pmremGenerator:PMREMGenerator;
    private var pathtracer:ViewportPathtracer;
    private var camera:THREE.PerspectiveCamera;
    private var scene:Scene;
    private var sceneHelpers:Object3D;
    private var grid:Group;
    private var grid1:GridHelper;
    private var grid2:GridHelper;
    private var viewHelper:ViewHelper;
    private var box:Box3;
    private var selectionBox:Box3Helper;
    private var objectPositionOnDown:Vector3;
    private var objectRotationOnDown:Vector3;
    private var objectScaleOnDown:Vector3;
    private var transformControls:TransformControls;
    private var xr:XR;
    private var onDownPosition:Vector2;
    private var onUpPosition:Vector2;
    private var onDoubleClickPosition:Vector2;
    private var controls:EditorControls;
    private var prevActionsInUse:Int;
    private var clock:Clock;
    private var startTime:Float;
    private var endTime:Float;
    private var useBackgroundAsEnvironment:Bool;

    public function new(editor:Editor) {
        this.editor = editor;
        this.selector = editor.selector;
        this.signals = editor.signals;

        this.container = new UIPanel();
        this.container.setId('viewport');
        this.container.setPosition('absolute');

        this.container.add(new ViewportControls(editor));
        this.container.add(new ViewportInfo(editor));

        this.renderer = null;
        this.pmremGenerator = null;
        this.pathtracer = null;

        this.camera = editor.camera;
        this.scene = editor.scene;
        this.sceneHelpers = editor.sceneHelpers;

        this.grid = new Group();

        this.grid1 = new GridHelper(30, 30);
        this.grid1.material.color.setHex(0x999999);
        this.grid1.material.vertexColors = false;
        this.grid.add(this.grid1);

        this.grid2 = new GridHelper(30, 6);
        this.grid2.material.color.setHex(0x777777);
        this.grid2.material.vertexColors = false;
        this.grid.add(this.grid2);

        this.viewHelper = new ViewHelper(this.camera, this.container);

        this.box = new Box3();

        this.selectionBox = new Box3Helper(this.box);
        this.selectionBox.material.depthTest = false;
        this.selectionBox.material.transparent = true;
        this.selectionBox.visible = false;
        this.sceneHelpers.add(this.selectionBox);

        this.objectPositionOnDown = null;
        this.objectRotationOnDown = null;
        this.objectScaleOnDown = null;

        this.transformControls = new TransformControls(this.camera, this.container.dom);
        this.transformControls.addEventListener('axis-changed', function() {
            if (this.editor.viewportShading !== 'realistic') this.render();
        });
        this.transformControls.addEventListener('objectChange', function() {
            this.signals.objectChanged.dispatch(this.transformControls.object);
        });
        this.transformControls.addEventListener('mouseDown', function() {
            var object = this.transformControls.object;

            this.objectPositionOnDown = object.position.clone();
            this.objectRotationOnDown = object.rotation.clone();
            this.objectScaleOnDown = object.scale.clone();

            this.controls.enabled = false;
        });
        this.transformControls.addEventListener('mouseUp', function() {
            var object = this.transformControls.object;

            if (object !== null) {
                switch (this.transformControls.getMode()) {
                    case 'translate':
                        if (!this.objectPositionOnDown.equals(object.position)) {
                            this.editor.execute(new SetPositionCommand(this.editor, object, object.position, this.objectPositionOnDown));
                        }
                        break;
                    case 'rotate':
                        if (!this.objectRotationOnDown.equals(object.rotation)) {
                            this.editor.execute(new SetRotationCommand(this.editor, object, object.rotation, this.objectRotationOnDown));
                        }
                        break;
                    case 'scale':
                        if (!this.objectScaleOnDown.equals(object.scale)) {
                            this.editor.execute(new SetScaleCommand(this.editor, object, object.scale, this.objectScaleOnDown));
                        }
                        break;
                }
            }

            this.controls.enabled = true;
        });

        this.sceneHelpers.add(this.transformControls);

        this.xr = new XR(this.editor, this.transformControls);

        this.onDownPosition = new Vector2();
        this.onUpPosition = new Vector2();
        this.onDoubleClickPosition = new Vector2();

        this.container.dom.addEventListener('mousedown', this.onMouseDown.bind(this));
        this.container.dom.addEventListener('touchstart', this.onTouchStart.bind(this), {passive: false});
        this.container.dom.addEventListener('dblclick', this.onDoubleClick.bind(this));

        this.controls = new EditorControls(this.camera, this.container.dom);
        this.controls.addEventListener('change', function() {
            this.signals.cameraChanged.dispatch(this.camera);
            this.signals.refreshSidebarObject3D.dispatch(this.camera);
        });
        this.viewHelper.center = this.controls.center;

        this.signals.editorCleared.add(function() {
            this.controls.center.set(0, 0, 0);
            this.pathtracer.reset();

            this.initPT();
            this.render();
        });

        this.signals.transformModeChanged.add(function(mode:String) {
            this.transformControls.setMode(mode);

            this.render();
        });

        this.signals.snapChanged.add(function(dist:Float) {
            this.transformControls.setTranslationSnap(dist);
        });

        this.signals.spaceChanged.add(function(space:String) {
            this.transformControls.setSpace(space);

            this.render();
        });

        this.signals.rendererUpdated.add(function() {
            this.scene.traverse(function(child:Object3D) {
                if (child.material !== null) {
                    child.material.needsUpdate = true;
                }
            });

            this.render();
        });

        this.signals.rendererCreated.add(function(newRenderer:WebGLRenderer) {
            if (this.renderer !== null) {
                this.renderer.setAnimationLoop(null);
                this.renderer.dispose();
                this.pmremGenerator.dispose();

                this.container.dom.removeChild(this.renderer.domElement);
            }

            this.renderer = newRenderer;

            this.renderer.setAnimationLoop(this.animate.bind(this));
            this.renderer.setClearColor(0xaaaaaa);

            if (window.matchMedia) {
                var mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
                mediaQuery.addEventListener('change', function(event:MediaQueryListEvent) {
                    this.renderer.setClearColor(event.matches ? 0x333333 : 0xaaaaaa);
                    this.updateGridColors(this.grid1, this.grid2, event.matches ? [0x555555, 0x888888] : [0x999999, 0x777777]);

                    this.render();
                });

                this.renderer.setClearColor(mediaQuery.matches ? 0x333333 : 0xaaaaaa);
                this.updateGridColors(this.grid1, this.grid2, mediaQuery.matches ? [0x555555, 0x888888] : [0x999999, 0x777777]);
            }

            this.renderer.setPixelRatio(window.devicePixelRatio);
            this.renderer.setSize(this.container.dom.offsetWidth, this.container.dom.offsetHeight);

            this.pmremGenerator = new PMREMGenerator(this.renderer);
            this.pmremGenerator.compileEquirectangularShader();

            this.pathtracer = new ViewportPathtracer(this.renderer);

            this.container.dom.appendChild(this.renderer.domElement);

            this.render();
        });

        this.signals.rendererDetectKTX2Support.add(function(ktx2Loader:KTX2Loader) {
            ktx2Loader.detectSupport(this.renderer);
        });

        this.signals.sceneGraphChanged.add(function() {
            this.initPT();
            this.render();
        });

        this.signals.cameraChanged.add(function() {
            this.pathtracer.reset();

            this.render();
        });

        this.signals.objectSelected.add(function(object:Object3D) {
            this.selectionBox.visible = false;
            this.transformControls.detach();

            if (object !== null && object !== this.scene && object !== this.camera) {
                this.box.setFromObject(object, true);

                if (this.box.isEmpty() === false) {
                    this.selectionBox.visible = true;
                }

                this.transformControls.attach(object);
            }

            this.render();
        });

        this.signals.objectFocused.add(function(object:Object3D) {
            this.controls.focus(object);
        });

        this.signals.geometryChanged.add(function(object:Object3D) {
            if (object !== null) {
                this.box.setFromObject(object, true);
            }

            this.initPT();
            this.render();
        });

        this.signals.objectChanged.add(function(object:Object3D) {
            if (this.editor.selected === object) {
                this.box.setFromObject(object, true);
            }

            if (object.isPerspectiveCamera) {
                object.updateProjectionMatrix();
            }

            var helper = this.editor.helpers[object.id];

            if (helper !== null && helper.isSkeletonHelper !== true) {
                helper.update();
            }

            this.initPT();
            this.render();
        });

        this.signals.objectRemoved.add(function(object:Object3D) {
            this.controls.enabled = true;

            if (object === this.transformControls.object) {
                this.transformControls.detach();
            }
        });

        this.signals.materialChanged.add(function() {
            this.updatePTMaterials();
            this.render();
        });

        this.signals.sceneBackgroundChanged.add(function(backgroundType:String, backgroundColor:Int, backgroundTexture:THREE.Texture, backgroundEquirectangularTexture:THREE.Texture, backgroundBlurriness:Float, backgroundIntensity:Float, backgroundRotation:Float) {
            this.scene.background = null;

            switch (backgroundType) {
                case 'Color':
                    this.scene.background = new Color(backgroundColor);
                    break;
                case 'Texture':
                    if (backgroundTexture !== null) {
                        this.scene.background = backgroundTexture;
                    }
                    break;
                case 'Equirectangular':
                    if (backgroundEquirectangularTexture !== null) {
                        backgroundEquirectangularTexture.mapping = EquirectangularReflectionMapping;

                        this.scene.background = backgroundEquirectangularTexture;
                        this.scene.backgroundBlurriness = backgroundBlurriness;
                        this.scene.backgroundIntensity = backgroundIntensity;
                        this.scene.backgroundRotation.y = backgroundRotation * MathUtils.DEG2RAD;

                        if (this.useBackgroundAsEnvironment) {
                            this.scene.environment = this.scene.background;
                            this.scene.environmentRotation.y = backgroundRotation * MathUtils.DEG2RAD;
                        }
                    }
                    break;
            }

            this.updatePTBackground();
            this.render();
        });

        this.useBackgroundAsEnvironment = false;

        this.signals.sceneEnvironmentChanged.add(function(environmentType:String, environmentEquirectangularTexture:THREE.Texture) {
            this.scene.environment = null;

            this.useBackgroundAsEnvironment = false;

            switch (environmentType) {
                case 'Background':
                    this.useBackgroundAsEnvironment = true;

                    if (this.scene.background !== null && this.scene.background.isTexture) {
                        this.scene.environment = this.scene.background;
                        this.scene.environment.mapping = EquirectangularReflectionMapping;
                        this.scene.environmentRotation.y = this.scene.backgroundRotation.y;
                    }

                    break;
                case 'Equirectangular':
                    if (environmentEquirectangularTexture !== null) {
                        this.scene.environment = environmentEquirectangularTexture;
                        this.scene.environment.mapping = EquirectangularReflectionMapping;
                    }

                    break;
                case 'ModelViewer':
                    this.scene.environment = this.pmremGenerator.fromScene(new RoomEnvironment(), 0.04).texture;

                    break;
            }

            this.updatePTEnvironment();
            this.render();
        });

        this.signals.sceneFogChanged.add(function(fogType:String, fogColor:Int, fogNear:Float, fogFar:Float, fogDensity:Float) {
            switch (fogType) {
                case 'None':
                    this.scene.fog = null;
                    break;
                case 'Fog':
                    this.scene.fog = new Fog(fogColor, fogNear, fogFar);
                    break;
                case 'FogExp2':
                    this.scene.fog = new FogExp2(fogColor, fogDensity);
                    break;
            }

            this.render();
        });

        this.signals.sceneFogSettingsChanged.add(function(fogType:String, fogColor:Int, fogNear:Float, fogFar:Float, fogDensity:Float) {
            switch (fogType) {
                case 'Fog':
                    this.scene.fog.color.setHex(fogColor);
                    this.scene.fog.near = fogNear;
                    this.scene.fog.far = fogFar;
                    break;
                case 'FogExp2':
                    this.scene.fog.color.setHex(fogColor);
                    this.scene.fog.density = fogDensity;
                    break;
            }

            this.render();
        });

        this.signals.viewportCameraChanged.add(function() {
            var viewportCamera = this.editor.viewportCamera;

            if (viewportCamera.isPerspectiveCamera) {
                viewportCamera.aspect = this.editor.camera.aspect;
                viewportCamera.projectionMatrix.copy(this.editor.camera.projectionMatrix);
            } else if (viewportCamera.isOrthographicCamera) {
                // TODO
            }

            this.controls.enabled = (viewportCamera === this.editor.camera);

            this.render();
        });

        this.signals.viewportShadingChanged.add(function() {
            var viewportShading = this.editor.viewportShading;

            switch (viewportShading) {
                case 'realistic':
                    this.pathtracer.init(this.scene, this.camera);
                    break;

                case 'solid':
                    this.scene.overrideMaterial = null;
                    break;

                case 'normals':
                    this.scene.overrideMaterial = new MeshNormalMaterial();
                    break;

                case 'wireframe':
                    this.scene.overrideMaterial = new MeshBasicMaterial({color: 0x000000, wireframe: true});
                    break;
            }

            this.render();
        });

        this.signals.windowResize.add(function() {
            this.updateAspectRatio();

            this.renderer.setSize(this.container.dom.offsetWidth, this.container.dom.offsetHeight);
            this.pathtracer.setSize(this.container.dom.offsetWidth, this.container.dom.offsetHeight);

            this.render();
        });

        this.signals.showGridChanged.add(function(value:Bool) {
            this.grid.visible = value;

            this.render();
        });

        this.signals.showHelpersChanged.add(function(value:Bool) {
            this.sceneHelpers.visible = value;
            this.transformControls.enabled = value;

            this.render();
        });

        this.signals.cameraResetted.add(this.updateAspectRatio);

        this.prevActionsInUse = 0;

        this.clock = new Clock();

        return this.container;
    }

    private function updateAspectRatio():Void {
        this.camera.aspect = this.container.dom.offsetWidth / this.container.dom.offsetHeight;
        this.camera.updateProjectionMatrix();
    }

    private function getMousePosition(dom:HTMLDivElement, x:Int, y:Int):Array<Float> {
        var rect = dom.getBoundingClientRect();
        return [(x - rect.left) / rect.width, (y - rect.top) / rect.height];
    }

    private function handleClick():Void {
        if (this.onDownPosition.distanceTo(this.onUpPosition) === 0) {
            var intersects = this.selector.getPointerIntersects(this.onUpPosition, this.camera);
            this.signals.intersectionsDetected.dispatch(intersects);

            this.render();
        }
    }

    private function onMouseDown(event:MouseEvent):Void {
        if (event.target !== this.renderer.domElement) return;

        var array = this.getMousePosition(this.container.dom, event.clientX, event.clientY);
        this.onDownPosition.fromArray(array);

        document.addEventListener('mouseup', this.onMouseUp.bind(this));
    }

    private function onMouseUp(event:MouseEvent):Void {
        var array = this.getMousePosition(this.container.dom, event.clientX, event.clientY);
        this.onUpPosition.fromArray(array);

        this.handleClick();

        document.removeEventListener('mouseup', this.onMouseUp.bind(this));
    }

    private function onTouchStart(event:TouchEvent):Void {
        var touch = event.changedTouches[0];

        var array = this.getMousePosition(this.container.dom, touch.clientX, touch.clientY);
        this.onDownPosition.fromArray(array);

        document.addEventListener('touchend', this.onTouchEnd.bind(this));
    }

    private function onTouchEnd(event:TouchEvent):Void {
        var touch = event.changedTouches[0];

        var array = this.getMousePosition(this.container.dom, touch.clientX, touch.clientY);
        this.onUpPosition.fromArray(array);

        this.handleClick();

        document.removeEventListener('touchend', this.onTouchEnd.bind(this));
    }

    private function onDoubleClick(event:MouseEvent):Void {
        var array = this.getMousePosition(this.container.dom, event.clientX, event.clientY);
        this.onDoubleClickPosition.fromArray(array);

        var intersects = this.selector.getPointerIntersects(this.onDoubleClickPosition, this.camera);

        if (intersects.length > 0) {
            var intersect = intersects[0];

            this.signals.objectFocused.dispatch(intersect.object);
        }
    }

    private function animate():Void {
        var mixer = this.editor.mixer;
        var delta = this.clock.getDelta();

        var needsUpdate = false;

        var actions = mixer.stats.actions;

        if (actions.inUse > 0 || this.prevActionsInUse > 0) {
            this.prevActionsInUse = actions.inUse;

            mixer.update(delta);
            needsUpdate = true;

            if (this.editor.selected !== null) {
                this.editor.selected.updateWorldMatrix(false, true);
                this.selectionBox.box.setFromObject(this.editor.selected, true);
            }
        }

        if (this.viewHelper.animating === true) {
            this.viewHelper.update(delta);
            needsUpdate = true;
        }

        if (this.renderer.xr.isPresenting === true) {
            needsUpdate = true;
        }

        if (needsUpdate === true) this.render();

        this.updatePT();
    }

    private function initPT():Void {
        if (this.editor.viewportShading === 'realistic') {
            this.pathtracer.init(this.scene, this.camera);
        }
    }

    private function updatePTBackground():Void {
        if (this.editor.viewportShading === 'realistic') {
            this.pathtracer.setBackground(this.scene.background, this.scene.backgroundBlurriness);
        }
    }

    private function updatePTEnvironment():Void {
        if (this.editor.viewportShading === 'realistic') {
            this.pathtracer.setEnvironment(this.scene.environment);
        }
    }

    private function updatePTMaterials():Void {
        if (this.editor.viewportShading === 'realistic') {
            this.pathtracer.updateMaterials();
        }
    }

    private function updatePT():Void {
        if (this.editor.viewportShading === 'realistic') {
            this.pathtracer.update();
        }
    }

    private function render():Void {
        this.startTime = performance.now();

        this.renderer.setViewport(0, 0, this.container.dom.offsetWidth, this.container.dom.offsetHeight);
        this.renderer.render(this.scene, this.editor.viewportCamera);

        if (this.camera === this.editor.viewportCamera) {
            this.renderer.autoClear = false;
            if (this.grid.visible === true) this.renderer.render(this.grid, this.camera);
            if (this.sceneHelpers.visible === true) this.renderer.render(this.sceneHelpers, this.camera);
            if (this.renderer.xr.isPresenting !== true) this.viewHelper.render(this.renderer);
            this.renderer.autoClear = true;
        }

        this.endTime = performance.now();
        this.editor.signals.sceneRendered.dispatch(this.endTime - this.startTime);
    }

    private function updateGridColors(grid1:GridHelper, grid2:GridHelper, colors:Array<Int>):Void {
        grid1.material.color.setHex(colors[0]);
        grid2.material.color.setHex(colors[1]);
    }
}
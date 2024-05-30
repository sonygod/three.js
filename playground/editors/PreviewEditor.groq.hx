package three.js.playground.editors;

import three.addons.controls.OrbitControls;
import three.addons.helpers.ViewHelper;
import flow.Element;
import flow.LabelElement;
import flow.SelectInput;
import BaseNodeEditor;
import three.nodes.MeshBasicNodeMaterial;
import three.nodes.Vec4;
import three.PerspectiveCamera;
import three.Scene;
import three.Mesh;
import three.DoubleSide;
import three.SphereGeometry;
import three.BoxGeometry;
import three.PlaneGeometry;
import three.TorusKnotGeometry;
import three.addons.renderers.webgpu.WebGPURenderer;

class PreviewEditor extends BaseNodeEditor {
    private var sceneDict:Map<String, Scene>;

    public function new() {
        super('Preview', null, 300);
        sceneDict = new Map<String, Scene>();

        var material:MeshBasicNodeMaterial = new MeshBasicNodeMaterial();
        material.colorNode = new Vec4(0, 0, 0, 1);
        material.side = DoubleSide;
        material.transparent = true;

        var previewElement:Element = new Element();
        previewElement.dom.style.paddingTop = 0;
        previewElement.dom.style.paddingBottom = 0;
        previewElement.dom.style.paddingLeft = 0;
        previewElement.dom.style.paddingRight = '14px';

        var sceneInput:SelectInput = new SelectInput([
            { name: 'Box', value: 'box' },
            { name: 'Sphere', value: 'sphere' },
            { name: 'Plane', value: 'plane' },
            { name: 'Sprite', value: 'sprite' },
            { name: 'Torus', value: 'torus' }
        ], 'box');

        var inputElement:LabelElement = setInputAestheticsFromType(new LabelElement('Input'), 'Color');
        inputElement.onConnect(() -> {
            material.colorNode = inputElement.getLinkedObject() || new Vec4(0, 0, 0, 1);
            material.dispose();
        }, true);

        var canvas:js.html.CanvasElement = js.Browser.document.createElement('canvas');
        canvas.style.position = 'absolute';
        previewElement.dom.appendChild(canvas);
        previewElement.setHeight(300);

        previewElement.dom.addEventListener('wheel', e -> e.stopPropagation());

        var renderer:WebGPURenderer = new WebGPURenderer({
            canvas: canvas,
            alpha: true,
            antialias: true
        });
        renderer.autoClear = false;
        renderer.setSize(300, 300, true);
        renderer.setPixelRatio(js.Browser.window.devicePixelRatio);

        var camera:PerspectiveCamera = new PerspectiveCamera(45, 300 / 300, 0.1, 100);
        camera.aspect = 300 / 300;
        camera.updateProjectionMatrix();
        camera.position.set(-2, 2, 2);
        camera.lookAt(0, 0, 0);

        var controls:OrbitControls = new OrbitControls(camera, previewElement.dom);
        controls.enableKeys = false;
        controls.update();

        var viewHelper:ViewHelper = new ViewHelper(camera, previewElement.dom);

        this.sceneInput = sceneInput;
        this.viewHelper = viewHelper;
        this.material = material;
        this.camera = camera;
        this.renderer = renderer;

        this.add(inputElement)
            .add(new LabelElement('Object').add(sceneInput))
            .add(previewElement);
    }

    public function setEditor(editor:BaseNodeEditor) {
        super.setEditor(editor);
        this.updateAnimationRequest();
    }

    public function updateAnimationRequest() {
        if (this.editor != null) {
            js.Browser.window.requestAnimationFrame(() -> this.update());
        }
    }

    public function update() {
        var viewHelper:ViewHelper = this.viewHelper;
        var material:MeshBasicNodeMaterial = this.material;
        var renderer:WebGPURenderer = this.renderer;
        var camera:PerspectiveCamera = this.camera;
        var sceneInput:SelectInput = this.sceneInput;

        this.updateAnimationRequest();

        var sceneName:String = sceneInput.getValue();
        var scene:Scene = getScene(sceneName);
        var mesh:Mesh = scene.children[0];

        mesh.material = material;

        if (sceneName == 'sprite') {
            mesh.lookAt(camera.position);
        }

        renderer.clearAsync().then(_ -> {
            renderer.renderAsync(scene, camera).then(_ -> {
                viewHelper.render(renderer);
            });
        });
    }

    private function getScene(name:String):Scene {
        var scene:Scene = sceneDict.get(name);

        if (scene == null) {
            scene = new Scene();

            switch (name) {
                case 'box':
                    var box:Mesh = new Mesh(new BoxGeometry(1.3, 1.3, 1.3));
                    scene.add(box);
                case 'sphere':
                    var sphere:Mesh = new Mesh(new SphereGeometry(1, 32, 16));
                    scene.add(sphere);
                case 'plane', 'sprite':
                    var plane:Mesh = new Mesh(new PlaneGeometry(2, 2));
                    scene.add(plane);
                case 'torus':
                    var torus:Mesh = new Mesh(new TorusKnotGeometry(.7, .1, 100, 16));
                    scene.add(torus);
            }

            sceneDict.set(name, scene);
        }

        return scene;
    }
}
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
    private var sceneDict:Map<String, Scene> = new Map();
    private var webGPURenderer:WebGPURenderer;
    private var camera:PerspectiveCamera;
    private var material:MeshBasicNodeMaterial;
    private var viewHelper:ViewHelper;
    private var sceneInput:SelectInput;
    private var previewElement:Element;

    public function new() {
        super('Preview', null, 300);

        material = new MeshBasicNodeMaterial();
        material.colorNode = new Vec4(0, 0, 0, 1);
        material.side = DoubleSide;
        material.transparent = true;

        previewElement = new Element();
        previewElement.dom.style.paddingTop = '0px';
        previewElement.dom.style.paddingBottom = '0px';
        previewElement.dom.style.paddingLeft = '0px';
        previewElement.dom.style.paddingRight = '14px';

        sceneInput = new SelectInput([
            { name: 'Box', value: 'box' },
            { name: 'Sphere', value: 'sphere' },
            { name: 'Plane', value: 'plane' },
            { name: 'Sprite', value: 'sprite' },
            { name: 'Torus', value: 'torus' }
        ], 'box');

        var inputElement = setInputAestheticsFromType(new LabelElement('Input'), 'Color');
        inputElement.onConnect(() -> {
            material.colorNode = inputElement.getLinkedObject() || new Vec4(0, 0, 0, 1);
            material.dispose();
        }, true);

        var canvas = js.Browser.document.createElement('canvas');
        canvas.style.position = 'absolute';
        previewElement.dom.appendChild(canvas);
        previewElement.setHeight(300);

        previewElement.dom.addEventListener('wheel', e -> e.stopPropagation());

        webGPURenderer = new WebGPURenderer({
            canvas: canvas,
            alpha: true,
            antialias: true
        });

        webGPURenderer.autoClear = false;
        webGPURenderer.setSize(300, 300, true);
        webGPURenderer.setPixelRatio(js.Browser.window.devicePixelRatio);

        camera = new PerspectiveCamera(45, 300 / 300, 0.1, 100);
        camera.aspect = 300 / 300;
        camera.updateProjectionMatrix();
        camera.position.set(-2, 2, 2);
        camera.lookAt(0, 0, 0);

        var controls = new OrbitControls(camera, previewElement.dom);
        controls.enableKeys = false;
        controls.update();

        viewHelper = new ViewHelper(camera, previewElement.dom);

        this.sceneInput = sceneInput;
        this.viewHelper = viewHelper;
        this.material = material;
        this.camera = camera;
        this.webGPURenderer = webGPURenderer;

        this.add(inputElement)
            .add(new LabelElement('Object').add(sceneInput))
            .add(previewElement);
    }

    override public function setEditor(editor:BaseNodeEditor) {
        super.setEditor(editor);
        updateAnimationRequest();
    }

    private function updateAnimationRequest() {
        if (editor != null) {
            js.Browser.window.requestAnimationFrame(update);
        }
    }

    private function update() {
        updateAnimationRequest();

        var sceneName = sceneInput.getValue();
        var scene = getScene(sceneName);
        var mesh = scene.children[0];
        mesh.material = material;

        if (sceneName == 'sprite') {
            mesh.lookAt(camera.position);
        }

        webGPURenderer.clearAsync().then(_ -> webGPURenderer.renderAsync(scene, camera)).then(_ -> {
            viewHelper.render(webGPURenderer);
        });
    }

    private function getScene(name:String):Scene {
        if (!sceneDict.exists(name)) {
            var scene = new Scene();

            switch (name) {
                case 'box':
                    var box = new Mesh(new BoxGeometry(1.3, 1.3, 1.3));
                    scene.add(box);
                case 'sphere':
                    var sphere = new Mesh(new SphereGeometry(1, 32, 16));
                    scene.add(sphere);
                case 'plane', 'sprite':
                    var plane = new Mesh(new PlaneGeometry(2, 2));
                    scene.add(plane);
                case 'torus':
                    var torus = new Mesh(new TorusKnotGeometry(.7, .1, 100, 16));
                    scene.add(torus);
            }

            sceneDict.set(name, scene);
        }

        return sceneDict.get(name);
    }
}
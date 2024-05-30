import three.addons.controls.OrbitControls;
import three.addons.helpers.ViewHelper;
import flow.Element;
import flow.LabelElement;
import flow.SelectInput;
import BaseNodeEditor from '../BaseNodeEditor.js';
import three.nodes.MeshBasicNodeMaterial;
import three.nodes.vec4;
import three.PerspectiveCamera;
import three.Scene;
import three.Mesh;
import three.DoubleSide;
import three.SphereGeometry;
import three.BoxGeometry;
import three.PlaneGeometry;
import three.TorusKnotGeometry;
import three.addons.renderers.webgpu.WebGPURenderer;
import DataTypeLib.setInputAestheticsFromType;

class PreviewEditor extends BaseNodeEditor {

    var sceneDict:Map<String, Scene> = new Map();

    public function new() {

        var width = 300;
        var height = 300;

        super('Preview', null, width);

        var material = new MeshBasicNodeMaterial();
        material.colorNode = vec4(0, 0, 0, 1);
        material.side = DoubleSide;
        material.transparent = true;

        var previewElement = new Element();
        previewElement.dom.style['padding-top'] = 0;
        previewElement.dom.style['padding-bottom'] = 0;
        previewElement.dom.style['padding-left'] = 0;
        previewElement.dom.style['padding-right'] = '14px';

        var sceneInput = new SelectInput([
            { name: 'Box', value: 'box' },
            { name: 'Sphere', value: 'sphere' },
            { name: 'Plane', value: 'plane' },
            { name: 'Sprite', value: 'sprite' },
            { name: 'Torus', value: 'torus' }
        ], 'box');

        var inputElement = setInputAestheticsFromType(new LabelElement('Input'), 'Color').onConnect(function () {

            material.colorNode = inputElement.getLinkedObject() || vec4(0, 0, 0, 1);
            material.dispose();

        }, true);

        var canvas = js.Browser.document.createElement('canvas');
        canvas.style.position = 'absolute';
        previewElement.dom.append(canvas);
        previewElement.setHeight(height);

        previewElement.dom.addEventListener('wheel', function (e) {
            e.stopPropagation();
        });

        var renderer = new WebGPURenderer({
            canvas: canvas,
            alpha: true,
            antialias: true
        });

        renderer.autoClear = false;
        renderer.setSize(width, height, true);
        renderer.setPixelRatio(js.Browser.window.devicePixelRatio);

        var camera = new PerspectiveCamera(45, width / height, 0.1, 100);
        camera.aspect = width / height;
        camera.updateProjectionMatrix();
        camera.position.set(-2, 2, 2);
        camera.lookAt(0, 0, 0);

        var controls = new OrbitControls(camera, previewElement.dom);
        controls.enableKeys = false;
        controls.update();

        var viewHelper = new ViewHelper(camera, previewElement.dom);

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

        if (this.editor !== null) {

            js.Browser.requestAnimationFrame(function () {
                this.update();
            });
        }
    }

    public async function update() {

        var viewHelper = this.viewHelper;
        var material = this.material;
        var renderer = this.renderer;
        var camera = this.camera;
        var sceneInput = this.sceneInput;

        this.updateAnimationRequest();

        var sceneName = sceneInput.getValue();

        var scene = getScene(sceneName);
        var mesh = scene.children[0];

        mesh.material = material;

        if (sceneName == 'sprite') {

            mesh.lookAt(camera.position);
        }

        await renderer.clearAsync();
        await renderer.renderAsync(scene, camera);

        viewHelper.render(renderer);
    }

    private function getScene(name:String):Scene {

        var scene = sceneDict.get(name);

        if (scene == null) {

            scene = new Scene();

            switch (name) {
                case 'box':
                    var box = new Mesh(new BoxGeometry(1.3, 1.3, 1.3));
                    scene.add(box);
                    break;
                case 'sphere':
                    var sphere = new Mesh(new SphereGeometry(1, 32, 16));
                    scene.add(sphere);
                    break;
                case 'plane':
                case 'sprite':
                    var plane = new Mesh(new PlaneGeometry(2, 2));
                    scene.add(plane);
                    break;
                case 'torus':
                    var torus = new Mesh(new TorusKnotGeometry(0.7, 0.1, 100, 16));
                    scene.add(torus);
                    break;
            }

            sceneDict.set(name, scene);
        }

        return scene;
    }
}
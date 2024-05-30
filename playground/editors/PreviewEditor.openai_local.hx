将JavaScript代码转换为Haxe需要将每个对应的库和功能转换为Haxe的等效实现。以下是转换后的Haxe代码：

```haxe
import three_addons_controls_OrbitControls;
import three_addons_helpers_ViewHelper;
import flow.Element;
import flow.LabelElement;
import flow.SelectInput;
import BaseNodeEditor;
import three_nodes.MeshBasicNodeMaterial;
import three_nodes.vec4;
import three.PerspectiveCamera;
import three.Scene;
import three.Mesh;
import three.DoubleSide;
import three.SphereGeometry;
import three.BoxGeometry;
import three.PlaneGeometry;
import three.TorusKnotGeometry;
import three_addons_renderers_webgpu_WebGPURenderer;
import DataTypeLib.setInputAestheticsFromType;

class PreviewEditor extends BaseNodeEditor {

    var sceneDict:Map<String, Scene> = new Map<String, Scene>();
    var sceneInput:SelectInput;
    var viewHelper:ViewHelper;
    var material:MeshBasicNodeMaterial;
    var camera:PerspectiveCamera;
    var renderer:WebGPURenderer;

    public function new() {
        var width = 300;
        var height = 300;

        super('Preview', null, width);

        material = new MeshBasicNodeMaterial();
        material.colorNode = vec4(0, 0, 0, 1);
        material.side = DoubleSide;
        material.transparent = true;

        var previewElement = new Element();
        previewElement.dom.style.paddingTop = 0;
        previewElement.dom.style.paddingBottom = 0;
        previewElement.dom.style.paddingLeft = 0;
        previewElement.dom.style.paddingRight = '14px';

        sceneInput = new SelectInput([
            { name: 'Box', value: 'box' },
            { name: 'Sphere', value: 'sphere' },
            { name: 'Plane', value: 'plane' },
            { name: 'Sprite', value: 'sprite' },
            { name: 'Torus', value: 'torus' }
        ], 'box');

        var inputElement = setInputAestheticsFromType(new LabelElement('Input'), 'Color').onConnect(() -> {
            material.colorNode = inputElement.getLinkedObject() || vec4(0, 0, 0, 1);
            material.dispose();
        }, true);

        var canvas = js.Browser.document.createCanvasElement();
        canvas.style.position = 'absolute';
        previewElement.dom.appendChild(canvas);
        previewElement.setHeight(height);

        previewElement.dom.addEventListener('wheel', e -> e.stopPropagation());

        renderer = new WebGPURenderer({
            canvas: canvas,
            alpha: true,
            antialias: true
        });

        renderer.autoClear = false;
        renderer.setSize(width, height, true);
        renderer.setPixelRatio(js.Browser.window.devicePixelRatio);

        camera = new PerspectiveCamera(45, width / height, 0.1, 100);
        camera.aspect = width / height;
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
        this.renderer = renderer;

        this.add(inputElement)
            .add(new LabelElement('Object').add(scene
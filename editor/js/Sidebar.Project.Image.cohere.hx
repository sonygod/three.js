import js.three.ObjectLoader;
import js.three.WebGLRenderer;

import js.dom.window.Window;
import js.html.canvas.CanvasElement;
import js.html.dom.Document;
import js.html.dom.Element;
import js.html.dom.HTMLCollection;
import js.html.meta.MetaElement;
import js.html.text.TextNode;

class SidebarProjectImage {
    public function new(editor:Editor) {
        var container = new UIPanel();
        container.setId('render');

        // Image
        container.add(new UIText(editor.strings.getKey('sidebar/project/image')).setTextTransform('uppercase'));
        container.add(new UIBreak());
        container.add(new UIBreak());

        // Shading
        var shadingRow = new UIRow();
        shadingRow.add(new UIText(editor.strings.getKey('sidebar/project/shading')).setClass('Label'));

        var shadingTypeSelect = new UISelect();
        shadingTypeSelect.setOptions([
            {'Solid': 0},
            {'Realistic': 1}
        ]);
        shadingTypeSelect.setValue(0);
        shadingRow.add(shadingTypeSelect);

        // Resolution
        var resolutionRow = new UIRow();
        container.add(resolutionRow);

        resolutionRow.add(new UIText(editor.strings.getKey('sidebar/project/resolution')).setClass('Label'));

        var imageWidth = new UIInteger(1024);
        imageWidth.setTextAlign('center');
        imageWidth.setWidth('28px');
        resolutionRow.add(imageWidth);

        resolutionRow.add(new UIText('×').setTextAlign('center').setFontSize('12px').setWidth('12px'));

        var imageHeight = new UIInteger(1024);
        imageHeight.setTextAlign('center');
        imageHeight.setWidth('28px');
        resolutionRow.add(imageHeight);

        // Render
        var renderButton = new UIButton(editor.strings.getKey('sidebar/project/render'));
        renderButton.setWidth('170px');
        renderButton.setMarginLeft('120px');
        renderButton.onClick(function() {
            var json = editor.toJSON();
            var project = json.project;

            var loader = new ObjectLoader();

            var camera = cast loader.parse(json.camera), Camera;
            camera.aspect = imageWidth.getValue() / imageHeight.getValue();
            camera.updateProjectionMatrix();
            camera.updateMatrixWorld();

            var scene = cast loader.parse(json.scene), Scene;

            var renderer = new WebGLRenderer({antialias: true});
            renderer.setSize(imageWidth.getValue(), imageHeight.getValue());

            if (project.shadows != null) renderer.shadowMap.enabled = project.shadows;
            if (project.shadowType != null) renderer.shadowMap.type = project.shadowType;
            if (project.toneMapping != null) renderer.toneMapping = project.toneMapping;
            if (project.toneMappingExposure != null) renderer.toneMappingExposure = project.toneMappingExposure;

            // Popup
            var width = imageWidth.getValue() / Window.devicePixelRatio;
            var height = imageHeight.getValue() / Window.devicePixelRatio;

            var left = (Window.screen.width - width) / 2;
            var top = (Window.screen.height - height) / 2;

            var output = Window.open('', '_blank', 'location=no,left=$left,top=$top,width=$width,height=$height');

            var meta = cast output.document.createElement('meta'), MetaElement;
            meta.name = 'viewport';
            meta.content = 'width=device-width, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0';
            cast output.document.head, HTMLCollection.ElementList.fromArray([meta]);

            cast output.document.body, Element.setStyle('background', '#000');
            cast output.document.body, Element.setStyle('margin', '0px');
            cast output.document.body, Element.setStyle('overflow', 'hidden');

            var canvas = cast renderer.domElement, CanvasElement;
            cast canvas, Element.setStyle('width', Std.string(width) + 'px');
            cast canvas, Element.setStyle('height', Std.string(height) + 'px');
            cast output.document.body, Element.appendChild(canvas);

            switch (shadingTypeSelect.getValue()) {
                case 0: // SOLID
                    renderer.render(scene, camera);
                    renderer.dispose();
                    break;
                /*
                case 1: // REALISTIC
                    var status = output.document.createElement('div');
                    cast status, Element.setStyle('position', 'absolute');
                    cast status, Element.setStyle('top', '10px');
                    cast status, Element.setStyle('left', '10px');
                    cast status, Element.setStyle('color', 'white');
                    cast status, Element.setStyle('font-family', 'system-ui');
                    cast status, Element.setStyle('font-size', '12px');
                    cast output.document.body, Element.appendChild(status);

                    var pathtracer = new ViewportPathtracer(renderer);
                    pathtracer.init(scene, camera);
                    pathtracer.setSize(imageWidth.getValue(), imageHeight.getValue());

                    function animate() {
                        if (output.closed) return;

                        Window.requestAnimationFrame(animate);

                        pathtracer.update();

                        // status.textContent = Math.floor(samples);
                    }

                    animate();
                    break;
                */
            }
        });
        container.add(renderButton);

        return container;
    }
}

class Editor {
    public var toJSON:Dynamic;
    public var strings:Dynamic;
}

class UIPanel {
    public function new() {

    }

    public function setId(id:String) {

    }

    public function add(elements:Dynamic) {

    }
}

class UIText {
    public function new(text:String) {

    }

    public function setTextTransform(transform:String) {

    }
}

class UIBreak {

}

class UIRow {
    public function new() {

    }

    public function add(elements:Dynamic) {

    }
}

class UISelect {
    public function new() {

    }

    public function setOptions(options:Dynamic) {

    }

    public function setValue(value:Int) {

    }

    public function getValue():Int {
        return 0;
    }
}

class UIInteger {
    public function new(value:Int) {

    }

    public function setTextAlign(align:String) {

    }

    public function setWidth(width:String) {

    }

    public function getValue():Int {
        return 0;
    }
}

class UIButton {
    public function new(title:String) {

    }

    public function setWidth(width:String) {

    }

    public function setMarginLeft(margin:String) {

    }

    public function onClick(callback:Void->Void) {

    }
}
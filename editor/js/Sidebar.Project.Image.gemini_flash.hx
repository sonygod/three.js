import three.THREE;
import three.cameras.Camera;
import three.loaders.ObjectLoader;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import js.Browser;

import ui.UIBreak;
import ui.UIButton;
import ui.UIInteger;
import ui.UIPanel;
import ui.UIRow;
import ui.UISelect;
import ui.UIText;

// import ViewportPathtracer from './Viewport.Pathtracer';

class SidebarProjectImage {

    public function new(editor : Dynamic) {

        final strings = editor.strings;

        final container = new UIPanel();
        container.setId('render');

        // Image

        container.add(new UIText(strings.getKey('sidebar/project/image')).setTextTransform('uppercase'));
        container.add(new UIBreak(), new UIBreak());

        // Shading

        final shadingRow = new UIRow();
        // container.add(shadingRow);

        shadingRow.add(new UIText(strings.getKey('sidebar/project/shading')).setClass('Label'));

        final shadingTypeSelect = new UISelect().setOptions({
            0: 'Solid',
            1: 'Realistic'
        }).setWidth('125px');
        shadingTypeSelect.setValue(0);
        shadingRow.add(shadingTypeSelect);

        // Resolution

        final resolutionRow = new UIRow();
        container.add(resolutionRow);

        resolutionRow.add(new UIText(strings.getKey('sidebar/project/resolution')).setClass('Label'));

        final imageWidth = new UIInteger(1024).setTextAlign('center').setWidth('28px');
        resolutionRow.add(imageWidth);

        resolutionRow.add(new UIText('×').setTextAlign('center').setFontSize('12px').setWidth('12px'));

        final imageHeight = new UIInteger(1024).setTextAlign('center').setWidth('28px');
        resolutionRow.add(imageHeight);

        // Render

        final renderButton = new UIButton(strings.getKey('sidebar/project/render'));
        renderButton.setWidth('170px');
        renderButton.setMarginLeft('120px');
        renderButton.onClick(async () -> {

            final json = editor.toJSON();
            final project = json.project;

            //

            final loader = new ObjectLoader();

            final camera = loader.parse(json.camera);
            camera.aspect = imageWidth.getValue() / imageHeight.getValue();
            camera.updateProjectionMatrix();
            camera.updateMatrixWorld();

            final scene = loader.parse(json.scene);

            final renderer = new WebGLRenderer({ antialias: true });
            renderer.setSize(imageWidth.getValue(), imageHeight.getValue());

            if (project.shadows != null) renderer.shadowMap.enabled = project.shadows;
            if (project.shadowType != null) renderer.shadowMap.type = project.shadowType;
            if (project.toneMapping != null) renderer.toneMapping = project.toneMapping;
            if (project.toneMappingExposure != null) renderer.toneMappingExposure = project.toneMappingExposure;

            // popup

            final width = imageWidth.getValue() / Browser.window.devicePixelRatio;
            final height = imageHeight.getValue() / Browser.window.devicePixelRatio;

            final left = (Browser.screen.width - width) / 2;
            final top = (Browser.screen.height - height) / 2;

            final output = Browser.window.open('', '_blank', 'location=no,left=$left,top=$top,width=$width,height=$height');

            final meta = Browser.document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0';
            output.document.head.appendChild(meta);

            output.document.body.style.background = '#000';
            output.document.body.style.margin = '0px';
            output.document.body.style.overflow = 'hidden';

            final canvas = renderer.domElement;
            canvas.style.width = '$width' + 'px';
            canvas.style.height = '$height' + 'px';
            output.document.body.appendChild(canvas);

            //

            switch (shadingTypeSelect.getValue()) {

                case 0: // SOLID

                    renderer.render(scene, cast camera);
                    renderer.dispose();

                /*
                case 1: // REALISTIC

                    final status = Browser.document.createElement('div');
                    status.style.position = 'absolute';
                    status.style.top = '10px';
                    status.style.left = '10px';
                    status.style.color = 'white';
                    status.style.fontFamily = 'system-ui';
                    status.style.fontSize = '12px';
                    output.document.body.appendChild(status);

                    final pathtracer = new ViewportPathtracer(renderer);
                    pathtracer.init(scene, camera);
                    pathtracer.setSize(imageWidth.getValue(), imageHeight.getValue());

                    function animate() {

                        if (output.closed) return;

                        Browser.window.requestAnimationFrame(animate);

                        pathtracer.update();

                        // status.textContent = Math.floor(samples);

                    }

                    animate();

                    break;
                */

            }

        });
        container.add(renderButton);

        //

        return container;

    }

}
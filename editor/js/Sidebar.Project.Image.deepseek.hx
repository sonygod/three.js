import js.Lib;
import three.THREE;
import three.ui.UIPanel;
import three.ui.UIText;
import three.ui.UIBreak;
import three.ui.UIButton;
import three.ui.UIInteger;
import three.ui.UIRow;
import three.ui.UISelect;

class SidebarProjectImage {

    public function new(editor:Dynamic) {

        var strings = editor.strings;

        var container = new UIPanel();
        container.setId('render');

        // Image

        container.add(new UIText(strings.getKey('sidebar/project/image')).setTextTransform('uppercase'));
        container.add(new UIBreak(), new UIBreak());

        // Shading

        var shadingRow = new UIRow();
        container.add(shadingRow);

        shadingRow.add(new UIText(strings.getKey('sidebar/project/shading')).setClass('Label'));

        var shadingTypeSelect = new UISelect().setOptions({
            0: 'Solid',
            1: 'Realistic'
        }).setWidth('125px');
        shadingTypeSelect.setValue(0);
        shadingRow.add(shadingTypeSelect);

        // Resolution

        var resolutionRow = new UIRow();
        container.add(resolutionRow);

        resolutionRow.add(new UIText(strings.getKey('sidebar/project/resolution')).setClass('Label'));

        var imageWidth = new UIInteger(1024).setTextAlign('center').setWidth('28px');
        resolutionRow.add(imageWidth);

        resolutionRow.add(new UIText('×').setTextAlign('center').setFontSize('12px').setWidth('12px'));

        var imageHeight = new UIInteger(1024).setTextAlign('center').setWidth('28px');
        resolutionRow.add(imageHeight);

        // Render

        var renderButton = new UIButton(strings.getKey('sidebar/project/render'));
        renderButton.setWidth('170px');
        renderButton.setMarginLeft('120px');
        renderButton.onClick(function() {

            var json = editor.toJSON();
            var project = json.project;

            //

            var loader = new THREE.ObjectLoader();

            var camera = loader.parse(json.camera);
            camera.aspect = imageWidth.getValue() / imageHeight.getValue();
            camera.updateProjectionMatrix();
            camera.updateMatrixWorld();

            var scene = loader.parse(json.scene);

            var renderer = new THREE.WebGLRenderer({ antialias: true });
            renderer.setSize(imageWidth.getValue(), imageHeight.getValue());

            if (project.shadows !== undefined) renderer.shadowMap.enabled = project.shadows;
            if (project.shadowType !== undefined) renderer.shadowMap.type = project.shadowType;
            if (project.toneMapping !== undefined) renderer.toneMapping = project.toneMapping;
            if (project.toneMappingExposure !== undefined) renderer.toneMappingExposure = project.toneMappingExposure;

            // popup

            var width = imageWidth.getValue() / window.devicePixelRatio;
            var height = imageHeight.getValue() / window.devicePixelRatio;

            var left = (screen.width - width) / 2;
            var top = (screen.height - height) / 2;

            var output = window.open('', '_blank', `location=no,left=${left},top=${top},width=${width},height=${height}`);

            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0';
            output.document.head.appendChild(meta);

            output.document.body.style.background = '#000';
            output.document.body.style.margin = '0px';
            output.document.body.style.overflow = 'hidden';

            var canvas = renderer.domElement;
            canvas.style.width = width + 'px';
            canvas.style.height = height + 'px';
            output.document.body.appendChild(canvas);

            //

            switch (Lib.parseInt(shadingTypeSelect.getValue())) {

                case 0: // SOLID

                    renderer.render(scene, camera);
                    renderer.dispose();

                    break;
                /*
                case 1: // REALISTIC

                    var status = document.createElement('div');
                    status.style.position = 'absolute';
                    status.style.top = '10px';
                    status.style.left = '10px';
                    status.style.color = 'white';
                    status.style.fontFamily = 'system-ui';
                    status.style.fontSize = '12px';
                    output.document.body.appendChild(status);

                    var pathtracer = new ViewportPathtracer(renderer);
                    pathtracer.init(scene, camera);
                    pathtracer.setSize(imageWidth.getValue(), imageHeight.getValue());

                    function animate() {

                        if (output.closed === true) return;

                        requestAnimationFrame(animate);

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
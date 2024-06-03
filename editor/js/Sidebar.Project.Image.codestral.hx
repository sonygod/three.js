import three.THREE;
import ui.UIBreak;
import ui.UIButton;
import ui.UIInteger;
import ui.UIPanel;
import ui.UIRow;
import ui.UISelect;
import ui.UIText;

class SidebarProjectImage {
    public function new(editor:Editor) {
        var strings:Strings = editor.strings;

        var container:UIPanel = new UIPanel();
        container.setId('render');

        container.add(new UIText(strings.getKey('sidebar/project/image')).setTextTransform('uppercase'));
        container.add(new UIBreak(), new UIBreak());

        var shadingRow:UIRow = new UIRow();
        shadingRow.add(new UIText(strings.getKey('sidebar/project/shading')).setClass('Label'));

        var shadingTypeSelect:UISelect = new UISelect().setOptions({0:'Solid', 1:'Realistic'}).setWidth('125px');
        shadingTypeSelect.setValue(0);
        shadingRow.add(shadingTypeSelect);

        var resolutionRow:UIRow = new UIRow();
        container.add(resolutionRow);

        resolutionRow.add(new UIText(strings.getKey('sidebar/project/resolution')).setClass('Label'));

        var imageWidth:UIInteger = new UIInteger(1024).setTextAlign('center').setWidth('28px');
        resolutionRow.add(imageWidth);

        resolutionRow.add(new UIText('×').setTextAlign('center').setFontSize('12px').setWidth('12px'));

        var imageHeight:UIInteger = new UIInteger(1024).setTextAlign('center').setWidth('28px');
        resolutionRow.add(imageHeight);

        var renderButton:UIButton = new UIButton(strings.getKey('sidebar/project/render'));
        renderButton.setWidth('170px');
        renderButton.setMarginLeft('120px');
        renderButton.onClick(function() {
            var json = editor.toJSON();
            var project = json.project;

            var loader = new THREE.ObjectLoader();

            var camera = loader.parse(json.camera);
            camera.aspect = imageWidth.getValue() / imageHeight.getValue();
            camera.updateProjectionMatrix();
            camera.updateMatrixWorld();

            var scene = loader.parse(json.scene);

            var renderer = new THREE.WebGLRenderer({antialias: true});
            renderer.setSize(imageWidth.getValue(), imageHeight.getValue());

            if (project.shadows != null) renderer.shadowMap.enabled = project.shadows;
            if (project.shadowType != null) renderer.shadowMap.type = project.shadowType;
            if (project.toneMapping != null) renderer.toneMapping = project.toneMapping;
            if (project.toneMappingExposure != null) renderer.toneMappingExposure = project.toneMappingExposure;

            var width = imageWidth.getValue() / window.devicePixelRatio;
            var height = imageHeight.getValue() / window.devicePixelRatio;

            var left = (window.screen.width - width) / 2;
            var top = (window.screen.height - height) / 2;

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

            switch (Std.parseInt(shadingTypeSelect.getValue())) {
                case 0:
                    renderer.render(scene, camera);
                    renderer.dispose();
                    break;
            }
        });
        container.add(renderButton);

        return container;
    }
}
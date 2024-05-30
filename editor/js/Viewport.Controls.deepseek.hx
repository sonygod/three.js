import three.js.editor.js.libs.ui.UIPanel;
import three.js.editor.js.libs.ui.UISelect;
import three.js.editor.js.libs.ui.three.UIBoolean;

class ViewportControls {

    public function new(editor:Dynamic) {

        var signals = editor.signals;
        var strings = editor.strings;

        var container = new UIPanel();
        container.setPosition('absolute');
        container.setRight('10px');
        container.setTop('10px');
        container.setColor('#ffffff');

        // grid

        var gridCheckbox = new UIBoolean(true, strings.getKey('viewport/controls/grid'));
        gridCheckbox.onChange(function () {

            signals.showGridChanged.dispatch(this.getValue());

        });
        container.add(gridCheckbox);

        // helpers

        var helpersCheckbox = new UIBoolean(true, strings.getKey('viewport/controls/helpers'));
        helpersCheckbox.onChange(function () {

            signals.showHelpersChanged.dispatch(this.getValue());

        });
        container.add(helpersCheckbox);

        // camera

        var cameraSelect = new UISelect();
        cameraSelect.setMarginLeft('10px');
        cameraSelect.setMarginRight('10px');
        cameraSelect.onChange(function () {

            editor.setViewportCamera(this.getValue());

        });
        container.add(cameraSelect);

        signals.cameraAdded.add(update);
        signals.cameraRemoved.add(update);
        signals.objectChanged.add(function (object) {

            if (object.isCamera) {

                update();

            }

        });

        // shading

        var shadingSelect = new UISelect();
        shadingSelect.setOptions({'realistic': 'realistic', 'solid': 'solid', 'normals': 'normals', 'wireframe': 'wireframe'});
        shadingSelect.setValue('solid');
        shadingSelect.onChange(function () {

            editor.setViewportShading(this.getValue());

        });
        container.add(shadingSelect);

        signals.editorCleared.add(function () {

            editor.setViewportCamera(editor.camera.uuid);

            shadingSelect.setValue('solid');
            editor.setViewportShading(shadingSelect.getValue());

        });

        signals.cameraResetted.add(update);

        update();

        //

        function update() {

            var options = {};

            var cameras = editor.cameras;

            for (key in cameras) {

                var camera = cameras[key];
                options[camera.uuid] = camera.name;

            }

            cameraSelect.setOptions(options);

            var selectedCamera = (editor.viewportCamera.uuid in options)
                ? editor.viewportCamera
                : editor.camera;

            cameraSelect.setValue(selectedCamera.uuid);
            editor.setViewportCamera(selectedCamera.uuid);

        }

        return container;

    }

}
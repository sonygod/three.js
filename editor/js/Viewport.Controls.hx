Here is the converted Haxe code:
```
package three.js.editor.js;

import js.html.DOMElement;
import js.Browser;

import three.js.editor.ui.UIPanel;
import three.js.editor.ui.UISelect;
import three.js.editor.ui.UIBoolean;

class ViewportControls {
    private var editor:Dynamic;
    private var signals:Dynamic;
    private var strings:Dynamic;
    private var container:UIPanel;
    private var gridCheckbox:UIBoolean;
    private var helpersCheckbox:UIBoolean;
    private var cameraSelect:UISelect;
    private var shadingSelect:UISelect;

    public function new(editor:Dynamic) {
        this.editor = editor;
        signals = editor.signals;
        strings = editor.strings;

        container = new UIPanel();
        container.setPosition('absolute');
        container.setRight('10px');
        container.setTop('10px');
        container.setColor('#ffffff');

        // grid

        gridCheckbox = new UIBoolean(true, strings.getKey('viewport/controls/grid'));
        gridCheckbox.onChange(function() {
            signals.showGridChanged.dispatch(gridCheckbox.getValue());
        });
        container.add(gridCheckbox);

        // helpers

        helpersCheckbox = new UIBoolean(true, strings.getKey('viewport/controls/helpers'));
        helpersCheckbox.onChange(function() {
            signals.showHelpersChanged.dispatch(helpersCheckbox.getValue());
        });
        container.add(helpersCheckbox);

        // camera

        cameraSelect = new UISelect();
        cameraSelect.setMarginLeft('10px');
        cameraSelect.setMarginRight('10px');
        cameraSelect.onChange(function() {
            editor.setViewportCamera(cameraSelect.getValue());
        });
        container.add(cameraSelect);

        signals.cameraAdded.add(update);
        signals.cameraRemoved.add(update);
        signals.objectChanged.add(function(object:Dynamic) {
            if (object.isCamera) {
                update();
            }
        });

        // shading

        shadingSelect = new UISelect();
        shadingSelect.setOptions({
            'realistic': 'realistic',
            'solid': 'solid',
            'normals': 'normals',
            'wireframe': 'wireframe'
        });
        shadingSelect.setValue('solid');
        shadingSelect.onChange(function() {
            editor.setViewportShading(shadingSelect.getValue());
        });
        container.add(shadingSelect);

        signals.editorCleared.add(function() {
            editor.setViewportCamera(editor.camera.uuid);
            shadingSelect.setValue('solid');
            editor.setViewportShading(shadingSelect.getValue());
        });

        signals.cameraResetted.add(update);

        update();
    }

    private function update() {
        var options = {};

        var cameras = editor.cameras;

        for (var key in cameras) {
            var camera = cameras[key];
            options[camera.uuid] = camera.name;
        }

        cameraSelect.setOptions(options);

        var selectedCamera = (editor.viewportCamera.uuid in options) ? editor.viewportCamera : editor.camera;

        cameraSelect.setValue(selectedCamera.uuid);
        editor.setViewportCamera(selectedCamera.uuid);
    }

    public function getContainer():UIPanel {
        return container;
    }
}
```
Note that I've used the `js` package to import the necessary UI components, and `Dynamic` type to represent the `editor` object. I've also used the `private` keyword to declare private variables and functions.
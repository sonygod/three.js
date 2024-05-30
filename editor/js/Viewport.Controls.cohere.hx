import js.Browser.window;

import js.html.DivElement;
import js.html.InputElement;
import js.html.OptionElement;
import js.html.SelectElement;

class ViewportControls {
    public var container:DivElement;
    public var gridCheckbox:InputElement;
    public var helpersCheckbox:InputElement;
    public var cameraSelect:SelectElement;
    public var shadingSelect:SelectElement;

    public function new(editor:Editor) {
        var signals = editor.signals;
        var strings = editor.strings;

        container = window.document.createElement('div');
        container.style.position = 'absolute';
        container.style.right = '10px';
        container.style.top = '10px';
        container.style.color = '#ffffff';

        // grid

        gridCheckbox = window.document.createElement('input');
        gridCheckbox.type = 'checkbox';
        gridCheckbox.checked = true;
        gridCheckbox.id = 'grid';
        gridCheckbox.onchange = function() {
            signals.showGridChanged.dispatch(gridCheckbox.checked);
        };
        container.appendChild(gridCheckbox);
        gridCheckbox.nextSibling.nodeValue = strings.getKey('viewport/controls/grid');

        // helpers

        helpersCheckbox = window.document.createElement('input');
        helpersCheckbox.type = 'checkbox';
        helpersCheckbox.checked = true;
        helpersCheckbox.id = 'helpers';
        helpersCheckbox.onchange = function() {
            signals.showHelpersChanged.dispatch(helpersCheckbox.checked);
        };
        container.appendChild(helpersCheckbox);
        helpersCheckbox.nextSibling.nodeValue = strings.getKey('viewport/controls/helpers');

        // camera

        cameraSelect = window.document.createElement('select');
        cameraSelect.style.marginLeft = '10px';
        cameraSelect.style.marginRight = '10px';
        cameraSelect.onchange = function() {
            editor.setViewportCamera(cameraSelect.value);
        };
        container.appendChild(cameraSelect);

        signals.cameraAdded.add(update);
        signals.cameraRemoved.add(update);
        signals.objectChanged.add(function(object) {
            if (Std.is(object, Camera)) {
                update();
            }
        });

        // shading

        shadingSelect = window.document.createElement('select');
        var shadingOptions = ['realistic', 'solid', 'normals', 'wireframe'];
        for (option in shadingOptions) {
            var optionElement = window.document.createElement('option');
            optionElement.value = option;
            optionElement.text = option;
            shadingSelect.add(optionElement);
        }
        shadingSelect.value = 'solid';
        shadingSelect.onchange = function() {
            editor.setViewportShading(shadingSelect.value);
        };
        container.appendChild(shadingSelect);

        signals.editorCleared.add(function() {
            editor.setViewportCamera(editor.camera.uuid);
            shadingSelect.value = 'solid';
            editor.setViewportShading(shadingSelect.value);
        });

        signals.cameraResetted.add(update);

        update();
    }

    public function update() {
        var options = new Map();
        var cameras = editor.cameras;
        for (camera in cameras) {
            options.set(camera.uuid, camera.name);
        }

        cameraSelect.innerHTML = '';
        for (option in options.keys()) {
            var optionElement = window.document.createElement('option');
            optionElement.value = option;
            optionElement.text = options.get(option);
            cameraSelect.add(optionElement);
        }

        var selectedCamera = editor.viewportCamera;
        if (!options.has(selectedCamera.uuid)) {
            selectedCamera = editor.camera;
        }

        cameraSelect.value = selectedCamera.uuid;
        editor.setViewportCamera(selectedCamera.uuid);
    }
}

class Editor {
    public var signals:Signals;
    public var strings:StringMap<String>;
    public var cameras:Map<Camera>;
    public var viewportCamera:Camera;
    public var camera:Camera;

    public function setViewportCamera(uuid:String) {
        // implementation
    }

    public function setViewportShading(value:String) {
        // implementation
    }
}

class Camera {
    public var uuid:String;
    public var name:String;

    public function isCamera():Bool {
        return true;
    }
}

class Signals {
    public var showGridChanged:Signal;
    public var showHelpersChanged:Signal;
    public var cameraAdded:Signal;
    public var cameraRemoved:Signal;
    public var objectChanged:Signal;
    public var editorCleared:Signal;
    public var cameraResetted:Signal;
}

class Signal {
    public function dispatch(value:Bool) {
        // implementation
    }

    public function add(callback:Void->Void) {
        // implementation
    }
}
import ui.UIPanel;
import ui.UISelect;
import ui.three.UIBoolean;

class ViewportControls {

    private var signals: Signals;
    private var strings: Strings;

    private var container: UIPanel;
    private var gridCheckbox: UIBoolean;
    private var helpersCheckbox: UIBoolean;
    private var cameraSelect: UISelect;
    private var shadingSelect: UISelect;

    public function new(editor: Editor) {

        this.signals = editor.signals;
        this.strings = editor.strings;

        this.container = new UIPanel();
        this.container.setPosition('absolute');
        this.container.setRight('10px');
        this.container.setTop('10px');
        this.container.setColor('#ffffff');

        this.gridCheckbox = new UIBoolean(true, this.strings.getKey('viewport/controls/grid'));
        this.gridCheckbox.onChange(() -> {
            this.signals.showGridChanged.dispatch(this.gridCheckbox.getValue());
        });
        this.container.add(this.gridCheckbox);

        this.helpersCheckbox = new UIBoolean(true, this.strings.getKey('viewport/controls/helpers'));
        this.helpersCheckbox.onChange(() -> {
            this.signals.showHelpersChanged.dispatch(this.helpersCheckbox.getValue());
        });
        this.container.add(this.helpersCheckbox);

        this.cameraSelect = new UISelect();
        this.cameraSelect.setMarginLeft('10px');
        this.cameraSelect.setMarginRight('10px');
        this.cameraSelect.onChange(() -> {
            editor.setViewportCamera(this.cameraSelect.getValue());
        });
        this.container.add(this.cameraSelect);

        this.signals.cameraAdded.add(update);
        this.signals.cameraRemoved.add(update);
        this.signals.objectChanged.add((object) -> {
            if (object.isCamera) {
                update();
            }
        });

        this.shadingSelect = new UISelect();
        this.shadingSelect.setOptions({'realistic': 'realistic', 'solid': 'solid', 'normals': 'normals', 'wireframe': 'wireframe'});
        this.shadingSelect.setValue('solid');
        this.shadingSelect.onChange(() -> {
            editor.setViewportShading(this.shadingSelect.getValue());
        });
        this.container.add(this.shadingSelect);

        this.signals.editorCleared.add(() -> {
            editor.setViewportCamera(editor.camera.uuid);
            this.shadingSelect.setValue('solid');
            editor.setViewportShading(this.shadingSelect.getValue());
        });

        this.signals.cameraResetted.add(update);

        update();
    }

    private function update(): Void {
        var options = new haxe.ds.StringMap<String>();

        var cameras = editor.cameras;

        for (key in cameras.keys()) {
            var camera = cameras.get(key);
            options.set(camera.uuid, camera.name);
        }

        this.cameraSelect.setOptions(options);

        var selectedCamera = (editor.viewportCamera.uuid in options) ? editor.viewportCamera : editor.camera;

        this.cameraSelect.setValue(selectedCamera.uuid);
        editor.setViewportCamera(selectedCamera.uuid);
    }

    public function getContainer(): UIPanel {
        return this.container;
    }
}
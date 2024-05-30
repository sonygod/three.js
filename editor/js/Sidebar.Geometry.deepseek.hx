import js.Browser.window;
import js.Lib.three;
import js.Lib.ui;
import js.Lib.SetGeometryValueCommand;
import js.Lib.SidebarGeometryBufferGeometry;
import js.Lib.SidebarGeometryModifiers;
import js.Lib.VertexNormalsHelper;

class SidebarGeometry {

    var editor:Dynamic;
    var strings:Dynamic;
    var signals:Dynamic;
    var container:Dynamic;
    var currentGeometryType:Dynamic;

    public function new(editor:Dynamic) {
        this.editor = editor;
        this.strings = editor.strings;
        this.signals = editor.signals;
        this.container = new ui.UIPanel();
        this.container.setBorderTop('0');
        this.container.setDisplay('none');
        this.container.setPaddingTop('20px');
        this.currentGeometryType = null;

        // Actions, type, uuid, name, parameters, buffergeometry, Size, Helpers, Export JSON, and build functions are omitted for brevity.

        signals.objectSelected.add(function () {
            this.currentGeometryType = null;
            this.build();
        });

        signals.geometryChanged.add(this.build);
    }

    function build() {
        var object = editor.selected;

        if (object && object.geometry) {
            var geometry = object.geometry;

            this.container.setDisplay('block');

            this.geometryType.setValue(geometry.type);

            this.geometryUUID.setValue(geometry.uuid);
            this.geometryName.setValue(geometry.name);

            // ...

            if (geometry.boundingBox === null) geometry.computeBoundingBox();

            var boundingBox = geometry.boundingBox;
            var x = Math.floor((boundingBox.max.x - boundingBox.min.x) * 1000) / 1000;
            var y = Math.floor((boundingBox.max.y - boundingBox.min.y) * 1000) / 1000;
            var z = Math.floor((boundingBox.max.z - boundingBox.min.z) * 1000) / 1000;

            this.geometryBoundingBox.setInnerHTML(`${x}<br/>${y}<br/>${z}`);

            this.helpersRow.setDisplay(geometry.hasAttribute('normal') ? '' : 'none');

        } else {
            this.container.setDisplay('none');
        }
    }
}
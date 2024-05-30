import js.THREE.OctahedronGeometry;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UIInteger;
import js.UINumber;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Dynamic) {
        var strings = editor.strings;
        var signals = editor.signals;
        var container = js.UIDiv_();

        var geometry = untyped object.geometry;
        var parameters = untyped geometry.parameters;

        var radiusRow = js.UIRow_();
        var radius = js.UINumber_parameters.radius;
        radius.onChange(update);

        radiusRow.add(js.UIText_(strings.getKey('sidebar/geometry/octahedron_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        var detailRow = js.UIRow_();
        var detail = js.UIInteger_parameters.detail;
        detail.setRange(0, Int.positiveInfinity);
        detail.onChange(update);

        detailRow.add(js.UIText_(strings.getKey('sidebar/geometry/octahedron_geometry/detail')).setClass('Label'));
        detailRow.add(detail);

        container.add(detailRow);

        function update() {
            var octahedronGeometry = js.THREE.OctahedronGeometry_radius(radius.getValue(), detail.getValue());
            editor.execute(SetGeometryCommand(editor, object, octahedronGeometry));
            signals.objectChanged.dispatch(object);
        }

        return container;
    }
}

class SetGeometryCommand {
    public function new(editor:Editor, object:Dynamic, geometry:Dynamic) {
        this.editor = editor;
        this.object = object;
        this.geometry = geometry;
    }

    public function execute():Void {
        // Implementation of the command execution
    }

    public function undo():Void {
        // Implementation of the command undo
    }

    private var editor:Editor;
    private var object:Dynamic;
    private var geometry:Dynamic;
}
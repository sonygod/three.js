import js.THREE.IcosahedronGeometry;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UIInteger;
import js.UINumber;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Dynamic) {
        var strings = editor.strings;
        var signals = editor.signals;
        var container = new UIDiv();
        var geometry = untyped object.geometry;
        var parameters = untyped geometry.parameters;

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius);
        radius.onChange(function() -> update());

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/icosahedron_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        var detailRow = new UIRow();
        var detail = new UIInteger(parameters.detail).setRange(0, Int.positiveInfinity);
        detail.onChange(function() -> update());

        detailRow.add(new UIText(strings.getKey('sidebar/geometry/icosahedron_geometry/detail')).setClass('Label'));
        detailRow.add(detail);

        container.add(detailRow);

        function update() {
            var newGeometry = new IcosahedronGeometry(radius.getValue(), detail.getValue());
            editor.execute(new SetGeometryCommand(editor, object, newGeometry));
            signals.objectChanged.dispatch(object);
        }

        return container;
    }
}

class SetGeometryCommand {
    public function new(editor:Editor, object:Dynamic, geometry:Dynamic) {
        // Implementation...
    }
}
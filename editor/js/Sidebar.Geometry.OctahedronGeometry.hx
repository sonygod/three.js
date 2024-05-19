package three.js.editor.js;

import js.three.*;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Object3D) {
        var strings = editor.strings;
        var signals = editor.signals;

        var container = new UIDiv();

        var geometry:Geometry = object.geometry;
        var parameters = geometry.parameters;

        // radius
        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius);
        radius.onChange(update);

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/octahedron_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        // detail
        var detailRow = new UIRow();
        var detail = new UIInteger(parameters.detail);
        detail.setRange(0, Math.POSITIVE_INFINITY);
        detail.onChange(update);

        detailRow.add(new UIText(strings.getKey('sidebar/geometry/octahedron_geometry/detail')).setClass('Label'));
        detailRow.add(detail);

        container.add(detailRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new OctahedronGeometry(radius.getValue(), detail.getValue())));
            signals.objectChanged.dispatch(object);
        }

        return container;
    }
}
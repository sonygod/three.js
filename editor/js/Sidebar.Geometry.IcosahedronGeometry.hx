package three.js.editor.js;

import three.js.THREE;

import js.ui.UIDiv;
import js.ui.UIRow;
import js.ui.UIText;
import js.ui.UIInteger;
import js.ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Dynamic, object:Dynamic) {
        var strings = editor.strings;
        var signals = editor.signals;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // radius
        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius);
        radius.onChange = update;

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/icosahedron_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        // detail
        var detailRow = new UIRow();
        var detail = new UIInteger(parameters.detail);
        detail.setRange(0, Math.POSITIVE_INFINITY);
        detail.onChange = update;

        detailRow.add(new UIText(strings.getKey('sidebar/geometry/icosahedron_geometry/detail')).setClass('Label'));
        detailRow.add(detail);

        container.add(detailRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new THREE.IcosahedronGeometry(radius.getValue(), detail.getValue())));
            signals.objectChanged.dispatch(object);
        }

        return container;
    }
}
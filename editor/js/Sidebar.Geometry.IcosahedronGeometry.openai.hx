package three.js.editor.js;

import three.js.Three;

import js.ui.UIDiv;
import js.ui.UIRow;
import js.ui.UIText;
import js.ui.UIInteger;
import js.ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor: Editor, object: Object3D) {
        var strings = editor.strings;
        var signals = editor.signals;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // radius

        var radiusRow = new UIRow();
        var radiusInput = new UINumber(parameters.radius);
        radiusInput.onChange = update;

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/icosahedron_geometry/radius')).setClass('Label'));
        radiusRow.add(radiusInput);

        container.add(radiusRow);

        // detail

        var detailRow = new UIRow();
        var detailInput = new UIInteger(parameters.detail);
        detailInput.setRange(0, Math.POSITIVE_INFINITY);
        detailInput.onChange = update;

        detailRow.add(new UIText(strings.getKey('sidebar/geometry/icosahedron_geometry/detail')).setClass('Label'));
        detailRow.add(detailInput);

        container.add(detailRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new Three.IcosahedronGeometry(radiusInput.getValue(), detailInput.getValue())));
            signals.objectChanged.dispatch(object);
        }

        return container;
    }
}
package three.js.editor.js;

import three.*;

import js.lib.ui.UIDiv;
import js.lib.ui.UIRow;
import js.lib.ui.UIText;
import js.lib.ui.UIInteger;
import js.lib.ui.UIButton;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Object3D) {
        var strings = editor.strings;

        var container = new UIDiv();

        var geometry:Geometry = object.geometry;
        var parameters = geometry.parameters;

        // curveSegments
        var curveSegmentsRow = new UIRow();
        var curveSegments = new UIInteger(parameters.curveSegments == null ? 12 : parameters.curveSegments).onChange(changeShape).setRange(1, Math.POSITIVE_INFINITY);

        curveSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/shape_geometry/curveSegments')).setClass('Label'));
        curveSegmentsRow.add(curveSegments);

        container.add(curveSegmentsRow);

        // to extrude
        var button = new UIButton(strings.getKey('sidebar/geometry/shape_geometry/extrude')).onClick(toExtrude).setClass('Label').setMarginLeft('120px');
        container.add(button);

        function changeShape() {
            editor.execute(new SetGeometryCommand(editor, object, new ShapeGeometry(parameters.shapes, curveSegments.getValue())));
        }

        function toExtrude() {
            editor.execute(new SetGeometryCommand(editor, object, new ExtrudeGeometry(parameters.shapes, { curveSegments: curveSegments.getValue() })));
        }

        return container;
    }
}
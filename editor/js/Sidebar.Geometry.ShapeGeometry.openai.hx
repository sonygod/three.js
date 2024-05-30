package three.js.editor.js;

import three.js.Three;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UIButton;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Object3D) {
        var strings = editor.strings;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // curveSegments
        var curveSegmentsRow = new UIRow();
        var curveSegments = new UIInteger(parameters.curveSegments != null ? parameters.curveSegments : 12);
        curveSegments.onChange(changeShape);
        curveSegments.setRange(1, Math.POSITIVE_INFINITY);

        curveSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/shape_geometry/curveSegments')).setClass('Label'));
        curveSegmentsRow.add(curveSegments);

        container.add(curveSegmentsRow);

        // to extrude
        var button = new UIButton(strings.getKey('sidebar/geometry/shape_geometry/extrude'));
        button.onClick(toExtrude);
        button.setClass('Label');
        button.setMarginLeft('120px');
        container.add(button);

        function changeShape() {
            editor.execute(new SetGeometryCommand(editor, object, new Three.ShapeGeometry(parameters.shapes, curveSegments.getValue())));
        }

        function toExtrude() {
            editor.execute(new SetGeometryCommand(editor, object, new Three.ExtrudeGeometry(parameters.shapes, { curveSegments: curveSegments.getValue() })));
        }

        return container;
    }
}
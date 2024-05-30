import js.THREE;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UIInteger;
import js.UIButton;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Dynamic) {
        var strings = editor.strings;
        var container = new UIDiv();
        var geometry = untyped object.geometry;
        var parameters = untyped geometry.parameters;

        var curveSegmentsRow = new UIRow();
        var curveSegments = new UIInteger(parameters.curveSegments as Int ? 12).onChange(changeShape).setRange(1, Int.positiveInfinity);

        curveSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/shape_geometry/curveSegments')).setClass('Label'));
        curveSegmentsRow.add(curveSegments);

        container.add(curveSegmentsRow);

        var button = new UIButton(strings.getKey('sidebar/geometry/shape_geometry/extrude')).onClick(toExtrude).setClass('Label').setMarginLeft('120px');
        container.add(button);

        function changeShape() {
            var shapeGeometry = new THREE.ShapeGeometry(parameters.shapes, curveSegments.getValue() as Int);
            editor.execute(new SetGeometryCommand(editor, object, shapeGeometry));
        }

        function toExtrude() {
            var extrudeGeometry = new THREE.ExtrudeGeometry(parameters.shapes, { curveSegments: curveSegments.getValue() as Int });
            editor.execute(new SetGeometryCommand(editor, object, extrudeGeometry));
        }

        return container;
    }
}

class SetGeometryCommand {
    public function new(editor:Editor, object:Dynamic, geometry:THREE.Geometry) {
        // Implementation...
    }
}
import three.THREE;
import ui.UI;
import commands.SetGeometryCommand;

class GeometryParametersPanel {

    public function new(editor:Editor, object:Object3D) {

        var strings = editor.strings;

        var container = new UI.UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // curveSegments

        var curveSegmentsRow = new UI.UIRow();
        var curveSegments = new UI.UIInteger(parameters.curveSegments != null ? parameters.curveSegments : 12).onChange(changeShape).setRange(1, Int.POSITIVE_INFINITY);

        curveSegmentsRow.add(new UI.UIText(strings.getKey('sidebar/geometry/shape_geometry/curveSegments')).setClass('Label'));
        curveSegmentsRow.add(curveSegments);

        container.add(curveSegmentsRow);

        // to extrude
        var button = new UI.UIButton(strings.getKey('sidebar/geometry/shape_geometry/extrude')).onClick(toExtrude).setClass('Label').setMarginLeft('120px');
        container.add(button);

        function changeShape() {
            editor.execute(new SetGeometryCommand(editor, object, new THREE.ShapeGeometry(
                parameters.shapes,
                curveSegments.getValue()
            )));
        }

        function toExtrude() {
            editor.execute(new SetGeometryCommand(editor, object, new THREE.ExtrudeGeometry(
                parameters.shapes, {
                    curveSegments: curveSegments.getValue()
                }
            )));
        }

        return container;
    }
}
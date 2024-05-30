import three.THREE;
import js.Browser.window;
import js.Lib.{UIDiv, UIRow, UIText, UIInteger, UIButton};
import js.Lib.commands.SetGeometryCommand;

class GeometryParametersPanel {

    public function new(editor:Dynamic, object:Dynamic) {

        var strings = editor.strings;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // curveSegments

        var curveSegmentsRow = new UIRow();
        var curveSegments = new UIInteger(untyped parameters.curveSegments || 12).onChange(changeShape).setRange(1, Infinity);

        curveSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/shape_geometry/curveSegments')).setClass('Label'));
        curveSegmentsRow.add(curveSegments);

        container.add(curveSegmentsRow);

        // to extrude
        var button = new UIButton(strings.getKey('sidebar/geometry/shape_geometry/extrude')).onClick(toExtrude).setClass('Label').setMarginLeft('120px');
        container.add(button);

        //

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
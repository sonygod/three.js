import js.Browser.document;
import js.html.Element;
import js.html.InputElement;
import js.html.LabelElement;
import js.three.Three;
import js.three.geometries.OctahedronGeometry;
import js.three.objects.Mesh;
import ui.UI;
import ui.elements.UINumber;
import ui.elements.UIInteger;
import ui.elements.UIRow;
import ui.elements.UIText;
import ui.elements.UIDiv;
import editor.Editor;
import editor.commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor: Editor, object: Mesh) {
        var strings = editor.strings;
        var signals = editor.signals;
        var container = new UIDiv();
        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // radius
        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius).onChange(update);

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/octahedron_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        // detail
        var detailRow = new UIRow();
        var detail = new UIInteger(parameters.detail).setRange(0, Int.POSITIVE_INFINITY).onChange(update);

        detailRow.add(new UIText(strings.getKey('sidebar/geometry/octahedron_geometry/detail')).setClass('Label'));
        detailRow.add(detail);

        container.add(detailRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new OctahedronGeometry(
                radius.getValue(),
                detail.getValue()
            )));

            signals.objectChanged.dispatch(object);
        }

        return container;
    }
}
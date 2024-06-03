import js.Browser.document;
import three.THREE;
import three.geometries.TorusKnotGeometry;
import ui.UI;
import ui.UIInteger;
import ui.UINumber;
import ui.UIRow;
import ui.UIText;
import ui.UIDiv;
import commands.SetGeometryCommand;
import editor.Editor;

class GeometryParametersPanel {

    public function new(editor: Editor, object: THREE.Object3D) {
        var strings = editor.strings;
        var container = new UIDiv();
        var geometry: TorusKnotGeometry = object.geometry;
        var parameters = geometry.parameters;

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius).onChange(update);
        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);
        container.add(radiusRow);

        var tubeRow = new UIRow();
        var tube = new UINumber(parameters.tube).onChange(update);
        tubeRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/tube')).setClass('Label'));
        tubeRow.add(tube);
        container.add(tubeRow);

        var tubularSegmentsRow = new UIRow();
        var tubularSegments = new UIInteger(parameters.tubularSegments).setRange(1, Int.POSITIVE_INFINITY).onChange(update);
        tubularSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/tubularsegments')).setClass('Label'));
        tubularSegmentsRow.add(tubularSegments);
        container.add(tubularSegmentsRow);

        var radialSegmentsRow = new UIRow();
        var radialSegments = new UIInteger(parameters.radialSegments).setRange(1, Int.POSITIVE_INFINITY).onChange(update);
        radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/radialsegments')).setClass('Label'));
        radialSegmentsRow.add(radialSegments);
        container.add(radialSegmentsRow);

        var pRow = new UIRow();
        var p = new UINumber(parameters.p).onChange(update);
        pRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/p')).setClass('Label'));
        pRow.add(p);
        container.add(pRow);

        var qRow = new UIRow();
        var q = new UINumber(parameters.q).onChange(update);
        qRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/q')).setClass('Label'));
        qRow.add(q);
        container.add(qRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new TorusKnotGeometry(
                radius.getValue(),
                tube.getValue(),
                tubularSegments.getValue(),
                radialSegments.getValue(),
                p.getValue(),
                q.getValue()
            )));
        }

        return container;
    }
}
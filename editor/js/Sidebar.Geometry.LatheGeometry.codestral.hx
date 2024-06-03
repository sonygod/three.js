import js.Browser.document;
import three.THREE;
import js.ui.UIDiv;
import js.ui.UIRow;
import js.ui.UIText;
import js.ui.UIInteger;
import js.ui.UINumber;
import js.ui.UIPoints2;
import js.commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Dynamic, object:Dynamic) {
        var strings = editor.strings;
        var container = new UIDiv();
        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // segments
        var segmentsRow = new UIRow();
        var segments = new UIInteger(parameters.segments);
        segments.onChange(update);
        segmentsRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/segments')).setClass('Label'));
        segmentsRow.add(segments);
        container.add(segmentsRow);

        // phiStart
        var phiStartRow = new UIRow();
        var phiStart = new UINumber(parameters.phiStart * 180 / Math.PI);
        phiStart.onChange(update);
        phiStartRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/phistart')).setClass('Label'));
        phiStartRow.add(phiStart);
        container.add(phiStartRow);

        // phiLength
        var phiLengthRow = new UIRow();
        var phiLength = new UINumber(parameters.phiLength * 180 / Math.PI);
        phiLength.onChange(update);
        phiLengthRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/philength')).setClass('Label'));
        phiLengthRow.add(phiLength);
        container.add(phiLengthRow);

        // points
        var pointsRow = new UIRow();
        pointsRow.add(new UIText(strings.getKey('sidebar/geometry/lathe_geometry/points')).setClass('Label'));
        var points = new UIPoints2();
        points.setValue(parameters.points);
        points.onChange(update);
        pointsRow.add(points);
        container.add(pointsRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new THREE.LatheGeometry(
                points.getValue(),
                segments.getValue(),
                phiStart.getValue() / 180 * Math.PI,
                phiLength.getValue() / 180 * Math.PI
            )));
        }

        return container;
    }
}
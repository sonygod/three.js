import js.three.THREE;
import js.ui.UIDiv;
import js.ui.UIRow;
import js.ui.UIText;
import js.ui.UIInteger;
import js.ui.UINumber;
import js.commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Dynamic, object:Dynamic) {
        var strings = editor.strings;
        var container = new UIDiv();
        var geometry = object.geometry;
        var parameters = geometry.parameters;

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius).onChange(update);
        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);
        container.add(radiusRow);

        var segmentsRow = new UIRow();
        var segments = new UIInteger(parameters.segments).setRange(3, Int.POSITIVE_INFINITY).onChange(update);
        segmentsRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/segments')).setClass('Label'));
        segmentsRow.add(segments);
        container.add(segmentsRow);

        var thetaStartRow = new UIRow();
        var thetaStart = new UINumber(parameters.thetaStart * THREE.MathUtils.RAD2DEG).setStep(10).onChange(update);
        thetaStartRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/thetastart')).setClass('Label'));
        thetaStartRow.add(thetaStart);
        container.add(thetaStartRow);

        var thetaLengthRow = new UIRow();
        var thetaLength = new UINumber(parameters.thetaLength * THREE.MathUtils.RAD2DEG).setStep(10).onChange(update);
        thetaLengthRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/thetalength')).setClass('Label'));
        thetaLengthRow.add(thetaLength);
        container.add(thetaLengthRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new THREE.CircleGeometry(
                radius.getValue(),
                segments.getValue(),
                thetaStart.getValue() * THREE.MathUtils.DEG2RAD,
                thetaLength.getValue() * THREE.MathUtils.DEG2RAD
            )));
        }

        return container;
    }
}
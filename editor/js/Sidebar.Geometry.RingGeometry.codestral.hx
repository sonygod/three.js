import js.Browser.document;
import three.THREE;
import three.core.Object3D;
import three.geometries.RingGeometry;
import editor.Editor;
import editor.commands.SetGeometryCommand;
import editor.ui.UIDiv;
import editor.ui.UIRow;
import editor.ui.UIText;
import editor.ui.UIInteger;
import editor.ui.UINumber;

class GeometryParametersPanel {
    public function new(editor: Editor, object: Object3D) {
        var strings = editor.strings;
        var container = new UIDiv();
        var geometry = object.geometry;
        var parameters = geometry.parameters;

        var innerRadiusRow = new UIRow();
        var innerRadius = new UINumber(parameters.innerRadius).onChange(update);

        innerRadiusRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/innerRadius')).setClass('Label'));
        innerRadiusRow.add(innerRadius);
        container.add(innerRadiusRow);

        var outerRadiusRow = new UIRow();
        var outerRadius = new UINumber(parameters.outerRadius).onChange(update);

        outerRadiusRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/outerRadius')).setClass('Label'));
        outerRadiusRow.add(outerRadius);
        container.add(outerRadiusRow);

        var thetaSegmentsRow = new UIRow();
        var thetaSegments = new UIInteger(parameters.thetaSegments).setRange(3, Int.POSITIVE_INFINITY).onChange(update);

        thetaSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/thetaSegments')).setClass('Label'));
        thetaSegmentsRow.add(thetaSegments);
        container.add(thetaSegmentsRow);

        var phiSegmentsRow = new UIRow();
        var phiSegments = new UIInteger(parameters.phiSegments).setRange(3, Int.POSITIVE_INFINITY).onChange(update);

        phiSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/phiSegments')).setClass('Label'));
        phiSegmentsRow.add(phiSegments);
        container.add(phiSegmentsRow);

        var thetaStartRow = new UIRow();
        var thetaStart = new UINumber(parameters.thetaStart * THREE.MathUtils.RAD2DEG).setStep(10).onChange(update);

        thetaStartRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/thetastart')).setClass('Label'));
        thetaStartRow.add(thetaStart);
        container.add(thetaStartRow);

        var thetaLengthRow = new UIRow();
        var thetaLength = new UINumber(parameters.thetaLength * THREE.MathUtils.RAD2DEG).setStep(10).onChange(update);

        thetaLengthRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/thetalength')).setClass('Label'));
        thetaLengthRow.add(thetaLength);
        container.add(thetaLengthRow);

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new RingGeometry(
                innerRadius.getValue(),
                outerRadius.getValue(),
                thetaSegments.getValue(),
                phiSegments.getValue(),
                thetaStart.getValue() * THREE.MathUtils.DEG2RAD,
                thetaLength.getValue() * THREE.MathUtils.DEG2RAD
            )));
        }

        return container;
    }
}
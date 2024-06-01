import three.core.Object3D;
import three.geometries.RingGeometry;
import three.math.MathUtils;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UINumber;

class GeometryParametersPanel extends UIDiv {

  public function new(editor : Editor, object : Object3D) {
    super();

    var geometry = cast(object.geometry, RingGeometry);
    var parameters = geometry.parameters;

    // innerRadius

    var innerRadiusRow = new UIRow();
    var innerRadius = new UINumber(parameters.innerRadius).onChange(update);

    innerRadiusRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/innerRadius')).setClass('Label'));
    innerRadiusRow.add(innerRadius);

    add(innerRadiusRow);

    // outerRadius

    var outerRadiusRow = new UIRow();
    var outerRadius = new UINumber(parameters.outerRadius).onChange(update);

    outerRadiusRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/outerRadius')).setClass('Label'));
    outerRadiusRow.add(outerRadius);

    add(outerRadiusRow);

    // thetaSegments

    var thetaSegmentsRow = new UIRow();
    var thetaSegments = new UIInteger(parameters.thetaSegments).setRange(3, Math.POSITIVE_INFINITY).onChange(update);

    thetaSegmentsRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/thetaSegments')).setClass('Label'));
    thetaSegmentsRow.add(thetaSegments);

    add(thetaSegmentsRow);

    // phiSegments

    var phiSegmentsRow = new UIRow();
    var phiSegments = new UIInteger(parameters.phiSegments).setRange(3, Math.POSITIVE_INFINITY).onChange(update);

    phiSegmentsRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/phiSegments')).setClass('Label'));
    phiSegmentsRow.add(phiSegments);

    add(phiSegmentsRow);

    // thetaStart

    var thetaStartRow = new UIRow();
    var thetaStart = new UINumber(parameters.thetaStart * MathUtils.RAD2DEG).setStep(10).onChange(update);

    thetaStartRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/thetastart')).setClass('Label'));
    thetaStartRow.add(thetaStart);

    add(thetaStartRow);

    // thetaLength

    var thetaLengthRow = new UIRow();
    var thetaLength = new UINumber(parameters.thetaLength * MathUtils.RAD2DEG).setStep(10).onChange(update);

    thetaLengthRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/thetalength')).setClass('Label'));
    thetaLengthRow.add(thetaLength);

    add(thetaLengthRow);

    function update(_) {
      editor.execute(new SetGeometryCommand(editor, object, new RingGeometry(
        innerRadius.getValue(),
        outerRadius.getValue(),
        thetaSegments.getValue(),
        phiSegments.getValue(),
        thetaStart.getValue() * MathUtils.DEG2RAD,
        thetaLength.getValue() * MathUtils.DEG2RAD
      )));
    }
  }
}
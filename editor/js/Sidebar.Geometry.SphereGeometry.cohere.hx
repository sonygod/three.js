import js.THREE.MathUtils;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UIInteger;
import js.UINumber;

import js.SetGeometryCommand;

function GeometryParametersPanel(editor:Editor, object:Dynamic) {
    var strings = editor.strings;
    var container = new UIDiv();
    var geometry = object.geometry;
    var parameters = geometry.parameters;

    var radiusRow = new UIRow();
    var radius = new UINumber(parameters.radius).onChange(update);

    radiusRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/radius')).setClass('Label'));
    radiusRow.add(radius);

    container.add(radiusRow);

    var widthSegmentsRow = new UIRow();
    var widthSegments = new UIInteger(parameters.widthSegments).setRange(1, Int.positiveInfinity).onChange(update);

    widthSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/widthsegments')).setClass('Label'));
    widthSegmentsRow.add(widthSegments);

    container.add(widthSegmentsRow);

    var heightSegmentsRow = new UIRow();
    var heightSegments = new UIInteger(parameters.heightSegments).setRange(1, Int.positiveInfinity).onChange(update);

    heightSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/heightsegments')).setClass('Label'));
    heightSegmentsRow.add(heightSegments);

    container.add(heightSegmentsRow);

    var phiStartRow = new UIRow();
    var phiStart = new UINumber(parameters.phiStart * MathUtils.RAD2DEG).setStep(10).onChange(update);

    phiStartRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/phistart')).setClass('Label'));
    phiStartRow.add(phiStart);

    container.add(phiStartRow);

    var phiLengthRow = new UIRow();
    var phiLength = new UINumber(parameters.phiLength * MathUtils.RAD2DEG).setStep(10).onChange(update);

    phiLengthRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/philength')).setClass('Label'));
    phiLengthRow.add(phiLength);

    container.add(phiLengthRow);

    var thetaStartRow = new UIRow();
    var thetaStart = new UINumber(parameters.thetaStart * MathUtils.RAD2DEG).setStep(10).onChange(update);

    thetaStartRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/thetastart')).setClass('Label'));
    thetaStartRow.add(thetaStart);

    container.add(thetaStartRow);

    var thetaLengthRow = new UIRow();
    var thetaLength = new UINumber(parameters.thetaLength * MathUtils.RAD2DEG).setStep(10).onChange(update);

    thetaLengthRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/thetalength')).setClass('Label'));
    thetaLengthRow.add(thetaLength);

    container.add(thetaLengthRow);

    function update() {
        editor.execute(new SetGeometryCommand(editor, object, new js.THREE.SphereGeometry(
            radius.getValue(),
            widthSegments.getValue(),
            heightSegments.getValue(),
            phiStart.getValue() * MathUtils.DEG2RAD,
            phiLength.getValue() * MathUtils.DEG2RAD,
            thetaStart.getValue() * MathUtils.DEG2RAD,
            thetaLength.getValue() * MathUtils.DEG2RAD
        )));
    }

    return container;
}

class GeometryParametersPanel {
}
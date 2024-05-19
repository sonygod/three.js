package three.js.editor.js;

import three.js.*;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Dynamic, object:Dynamic) {
        var strings = editor.strings;
        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // radius
        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius);
        radius.onChange = update;
        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);
        container.add(radiusRow);

        // widthSegments
        var widthSegmentsRow = new UIRow();
        var widthSegments = new UIInteger(parameters.widthSegments);
        widthSegments.setRange(1, Math.POSITIVE_INFINITY);
        widthSegments.onChange = update;
        widthSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/widthsegments')).setClass('Label'));
        widthSegmentsRow.add(widthSegments);
        container.add(widthSegmentsRow);

        // heightSegments
        var heightSegmentsRow = new UIRow();
        var heightSegments = new UIInteger(parameters.heightSegments);
        heightSegments.setRange(1, Math.POSITIVE_INFINITY);
        heightSegments.onChange = update;
        heightSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/heightsegments')).setClass('Label'));
        heightSegmentsRow.add(heightSegments);
        container.add(heightSegmentsRow);

        // phiStart
        var phiStartRow = new UIRow();
        var phiStart = new UINumber(parameters.phiStart * MathUtils.RAD2DEG);
        phiStart.setStep(10);
        phiStart.onChange = update;
        phiStartRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/phistart')).setClass('Label'));
        phiStartRow.add(phiStart);
        container.add(phiStartRow);

        // phiLength
        var phiLengthRow = new UIRow();
        var phiLength = new UINumber(parameters.phiLength * MathUtils.RAD2DEG);
        phiLength.setStep(10);
        phiLength.onChange = update;
        phiLengthRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/philength')).setClass('Label'));
        phiLengthRow.add(phiLength);
        container.add(phiLengthRow);

        // thetaStart
        var thetaStartRow = new UIRow();
        var thetaStart = new UINumber(parameters.thetaStart * MathUtils.RAD2DEG);
        thetaStart.setStep(10);
        thetaStart.onChange = update;
        thetaStartRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/thetastart')).setClass('Label'));
        thetaStartRow.add(thetaStart);
        container.add(thetaStartRow);

        // thetaLength
        var thetaLengthRow = new UIRow();
        var thetaLength = new UINumber(parameters.thetaLength * MathUtils.RAD2DEG);
        thetaLength.setStep(10);
        thetaLength.onChange = update;
        thetaLengthRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/thetalength')).setClass('Label'));
        thetaLengthRow.add(thetaLength);
        container.add(thetaLengthRow);

        //

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new SphereGeometry(
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
}
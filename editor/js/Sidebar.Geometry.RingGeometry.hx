package three.js.editor.js;

import three.js.Three;

import js.ui.UIDiv;
import js.ui.UIRow;
import js.ui.UIText;
import js.ui.UIInteger;
import js.ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Dynamic, object:Dynamic) {
        var strings = editor.strings;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // innerRadius

        var innerRadiusRow = new UIRow();
        var innerRadius = new UINumber(parameters.innerRadius);
        innerRadius.onChange = update;

        innerRadiusRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/innerRadius')).setClass('Label'));
        innerRadiusRow.add(innerRadius);

        container.add(innerRadiusRow);

        // outerRadius

        var outerRadiusRow = new UIRow();
        var outerRadius = new UINumber(parameters.outerRadius);
        outerRadius.onChange = update;

        outerRadiusRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/outerRadius')).setClass('Label'));
        outerRadiusRow.add(outerRadius);

        container.add(outerRadiusRow);

        // thetaSegments

        var thetaSegmentsRow = new UIRow();
        var thetaSegments = new UIInteger(parameters.thetaSegments);
        thetaSegments.setRange(3, Math.POSITIVE_INFINITY);
        thetaSegments.onChange = update;

        thetaSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/thetaSegments')).setClass('Label'));
        thetaSegmentsRow.add(thetaSegments);

        container.add(thetaSegmentsRow);

        // phiSegments

        var phiSegmentsRow = new UIRow();
        var phiSegments = new UIInteger(parameters.phiSegments);
        phiSegments.setRange(3, Math.POSITIVE_INFINITY);
        phiSegments.onChange = update;

        phiSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/phiSegments')).setClass('Label'));
        phiSegmentsRow.add(phiSegments);

        container.add(phiSegmentsRow);

        // thetaStart

        var thetaStartRow = new UIRow();
        var thetaStart = new UINumber(parameters.thetaStart * Three.MathUtils.RAD2DEG);
        thetaStart.setStep(10);
        thetaStart.onChange = update;

        thetaStartRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/thetastart')).setClass('Label'));
        thetaStartRow.add(thetaStart);

        container.add(thetaStartRow);

        // thetaLength

        var thetaLengthRow = new UIRow();
        var thetaLength = new UINumber(parameters.thetaLength * Three.MathUtils.RAD2DEG);
        thetaLength.setStep(10);
        thetaLength.onChange = update;

        thetaLengthRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/thetalength')).setClass('Label'));
        thetaLengthRow.add(thetaLength);

        container.add(thetaLengthRow);

        //

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new Three.RingGeometry(
                innerRadius.getValue(),
                outerRadius.getValue(),
                thetaSegments.getValue(),
                phiSegments.getValue(),
                thetaStart.getValue() * Three.MathUtils.DEG2RAD,
                thetaLength.getValue() * Three.MathUtils.DEG2RAD
            )));
        }

        return container;
    }
}

#elseif js
extern class GeometryParametersPanel {
    public static function create(editor:Dynamic, object:Dynamic):UIDiv {
        return new GeometryParametersPanel(editor, object);
    }
}
#end
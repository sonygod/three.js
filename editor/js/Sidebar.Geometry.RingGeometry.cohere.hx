import js.THREE.MathUtils;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UIInteger;
import js.UINumber;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Dynamic) {
        var container = new UIDiv();
        var geometry = untyped object.geometry;
        var parameters = untyped geometry.parameters;

        var innerRadiusRow = new UIRow();
        var innerRadius = new UINumber(parameters.innerRadius).onChange(update);

        innerRadiusRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/innerRadius')).setClass('Label'));
        innerRadiusRow.add(innerRadius);

        container.add(innerRadiusRow);

        var outerRadiusRow = new UIRow();
        var outerRadius = new UINumber(parameters.outerRadius).onChange(update);

        outerRadiusRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/outerRadius')).setClass('Label'));
        outerRadiusRow.add(outerRadius);

        container.add(outerRadiusRow);

        var thetaSegmentsRow = new UIRow();
        var thetaSegments = new UIInteger(parameters.thetaSegments).setRange(3, Int.posInfinity).onChange(update);

        thetaSegmentsRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/thetaSegments')).setClass('Label'));
        thetaSegmentsRow.add(thetaSegments);

        container.add(thetaSegmentsRow);

        var phiSegmentsRow = new UIRow();
        var phiSegments = new UIInteger(parameters.phiSegments).setRange(3, Int.posInfinity).onChange(update);

        phiSegmentsRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/phiSegments')).setClass('Label'));
        phiSegmentsRow.add(phiSegments);

        container.add(phiSegmentsRow);

        var thetaStartRow = new UIRow();
        var thetaStart = new UINumber(parameters.thetaStart * MathUtils.RAD2DEG).setStep(10).onChange(update);

        thetaStartRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/thetastart')).setClass('Label'));
        thetaStartRow.add(thetaStart);

        container.add(thetaStartRow);

        var thetaLengthRow = new UIRow();
        var thetaLength = new UINumber(parameters.thetaLength * MathUtils.RAD2DEG).setStep(10).onChange(update);

        thetaLengthRow.add(new UIText(editor.strings.getKey('sidebar/geometry/ring_geometry/thetalength')).setClass('Label'));
        thetaLengthRow.add(thetaLength);

        container.add(thetaLengthRow);

        function update() {
            var innerRadiusValue = innerRadius.getValue();
            var outerRadiusValue = outerRadius.getValue();
            var thetaSegmentsValue = thetaSegments.getValue();
            var phiSegmentsValue = phiSegments.getValue();
            var thetaStartValue = thetaStart.getValue() * MathUtils.DEG2RAD;
            var thetaLengthValue = thetaLength.getValue() * MathUtils.DEG2RAD;

            var newGeometry = new js.THREE.RingGeometry(
                innerRadiusValue,
                outerRadiusValue,
                thetaSegmentsValue,
                phiSegmentsValue,
                thetaStartValue,
                thetaLengthValue
            );

            editor.execute(new SetGeometryCommand(editor, object, newGeometry));
        }

        return container;
    }
}

class SetGeometryCommand {
    public function new(editor:Editor, object:Dynamic, geometry:Dynamic) {
        this.editor = editor;
        this.object = object;
        this.geometry = geometry;
    }

    public function do() {
        untyped this.object.geometry = this.geometry;
        this.editor.signal('updateSelection');
    }

    public function undo() {
        this.do();
    }
}
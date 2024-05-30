import three.THREE;
import js.Browser.window;
import js.Lib.{UIDiv, UIRow, UIText, UIInteger, UINumber};
import js.Lib.commands.SetGeometryCommand;

class GeometryParametersPanel {

    var strings:Dynamic;
    var container:UIDiv;
    var geometry:Dynamic;
    var parameters:Dynamic;
    var innerRadius:UINumber;
    var outerRadius:UINumber;
    var thetaSegments:UIInteger;
    var phiSegments:UIInteger;
    var thetaStart:UINumber;
    var thetaLength:UINumber;

    public function new(editor:Dynamic, object:Dynamic) {

        strings = editor.strings;

        container = new UIDiv();

        geometry = object.geometry;
        parameters = geometry.parameters;

        // innerRadius

        var innerRadiusRow = new UIRow();
        innerRadius = new UINumber(parameters.innerRadius).onChange(update);

        innerRadiusRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/innerRadius')).setClass('Label'));
        innerRadiusRow.add(innerRadius);

        container.add(innerRadiusRow);

        // outerRadius

        var outerRadiusRow = new UIRow();
        outerRadius = new UINumber(parameters.outerRadius).onChange(update);

        outerRadiusRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/outerRadius')).setClass('Label'));
        outerRadiusRow.add(outerRadius);

        container.add(outerRadiusRow);

        // thetaSegments

        var thetaSegmentsRow = new UIRow();
        thetaSegments = new UIInteger(parameters.thetaSegments).setRange(3, Infinity).onChange(update);

        thetaSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/thetaSegments')).setClass('Label'));
        thetaSegmentsRow.add(thetaSegments);

        container.add(thetaSegmentsRow);

        // phiSegments

        var phiSegmentsRow = new UIRow();
        phiSegments = new UIInteger(parameters.phiSegments).setRange(3, Infinity).onChange(update);

        phiSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/phiSegments')).setClass('Label'));
        phiSegmentsRow.add(phiSegments);

        container.add(phiSegmentsRow);

        // thetaStart

        var thetaStartRow = new UIRow();
        thetaStart = new UINumber(parameters.thetaStart * THREE.MathUtils.RAD2DEG).setStep(10).onChange(update);

        thetaStartRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/thetastart')).setClass('Label'));
        thetaStartRow.add(thetaStart);

        container.add(thetaStartRow);

        // thetaLength

        var thetaLengthRow = new UIRow();
        thetaLength = new UINumber(parameters.thetaLength * THREE.MathUtils.RAD2DEG).setStep(10).onChange(update);

        thetaLengthRow.add(new UIText(strings.getKey('sidebar/geometry/ring_geometry/thetalength')).setClass('Label'));
        thetaLengthRow.add(thetaLength);

        container.add(thetaLengthRow);

    }

    function update() {

        editor.execute(new SetGeometryCommand(editor, object, new THREE.RingGeometry(
            innerRadius.getValue(),
            outerRadius.getValue(),
            thetaSegments.getValue(),
            phiSegments.getValue(),
            thetaStart.getValue() * THREE.MathUtils.DEG2RAD,
            thetaLength.getValue() * THREE.MathUtils.DEG2RAD
        )));

    }

    public function getContainer():UIDiv {
        return container;
    }

}
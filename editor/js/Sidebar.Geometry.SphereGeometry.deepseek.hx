import three.THREE;
import js.Browser.window;
import js.Lib.{UIDiv, UIRow, UIText, UIInteger, UINumber};
import js.Lib.commands.SetGeometryCommand;

class GeometryParametersPanel {

    public function new(editor:Dynamic, object:Dynamic) {

        var strings = editor.strings;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // radius

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius).onChange(update);

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        // widthSegments

        var widthSegmentsRow = new UIRow();
        var widthSegments = new UIInteger(parameters.widthSegments).setRange(1, Infinity).onChange(update);

        widthSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/widthsegments')).setClass('Label'));
        widthSegmentsRow.add(widthSegments);

        container.add(widthSegmentsRow);

        // heightSegments

        var heightSegmentsRow = new UIRow();
        var heightSegments = new UIInteger(parameters.heightSegments).setRange(1, Infinity).onChange(update);

        heightSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/heightsegments')).setClass('Label'));
        heightSegmentsRow.add(heightSegments);

        container.add(heightSegmentsRow);

        // phiStart

        var phiStartRow = new UIRow();
        var phiStart = new UINumber(parameters.phiStart * THREE.MathUtils.RAD2DEG).setStep(10).onChange(update);

        phiStartRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/phistart')).setClass('Label'));
        phiStartRow.add(phiStart);

        container.add(phiStartRow);

        // phiLength

        var phiLengthRow = new UIRow();
        var phiLength = new UINumber(parameters.phiLength * THREE.MathUtils.RAD2DEG).setStep(10).onChange(update);

        phiLengthRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/philength')).setClass('Label'));
        phiLengthRow.add(phiLength);

        container.add(phiLengthRow);

        // thetaStart

        var thetaStartRow = new UIRow();
        var thetaStart = new UINumber(parameters.thetaStart * THREE.MathUtils.RAD2DEG).setStep(10).onChange(update);

        thetaStartRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/thetastart')).setClass('Label'));
        thetaStartRow.add(thetaStart);

        container.add(thetaStartRow);

        // thetaLength

        var thetaLengthRow = new UIRow();
        var thetaLength = new UINumber(parameters.thetaLength * THREE.MathUtils.RAD2DEG).setStep(10).onChange(update);

        thetaLengthRow.add(new UIText(strings.getKey('sidebar/geometry/sphere_geometry/thetalength')).setClass('Label'));
        thetaLengthRow.add(thetaLength);

        container.add(thetaLengthRow);

        function update() {

            editor.execute(new SetGeometryCommand(editor, object, new THREE.SphereGeometry(
                radius.getValue(),
                widthSegments.getValue(),
                heightSegments.getValue(),
                phiStart.getValue() * THREE.MathUtils.DEG2RAD,
                phiLength.getValue() * THREE.MathUtils.DEG2RAD,
                thetaStart.getValue() * THREE.MathUtils.DEG2RAD,
                thetaLength.getValue() * THREE.MathUtils.DEG2RAD
            )));

        }

        return container;

    }

}
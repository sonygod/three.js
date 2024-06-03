import three.THREE;
import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UINumber;
import commands.SetGeometryCommand;

class GeometryParametersPanel {

    public function new(editor:Editor, object:Object3D) {

        var strings = editor.strings;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // radius

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius).onChange(update);

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        // tube

        var tubeRow = new UIRow();
        var tube = new UINumber(parameters.tube).onChange(update);

        tubeRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/tube')).setClass('Label'));
        tubeRow.add(tube);

        container.add(tubeRow);

        // radialSegments

        var radialSegmentsRow = new UIRow();
        var radialSegments = new UIInteger(parameters.radialSegments).setRange(1, Float.POSITIVE_INFINITY).onChange(update);

        radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/radialsegments')).setClass('Label'));
        radialSegmentsRow.add(radialSegments);

        container.add(radialSegmentsRow);

        // tubularSegments

        var tubularSegmentsRow = new UIRow();
        var tubularSegments = new UIInteger(parameters.tubularSegments).setRange(1, Float.POSITIVE_INFINITY).onChange(update);

        tubularSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/tubularsegments')).setClass('Label'));
        tubularSegmentsRow.add(tubularSegments);

        container.add(tubularSegmentsRow);

        // arc

        var arcRow = new UIRow();
        var arc = new UINumber(parameters.arc * THREE.MathUtils.RAD2DEG).setStep(10).onChange(update);

        arcRow.add(new UIText(strings.getKey('sidebar/geometry/torus_geometry/arc')).setClass('Label'));
        arcRow.add(arc);

        container.add(arcRow);


        //

        function update() {

            editor.execute(new SetGeometryCommand(editor, object, new THREE.TorusGeometry(
                radius.getValue(),
                tube.getValue(),
                radialSegments.getValue(),
                tubularSegments.getValue(),
                arc.getValue() * THREE.MathUtils.DEG2RAD
            )));

        }

        return container;

    }

}
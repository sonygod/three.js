import js.THREE.Geometry;
import js.THREE.MathUtils;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UIInteger;
import js.UINumber;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Dynamic) {
        var strings = editor.strings;
        var container = js.UIDiv_construct();
        var geometry = object.geometry;
        var parameters = geometry.parameters;

        var radiusRow = js.UIRow_construct();
        var radius = js.UINumber_construct(parameters.radius);
        radius.onChange(update);

        radiusRow.add(js.UIText_construct(strings.getKey('sidebar/geometry/torus_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        var tubeRow = js.UIRow_construct();
        var tube = js.UINumber_construct(parameters.tube);
        tube.onChange(update);

        tubeRow.add(js.UIText_construct(strings.getKey('sidebar/geometry/torus_geometry/tube')).setClass('Label'));
        tubeRow.add(tube);

        container.add(tubeRow);

        var radialSegmentsRow = js.UIRow_construct();
        var radialSegments = js.UIInteger_construct(parameters.radialSegments);
        radialSegments.setRange(1, Int.POSITIVE_INFINITY);
        radialSegments.onChange(update);

        radialSegmentsRow.add(js.UIText_construct(strings.getKey('sidebar/geometry/torus_geometry/radialsegments')).setClass('Label'));
        radialSegmentsRow.add(radialSegments);

        container.add(radialSegmentsRow);

        var tubularSegmentsRow = js.UIRow_construct();
        var tubularSegments = js.UIInteger_construct(parameters.tubularSegments);
        tubularSegments.setRange(1, Int.POSITIVE_INFINITY);
        tubularSegments.onChange(update);

        tubularSegmentsRow.add(js.UIText_construct(strings.getKey('sidebar/geometry/torus_geometry/tubularsegments')).setClass('Label'));
        tubularSegmentsRow.add(tubularSegments);

        container.add(tubularSegmentsRow);

        var arcRow = js.UIRow_construct();
        var arc = js.UINumber_construct(parameters.arc * js.THREE.MathUtils.RAD2DEG);
        arc.setStep(10);
        arc.onChange(update);

        arcRow.add(js.UIText_construct(strings.getKey('sidebar/geometry/torus_geometry/arc')).setClass('Label'));
        arcRow.add(arc);

        container.add(arcRow);

        function update() {
            editor.execute(SetGeometryCommand(editor, object, js.THREE.TorusGeometry(
                radius.getValue(),
                tube.getValue(),
                radialSegments.getValue(),
                tubularSegments.getValue(),
                arc.getValue() * js.THREE.MathUtils.DEG2RAD
            )));
        }

        return container;
    }
}

class SetGeometryCommand {
    public function new(editor:Editor, object:Dynamic, geometry:Geometry) {
        this.editor = editor;
        this.object = object;
        this.geometry = geometry;
    }
}
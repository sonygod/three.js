import js.THREE.TorusKnotGeometry;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UIInteger;
import js.UINumber;

class GeometryParametersPanel {
    static public function create(editor:Dynamic, object:Dynamic) {
        var strings = editor.strings;
        var container = new UIDiv();
        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // radius
        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius).onChange(update);

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        // tube
        var tubeRow = new UIRow();
        var tube = new UINumber(parameters.tube).onChange(update);

        tubeRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/tube')).setClass('Label'));
        tubeRow.add(tube);

        container.add(tubeRow);

        // tubularSegments
        var tubularSegmentsRow = new UIRow();
        var tubularSegments = new UIInteger(parameters.tubularSegments).setRange(1, Int.POSITIVE_INFINITY).onChange(update);

        tubularSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/tubularsegments')).setClass('Label'));
        tubularSegmentsRow.add(tubularSegments);

        container.add(tubularSegmentsRow);

        // radialSegments
        var radialSegmentsRow = new UIRow();
        var radialSegments = new UIInteger(parameters.radialSegments).setRange(1, Int.POSITIVE_INFINITY).onChange(update);

        radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/radialsegments')).setClass('Label'));
        radialSegmentsRow.add(radialSegments);

        container.add(radialSegmentsRow);

        // p
        var pRow = new UIRow();
        var p = new UINumber(parameters.p).onChange(update);

        pRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/p')).setClass('Label'));
        pRow.add(p);

        container.add(pRow);

        // q
        var qRow = new UIRow();
        var q = new UINumber(parameters.q).onChange(update);

        qRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/q')).setClass('Label'));
        qRow.add(q);

        container.add(qRow);

        // update function
        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new TorusKnotGeometry(
                radius.getValue(),
                tube.getValue(),
                tubularSegments.getValue(),
                radialSegments.getValue(),
                p.getValue(),
                q.getValue()
            )));
        }

        return container;
    }
}

class SetGeometryCommand {
    public function new(editor:Dynamic, object:Dynamic, geometry:Dynamic) {
        this.editor = editor;
        this.object = object;
        this.geometry = geometry;
    }
}
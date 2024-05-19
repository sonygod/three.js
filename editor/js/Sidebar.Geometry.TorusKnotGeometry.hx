package three.js.editor.js;

import three.js.*;

import js.ui.UIDiv;
import js.ui.UIRow;
import js.ui.UIText;
import js.ui.UIInteger;
import js.ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Object3D) {
        var strings = editor.strings;
        var container = new UIDiv();

        var geometry:Geometry = object.geometry;
        var parameters:Dynamic = geometry.parameters;

        // radius
        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius);
        radius.onChange = update;
        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);
        container.add(radiusRow);

        // tube
        var tubeRow = new UIRow();
        var tube = new UINumber(parameters.tube);
        tube.onChange = update;
        tubeRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/tube')).setClass('Label'));
        tubeRow.add(tube);
        container.add(tubeRow);

        // tubularSegments
        var tubularSegmentsRow = new UIRow();
        var tubularSegments = new UIInteger(parameters.tubularSegments);
        tubularSegments.setRange(1, Math.POSITIVE_INFINITY);
        tubularSegments.onChange = update;
        tubularSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/tubularsegments')).setClass('Label'));
        tubularSegmentsRow.add(tubularSegments);
        container.add(tubularSegmentsRow);

        // radialSegments
        var radialSegmentsRow = new UIRow();
        var radialSegments = new UIInteger(parameters.radialSegments);
        radialSegments.setRange(1, Math.POSITIVE_INFINITY);
        radialSegments.onChange = update;
        radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/radialsegments')).setClass('Label'));
        radialSegmentsRow.add(radialSegments);
        container.add(radialSegmentsRow);

        // p
        var pRow = new UIRow();
        var p = new UINumber(parameters.p);
        p.onChange = update;
        pRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/p')).setClass('Label'));
        pRow.add(p);
        container.add(pRow);

        // q
        var qRow = new UIRow();
        var q = new UINumber(parameters.q);
        q.onChange = update;
        qRow.add(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/q')).setClass('Label'));
        qRow.add(q);
        container.add(qRow);

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
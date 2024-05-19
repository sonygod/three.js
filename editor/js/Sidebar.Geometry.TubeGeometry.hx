package three.editor.js;

import three.*;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UISelect;
import ui.UICheckbox;
import ui.UINumber;
import ui.three.UIPoints3;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Object3D) {
        var strings = editor.strings;

        var container = new UIDiv();

        var geometry:Geometry = object.geometry;
        var parameters = geometry.parameters;

        // points

        var pointsRow = new UIRow();
        pointsRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/path')).setClass('Label'));

        var points = new UIPoints3();
        points.setValue(parameters.path.points);
        points.onChange(update);
        pointsRow.add(points);

        container.add(pointsRow);

        // radius

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius);
        radius.onChange(update);

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        // tubularSegments

        var tubularSegmentsRow = new UIRow();
        var tubularSegments = new UIInteger(parameters.tubularSegments);
        tubularSegments.onChange(update);

        tubularSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/tubularsegments')).setClass('Label'));
        tubularSegmentsRow.add(tubularSegments);

        container.add(tubularSegmentsRow);

        // radialSegments

        var radialSegmentsRow = new UIRow();
        var radialSegments = new UIInteger(parameters.radialSegments);
        radialSegments.onChange(update);

        radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/radialsegments')).setClass('Label'));
        radialSegmentsRow.add(radialSegments);

        container.add(radialSegmentsRow);

        // closed

        var closedRow = new UIRow();
        var closed = new UICheckbox(parameters.closed);
        closed.onChange(update);

        closedRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/closed')).setClass('Label'));
        closedRow.add(closed);

        container.add(closedRow);

        // curveType

        var curveTypeRow = new UIRow();
        var curveType = new UISelect();
        curveType.setOptions([{ value: 'centripetal', label: 'centripetal' }, { value: 'chordal', label: 'chordal' }, { value: 'catmullrom', label: 'catmullrom' }]);
        curveType.setValue(parameters.path.curveType);
        curveType.onChange(update);

        curveTypeRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/curvetype')).setClass('Label'));
        curveTypeRow.add(curveType);

        container.add(curveTypeRow);

        // tension

        var tensionRow = new UIRow();
        tensionRow.setDisplay(curveType.getValue() == 'catmullrom' ? '' : 'none');
        var tension = new UINumber(parameters.path.tension);
        tension.setStep(0.01);
        tension.onChange(update);

        tensionRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/tension')).setClass('Label'));
        tensionRow.add(tension);

        container.add(tensionRow);

        //

        function update() {
            tensionRow.setDisplay(curveType.getValue() == 'catmullrom' ? '' : 'none');

            editor.execute(new SetGeometryCommand(editor, object, new TubeGeometry(
                new CatmullRomCurve3(points.getValue(), closed.getValue(), curveType.getValue(), tension.getValue()),
                tubularSegments.getValue(),
                radius.getValue(),
                radialSegments.getValue(),
                closed.getValue()
            )));
        }

        return container;
    }
}
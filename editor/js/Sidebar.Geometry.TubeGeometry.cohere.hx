import js.three.TubeGeometry;
import js.three.CatmullRomCurve3;

import js.UIDiv;
import js.UIRow;
import js.UIText;
import js.UIInteger;
import js.UISelect;
import js.UICheckbox;
import js.UINumber;
import js.UIPoints3;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Dynamic) {
        var strings = editor.strings;
        var container = new UIDiv();
        var geometry = untyped object.geometry;
        var parameters = untyped geometry.parameters;

        var pointsRow = new UIRow();
        pointsRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/path')).setClass('Label'));
        var points = new UIPoints3().setValue(parameters.path.points).onChange(update);
        pointsRow.add(points);
        container.add(pointsRow);

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius).onChange(update);
        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);
        container.add(radiusRow);

        var tubularSegmentsRow = new UIRow();
        var tubularSegments = new UIInteger(parameters.tubularSegments).onChange(update);
        tubularSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/tubularsegments')).setClass('Label'));
        tubularSegmentsRow.add(tubularSegments);
        container.add(tubularSegmentsRow);

        var radialSegmentsRow = new UIRow();
        var radialSegments = new UIInteger(parameters.radialSegments).onChange(update);
        radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/radialsegments')).setClass('Label'));
        radialSegmentsRow.add(radialSegments);
        container.add(radialSegmentsRow);

        var closedRow = new UIRow();
        var closed = new UICheckbox(parameters.closed).onChange(update);
        closedRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/closed')).setClass('Label'));
        closedRow.add(closed);
        container.add(closedRow);

        var curveTypeRow = new UIRow();
        var curveType = new UISelect().setOptions({
            centripetal: 'centripetal',
            chordal: 'chordal',
            catmullrom: 'catmullrom'
        }).setValue(parameters.path.curveType).onChange(update);
        curveTypeRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/curvetype')).setClass('Label'));
        curveTypeRow.add(curveType);
        container.add(curveTypeRow);

        var tensionRow = new UIRow().setDisplay(if (curveType.getValue() == 'catmullrom') '' else 'none');
        var tension = new UINumber(parameters.path.tension).setStep(0.01).onChange(update);
        tensionRow.add(new UIText(strings.getKey('sidebar/geometry/tube_geometry/tension')).setClass('Label'));
        tensionRow.add(tension);
        container.add(tensionRow);

        function update() {
            tensionRow.setDisplay(if (curveType.getValue() == 'catmullrom') '' else 'none');
            var path = new CatmullRomCurve3(points.getValue(), closed.getValue(), curveType.getValue(), tension.getValue());
            var geometry = new TubeGeometry(path, tubularSegments.getValue(), radius.getValue(), radialSegments.getValue(), closed.getValue());
            editor.execute(new SetGeometryCommand(editor, object, geometry));
        }

        return container;
    }
}
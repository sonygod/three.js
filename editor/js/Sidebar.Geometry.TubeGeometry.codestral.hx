import three.THREE;
import ui.UI;

class GeometryParametersPanel {

    private var editor:Editor;
    private var object:Dynamic;
    private var strings:Dynamic;
    private var container:UI.UIDiv;
    private var geometry:Dynamic;
    private var parameters:Dynamic;
    private var points:UI.UIPoints3;
    private var radius:UI.UINumber;
    private var tubularSegments:UI.UIInteger;
    private var radialSegments:UI.UIInteger;
    private var closed:UI.UICheckbox;
    private var curveType:UI.UISelect;
    private var tensionRow:UI.UIRow;
    private var tension:UI.UINumber;

    public function new(editor:Editor, object:Dynamic) {
        this.editor = editor;
        this.object = object;
        this.strings = editor.strings;

        this.container = new UI.UIDiv();
        this.geometry = object.geometry;
        this.parameters = this.geometry.parameters;

        // points
        var pointsRow = new UI.UIRow();
        pointsRow.add(new UI.UIText(this.strings.getKey('sidebar/geometry/tube_geometry/path')).setClass('Label'));
        this.points = new UI.UIPoints3().setValue(this.parameters.path.points).onChange(update);
        pointsRow.add(this.points);
        this.container.add(pointsRow);

        // radius
        var radiusRow = new UI.UIRow();
        this.radius = new UI.UINumber(this.parameters.radius).onChange(update);
        radiusRow.add(new UI.UIText(this.strings.getKey('sidebar/geometry/tube_geometry/radius')).setClass('Label'));
        radiusRow.add(this.radius);
        this.container.add(radiusRow);

        // tubularSegments
        var tubularSegmentsRow = new UI.UIRow();
        this.tubularSegments = new UI.UIInteger(this.parameters.tubularSegments).onChange(update);
        tubularSegmentsRow.add(new UI.UIText(this.strings.getKey('sidebar/geometry/tube_geometry/tubularsegments')).setClass('Label'));
        tubularSegmentsRow.add(this.tubularSegments);
        this.container.add(tubularSegmentsRow);

        // radialSegments
        var radialSegmentsRow = new UI.UIRow();
        this.radialSegments = new UI.UIInteger(this.parameters.radialSegments).onChange(update);
        radialSegmentsRow.add(new UI.UIText(this.strings.getKey('sidebar/geometry/tube_geometry/radialsegments')).setClass('Label'));
        radialSegmentsRow.add(this.radialSegments);
        this.container.add(radialSegmentsRow);

        // closed
        var closedRow = new UI.UIRow();
        this.closed = new UI.UICheckbox(this.parameters.closed).onChange(update);
        closedRow.add(new UI.UIText(this.strings.getKey('sidebar/geometry/tube_geometry/closed')).setClass('Label'));
        closedRow.add(this.closed);
        this.container.add(closedRow);

        // curveType
        var curveTypeRow = new UI.UIRow();
        this.curveType = new UI.UISelect().setOptions({centripetal: 'centripetal', chordal: 'chordal', catmullrom: 'catmullrom'}).setValue(this.parameters.path.curveType).onChange(update);
        curveTypeRow.add(new UI.UIText(this.strings.getKey('sidebar/geometry/tube_geometry/curvetype')).setClass('Label'), this.curveType);
        this.container.add(curveTypeRow);

        // tension
        this.tensionRow = new UI.UIRow().setDisplay(this.curveType.getValue() == 'catmullrom' ? '' : 'none');
        this.tension = new UI.UINumber(this.parameters.path.tension).setStep(0.01).onChange(update);
        this.tensionRow.add(new UI.UIText(this.strings.getKey('sidebar/geometry/tube_geometry/tension')).setClass('Label'), this.tension);
        this.container.add(this.tensionRow);
    }

    private function update():Void {
        this.tensionRow.setDisplay(this.curveType.getValue() == 'catmullrom' ? '' : 'none');
        this.editor.execute(new SetGeometryCommand(this.editor, this.object, new THREE.TubeGeometry(
            new THREE.CatmullRomCurve3(this.points.getValue(), this.closed.getValue(), this.curveType.getValue(), this.tension.getValue()),
            this.tubularSegments.getValue(),
            this.radius.getValue(),
            this.radialSegments.getValue(),
            this.closed.getValue()
        )));
    }

    public function getContainer():UI.UIDiv {
        return this.container;
    }
}
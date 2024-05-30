import js.three.Geometry;
import js.three.LatheGeometry;
import js.three.Object3D;

class GeometryParametersPanel {
    public function new(editor:Editor, object:Object3D) {
        var container = js.browser.window.document.createElement('div');
        var geometry = object.geometry as Geometry;
        var parameters = geometry.parameters;

        var segmentsRow = js.browser.window.document.createElement('div');
        var segments = js.browser.window.document.createElement('input');
        segments.type = 'number';
        segments.value = Std.string(parameters.segments);
        segments.onchange = update;

        var segmentsLabel = js.browser.window.document.createElement('span');
        segmentsLabel.innerText = editor.strings.getKey('sidebar/geometry/lathe_geometry/segments');

        segmentsRow.appendChild(segmentsLabel);
        segmentsRow.appendChild(segments);
        container.appendChild(segmentsRow);

        var phiStartRow = js.browser.window.document.createElement('div');
        var phiStart = js.browser.window.document.createElement('input');
        phiStart.type = 'number';
        phiStart.value = Std.string(parameters.phiStart * 180 / Math.PI);
        phiStart.onchange = update;

        var phiStartLabel = js.browser.window.document.createElement('span');
        phiStartLabel.innerText = editor.strings.getKey('sidebar/geometry/lathe_geometry/phistart');

        phiStartRow.appendChild(phiStartLabel);
        phiStartRow.appendChild(phiStart);
        container.appendChild(phiStartRow);

        var phiLengthRow = js.browser.window.document.createElement('div');
        var phiLength = js.browser.window.document.createElement('input');
        phiLength.type = 'number';
        phiLength.value = Std.string(parameters.phiLength * 180 / Math.PI);
        phiLength.onchange = update;

        var phiLengthLabel = js.browser.window.document.createElement('span');
        phiLengthLabel.innerText = editor.strings.getKey('sidebar/geometry/lathe_geometry/philength');

        phiLengthRow.appendChild(phiLengthLabel);
        phiLengthRow.appendChild(phiLength);
        container.appendChild(phiLengthRow);

        var pointsRow = js.browser.window.document.createElement('div');
        var pointsLabel = js.browser.window.document.createElement('span');
        pointsLabel.innerText = editor.strings.getKey('sidebar/geometry/lathe_geometry/points');
        pointsRow.appendChild(pointsLabel);

        var points = js.browser.window.document.createElement('input');
        points.type = 'text';
        points.value = parameters.points.toString();
        points.onchange = update;
        pointsRow.appendChild(points);
        container.appendChild(pointsRow);

        function update() {
            var pointsArray = points.value.split(',').map(Std.parseInt);
            var newGeometry = new LatheGeometry(pointsArray, Std.parseInt(segments.value), phiStart.value / 180 * Math.PI, phiLength.value / 180 * Math.PI);
            editor.execute(new SetGeometryCommand(editor, object, newGeometry));
        }

        return container;
    }
}

class SetGeometryCommand {
    public function new(editor:Editor, object:Object3D, geometry:Geometry) {
        this.editor = editor;
        this.object = object;
        this.geometry = geometry;
    }

    public function do() {
        this.object.geometry = this.geometry;
        this.editor.select(null);
        this.editor.select(this.object);
    }

    public function undo() {
        this.editor.select(null);
        this.editor.select(this.object);
    }

    private var editor:Editor;
    private var object:Object3D;
    private var geometry:Geometry;
}
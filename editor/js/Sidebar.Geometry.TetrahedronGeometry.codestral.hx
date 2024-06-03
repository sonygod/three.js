import js.THREE.*;
import ui.*;
import commands.SetGeometryCommand;

class GeometryParametersPanel {

    private var editor:Editor;
    private var object:THREE.Object3D;

    private var strings:Strings;
    private var signals:Signals;

    private var container:UIDiv;
    private var geometry:THREE.TetrahedronGeometry;
    private var parameters:Dynamic;

    // radius
    private var radiusRow:UIRow;
    private var radius:UINumber;

    // detail
    private var detailRow:UIRow;
    private var detail:UIInteger;

    public function new(editor:Editor, object:THREE.Object3D) {
        this.editor = editor;
        this.object = object;

        this.strings = editor.strings;
        this.signals = editor.signals;

        this.container = new UIDiv();

        this.geometry = object.geometry;
        this.parameters = this.geometry.parameters;

        // radius
        this.radiusRow = new UIRow();
        this.radius = new UINumber(this.parameters.radius).onChange(this.update);

        this.radiusRow.add(new UIText(this.strings.getKey('sidebar/geometry/tetrahedron_geometry/radius')).setClass('Label'));
        this.radiusRow.add(this.radius);

        this.container.add(this.radiusRow);

        // detail
        this.detailRow = new UIRow();
        this.detail = new UIInteger(this.parameters.detail).setRange(0, Float.POSITIVE_INFINITY).onChange(this.update);

        this.detailRow.add(new UIText(this.strings.getKey('sidebar/geometry/tetrahedron_geometry/detail')).setClass('Label'));
        this.detailRow.add(this.detail);

        this.container.add(this.detailRow);
    }

    private function update():Void {
        this.editor.execute(new SetGeometryCommand(this.editor, this.object, new TetrahedronGeometry(
            this.radius.getValue(),
            this.detail.getValue()
        )));

        this.signals.objectChanged.dispatch(this.object);
    }

    public function getContainer():UIDiv {
        return this.container;
    }
}
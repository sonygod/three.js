import three.THREE;
import ui.UIElements;
import commands.SetGeometryCommand;

class GeometryParametersPanel {
    var editor: Editor;
    var object: Object;
    var strings: Strings;
    var signals: Signals;
    var container: UIDiv;
    var geometry: THREE.Geometry;
    var parameters: Object;
    var radiusRow: UIRow;
    var radius: UINumber;
    var detailRow: UIRow;
    var detail: UIInteger;

    function new(editor: Editor, object: Object) {
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
        this.radiusRow.add(new UIText(this.strings.getKey('sidebar/geometry/icosahedron_geometry/radius')).setClass('Label'));
        this.radiusRow.add(this.radius);
        this.container.add(this.radiusRow);

        // detail
        this.detailRow = new UIRow();
        this.detail = new UIInteger(this.parameters.detail).setRange(0, Int.POSITIVE_INFINITY).onChange(this.update);
        this.detailRow.add(new UIText(this.strings.getKey('sidebar/geometry/icosahedron_geometry/detail')).setClass('Label'));
        this.detailRow.add(this.detail);
        this.container.add(this.detailRow);
    }

    function update(): Void {
        this.editor.execute(new SetGeometryCommand(this.editor, this.object, new THREE.IcosahedronGeometry(
            this.radius.getValue(),
            this.detail.getValue()
        )));
        this.signals.objectChanged.dispatch(this.object);
    }
}
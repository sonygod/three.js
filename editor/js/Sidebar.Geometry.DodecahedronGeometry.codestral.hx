import js.html.UIElement;
import js.html.InputElement;
import js.html.LabelElement;
import js.html.Document;
import js.Browser;
import js.Boot;

import three.DodecahedronGeometry;
import three.Geometry;

import editor.strings.Strings;
import editor.ui.UIDiv;
import editor.ui.UIRow;
import editor.ui.UIText;
import editor.ui.UIInteger;
import editor.ui.UINumber;
import editor.commands.SetGeometryCommand;
import editor.Editor;
import editor.Object3D;

class GeometryParametersPanel {

    private var editor:Editor;
    private var object:Object3D;
    private var strings:Strings;
    private var container:UIDiv;
    private var geometry:Geometry;
    private var parameters:Dynamic;
    private var radius:UINumber;
    private var detail:UIInteger;

    public function new(editor:Editor, object:Object3D) {
        this.editor = editor;
        this.object = object;
        this.strings = editor.strings;
        this.container = new UIDiv();
        this.geometry = object.geometry;
        this.parameters = this.geometry.parameters;

        // radius
        var radiusRow = new UIRow();
        this.radius = new UINumber(this.parameters.radius).onChange(Boot.bind(this, this.update));
        radiusRow.add(new UIText(this.strings.getKey('sidebar/geometry/dodecahedron_geometry/radius')).setClass('Label'));
        radiusRow.add(this.radius);
        this.container.add(radiusRow);

        // detail
        var detailRow = new UIRow();
        this.detail = new UIInteger(this.parameters.detail).setRange(0, js.Math.POSITIVE_INFINITY).onChange(Boot.bind(this, this.update));
        detailRow.add(new UIText(this.strings.getKey('sidebar/geometry/dodecahedron_geometry/detail')).setClass('Label'));
        detailRow.add(this.detail);
        this.container.add(detailRow);
    }

    private function update():Void {
        this.editor.execute(new SetGeometryCommand(this.editor, this.object, new DodecahedronGeometry(
            this.radius.getValue(),
            this.detail.getValue()
        )));
    }

    public function getContainer():UIDiv {
        return this.container;
    }
}
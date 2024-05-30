package three.js.editor.js.Sidebar.Geometry;

import three.js.THREE;

import js.html.DivElement;
import js.html.SpanElement;
import js.Browser.console;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
    private var editor:Dynamic;
    private var object:Dynamic;
    private var container:UIDiv;
    private var geometry:Dynamic;
    private var parameters:Dynamic;
    private var radius:UINumber;
    private var detail:UIInteger;

    public function new(editor:Dynamic, object:Dynamic) {
        this.editor = editor;
        this.object = object;

        container = new UIDiv();

        geometry = object.geometry;
        parameters = geometry.parameters;

        // radius
        var radiusRow:UIRow = new UIRow();
        radius = new UINumber(parameters.radius);
        radius.onChange = update;
        radiusRow.add(new UIText(editor.strings.getKey('sidebar/geometry/tetrahedron_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);
        container.add(radiusRow);

        // detail
        var detailRow:UIRow = new UIRow();
        detail = new UIInteger(parameters.detail);
        detail.setRange(0, Math.POSITIVE_INFINITY);
        detail.onChange = update;
        detailRow.add(new UIText(editor.strings.getKey('sidebar/geometry/tetrahedron_geometry/detail')).setClass('Label'));
        detailRow.add(detail);
        container.add(detailRow);
    }

    private function update():Void {
        editor.execute(new SetGeometryCommand(editor, object, new THREE.TetrahedronGeometry(radius.getValue(), detail.getValue())));
        editor.signals.objectChanged.dispatch(object);
    }

    public function getContainer():UIDiv {
        return container;
    }
}
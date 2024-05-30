import js.THREE.DodecahedronGeometry;

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

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius);
        radius.onChange(function() update() {
            var detail = detail.getValue();
            editor.execute(new SetGeometryCommand(editor, object, new DodecahedronGeometry(radius.getValue(), detail)));
        });

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/dodecahedron_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);
        container.add(radiusRow);

        var detailRow = new UIRow();
        var detail = new UIInteger(parameters.detail).setRange(0, Int.positiveInfinity);
        detail.onChange(update);

        detailRow.add(new UIText(strings.getKey('sidebar/geometry/dodecahedron_geometry/detail')).setClass('Label'));
        detailRow.add(detail);
        container.add(detailRow);

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
import three.THREE;
import js.Browser.window;
import js.Lib.{UIDiv, UIRow, UIText, UIInteger, UINumber};
import js.Lib.SetGeometryCommand;

class GeometryParametersPanel {

    var strings:Dynamic;
    var signals:Dynamic;
    var container:UIDiv;
    var geometry:Dynamic;
    var parameters:Dynamic;
    var radius:UINumber;
    var radiusRow:UIRow;
    var detail:UIInteger;
    var detailRow:UIRow;

    public function new(editor:Dynamic, object:Dynamic) {

        strings = editor.strings;
        signals = editor.signals;
        container = new UIDiv();
        geometry = object.geometry;
        parameters = geometry.parameters;

        // radius
        radiusRow = new UIRow();
        radius = new UINumber(parameters.radius).onChange(update);
        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/icosahedron_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);
        container.add(radiusRow);

        // detail
        detailRow = new UIRow();
        detail = new UIInteger(parameters.detail).setRange(0, Infinity).onChange(update);
        detailRow.add(new UIText(strings.getKey('sidebar/geometry/icosahedron_geometry/detail')).setClass('Label'));
        detailRow.add(detail);
        container.add(detailRow);

    }

    function update() {

        editor.execute(new SetGeometryCommand(editor, object, new THREE.IcosahedronGeometry(
            radius.getValue(),
            detail.getValue()
        )));

        signals.objectChanged.dispatch(object);

    }

    public function getContainer():UIDiv {
        return container;
    }

}
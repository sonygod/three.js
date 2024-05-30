import three.THREE;
import js.Browser.window;
import js.Lib.{UIDiv, UIRow, UIText, UIInteger, UINumber};
import js.Lib.SetGeometryCommand;

class GeometryParametersPanel {

    public function new(editor:Dynamic, object:Dynamic) {

        var strings = editor.strings;

        var container = new UIDiv();

        var geometry = object.geometry;
        var parameters = geometry.parameters;

        // radius

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius).onChange(update);

        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/dodecahedron_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);

        container.add(radiusRow);

        // detail

        var detailRow = new UIRow();
        var detail = new UIInteger(parameters.detail).setRange(0, Infinity).onChange(update);

        detailRow.add(new UIText(strings.getKey('sidebar/geometry/dodecahedron_geometry/detail')).setClass('Label'));
        detailRow.add(detail);

        container.add(detailRow);

        //

        function update() {

            editor.execute(new SetGeometryCommand(editor, object, new THREE.DodecahedronGeometry(
                radius.getValue(),
                detail.getValue()
            )));

        }

        return container;

    }

}
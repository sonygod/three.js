package three.js.editor.js;

import three.js.THREE;
import js.lib.ui.UIDiv;
import js.lib.ui.UIRow;
import js.lib.ui.UIText;
import js.lib.ui.UIInteger;
import js.lib.ui.UINumber;
import commands.SetGeometryCommand;

class GeometryParametersPanel {
  public function new(editor:Dynamic, object:Dynamic) {
    var strings = editor.strings;
    var container = new UIDiv();

    var geometry:THREE.Geometry = object.geometry;
    var parameters:Dynamic = geometry.parameters;

    // radius
    var radiusRow:UIRow = new UIRow();
    var radius:UINumber = new UINumber(parameters.radius);
    radius.onChange = update;
    radiusRow.add(new UIText(strings.getKey('sidebar/geometry/dodecahedron_geometry/radius')).setClass('Label'));
    radiusRow.add(radius);
    container.add(radiusRow);

    // detail
    var detailRow:UIRow = new UIRow();
    var detail:UIInteger = new UIInteger(parameters.detail);
    detail.setRange(0, Math.POSITIVE_INFINITY);
    detail.onChange = update;
    detailRow.add(new UIText(strings.getKey('sidebar/geometry/dodecahedron_geometry/detail')).setClass('Label'));
    detailRow.add(detail);
    container.add(detailRow);

    function update():Void {
      editor.execute(new SetGeometryCommand(editor, object, new THREE.DodecahedronGeometry(radius.getValue(), detail.getValue())));
    }

    return container;
  }
}
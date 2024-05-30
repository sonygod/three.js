package three.js.editor.js;

import three.js.Lib;
import js.ui.UI;

class SidebarGeometryTorusKnotGeometry {
  static function GeometryParametersPanel(editor:Editor, object:Object3D) {
    var strings = editor.strings;

    var container = new UIDiv();

    var geometry = object.geometry;
    var parameters = geometry.parameters;

    // radius

    var radiusRow = new UIRow();
    var radius = new UINumber(parameters.radius);
    radius.onChange(update);

    radiusRow.addChild(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/radius')).addClass('Label'));
    radiusRow.addChild(radius);

    container.addChild(radiusRow);

    // tube

    var tubeRow = new UIRow();
    var tube = new UINumber(parameters.tube);
    tube.onChange(update);

    tubeRow.addChild(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/tube')).addClass('Label'));
    tubeRow.addChild(tube);

    container.addChild(tubeRow);

    // tubularSegments

    var tubularSegmentsRow = new UIRow();
    var tubularSegments = new UIInteger(parameters.tubularSegments);
    tubularSegments.setRange(1, Math.POSITIVE_INFINITY);
    tubularSegments.onChange(update);

    tubularSegmentsRow.addChild(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/tubularsegments')).addClass('Label'));
    tubularSegmentsRow.addChild(tubularSegments);

    container.addChild(tubularSegmentsRow);

    // radialSegments

    var radialSegmentsRow = new UIRow();
    var radialSegments = new UIInteger(parameters.radialSegments);
    radialSegments.setRange(1, Math.POSITIVE_INFINITY);
    radialSegments.onChange(update);

    radialSegmentsRow.addChild(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/radialsegments')).addClass('Label'));
    radialSegmentsRow.addChild(radialSegments);

    container.addChild(radialSegmentsRow);

    // p

    var pRow = new UIRow();
    var p = new UINumber(parameters.p);
    p.onChange(update);

    pRow.addChild(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/p')).addClass('Label'));
    pRow.addChild(p);

    container.addChild(pRow);

    // q

    var qRow = new UIRow();
    var q = new UINumber(parameters.q);
    q.onChange(update);

    qRow.addChild(new UIText(strings.getKey('sidebar/geometry/torusKnot_geometry/q')).addClass('Label'));
    qRow.addChild(q);

    container.addChild(qRow);

    function update() {
      editor.execute(new SetGeometryCommand(editor, object, new three.js.TorusKnotGeometry(
        radius.getValue(),
        tube.getValue(),
        tubularSegments.getValue(),
        radialSegments.getValue(),
        p.getValue(),
        q.getValue()
      )));
    }

    return container;
  }
}
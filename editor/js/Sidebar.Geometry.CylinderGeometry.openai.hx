package three.editor.js;

import js.three.Lib;
import js.three.CylinderGeometry;

import ui.UIDiv;
import ui.UIRow;
import ui.UIText;
import ui.UIInteger;
import ui.UICheckbox;
import ui.UINumber;

import commands.SetGeometryCommand;

class GeometryParametersPanel {
  public function new(editor:Dynamic, object:Dynamic) {
    var strings = editor.strings;
    var container = new UIDiv();

    var geometry = object.geometry;
    var parameters = geometry.parameters;

    // radiusTop
    var radiusTopRow = new UIRow();
    var radiusTop = new UINumber(parameters.radiusTop);
    radiusTop.onChange = update;
    radiusTopRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/radiustop')).setClass('Label'));
    radiusTopRow.add(radiusTop);
    container.add(radiusTopRow);

    // radiusBottom
    var radiusBottomRow = new UIRow();
    var radiusBottom = new UINumber(parameters.radiusBottom);
    radiusBottom.onChange = update;
    radiusBottomRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/radiusbottom')).setClass('Label'));
    radiusBottomRow.add(radiusBottom);
    container.add(radiusBottomRow);

    // height
    var heightRow = new UIRow();
    var height = new UINumber(parameters.height);
    height.onChange = update;
    heightRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/height')).setClass('Label'));
    heightRow.add(height);
    container.add(heightRow);

    // radialSegments
    var radialSegmentsRow = new UIRow();
    var radialSegments = new UIInteger(parameters.radialSegments);
    radialSegments.setRange(1, Math.POSITIVE_INFINITY);
    radialSegments.onChange = update;
    radialSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/radialsegments')).setClass('Label'));
    radialSegmentsRow.add(radialSegments);
    container.add(radialSegmentsRow);

    // heightSegments
    var heightSegmentsRow = new UIRow();
    var heightSegments = new UIInteger(parameters.heightSegments);
    heightSegments.setRange(1, Math.POSITIVE_INFINITY);
    heightSegments.onChange = update;
    heightSegmentsRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/heightsegments')).setClass('Label'));
    heightSegmentsRow.add(heightSegments);
    container.add(heightSegmentsRow);

    // openEnded
    var openEndedRow = new UIRow();
    var openEnded = new UICheckbox(parameters.openEnded);
    openEnded.onChange = update;
    openEndedRow.add(new UIText(strings.getKey('sidebar/geometry/cylinder_geometry/openended')).setClass('Label'));
    openEndedRow.add(openEnded);
    container.add(openEndedRow);

    function update() {
      editor.execute(new SetGeometryCommand(editor, object, new CylinderGeometry(
        radiusTop.getValue(),
        radiusBottom.getValue(),
        height.getValue(),
        radialSegments.getValue(),
        heightSegments.getValue(),
        openEnded.getValue()
      )));
    }

    return container;
  }
}

// Export the class
extern class GeometryParametersPanel {}
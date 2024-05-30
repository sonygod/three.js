package three.js.editor.js;

import three js.Three;
import js.ui.UIDiv;
import js.ui.UIRow;
import js.ui.UIText;
import js.ui.UIInteger;
import js.ui.UINumber;
import commands.SetGeometryCommand;

class GeometryParametersPanel {
    
    public function new(editor:Dynamic, object:Dynamic) {
        
        var strings = editor.strings;
        
        var container = new UIDiv();
        
        var geometry = object.geometry;
        var parameters = geometry.parameters;
        
        // radius

        var radiusRow = new UIRow();
        var radius = new UINumber(parameters.radius);
        radius.onChange = update;
        
        radiusRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/radius')).setClass('Label'));
        radiusRow.add(radius);
        
        container.add(radiusRow);

        // segments

        var segmentsRow = new UIRow();
        var segments = new UIInteger(parameters.segments);
        segments.setRange(3, Math.POSITIVE_INFINITY);
        segments.onChange = update;
        
        segmentsRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/segments')).setClass('Label'));
        segmentsRow.add(segments);
        
        container.add(segmentsRow);

        // thetaStart

        var thetaStartRow = new UIRow();
        var thetaStart = new UINumber(parameters.thetaStart * Three.MathUtils.RAD2DEG);
        thetaStart.setStep(10);
        thetaStart.onChange = update;
        
        thetaStartRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/thetastart')).setClass('Label'));
        thetaStartRow.add(thetaStart);
        
        container.add(thetaStartRow);

        // thetaLength

        var thetaLengthRow = new UIRow();
        var thetaLength = new UINumber(parameters.thetaLength * Three.MathUtils.RAD2DEG);
        thetaLength.setStep(10);
        thetaLength.onChange = update;
        
        thetaLengthRow.add(new UIText(strings.getKey('sidebar/geometry/circle_geometry/thetalength')).setClass('Label'));
        thetaLengthRow.add(thetaLength);
        
        container.add(thetaLengthRow);

        //

        function update() {
            editor.execute(new SetGeometryCommand(editor, object, new Three.CircleGeometry(
                radius.getValue(),
                segments.getValue(),
                thetaStart.getValue() * Three.MathUtils.DEG2RAD,
                thetaLength.getValue() * Three.MathUtils.DEG2RAD
            )));
        }
        
        return container;
    }
}
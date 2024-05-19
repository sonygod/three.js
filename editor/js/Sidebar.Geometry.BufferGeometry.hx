package three.js.editor.js;

import ui.UIRow;
import ui.UIText;
import ui.UISpan;
import ui.UIBreak;
import ui.UICheckbox;

class SidebarGeometryBufferGeometry {
  private var editor:Editor;
  private var strings:Strings;
  private var signals:Signals;
  private var container:UIRow;

  public function new(editor:Editor) {
    this.editor = editor;
    this.strings = editor.strings;
    this.signals = editor.signals;
    this.container = new UIRow();

    update(null);

    signals.objectSelected.add(update);
    signals.geometryChanged.add(update);
  }

  private function update(object:Dynamic) {
    if (object == null) return; // objectSelected.dispatch( null )
    if (object == null || object == undefined) return;

    var geometry:Geometry = object.geometry;

    if (geometry != null) {
      container.clear();
      container.setDisplay('block');

      // attributes

      var attributesRow:UIRow = new UIRow();

      var textAttributes:UIText = new UIText(strings.getKey('sidebar/geometry/buffer_geometry/attributes')).setClass('Label');
      attributesRow.add(textAttributes);

      var containerAttributes:UISpan = new UISpan().setDisplay('inline-block').setVerticalAlign('middle').setWidth('160px');
      attributesRow.add(containerAttributes);

      var index:Index = geometry.index;

      if (index != null) {
        containerAttributes.add(new UIText(strings.getKey('sidebar/geometry/buffer_geometry/index')).setWidth('80px'));
        containerAttributes.add(new UIText(editor.utils.formatNumber(index.count)).setFontSize('12px'));
        containerAttributes.add(new UIBreak());
      }

      var attributes:Dynamic = geometry.attributes;

      for (name in attributes) {
        var attribute:Dynamic = attributes[name];

        containerAttributes.add(new UIText(name).setWidth('80px'));
        containerAttributes.add(new UIText(editor.utils.formatNumber(attribute.count) + ' (' + attribute.itemSize + ')').setFontSize('12px'));
        containerAttributes.add(new UIBreak());
      }

      container.add(attributesRow);

      // morph targets

      var morphAttributes:Dynamic = geometry.morphAttributes;
      var hasMorphTargets:Bool = Lambda.count(morphAttributes) > 0;

      if (hasMorphTargets) {
        // morph attributes

        var rowMorphAttributes:UIRow = new UIRow();

        var textMorphAttributes:UIText = new UIText(strings.getKey('sidebar/geometry/buffer_geometry/morphAttributes')).setClass('Label');
        rowMorphAttributes.add(textMorphAttributes);

        var containerMorphAttributes:UISpan = new UISpan().setDisplay('inline-block').setVerticalAlign('middle').setWidth('160px');
        rowMorphAttributes.add(containerMorphAttributes);

        for (name in morphAttributes) {
          var morphTargets:Dynamic = morphAttributes[name];

          containerMorphAttributes.add(new UIText(name).setWidth('80px'));
          containerMorphAttributes.add(new UIText(editor.utils.formatNumber(morphTargets.length)).setFontSize('12px'));
          containerMorphAttributes.add(new UIBreak());
        }

        container.add(rowMorphAttributes);

        // morph relative

        var rowMorphRelative:UIRow = new UIRow();

        var textMorphRelative:UIText = new UIText(strings.getKey('sidebar/geometry/buffer_geometry/morphRelative')).setClass('Label');
        rowMorphRelative.add(textMorphRelative);

        var checkboxMorphRelative:UICheckbox = new UICheckbox().setValue(geometry.morphTargetsRelative).setDisabled(true);
        rowMorphRelative.add(checkboxMorphRelative);

        container.add(rowMorphRelative);
      }
    } else {
      container.setDisplay('none');
    }
  }
}
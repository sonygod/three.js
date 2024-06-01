package;

import three.THREE;

import ui.UIPanel;
import ui.UIBreak;
import ui.UIRow;
import ui.UIColor;
import ui.UISelect;
import ui.UIText;
import ui.UINumber;
import ui.three.UIOutliner;
import ui.three.UITexture;

import js.html.Element;

class SidebarScene {

  public function new(editor:Editor) {

    final signals = editor.signals;
    final strings = editor.strings;

    final container = new UIPanel();
    container.setBorderTop('0');
    container.setPaddingTop('20px');

    // outliner

    final nodeStates = new Map<THREE.Object3D, Bool>();

    function buildOption(object:THREE.Object3D, draggable:Bool):Element {

      final option = js.html.Document.createElement("div");
      option.draggable = draggable;
      option.innerHTML = buildHTML(object);
      option.value = Std.string(object.id);

      // opener

      if (nodeStates.exists(object)) {

        final state = nodeStates.get(object);

        final opener = js.html.Document.createElement("span");
        opener.classList.add('opener');

        if (object.children.length > 0) {

          if (state) {
            opener.classList.add('open');
          } else {
            opener.classList.add('closed');
          }

        }

        opener.addEventListener('click', function(_) {

          nodeStates.set(object, !nodeStates.get(object)); // toggle
          refreshUI();

        });

        option.insertBefore(opener, option.firstChild);

      }

      return option;

    }

    function getMaterialName(material:Dynamic):String {
      if (Std.isOfType(material, Array)) {
        final array:Array<String> = [];
        for (i in 0...cast(material, Array<THREE.Material>).length) {
          array.push(cast(material, Array<THREE.Material>)[i].name);
        }
        return array.join(',');
      }
      return cast(material, THREE.Material).name;
    }

    function escapeHTML(html:String):String {

      return html
        .replace('&', '&amp;')
        .replace('"', '&quot;')
        .replace('/', '&#39;')
        .replace('<', '&lt;')
        .replace('>', '&gt;');

    }

    function getObjectType(object:THREE.Object3D):String {

      if (Std.isOfType(object, THREE.Scene)) return 'Scene';
      if (Std.isOfType(object, THREE.Camera)) return 'Camera';
      if (Std.isOfType(object, THREE.Light)) return 'Light';
      if (Std.isOfType(object, THREE.Mesh)) return 'Mesh';
      if (Std.isOfType(object, THREE.Line)) return 'Line';
      if (Std.isOfType(object, THREE.Points)) return 'Points';

      return 'Object3D';

    }

    function buildHTML(object:THREE.Object3D):String {

      var html = '<span class="type ${getObjectType(object)}"></span> ${escapeHTML(object.name)}';

      if (Std.isOfType(object, THREE.Mesh)) {

        final geometry = cast(object, THREE.Mesh).geometry;
        final material = cast(object, THREE.Mesh).material;

        html += ' <span class="type Geometry"></span> ${escapeHTML(geometry.name)}';
        html += ' <span class="type Material"></span> ${escapeHTML(getMaterialName(material))}';

      }

      html += getScript(object.uuid);

      return html;

    }

    function getScript(uuid:String):String {

      if (!editor.scripts.exists(uuid)) return '';

      if (editor.scripts.get(uuid).length == 0) return '';

      return ' <span class="type Script"></span>';

    }

    var ignoreObjectSelectedSignal = false;

    final outliner = new UIOutliner(editor);
    outliner.setId('outliner');
    outliner.onChange(function(_) {

      ignoreObjectSelectedSignal = true;

      editor.selectById(Std.parseInt(outliner.getValue()));

      ignoreObjectSelectedSignal = false;

    });
    outliner.onDblClick(function(_) {

      editor.focusById(Std.parseInt(outliner.getValue()));

    });
    container.add(outliner);
    container.add(new UIBreak());

    // background

    final backgroundRow = new UIRow();

    final backgroundType = new UISelect()
      .setOptions({
        'None': '',
        'Color': 'Color',
        'Texture': 'Texture',
        'Equirectangular': 'Equirect'
      })
      .setWidth('150px');
    backgroundType.onChange(function(_) {

      onBackgroundChanged();
      refreshBackgroundUI();

    });

    backgroundRow.add(new UIText(strings.getKey('sidebar/scene/background')).setClass('Label'));
    backgroundRow.add(backgroundType);

    final backgroundColor = new UIColor()
      .setValue('#000000')
      .setMarginLeft('8px')
      .onInput(onBackgroundChanged);
    backgroundRow.add(backgroundColor);

    final backgroundTexture = new UITexture(editor)
      .setMarginLeft('8px')
      .onChange(onBackgroundChanged);
    backgroundTexture.setDisplay('none');
    backgroundRow.add(backgroundTexture);

    final backgroundEquirectangularTexture = new UITexture(editor)
      .setMarginLeft('8px')
      .onChange(onBackgroundChanged);
    backgroundEquirectangularTexture.setDisplay('none');
    backgroundRow.add(backgroundEquirectangularTexture);

    container.add(backgroundRow);

    final backgroundEquirectRow = new UIRow();
    backgroundEquirectRow.setDisplay('none');
    backgroundEquirectRow.setMarginLeft('120px');

    final backgroundBlurriness = new UINumber(0)
      .setWidth('40px')
      .setRange(0, 1)
      .onChange(onBackgroundChanged);
    backgroundEquirectRow.add(backgroundBlurriness);

    final backgroundIntensity = new UINumber(1)
      .setWidth('40px')
      .setRange(0, Math.POSITIVE_INFINITY)
      .onChange(onBackgroundChanged);
    backgroundEquirectRow.add(backgroundIntensity);

    final backgroundRotation = new UINumber(0)
      .setWidth('40px')
      .setRange(-180, 180)
      .setStep(10)
      .setNudge(0.1)
      .setUnit('°')
      .onChange(onBackgroundChanged);
    backgroundEquirectRow.add(backgroundRotation);

    container.add(backgroundEquirectRow);

    function onBackgroundChanged(_) {

      signals.sceneBackgroundChanged.dispatch(
        backgroundType.getValue(),
        backgroundColor.getHexValue(),
        backgroundTexture.getValue(),
        backgroundEquirectangularTexture.getValue(),
        backgroundBlurriness.getValue(),
        backgroundIntensity.getValue(),
        backgroundRotation.getValue()
      );

    }

    function refreshBackgroundUI() {

      final type = backgroundType.getValue();

      backgroundType.setWidth(type == 'None' ? '150px' : '110px');
      backgroundColor.setDisplay(type == 'Color' ? '' : 'none');
      backgroundTexture.setDisplay(type == 'Texture' ? '' : 'none');
      backgroundEquirectangularTexture.setDisplay(type == 'Equirectangular' ? '' : 'none');
      backgroundEquirectRow.setDisplay(type == 'Equirectangular' ? '' : 'none');

    }

    // environment

    final environmentRow = new UIRow();

    final environmentType = new UISelect()
      .setOptions({
        'None': '',
        'Background': 'Background',
        'Equirectangular': 'Equirect',
        'ModelViewer': 'ModelViewer'
      })
      .setWidth('150px');
    environmentType.setValue('None');
    environmentType.onChange(function(_) {

      onEnvironmentChanged();
      refreshEnvironmentUI();

    });

    environmentRow.add(new UIText(strings.getKey('sidebar/scene/environment')).setClass('Label'));
    environmentRow.add(environmentType);

    final environmentEquirectangularTexture = new UITexture(editor)
      .setMarginLeft('8px')
      .onChange(onEnvironmentChanged);
    environmentEquirectangularTexture.setDisplay('none');
    environmentRow.add(environmentEquirectangularTexture);

    container.add(environmentRow);

    function onEnvironmentChanged(_) {

      signals.sceneEnvironmentChanged.dispatch(
        environmentType.getValue(),
        environmentEquirectangularTexture.getValue()
      );

    }

    function refreshEnvironmentUI() {

      final type = environmentType.getValue();

      environmentType.setWidth(type != 'Equirectangular' ? '150px' : '110px');
      environmentEquirectangularTexture.setDisplay(type == 'Equirectangular' ? '' : 'none');

    }

    // fog

    function onFogChanged(_) {

      signals.sceneFogChanged.dispatch(
        fogType.getValue(),
        fogColor.getHexValue(),
        fogNear.getValue(),
        fogFar.getValue(),
        fogDensity.getValue()
      );

    }

    function onFogSettingsChanged(_) {

      signals.sceneFogSettingsChanged.dispatch(
        fogType.getValue(),
        fogColor.getHexValue(),
        fogNear.getValue(),
        fogFar.getValue(),
        fogDensity.getValue()
      );

    }

    final fogTypeRow = new UIRow();
    final fogType = new UISelect()
      .setOptions({
        'None': '',
        'Fog': 'Linear',
        'FogExp2': 'Exponential'
      })
      .setWidth('150px');
    fogType.onChange(function(_) {

      onFogChanged();
      refreshFogUI();

    });

    fogTypeRow.add(new UIText(strings.getKey('sidebar/scene/fog')).setClass('Label'));
    fogTypeRow.add(fogType);

    container.add(fogTypeRow);

    // fog color

    final fogPropertiesRow = new UIRow();
    fogPropertiesRow.setDisplay('none');
    fogPropertiesRow.setMarginLeft('120px');
    container.add(fogPropertiesRow);

    final fogColor = new UIColor()
      .setValue('#aaaaaa')
      .onInput(onFogSettingsChanged);
    fogPropertiesRow.add(fogColor);

    // fog near

    final fogNear = new UINumber(0.1)
      .setWidth('40px')
      .setRange(0, Math.POSITIVE_INFINITY)
      .onChange(onFogSettingsChanged);
    fogPropertiesRow.add(fogNear);

    // fog far

    final fogFar = new UINumber(50)
      .setWidth('40px')
      .setRange(0, Math.POSITIVE_INFINITY)
      .onChange(onFogSettingsChanged);
    fogPropertiesRow.add(fogFar);

    // fog density

    final fogDensity = new UINumber(0.05)
      .setWidth('40px')
      .setRange(0, 0.1)
      .setStep(0.001)
      .setPrecision(3)
      .onChange(onFogSettingsChanged);
    fogPropertiesRow.add(fogDensity);

    //

    function refreshUI() {

      final camera = editor.camera;
      final scene = editor.scene;

      final options:Array<Element> = [];

      options.push(buildOption(camera, false));
      options.push(buildOption(scene, false));

      function addObjects(objects:Array<THREE.Object3D>, pad:Int) {
        for (i in 0...objects.length) {
          final object = objects[i];
          if (!nodeStates.exists(object)) {
            nodeStates.set(object, false);
          }
          final option = buildOption(object, true);
          option.style.paddingLeft = '${pad * 18}px';
          options.push(option);
          if (nodeStates.get(object)) {
            addObjects(object.children, pad + 1);
          }
        }
      }
      addObjects(scene.children, 0);

      outliner.setOptions(options);

      if (editor.selected != null) {

        outliner.setValue(Std.string(editor.selected.id));

      }

      if (scene.background != null) {

        if (Std.isOfType(scene.background, THREE.Color)) {

          backgroundType.setValue('Color');
          backgroundColor.setHexValue(cast(scene.background, THREE.Color).getHex());

        } else if (Std.isOfType(scene.background, THREE.Texture)) {

          if (cast(scene.background, THREE.Texture).mapping == THREE.EquirectangularReflectionMapping) {

            backgroundType.setValue('Equirectangular');
            backgroundEquirectangularTexture.setValue(cast(scene.background, THREE.Texture));
            backgroundBlurriness.setValue(scene.backgroundBlurriness);
            backgroundIntensity.setValue(scene.backgroundIntensity);

          } else {

            backgroundType.setValue('Texture');
            backgroundTexture.setValue(cast(scene.background, THREE.Texture));

          }

        }

      } else {

        backgroundType.setValue('None');
        backgroundTexture.setValue(null);
        backgroundEquirectangularTexture.setValue(null);

      }

      if (scene.environment != null) {

        if (scene.background != null && Std.isOfType(scene.background, THREE.Texture) && cast(scene.background, THREE.Texture).uuid == scene.environment.uuid) {

          environmentType.setValue('Background');

        } else if (scene.environment.mapping == THREE.EquirectangularReflectionMapping) {

          environmentType.setValue('Equirectangular');
          environmentEquirectangularTexture.setValue(scene.environment);

        } else if (cast(scene.environment, THREE.RenderTargetTexture).isRenderTargetTexture == true) {

          environmentType.setValue('ModelViewer');

        }

      } else {

        environmentType.setValue('None');
        environmentEquirectangularTexture.setValue(null);

      }

      if (scene.fog != null) {

        fogColor.setHexValue(scene.fog.color.getHex());

        if (Std.isOfType(scene.fog, THREE.Fog)) {

          fogType.setValue('Fog');
          fogNear.setValue(cast(scene.fog, THREE.Fog).near);
          fogFar.setValue(cast(scene.fog, THREE.Fog).far);

        } else if (Std.isOfType(scene.fog, THREE.FogExp2)) {

          fogType.setValue('FogExp2');
          fogDensity.setValue(cast(scene.fog, THREE.FogExp2).density);

        }

      } else {

        fogType.setValue('None');

      }

      refreshBackgroundUI();
      refreshEnvironmentUI();
      refreshFogUI();

    }

    function refreshFogUI() {

      final type = fogType.getValue();

      fogPropertiesRow.setDisplay(type == 'None' ? 'none' : '');
      fogNear.setDisplay(type == 'Fog' ? '' : 'none');
      fogFar.setDisplay(type == 'Fog' ? '' : 'none');
      fogDensity.setDisplay(type == 'FogExp2' ? '' : 'none');

    }

    refreshUI();

    // events

    signals.editorCleared.add(function(_) refreshUI());

    signals.sceneGraphChanged.add(function(_) refreshUI());

    signals.refreshSidebarEnvironment.add(function(_) refreshUI());

    signals.objectChanged.add(function(object) {

      final options = outliner.options;

      for (i in 0...options.length) {

        final option = options[i];

        if (option.value == Std.string(object.id)) {

          final openerElement = cast(option.querySelector(':scope > .opener'), Element);
          final openerHTML = openerElement != null ? openerElement.outerHTML : '';
          option.innerHTML = openerHTML + buildHTML(object);
          return;

        }

      }

    });

    signals.scriptAdded.add(function(_) {
      if (editor.selected != null) signals.objectChanged.dispatch(editor.selected);
    });

    signals.scriptRemoved.add(function(_) {
      if (editor.selected != null) signals.objectChanged.dispatch(editor.selected);
    });


    signals.objectSelected.add(function(object:THREE.Object3D) {

      if (ignoreObjectSelectedSignal) return;

      if (object != null && object.parent != null) {

        var needsRefresh = false;
        var parent = object.parent;

        while (parent != editor.scene) {

          if (!nodeStates.get(parent)) {

            nodeStates.set(parent, true);
            needsRefresh = true;

          }

          parent = parent.parent;

        }

        if (needsRefresh) refreshUI();

        outliner.setValue(Std.string(object.id));

      } else {

        outliner.setValue(null);

      }

    });

    signals.sceneBackgroundChanged.add(function(_) {

      if (environmentType.getValue() == 'Background') {

        onEnvironmentChanged(null);
        refreshEnvironmentUI();

      }

    });

    return container;

  }

}
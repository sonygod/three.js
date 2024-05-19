package three.js.editor.js;

import three.js.Lib;

class SidebarScene {
  private var editor:Editor;
  private var strings:Dynamic;
  private var signals:Signals;
  private var nodeStates:WeakMap<Object, Bool>;

  public function new(editor:Editor) {
    this.editor = editor;
    this.strings = editor.strings;
    this.signals = editor.signals;
    this.nodeStates = new WeakMap();

    var container:UIPanel = new UIPanel();
    container.setBorderTop('0');
    container.setPaddingTop('20px');

    // outliner
    var outliner:UIOutliner = new UIOutliner(editor);
    outliner.setId('outliner');
    outliner.onChange(function() {
      ignoreObjectSelectedSignal = true;
      editor.selectById(Std.parseInt(outliner.getValue()));
      ignoreObjectSelectedSignal = false;
    });
    outliner.onDblClick(function() {
      editor.focusById(Std.parseInt(outliner.getValue()));
    });
    container.add(outliner);
    container.add(new UIBreak());

    // background
    var backgroundRow:UIRow = new UIRow();

    var backgroundType:UISelect = new UISelect();
    backgroundType.setOptions([
      {value: '', label: ''},
      {value: 'Color', label: 'Color'},
      {value: 'Texture', label: 'Texture'},
      {value: 'Equirectangular', label: 'Equirectangular'}
    ]);
    backgroundType.setWidth('150px');
    backgroundType.onChange(function() {
      onBackgroundChanged();
      refreshBackgroundUI();
    });

    backgroundRow.add(new UIText(strings.getKey('sidebar/scene/background')).setClass('Label'));
    backgroundRow.add(backgroundType);

    var backgroundColor:UIColor = new UIColor();
    backgroundColor.setValue('#000000');
    backgroundColor.setMarginLeft('8px');
    backgroundColor.onInput(onBackgroundChanged);
    backgroundRow.add(backgroundColor);

    var backgroundTexture:UITexture = new UITexture(editor);
    backgroundTexture.setMarginLeft('8px');
    backgroundTexture.onChange(onBackgroundChanged);
    backgroundTexture.setDisplay('none');
    backgroundRow.add(backgroundTexture);

    var backgroundEquirectangularTexture:UITexture = new UITexture(editor);
    backgroundEquirectangularTexture.setMarginLeft('8px');
    backgroundEquirectangularTexture.onChange(onBackgroundChanged);
    backgroundEquirectangularTexture.setDisplay('none');
    backgroundRow.add(backgroundEquirectangularTexture);

    container.add(backgroundRow);

    var backgroundEquirectRow:UIRow = new UIRow();
    backgroundEquirectRow.setDisplay('none');
    backgroundEquirectRow.setMarginLeft('120px');

    var backgroundBlurriness:UINumber = new UINumber(0);
    backgroundBlurriness.setWidth('40px');
    backgroundBlurriness.setRange(0, 1);
    backgroundBlurriness.onChange(onBackgroundChanged);
    backgroundEquirectRow.add(backgroundBlurriness);

    var backgroundIntensity:UINumber = new UINumber(1);
    backgroundIntensity.setWidth('40px');
    backgroundIntensity.setRange(0, Math.POSITIVE_INFINITY);
    backgroundIntensity.onChange(onBackgroundChanged);
    backgroundEquirectRow.add(backgroundIntensity);

    var backgroundRotation:UINumber = new UINumber(0);
    backgroundRotation.setWidth('40px');
    backgroundRotation.setRange(-180, 180);
    backgroundRotation.setStep(10);
    backgroundRotation.setNudge(0.1);
    backgroundRotation.setUnit('°');
    backgroundRotation.onChange(onBackgroundChanged);
    backgroundEquirectRow.add(backgroundRotation);

    container.add(backgroundEquirectRow);

    function onBackgroundChanged() {
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
      var type = backgroundType.getValue();
      backgroundType.setWidth(type == 'None' ? '150px' : '110px');
      backgroundColor.setDisplay(type == 'Color' ? '' : 'none');
      backgroundTexture.setDisplay(type == 'Texture' ? '' : 'none');
      backgroundEquirectangularTexture.setDisplay(type == 'Equirectangular' ? '' : 'none');
      backgroundEquirectRow.setDisplay(type == 'Equirectangular' ? '' : 'none');
    }

    // environment
    var environmentRow:UIRow = new UIRow();

    var environmentType:UISelect = new UISelect();
    environmentType.setOptions([
      {value: '', label: ''},
      {value: 'Background', label: 'Background'},
      {value: 'Equirectangular', label: 'Equirectangular'},
      {value: 'ModelViewer', label: 'ModelViewer'}
    ]);
    environmentType.setWidth('150px');
    environmentType.onChange(function() {
      onEnvironmentChanged();
      refreshEnvironmentUI();
    });

    environmentRow.add(new UIText(strings.getKey('sidebar/scene/environment')).setClass('Label'));
    environmentRow.add(environmentType);

    var environmentEquirectangularTexture:UITexture = new UITexture(editor);
    environmentEquirectangularTexture.setMarginLeft('8px');
    environmentEquirectangularTexture.onChange(onEnvironmentChanged);
    environmentEquirectangularTexture.setDisplay('none');
    environmentRow.add(environmentEquirectangularTexture);

    container.add(environmentRow);

    function onEnvironmentChanged() {
      signals.sceneEnvironmentChanged.dispatch(
        environmentType.getValue(),
        environmentEquirectangularTexture.getValue()
      );
    }

    function refreshEnvironmentUI() {
      var type = environmentType.getValue();
      environmentType.setWidth(type != 'Equirectangular' ? '150px' : '110px');
      environmentEquirectangularTexture.setDisplay(type == 'Equirectangular' ? '' : 'none');
    }

    // fog
    function onFogChanged() {
      signals.sceneFogChanged.dispatch(
        fogType.getValue(),
        fogColor.getHexValue(),
        fogNear.getValue(),
        fogFar.getValue(),
        fogDensity.getValue()
      );
    }

    function onFogSettingsChanged() {
      signals.sceneFogSettingsChanged.dispatch(
        fogType.getValue(),
        fogColor.getHexValue(),
        fogNear.getValue(),
        fogFar.getValue(),
        fogDensity.getValue()
      );
    }

    var fogTypeRow:UIRow = new UIRow();

    var fogType:UISelect = new UISelect();
    fogType.setOptions([
      {value: '', label: ''},
      {value: 'Fog', label: 'Linear'},
      {value: 'FogExp2', label: 'Exponential'}
    ]);
    fogType.setWidth('150px');
    fogType.onChange(function() {
      onFogChanged();
      refreshFogUI();
    });

    fogTypeRow.add(new UIText(strings.getKey('sidebar/scene/fog')).setClass('Label'));
    fogTypeRow.add(fogType);

    container.add(fogTypeRow);

    var fogPropertiesRow:UIRow = new UIRow();
    fogPropertiesRow.setDisplay('none');
    fogPropertiesRow.setMarginLeft('120px');
    container.add(fogPropertiesRow);

    var fogColor:UIColor = new UIColor();
    fogColor.setValue('#aaaaaa');
    fogColor.onInput(onFogSettingsChanged);
    fogPropertiesRow.add(fogColor);

    var fogNear:UINumber = new UINumber(0.1);
    fogNear.setWidth('40px');
    fogNear.setRange(0, Math.POSITIVE_INFINITY);
    fogNear.onChange(onFogSettingsChanged);
    fogPropertiesRow.add(fogNear);

    var fogFar:UINumber = new UINumber(50);
    fogFar.setWidth('40px');
    fogFar.setRange(0, Math.POSITIVE_INFINITY);
    fogFar.onChange(onFogSettingsChanged);
    fogPropertiesRow.add(fogFar);

    var fogDensity:UINumber = new UINumber(0.05);
    fogDensity.setWidth('40px');
    fogDensity.setRange(0, 0.1);
    fogDensity.setStep(0.001);
    fogDensity.setPrecision(3);
    fogDensity.onChange(onFogSettingsChanged);
    fogPropertiesRow.add(fogDensity);

    function refreshUI() {
      var camera = editor.camera;
      var scene = editor.scene;

      var options:Array<UIOption> = [];

      options.push(buildOption(camera, false));
      options.push(buildOption(scene, false));

      (function addObjects(objects:Array<Object3D>, pad:Int) {
        for (object in objects) {
          if (!nodeStates.exists(object)) {
            nodeStates.set(object, false);
          }

          var option:UIOption = buildOption(object, true);
          option.style.paddingLeft = (pad * 18) + 'px';
          options.push(option);

          if (nodeStates.get(object) == true) {
            addObjects(object.children, pad + 1);
          }
        }
      })(scene.children, 0);

      outliner.setOptions(options);

      if (editor.selected != null) {
        outliner.setValue(editor.selected.id);
      }

      if (scene.background != null) {
        if (scene.background.isColor) {
          backgroundType.setValue('Color');
          backgroundColor.setHexValue(scene.background.getHex());
        } else if (scene.background.isTexture) {
          if (scene.background.mapping == THREE.EquirectangularReflectionMapping) {
            backgroundType.setValue('Equirectangular');
            backgroundEquirectangularTexture.setValue(scene.background);
            backgroundBlurriness.setValue(scene.backgroundBlurriness);
            backgroundIntensity.setValue(scene.backgroundIntensity);
          } else {
            backgroundType.setValue('Texture');
            backgroundTexture.setValue(scene.background);
          }
        }
      } else {
        backgroundType.setValue('None');
        backgroundTexture.setValue(null);
        backgroundEquirectangularTexture.setValue(null);
      }

      if (scene.environment != null) {
        if (scene.background != null && scene.background.isTexture && scene.background.uuid == scene.environment.uuid) {
          environmentType.setValue('Background');
        } else if (scene.environment.mapping == THREE.EquirectangularReflectionMapping) {
          environmentType.setValue('Equirectangular');
          environmentEquirectangularTexture.setValue(scene.environment);
        } else if (scene.environment.isRenderTargetTexture) {
          environmentType.setValue('ModelViewer');
        }
      } else {
        environmentType.setValue('None');
        environmentEquirectangularTexture.setValue(null);
      }

      if (scene.fog != null) {
        fogColor.setHexValue(scene.fog.color.getHex());

        if (scene.fog.isFog) {
          fogType.setValue('Fog');
          fogNear.setValue(scene.fog.near);
          fogFar.setValue(scene.fog.far);
        } else if (scene.fog.isFogExp2) {
          fogType.setValue('FogExp2');
          fogDensity.setValue(scene.fog.density);
        }
      } else {
        fogType.setValue('None');
      }

      refreshBackgroundUI();
      refreshEnvironmentUI();
      refreshFogUI();
    }

    function refreshFogUI() {
      var type = fogType.getValue();
      fogPropertiesRow.setDisplay(type == 'None' ? 'none' : '');
      fogNear.setDisplay(type == 'Fog' ? '' : 'none');
      fogFar.setDisplay(type == 'Fog' ? '' : 'none');
      fogDensity.setDisplay(type == 'FogExp2' ? '' : 'none');
    }

    refreshUI();

    // events
    signals.editorCleared.add(refreshUI);
    signals.sceneGraphChanged.add(refreshUI);
    signals.refreshSidebarEnvironment.add(refreshUI);

    signals.objectChanged.add(function(object:Object3D) {
      var options:Array<UIOption> = outliner.options;

      for (option in options) {
        if (option.value == object.id) {
          var openerElement:HTMLElement = option.querySelector(':scope > .opener');
          var openerHTML:String = openerElement != null ? openerElement.outerHTML : '';

          option.innerHTML = openerHTML + buildHTML(object);

          return;
        }
      }
    });

    signals.scriptAdded.add(function() {
      if (editor.selected != null) signals.objectChanged.dispatch(editor.selected);
    });

    signals.scriptRemoved.add(function() {
      if (editor.selected != null) signals.objectChanged.dispatch(editor.selected);
    });

    signals.objectSelected.add(function(object:Object3D) {
      if (ignoreObjectSelectedSignal == true) return;

      if (object != null && object.parent != null) {
        var needsRefresh:Bool = false;
        var parent:Object3D = object.parent;

        while (parent != editor.scene) {
          if (!nodeStates.exists(parent)) {
            nodeStates.set(parent, true);
            needsRefresh = true;
          }

          parent = parent.parent;
        }

        if (needsRefresh) refreshUI();

        outliner.setValue(object.id);
      } else {
        outliner.setValue(null);
      }
    });

    signals.sceneBackgroundChanged.add(function() {
      if (environmentType.getValue() == 'Background') {
        onEnvironmentChanged();
        refreshEnvironmentUI();
      }
    });
  }

  static public function main(editor:Editor) {
    return new SidebarScene(editor);
  }
}
package three.js.editor.js;

import three.js.*;

import ui.UIPanel;
import ui.UIRow;
import ui.UISelect;
import ui.UIText;
import ui.UIBoolean;
import ui.UINumber;

class SidebarProjectRenderer {
    public var container:UIPanel;
    public var currentRenderer:WebGLRenderer;

    public function new(editor:Editor) {
        var config = editor.config;
        var signals = editor.signals;
        var strings = editor.strings;

        container = new UIPanel();
        container.setBorderTop('0px');

        // Antialias

        var antialiasRow = new UIRow();
        container.add(antialiasRow);

        antialiasRow.add(new UIText(strings.getKey('sidebar/project/antialias')).setClass('Label'));

        var antialiasBoolean = new UIBoolean(config.getKey('project/renderer/antialias')).onChange(createRenderer);
        antialiasRow.add(antialiasBoolean);

        // Shadows

        var shadowsRow = new UIRow();
        container.add(shadowsRow);

        shadowsRow.add(new UIText(strings.getKey('sidebar/project/shadows')).setClass('Label'));

        var shadowsBoolean = new UIBoolean(config.getKey('project/renderer/shadows')).onChange(updateShadows);
        shadowsRow.add(shadowsBoolean);

        var shadowTypeSelect = new UISelect().setOptions([
            {value: 0, label: 'Basic'},
            {value: 1, label: 'PCF'},
            {value: 2, label: 'PCF Soft'}
            // {value: 3, label: 'VSM'}
        ]).setWidth('125px').onChange(updateShadows);
        shadowTypeSelect.setValue(config.getKey('project/renderer/shadowType'));
        shadowsRow.add(shadowTypeSelect);

        function updateShadows() {
            currentRenderer.shadowMap.enabled = shadowsBoolean.getValue();
            currentRenderer.shadowMap.type = Std.parseFloat(shadowTypeSelect.getValue());
            signals.rendererUpdated.dispatch();
        }

        // Tonemapping

        var toneMappingRow = new UIRow();
        container.add(toneMappingRow);

        toneMappingRow.add(new UIText(strings.getKey('sidebar/project/toneMapping')).setClass('Label'));

        var toneMappingSelect = new UISelect().setOptions([
            {value: 0, label: 'No'},
            {value: 1, label: 'Linear'},
            {value: 2, label: 'Reinhard'},
            {value: 3, label: 'Cineon'},
            {value: 4, label: 'ACESFilmic'},
            {value: 6, label: 'AgX'},
            {value: 7, label: 'Neutral'}
        ]).setWidth('120px').onChange(updateToneMapping);
        toneMappingSelect.setValue(config.getKey('project/renderer/toneMapping'));
        toneMappingRow.add(toneMappingSelect);

        var toneMappingExposure = new UINumber(config.getKey('project/renderer/toneMappingExposure'));
        toneMappingExposure.setDisplay(toneMappingSelect.getValue() == '0' ? 'none' : '');
        toneMappingExposure.setWidth('30px').setMarginLeft('10px');
        toneMappingExposure.setRange(0, 10);
        toneMappingExposure.onChange(updateToneMapping);
        toneMappingRow.add(toneMappingExposure);

        function updateToneMapping() {
            toneMappingExposure.setDisplay(toneMappingSelect.getValue() == '0' ? 'none' : '');
            currentRenderer.toneMapping = Std.parseFloat(toneMappingSelect.getValue());
            currentRenderer.toneMappingExposure = toneMappingExposure.getValue();
            signals.rendererUpdated.dispatch();
        }

        //

        function createRenderer() {
            currentRenderer = new WebGLRenderer({antialias: antialiasBoolean.getValue()});
            currentRenderer.shadowMap.enabled = shadowsBoolean.getValue();
            currentRenderer.shadowMap.type = Std.parseFloat(shadowTypeSelect.getValue());
            currentRenderer.toneMapping = Std.parseFloat(toneMappingSelect.getValue());
            currentRenderer.toneMappingExposure = toneMappingExposure.getValue();
            signals.rendererCreated.dispatch(currentRenderer);
            signals.rendererUpdated.dispatch();
        }

        createRenderer();

        // Signals

        signals.editorCleared.add(function() {
            currentRenderer.shadowMap.enabled = true;
            currentRenderer.shadowMap.type = PCFShadowMap;
            currentRenderer.toneMapping = NoToneMapping;
            currentRenderer.toneMappingExposure = 1;

            shadowsBoolean.setValue(currentRenderer.shadowMap.enabled);
            shadowTypeSelect.setValue(currentRenderer.shadowMap.type);
            toneMappingSelect.setValue(currentRenderer.toneMapping);
            toneMappingExposure.setValue(currentRenderer.toneMappingExposure);
            toneMappingExposure.setDisplay(currentRenderer.toneMapping == 0 ? 'none' : '');
            signals.rendererUpdated.dispatch();
        });

        signals.rendererUpdated.add(function() {
            config.setKey(
                'project/renderer/antialias', antialiasBoolean.getValue(),
                'project/renderer/shadows', shadowsBoolean.getValue(),
                'project/renderer/shadowType', Std.parseFloat(shadowTypeSelect.getValue()),
                'project/renderer/toneMapping', Std.parseFloat(toneMappingSelect.getValue()),
                'project/renderer/toneMappingExposure', toneMappingExposure.getValue()
            );
        });
    }
}
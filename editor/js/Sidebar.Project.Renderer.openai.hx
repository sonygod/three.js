package three.js.editor.js;

import three.js.*;

import ui.UINumber;
import ui.UIPanel;
import ui.UIRow;
import ui.UISelect;
import ui.UIText;
import ui.three.UIBoolean;

class SidebarProjectRenderer {
    private var editor:_EDITOR;
    private var config:CONFIG;
    private var signals:SIGNALS;
    private var strings:STRINGS;

    private var currentRenderer:WebGLRenderer;
    private var container:UIPanel;

    public function new(editor:EDITOR) {
        this.editor = editor;
        this.config = editor.config;
        this.signals = editor.signals;
        this.strings = editor.strings;

        this.container = new UIPanel();
        this.container.setBorderTop('0px');

        // Antialias

        var antialiasRow:UIRow = new UIRow();
        this.container.add(antialiasRow);

        antialiasRow.add(new UIText(strings.getKey('sidebar/project/antialias')).setClass('Label'));

        var antialiasBoolean:UIBoolean = new UIBoolean(config.getKey('project/renderer/antialias')).onChange(createRenderer);
        antialiasRow.add(antialiasBoolean);

        // Shadows

        var shadowsRow:UIRow = new UIRow();
        this.container.add(shadowsRow);

        shadowsRow.add(new UIText(strings.getKey('sidebar/project/shadows')).setClass('Label'));

        var shadowsBoolean:UIBoolean = new UIBoolean(config.getKey('project/renderer/shadows')).onChange(updateShadows);
        shadowsRow.add(shadowsBoolean);

        var shadowTypeSelect:UISelect = new UISelect().setOptions([
            {value: '0', label: 'Basic'},
            {value: '1', label: 'PCF'},
            {value: '2', label: 'PCF Soft'},
            //{value: '3', label: 'VSM'}
        ]).setWidth('125px').onChange(updateShadows);
        shadowTypeSelect.setValue(config.getKey('project/renderer/shadowType'));
        shadowsRow.add(shadowTypeSelect);

        function updateShadows() {
            currentRenderer.shadowMap.enabled = shadowsBoolean.getValue();
            currentRenderer.shadowMap.type = Std.parseFloat(shadowTypeSelect.getValue());
            signals.rendererUpdated.dispatch();
        }

        // Tonemapping

        var toneMappingRow:UIRow = new UIRow();
        this.container.add(toneMappingRow);

        toneMappingRow.add(new UIText(strings.getKey('sidebar/project/toneMapping')).setClass('Label'));

        var toneMappingSelect:UISelect = new UISelect().setOptions([
            {value: '0', label: 'No'},
            {value: '1', label: 'Linear'},
            {value: '2', label: 'Reinhard'},
            {value: '3', label: 'Cineon'},
            {value: '4', label: 'ACESFilmic'},
            {value: '6', label: 'AgX'},
            {value: '7', label: 'Neutral'}
        ]).setWidth('120px').onChange(updateToneMapping);
        toneMappingSelect.setValue(config.getKey('project/renderer/toneMapping'));
        toneMappingRow.add(toneMappingSelect);

        var toneMappingExposure:UINumber = new UINumber(config.getKey('project/renderer/toneMappingExposure'));
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
            currentRenderer.shadowMap.type = THREE.PCFShadowMap;
            currentRenderer.toneMapping = THREE.NoToneMapping;
            currentRenderer.toneMappingExposure = 1;

            shadowsBoolean.setValue(currentRenderer.shadowMap.enabled);
            shadowTypeSelect.setValue(currentRenderer.shadowMap.type);
            toneMappingSelect.setValue(currentRenderer.toneMapping);
            toneMappingExposure.setValue(currentRenderer.toneMappingExposure);
            toneMappingExposure.setDisplay(currentRenderer.toneMapping === 0 ? 'none' : '');
            signals.rendererUpdated.dispatch();
        });

        signals.rendererUpdated.add(function() {
            config.setKey('project/renderer/antialias', antialiasBoolean.getValue());
            config.setKey('project/renderer/shadows', shadowsBoolean.getValue());
            config.setKey('project/renderer/shadowType', Std.parseFloat(shadowTypeSelect.getValue()));
            config.setKey('project/renderer/toneMapping', Std.parseFloat(toneMappingSelect.getValue()));
            config.setKey('project/renderer/toneMappingExposure', toneMappingExposure.getValue());
        });

        return container;
    }
}
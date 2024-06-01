package ;

import three.WebGLRenderer;
import three.ShadowMapType;
import three.ToneMapping;
import js.three.THREE;

import ui.Boolean as UIBoolean;
import ui.Number as UINumber;
import ui.Panel as UIPanel;
import ui.Row as UIRow;
import ui.Select as UISelect;
import ui.Text as UIText;

class SidebarProjectRenderer {

    public function new(editor:Editor) {

        var config = editor.config;
        var signals = editor.signals;
        var strings = editor.strings;

        var currentRenderer:WebGLRenderer = null;

        var container = new UIPanel();
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

        var shadowTypeSelect = new UISelect()
        .setOptions({
            '0': 'Basic',
            '1': 'PCF',
            '2': 'PCF Soft',
            // '3': 'VSM'
        })
        .setWidth('125px')
        .onChange(updateShadows);
        shadowTypeSelect.setValue(config.getKey('project/renderer/shadowType'));
        shadowsRow.add(shadowTypeSelect);

        function updateShadows() {

            currentRenderer.shadowMap.enabled = shadowsBoolean.getValue();
            currentRenderer.shadowMap.type = Std.parseInt(shadowTypeSelect.getValue());

            signals.rendererUpdated.dispatch();

        }

        // Tonemapping

        var toneMappingRow = new UIRow();
        container.add(toneMappingRow);

        toneMappingRow.add(new UIText(strings.getKey('sidebar/project/toneMapping')).setClass('Label'));

        var toneMappingSelect = new UISelect()
        .setOptions({
            '0': 'No',
            '1': 'Linear',
            '2': 'Reinhard',
            '3': 'Cineon',
            '4': 'ACESFilmic',
            '6': 'AgX',
            '7': 'Neutral'
        })
        .setWidth('120px')
        .onChange(updateToneMapping);
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

            currentRenderer.toneMapping = Std.parseInt(toneMappingSelect.getValue());
            currentRenderer.toneMappingExposure = toneMappingExposure.getValue();
            signals.rendererUpdated.dispatch();

        }

        //

        function createRenderer() {

            currentRenderer = new THREE.WebGLRenderer({ antialias: antialiasBoolean.getValue() });
            currentRenderer.shadowMap.enabled = shadowsBoolean.getValue();
            currentRenderer.shadowMap.type = Std.parseInt(shadowTypeSelect.getValue());
            currentRenderer.toneMapping = Std.parseInt(toneMappingSelect.getValue());
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
            shadowTypeSelect.setValue(Std.string(currentRenderer.shadowMap.type));
            toneMappingSelect.setValue(Std.string(currentRenderer.toneMapping));
            toneMappingExposure.setValue(currentRenderer.toneMappingExposure);
            toneMappingExposure.setDisplay(currentRenderer.toneMapping == 0 ? 'none' : '');

            signals.rendererUpdated.dispatch();

        });

        signals.rendererUpdated.add(function() {

            config.setKey(
                'project/renderer/antialias', antialiasBoolean.getValue(),
                'project/renderer/shadows', shadowsBoolean.getValue(),
                'project/renderer/shadowType', Std.parseInt(shadowTypeSelect.getValue()),
                'project/renderer/toneMapping', Std.parseInt(toneMappingSelect.getValue()),
                'project/renderer/toneMappingExposure', toneMappingExposure.getValue()
            );

        });

        this = container;

    }
    
}
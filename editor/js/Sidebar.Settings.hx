package three.js.editor.js;

import ui.UISpan;
import ui.UIPanel;
import ui.UIRow;
import ui.UISelect;
import ui.UIText;

import SidebarSettingsShortcuts;
import SidebarSettingsHistory;

class SidebarSettings {
    public function new(editor:Editor) {
        var config = editor.config;
        var strings = editor.strings;

        var container = new UISpan();

        var settings = new UIPanel();
        settings.setBorderTop('0');
        settings.setPaddingTop('20px');
        container.add(settings);

        // language

        var options = [
            { value: 'en', label: 'English' },
            { value: 'fr', label: 'Français' },
            { value: 'zh', label: '中文' },
            { value: 'ja', label: '日本語' },
        ];

        var languageRow = new UIRow();
        var language = new UISelect();
        language.setWidth('150px');
        language.setOptions(options);

        if (config.getKey('language') != null) {
            language.setValue(config.getKey('language'));
        }

        language.onChange(function() {
            var value = language.getValue();
            editor.config.setKey('language', value);
        });

        languageRow.add(new UIText(strings.getKey('sidebar/settings/language')).setClass('Label'));
        languageRow.add(language);

        settings.add(languageRow);

        //

        container.add(new SidebarSettingsShortcuts(editor));
        container.add(new SidebarSettingsHistory(editor));

        return container;
    }
}
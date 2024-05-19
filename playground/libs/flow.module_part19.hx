package three.js.playground.libs;

import js.html.SelectElement;
import js.html.OptionElement;
import js.Browser;

class SelectInput extends Input {
    private var dom:SelectElement;
    private var options:Array<Dynamic>;

    public function new(?options:Array<Dynamic> = [], ?value:Null<String>) {
        dom = Browser.document.createElement("select");
        super(dom);

        dom.addEventListener("change", function(_) {
            dispatchEvent(new Event("change"));
        });

        dom.addEventListener("mousedown", function(_) {
            dispatchEvent(new Event("click"));
        });
        dom.addEventListener("touchstart", function(_) {
            dispatchEvent(new Event("click"));
        });

        setOptions(options, value);
    }

    public function setOptions(options:Array<Dynamic>, ?value:Null<String>):SelectInput {
        var dom = this.dom;
        var defaultValue = dom.value;
        var containsDefaultValue = false;

        this.options = options;
        dom.innerHTML = '';

        for (i in 0...options.length) {
            var opt = options[i];
            if (Std.is(opt, String)) {
                opt = { name: opt, value: i };
            }

            var option = Browser.document.createElement("option");
            option.innerText = opt.name;
            option.value = opt.value;

            if (!containsDefaultValue && defaultValue == opt.value) {
                containsDefaultValue = true;
            }

            dom.appendChild(option);
        }

        dom.value = value != null ? value : containsDefaultValue ? defaultValue : '';

        return this;
    }

    public function getOptions():Array<Dynamic> {
        return options;
    }

    public function serialize(data:Dynamic) {
        data.options = [for (opt in options) opt];
        super.serialize(data);
    }

    public function deserialize(data:Dynamic) {
        var currentOptions = options;
        if (currentOptions.length == 0) {
            setOptions(data.options);
        }
        super.deserialize(data);
    }
}
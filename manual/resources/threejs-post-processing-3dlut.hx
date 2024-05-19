package three.js.manual.resources;

import js.html.svg.SVGElement;
import js.html.svg.SVGSVGElement;
import js.Browser;

class Waiter {
    public var promise:js.lib.Promise<Dynamic>;
    public var resolve:Dynamic->Void;

    public function new() {
        promise = new js.lib.Promise((resolve) -> {
            this.resolve = resolve;
        });
    }
}

class Diagrams {
    public static var lookup:Lookup = new Lookup();

    public static function createDiagram(base:js.html.Element) {
        var name:String = base.dataset.diagram;
        var info:Lookup = diagrams[name];
        if (info == null) {
            throw new Error('no diagram $name');
        }
        info.init(base);
    }
}

class Lookup {
    public function init(elem:js.html.Element) {
        getSVGDocument(elem).then((svg:SVGSVGElement) -> {
            var partsByName:Map<String, {Input:SVGElement, Output:SVGElement, Result:SVGElement}> = {};
            [
                '[id$=-Input]',
                '[id$=-Output]',
                '[id$=-Result]',
            ].forEach((selector:String) -> {
                svg.querySelectorAll('[id^=Effect]').iterate((elem:SVGElement) -> {
                    elem.style.mixBlendMode = elem.id.split('-')[1];
                });
                svg.querySelectorAll(selector).iterate((elem:SVGElement) -> {
                    var parts:Array<String> = elem.id.split('-');
                    var name:String = parts[0];
                    var type:String = parts[1];
                    if (!partsByName.exists(name)) {
                        partsByName[name] = {};
                    }
                    partsByName[name][type] = elem;
                    elem.style.visibility = 'hidden';
                });
            });
            var parts:Array<{Input:SVGElement, Output:SVGElement, Result:SVGElement}> = Lambda.array(Object.keys(partsByName).map(k -> partsByName[k]));
            var ndx:Int = 0;
            var step:Int = 0;
            var delay:Int = 0;
            Browser.window.setInterval(() -> {
                var part:{Input:SVGElement, Output:SVGElement, Result:SVGElement} = parts[ndx];
                switch (step) {
                    case 0:
                        part.Input.style.visibility = '';
                        step++;
                    case 1:
                        part.Output.style.visibility = '';
                        step++;
                    case 2:
                        part.Result.style.visibility = '';
                        step++;
                    case 3:
                        part.Input.style.visibility = 'hidden';
                        part.Output.style.visibility = 'hidden';
                        ndx = (ndx + 1) % parts.length;
                        if (ndx == 0) {
                            step = 4;
                            delay = 4;
                        } else {
                            step = 0;
                        }
                    case 4:
                        delay--;
                        if (delay <= 0) {
                            for (part in parts) {
                                for (elem in Lambda.array([part.Input, part.Output, part.Result])) {
                                    elem.style.visibility = 'hidden';
                                }
                            }
                            step = 0;
                        }
                }
            }, 500);
        });
    }
}

async function getSVGDocument(elem:js.html.Element):js.lib.Promise<SVGSVGElement> {
    var data:String = elem.data;
    elem.data = '';
    elem.data = data;
    var waiter:Waiter = new Waiter();
    elem.addEventListener('load', waiter.resolve);
    await waiter.promise;
    return elem.getSVGDocument();
}

Browser.document.addEventListener('DOMContentLoaded', () -> {
    for (elem in Browser.document.querySelectorAll('[data-diagram]')) {
        Diagrams.createDiagram(cast elem);
    }
});
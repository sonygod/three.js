package three.js.manual.resources;

import js.html.SVGElement;
import js.html.SVGSVGElement;
import js.Browser;

class Waiter {
    public var promise:js.Promise<Dynamic>;
    public var resolve:Dynamic->Void;

    public function new() {
        promise = new js.Promise((resolve) -> {
            this.resolve = resolve;
        });
    }
}

async function getSVGDocument(elem:SVGElement):Promise<SVGSVGElement> {
    var data = elem.data;
    elem.data = '';
    elem.data = data;
    var waiter = new Waiter();
    elem.addEventListener('load', waiter.resolve);
    await waiter.promise;
    return elem.getSVGDocument();
}

class Diagrams {
    public static var lookup:Lookup;

    static function init() {
        lookup = {
            async init(elem:SVGElement) {
                var svg = await getSVGDocument(elem);
                var partsByName = {};
                [
                    '[id$=-Input]',
                    '[id$=-Output]',
                    '[id$=-Result]',
                ].forEach((selector) -> {
                    svg.querySelectorAll('[id^=Effect]').forEach((elem) -> {
                        elem.style.mixBlendMode = elem.id.split('-')[1];
                    });
                    svg.querySelectorAll(selector).forEach((elem) -> {
                        var name:String = elem.id.split('-')[0];
                        partsByName[name] = partsByName[name] || {};
                        partsByName[name][elem.id.split('-')[1]] = elem;
                        elem.style.visibility = 'hidden';
                    });
                });
                var parts = Object.keys(partsByName).sort().map(k -> partsByName[k]);
                var ndx = 0;
                var step = 0;
                var delay = 0;
                Browser.window.setInterval(() -> {
                    var part = parts[ndx];
                    switch (step) {
                        case 0:
                            part.Input.style.visibility = '';
                            ++step;
                            break;
                        case 1:
                            part.Output.style.visibility = '';
                            ++step;
                            break;
                        case 2:
                            part.Result.style.visibility = '';
                            ++step;
                            break;
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
                            break;
                        case 4:
                            --delay;
                            if (delay <= 0) {
                                for (part in parts) {
                                    for (elem in Object.values(part)) {
                                        elem.style.visibility = 'hidden';
                                    }
                                }
                                step = 0;
                            }
                            break;
                    }
                }, 500);
            }
        };
    }
}

function createDiagram(base:SVGElement):Void {
    var name = base.dataset.diagram;
    var info = Diagrams.lookup;
    if (info == null) {
        throw new js.Error('no diagram $name');
    }
    info.init(base);
}

Browser.document.addEventListener('DOMContentLoaded', (_) -> {
    for (base in Browser.document.querySelectorAll('[data-diagram]')) {
        createDiagram(cast base);
    }
});
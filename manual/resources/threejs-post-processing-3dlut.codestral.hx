import js.Promise;
import js.html.HTMLElement;
import js.html.Document;
import js.html.SVGSVGElement;
import js.html.Element;
import js.html.HTMLObjectElement;

class Waiter {
    public var promise: Promise<Void>;
    public var resolve: Void -> Void;

    public function new() {
        this.promise = new Promise<Void>((resolve: Void -> Void, _reject: dynamic -> Void) -> Void {
            this.resolve = resolve;
            return null;
        });
    }
}

@:keep
function getSVGDocument(elem: HTMLObjectElement): Future<SVGSVGElement> {
    var data = elem.data;
    elem.data = '';
    elem.data = data;

    var waiter = new Waiter();
    elem.addEventListener('load', (_event: Event) -> {
        waiter.resolve(null);
        return null;
    });

    return Future.ofPromise(waiter.promise).map((_void: Void) -> elem.getSVGDocument());
}

@:keep
class DiagramInfo {
    public function new() {}

    public function init(elem: HTMLElement): Void {
        var svg = getSVGDocument(elem);
        var partsByName = new haxe.ds.StringMap<haxe.ds.StringMap<Element>>();

        ['[id$=-Input]', '[id$=-Output]', '[id$=-Result]'].forEach((selector) -> {
            var elems = Array.from(svg.get().querySelectorAll('[id^=Effect]'));
            for (elem in elems) {
                elem.style.mixBlendMode = elem.id.split('-')[1];
            }

            var elems = Array.from(svg.get().querySelectorAll(selector));
            for (elem in elems) {
                var parts = elem.id.split('-');
                var name = parts[0];
                var type = parts[1];

                if (!partsByName.exists(name)) {
                    partsByName.set(name, new haxe.ds.StringMap<Element>());
                }

                var partsMap = partsByName.get(name);
                partsMap.set(type, elem);
                elem.style.visibility = 'hidden';
            }
        });

        var parts = Array.from(partsByName.keys()).sort().map((k) -> partsByName.get(k));
        var ndx = 0;
        var step = 0;
        var delay = 0;

        js.Browser.window.setInterval(() -> {
            var part = parts[ndx];

            switch (step) {
                case 0:
                    part.get('Input').style.visibility = '';
                    ++step;
                    break;

                case 1:
                    part.get('Output').style.visibility = '';
                    ++step;
                    break;

                case 2:
                    part.get('Result').style.visibility = '';
                    ++step;
                    break;

                case 3:
                    part.get('Input').style.visibility = 'hidden';
                    part.get('Output').style.visibility = 'hidden';
                    ndx = (ndx + 1) % parts.length;

                    if (ndx === 0) {
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
                            for (elem in part.values()) {
                                elem.style.visibility = 'hidden';
                            }
                        }

                        step = 0;
                    }
                    break;
            }
        }, 500);
    }
}

class Diagrams {
    public static var lookup: DiagramInfo;
}

Diagrams.lookup = new DiagramInfo();

@:keep
function createDiagram(base: HTMLElement): Void {
    var name = base.dataset.diagram;
    var info = Type.getField(Diagrams, name);

    if (info == null) {
        throw new Error('No diagram ' + name);
    }

    info.init(base);
}

var elems = Array.from(js.Browser.document.querySelectorAll('[data-diagram]'));
for (elem in elems) {
    createDiagram(elem);
}
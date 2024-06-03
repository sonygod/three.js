import js.Browser.document;
import three.Vector2;

class SelectionHelper {
    public var element : js.html.Element;
    public var renderer : any;
    public var startPoint : Vector2;
    public var pointTopLeft : Vector2;
    public var pointBottomRight : Vector2;
    public var isDown : Bool;
    public var enabled : Bool;
    public var onPointerDown : js.Function;
    public var onPointerMove : js.Function;
    public var onPointerUp : js.Function;

    public function new(renderer : any, cssClassName : String) {
        this.element = document.createElement('div');
        this.element.classList.add(cssClassName);
        this.element.style.setProperty('pointerEvents', 'none');
        this.renderer = renderer;
        this.startPoint = new Vector2();
        this.pointTopLeft = new Vector2();
        this.pointBottomRight = new Vector2();
        this.isDown = false;
        this.enabled = true;

        this.onPointerDown = function(event : js.html.Event) {
            if (this.enabled == false) return;
            this.isDown = true;
            this.onSelectStart(event);
        }.bind(this);

        this.onPointerMove = function(event : js.html.Event) {
            if (this.enabled == false) return;
            if (this.isDown) {
                this.onSelectMove(event);
            }
        }.bind(this);

        this.onPointerUp = function() {
            if (this.enabled == false) return;
            this.isDown = false;
            this.onSelectOver();
        }.bind(this);

        this.renderer.domElement.addEventListener('pointerdown', this.onPointerDown);
        this.renderer.domElement.addEventListener('pointermove', this.onPointerMove);
        this.renderer.domElement.addEventListener('pointerup', this.onPointerUp);
    }

    public function dispose() {
        this.renderer.domElement.removeEventListener('pointerdown', this.onPointerDown);
        this.renderer.domElement.removeEventListener('pointermove', this.onPointerMove);
        this.renderer.domElement.removeEventListener('pointerup', this.onPointerUp);
    }

    public function onSelectStart(event : js.html.Event) {
        this.element.style.setProperty('display', 'none');
        this.renderer.domElement.parentElement.appendChild(this.element);
        this.element.style.setProperty('left', event.clientX + 'px');
        this.element.style.setProperty('top', event.clientY + 'px');
        this.element.style.setProperty('width', '0px');
        this.element.style.setProperty('height', '0px');
        this.startPoint.x = event.clientX;
        this.startPoint.y = event.clientY;
    }

    public function onSelectMove(event : js.html.Event) {
        this.element.style.setProperty('display', 'block');
        this.pointBottomRight.x = Math.max(this.startPoint.x, event.clientX);
        this.pointBottomRight.y = Math.max(this.startPoint.y, event.clientY);
        this.pointTopLeft.x = Math.min(this.startPoint.x, event.clientX);
        this.pointTopLeft.y = Math.min(this.startPoint.y, event.clientY);
        this.element.style.setProperty('left', this.pointTopLeft.x + 'px');
        this.element.style.setProperty('top', this.pointTopLeft.y + 'px');
        this.element.style.setProperty('width', (this.pointBottomRight.x - this.pointTopLeft.x) + 'px');
        this.element.style.setProperty('height', (this.pointBottomRight.y - this.pointTopLeft.y) + 'px');
    }

    public function onSelectOver() {
        this.element.parentElement.removeChild(this.element);
    }
}
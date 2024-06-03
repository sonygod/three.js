import js.html.Window;
import js.html.Element;
import js.html.Event;
import js.html.document;

class SplitscreenManager {
    private var editor: dynamic;
    private var renderer: dynamic;
    private var composer: dynamic;
    private var gutter: Element;
    private var gutterMoving: Bool;
    private var gutterOffset: Float;

    public function new(editor: dynamic) {
        this.editor = editor;
        this.renderer = editor.renderer;
        this.composer = editor.composer;
        this.gutter = null;
        this.gutterMoving = false;
        this.gutterOffset = 0.6;
    }

    public function setSplitview(value: Bool): Void {
        var nodeDOM = this.editor.domElement;
        var rendererContainer = this.renderer.domElement.parentNode;

        if (value) {
            this.addGutter(rendererContainer, nodeDOM);
        } else {
            this.removeGutter(rendererContainer, nodeDOM);
        }
    }

    private function addGutter(rendererContainer: Element, nodeDOM: Element): Void {
        rendererContainer.style['z-index'] = '20';

        this.gutter = document.createElement('f-gutter');

        nodeDOM.parentNode.appendChild(this.gutter);

        var onGutterMovement = () => {
            var offset = this.gutterOffset;

            this.gutter.style['left'] = (100 * offset) + '%';
            rendererContainer.style['left'] = (100 * offset) + '%';
            rendererContainer.style['width'] = (100 * (1 - offset)) + '%';
            nodeDOM.style['width'] = (100 * offset) + '%';
        };

        this.gutter.addEventListener('mousedown', () => {
            this.gutterMoving = true;
        });

        document.addEventListener('mousemove', (event: Event) => {
            if (this.gutter != null && this.gutterMoving) {
                this.gutterOffset = Math.max(0, Math.min(1, event.clientX / Window.innerWidth));
                onGutterMovement();
            }
        });

        document.addEventListener('mouseup', () => {
            this.gutterMoving = false;
        });

        onGutterMovement();
    }

    private function removeGutter(rendererContainer: Element, nodeDOM: Element): Void {
        rendererContainer.style['z-index'] = '0';

        this.gutter.remove();
        this.gutter = null;

        rendererContainer.style['left'] = '0%';
        rendererContainer.style['width'] = '100%';
        nodeDOM.style['width'] = '100%';
    }
}
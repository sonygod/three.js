class SplitscreenManager {
    private editor:Editor;
    private renderer:WebGLRenderer;
    private composer:Composer;
    private gutter:HTMLDivElement;
    private gutterMoving:Bool;
    private gutterOffset:Float;

    public function new(editor:Editor) {
        this.editor = editor;
        this.renderer = editor.renderer;
        this.composer = editor.composer;

        this.gutter = null;
        this.gutterMoving = false;
        this.gutterOffset = 0.6;
    }

    public function setSplitview(value:Bool) {
        var nodeDOM = this.editor.domElement;
        var rendererContainer = this.renderer.domElement.parentElement;

        if (value) {
            this.addGutter(rendererContainer, nodeDOM);
        } else {
            this.removeGutter(rendererContainer, nodeDOM);
        }
    }

    private function addGutter(rendererContainer:HTMLElement, nodeDOM:HTMLElement) {
        rendererContainer.style.zIndex = "20";

        this.gutter = <HTMLDivElement> window.document.createElement('f-gutter');

        nodeDOM.parentElement.appendChild(this.gutter);

        function onGutterMovement() {
            var offset = this.gutterOffset;

            this.gutter.style.left = (100 * offset) + "%";
            rendererContainer.style.left = (100 * offset) + "%";
            rendererContainer.style.width = (100 * (1 - offset)) + "%";
            nodeDOM.style.width = (100 * offset) + "%";
        }

        this.gutter.onMouseDown = function() {
            this.gutterMoving = true;
        };

        window.document.onMouseMove = function(event:MouseEvent) {
            if (this.gutter && this.gutterMoving) {
                this.gutterOffset = std.Math.max(0, std.Math.min(1, event.clientX / window.innerWidth));
                onGutterMovement();
            }
        };

        window.document.onMouseUp = function() {
            this.gutterMoving = false;
        };

        onGutterMovement();
    }

    private function removeGutter(rendererContainer:HTMLElement, nodeDOM:HTMLElement) {
        rendererContainer.style.zIndex = "0";

        this.gutter.remove();
        this.gutter = null;

        rendererContainer.style.left = "0%";
        rendererContainer.style.width = "100%";
        nodeDOM.style.width = "100%";
    }
}
// Define a class for the handlers
class Handlers {
    // Define a static function for onDropFile which takes a File and an Int as arguments.
    // By default, it does nothing.
    public static function onDropFile(file: js.html.File, fileNdx: Int) { }
}

// Define a class for the DragAndDrop setup
class DragAndDrop {
    // Define a private variable for the dragInfo element
    private var dragInfo: js.html.Element;

    // Define a private function for showing the drag info
    private function showDragInfo(show: Bool) {
        // Set the display style of dragInfo based on the show argument
        dragInfo.style.display = show ? '' : 'none';
    }

    // Define a public function for setting up the drag and drop functionality
    public function setup(options: Dynamic) {
        // Define the HTML string with the options message
        var html: String = `
            <style>
                .dragInfo {
                    position: fixed;
                    left: 0;
                    top: 0;
                    width: 100%;
                    height: 100%;
                    background: rgba(0, 0, 0, .9);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .dragInfo>div {
                    padding: 1em;
                    background: blue;
                    color: white;
                    pointer-events: none;
                }
                .dragerror div {
                    background: red !important;
                    font-weight: bold;
                    color: white;
                }
            </style>
            <div class="dragInfo" style="display: none;">
                <div>
                    ${options.msg}
                </div>
            </div>
        `;

        // Create a new div element for the drag info
        var elem: js.html.Element = js.html.Document.createElement('div');
        // Set the inner HTML of the element to the HTML string
        elem.innerHTML = html;
        // Append the element to the body of the document
        js.html.Document.body.appendChild(elem);

        // Get the dragInfo element from the document
        dragInfo = js.html.Document.querySelector('.dragInfo');

        // Add a dragenter event listener to the body of the document
        js.html.Document.body.addEventListener('dragenter', () => {
            // Show the drag info when the dragenter event is fired
            showDragInfo(true);
        });

        // Define a variable for the drag element
        var dragElem: js.html.Element = dragInfo;

        // Add a dragover event listener to the drag element
        dragElem.addEventListener('dragover', (e: js.html.Event) => {
            // Prevent the default behavior of the dragover event
            e.preventDefault();
            // Return false to prevent further event propagation
            return false;
        });

        // Add a dragleave event listener to the drag element
        dragElem.addEventListener('dragleave', () => {
            // Hide the drag info when the dragleave event is fired
            showDragInfo(false);
            // Return false to prevent further event propagation
            return false;
        });

        // Add a dragend event listener to the drag element
        dragElem.addEventListener('dragend', () => {
            // Hide the drag info when the dragend event is fired
            showDragInfo(false);
            // Return false to prevent further event propagation
            return false;
        });

        // Add a drop event listener to the drag element
        dragElem.addEventListener('drop', (e: js.html.Event) => {
            // Prevent the default behavior of the drop event
            e.preventDefault();
            // Hide the drag info when the drop event is fired
            showDragInfo(false);
            // Get the data transfer object from the drop event
            var dataTransfer: js.html.DataTransfer = js.html.Html.cast(e).dataTransfer;
            // If the data transfer object has items
            if (dataTransfer.items != null) {
                // Initialize a variable for the file index
                var fileNdx: Int = 0;
                // Loop through each item in the data transfer object
                for (i in 0...dataTransfer.items.length) {
                    // Get the current item
                    var item: js.html.DataTransferItem = dataTransfer.items[i];
                    // If the item is a file
                    if (item.kind == 'file') {
                        // Call the onDropFile function with the file and the file index
                        Handlers.onDropFile(item.getAsFile(), fileNdx++);
                    }
                }
            }
            // Return false to prevent further event propagation
            return false;
        });
    }
}

// Define a public function for setting the onDropFile function
public function onDropFile(fn: Function) {
    // Set the onDropFile function of the Handlers class to the provided function
    Handlers.onDropFile = fn;
}
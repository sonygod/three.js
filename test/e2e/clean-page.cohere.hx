package;

import js.Browser.Document;
import js.Browser.Element;
import js.Browser.Window;

class Main {
    static function main() {
        // Get the 'startButton' element
        var button = Document.getElementById("startButton");

        // If the button exists, click it
        if (button != null) {
            button.click();
        }

        // Create a new style element
        var style = Document.createElement("style");
        style.type = "text/css";

        // Set the style content
        style.innerHTML = "#info, button, input, body > div.lil-gui, body > div.lbl { display: none !important; }";

        // Append the style to the head of the document
        Document.querySelector("head").appendChild(style);

        // Loop through all div elements in the document
        for (element in Document.querySelectorAll("div")) {
            // Get the computed style of the element
            var computedStyle = Window.getComputedStyle(element);

            // Check if the z-index of the element is 10000
            if (computedStyle.zIndex == "10000") {
                // Remove the element
                element.remove();
                break;
            }
        }
    }
}
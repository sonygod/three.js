import js.NodeJs.NodeJs;
import js.NodeJs.Fs;
import js.NodeJs.Path;
import js.NodeJs.Process;
import js.Browser.Window;

class Main {
    static function main() {
        if (NodeJs.detect()) {
            trace("Running in Node.js");
        } else if (Window.detect()) {
            trace("Running in browser");
        } else {
            trace("Running somewhere else");
        }

        var path = "path/to/file.txt";
        if (NodeJs.detect()) {
            var fullPath = Path.join(NodeJs.cwd(), path);
            var content = Fs.read(fullPath);
            trace("File content: " + content);
        } else {
            trace("Reading file in browser is not supported");
        }

        var nodeVersion = Process.version();
        trace("Node.js version: " + nodeVersion);
    }
}

Main.main();
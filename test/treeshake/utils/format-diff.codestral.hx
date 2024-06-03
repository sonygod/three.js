import js.node.Process;
import FormatBytes; // assuming the FormatBytes class is in the same directory

class FormatDiff {
    static function main() {
        var filesize:Float = Float(Process.argv[2]);
        var filesizeBase:Float = Float(Process.argv[3]);

        var diff:Float = filesize - filesizeBase;
        var formatted:String = (diff >= 0 ? '+' : '-') + FormatBytes.formatBytes(Math.abs(diff), 2);

        console.log(formatted);
    }
}
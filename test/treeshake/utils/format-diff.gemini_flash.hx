import formatBytes from "formatBytes";

class Main {
  static function main() {
    var filesize = Std.parseFloat(Sys.args()[2]);
    var filesizeBase = Std.parseFloat(Sys.args()[3]);

    var diff = filesize - filesizeBase;
    var formatted = (diff >= 0 ? "+" : "-") + formatBytes(Math.abs(diff), 2);

    Sys.println(formatted);
  }
}
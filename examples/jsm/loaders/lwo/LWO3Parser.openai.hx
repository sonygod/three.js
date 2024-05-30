package three.js.examples.jsm.loaders.lwo;

import haxe.io.BytesInput;

class LWO3Parser {
  var IFF:IFFParser;

  public function new(IFFParser) {
    this.IFF = IFFParser;
  }

  public function parseBlock() {
    IFF.debugger.offset = IFF.reader.getPosition();
    IFF.debugger.closeForms();

    var blockID:String = IFF.reader.getIDTag();
    var length:Int = IFF.reader.getUInt32();

    IFF.debugger.dataOffset = IFF.reader.getPosition();
    IFF.debugger.length = length;

    switch (blockID) {
      // ... (rest of the switch statement remains the same)
    }
  }
}
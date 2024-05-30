function isSpace(ch: Int) -> Bool {
    return (ch < 14 && ch > 8) || ch == 32 || ch == 160;
}

function onOwnLine(text: String, pos: Int) -> Bool {
    while (pos > 0) {
        var prev = text.charCodeAt(pos - 1);
        if (prev == 10) break;
        if (!isSpace(prev)) return false;
        pos--;
    }
    return true;
}

function commentsBefore(text: String, pos: Int): Array<String> {
    var found: Array<String> = [];
    var emptyLines = 0;
    var topIsLineComment = false;
    while (pos > 0) {
        var prev = text.charCodeAt(pos - 1);
        if (prev == 10) {
            var scan = pos - 1;
            var sawNonWS = false;
            while (scan > 0) {
                prev = text.charCodeAt(scan - 1);
                if (prev == 47 && text.charCodeAt(scan - 2) == 47) {
                    if (!onOwnLine(text, scan - 2)) break;
                    var content = text.substring(scan, pos);
                    if (!emptyLines && topIsLineComment) {
                        found[0] = content + "\n" + found[0];
                    } else {
                        if (found.isEmpty()) {
                            found.push(content);
                        } else {
                            found.unshift(content);
                        }
                    }
                    topIsLineComment = true;
                    emptyLines = 0;
                    pos = scan - 2;
                    break;
                } else if (prev == 10) {
                    if (!sawNonWS && ++emptyLines > 1) break;
                    break;
                } else if (!sawNonWS && !isSpace(prev)) {
                    sawNonWS = true;
                }
                scan--;
            }
        } else if (prev == 47 && text.charCodeAt(pos - 2) == 42) {
            var scan = pos - 2;
            while (scan > 1) {
                if (text.charCodeAt(scan - 1) == 42 && text.charCodeAt(scan - 2) == 47) {
                    if (!onOwnLine(text, scan - 2)) break;
                    found.unshift(text.substring(scan, pos - 2));
                    topIsLineComment = false;
                    emptyLines = 0;
                    break;
                }
                scan--;
            }
            pos = scan - 2;
        } else if (isSpace(prev)) {
            pos--;
        } else {
            break;
        }
    }
    return found;
}

function commentAfter(text: String, pos: Int): String {
    while (pos < text.length) {
        var next = text.charCodeAt(pos);
        if (next == 47) {
            var after = text.charCodeAt(pos + 1);
            var end: Int;
            if (after == 47) { // line comment
                end = text.indexOf("\n", pos + 2);
            } else if (after == 42) { // block comment
                end = text.indexOf("*/", pos + 2);
            }
            if (end > 0) {
                return text.substring(pos + 2, end);
            }
        } else if (isSpace(next)) {
            pos++;
        } else {
            break;
        }
    }
    return "";
}

function ensureCommentsBefore(text: String, node: { start: Int, commentsBefore: Array<String> }) -> Array<String> {
    if (node.hasOwnProperty("commentsBefore")) return node.commentsBefore;
    return node.commentsBefore = commentsBefore(text, node.start);
}
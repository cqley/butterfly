import QtQuick
import Quickshell.Io

Process {
    id: root
    property var names: []
    property var found: ({})
    signal done

    function first() {
        return root.names.find(n => !!root.found[n]) || ""
    }

    command: ["sh", "-lc", 'for b in "$@"; do p=$(command -v "$b") && echo "$b $p"; done; true', "sh"].concat(root.names)
    stdout: StdioCollector {
        onStreamFinished: {
            const map = {}
            for (const line of text.trim().split("\n")) {
                const i = line.indexOf(" ")
                if (i > 0)
                    map[line.slice(0, i)] = line.slice(i + 1)
            }
            root.found = map
            root.done()
        }
    }
}

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Physical brightness of the monitor, over DDC/CI (VCP feature 0x10). The
// brightness keys drive it through `qs ipc call brightness up|down`.
//
// ddcutil takes 70-180 ms per call and calls must not overlap, while a held key
// repeats much faster than that. So `value` follows the keys right away and a
// single writer sends the monitor the latest value each time it gets free.
Singleton {
    id: root

    // Raw VCP value and the maximum the monitor reports
    property int value
    property int maximum: 100

    readonly property int percent: Math.round(value / maximum * 100)

    // False after a pause: the monitor's own buttons may have changed the value
    property bool trusted
    // Steps (in %) pressed while the current value is still being read
    property int pendingSteps
    // Last value the monitor confirmed
    property int writtenValue: -1

    // A key press was applied and `value` holds a real reading
    signal adjusted
    // The monitor could not be read, so `value` can't be relied on
    signal failed

    function step(percentDelta: int): void {
        if (trusted) {
            apply(percentDelta);
            return;
        }

        pendingSteps += percentDelta;
        reader.running = true;
    }

    function apply(percentDelta: int): void {
        const delta = Math.round(percentDelta * maximum / 100);
        value = Math.max(0, Math.min(value + delta, maximum));
        trustTimer.restart();
        flush();
        adjusted();
    }

    function flush(): void {
        if (writer.running || value === writtenValue)
            return;

        writer.target = value;
        writer.running = true;
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            root.step(5);
        }

        function down(): void {
            root.step(-5);
        }
    }

    Timer {
        id: trustTimer

        interval: 1500
        onTriggered: {
            // Never read while a write is on the bus
            if (writer.running)
                restart();
            else
                root.trusted = false;
        }
    }

    Process {
        id: reader

        command: ["ddcutil", "getvcp", "10", "--brief"]

        stdout: StdioCollector {
            onStreamFinished: {
                // Brief output: "VCP 10 C <current> <max>"
                const match = text.match(/^VCP 10 C (\d+) (\d+)/m);
                const steps = root.pendingSteps;
                root.pendingSteps = 0;

                if (!match || parseInt(match[2]) <= 0) {
                    console.warn("[Brightness] unexpected ddcutil output:", text.trim());
                    root.trusted = false;
                    root.failed();
                    return;
                }

                root.value = parseInt(match[1]);
                root.maximum = parseInt(match[2]);
                root.writtenValue = root.value;
                root.trusted = true;
                trustTimer.restart();

                if (steps !== 0)
                    root.apply(steps);
            }
        }
    }

    Process {
        id: writer

        property int target

        command: ["ddcutil", "setvcp", "10", String(target)]

        onExited: exitCode => {
            if (exitCode === 0) {
                root.writtenValue = target;
                trustTimer.restart();
                // `running` only clears after this handler returns
                Qt.callLater(root.flush);
                return;
            }

            console.warn("[Brightness] ddcutil setvcp", target, "exited with", exitCode);
            // Replace the value that never reached the monitor with the real one
            root.trusted = false;
            Qt.callLater(() => reader.running = true);
        }
    }
}

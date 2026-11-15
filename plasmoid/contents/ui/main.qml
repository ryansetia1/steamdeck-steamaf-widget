import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    implicitWidth: 320
    implicitHeight: 720   // transparent room; the card only grows as tall as its content
    Layout.minimumWidth: 300
    Layout.minimumHeight: 70
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    // ── Settings ────────────────────────────────────────────────────────────
    property bool glassMode: Plasmoid.configuration ? Plasmoid.configuration.backgroundStyle === 1 : false
    property real glassOpacity: ((Plasmoid.configuration && Plasmoid.configuration.glassOpacity) || 55) / 100
    property string currency: (Plasmoid.configuration && Plasmoid.configuration.currency) || "USD"
    onCurrencyChanged: {
        if (root.detail) root.openDetail(root.detail.id, root.detail.name);
        root.lastQuery = "";
        root.runSearch(root.queryText);
    }

    function tileColor(solid) {
        return root.glassMode ? Qt.rgba(1, 1, 1, 0.08) : solid;
    }

    // ── Verdict look (matches steamAF's dealTone) ───────────────────────────
    function verdictColor(state) {
        switch (state) {
        case "worth-it": return "#34d399";
        case "good-deal": return "#5eead4";
        case "no-rush": return "#66c0f4";
        case "wait": return "#fbbf24";
        default: return "#94a3b8";
        }
    }
    function verdictLabel(state) {
        switch (state) {
        case "worth-it": return "Worth it";
        case "good-deal": return "Good deal";
        case "no-rush": return "No rush";
        case "wait": return "Wait";
        case "free": return "Free";
        case "coming-soon": return "Coming soon";
        case "no-history": return "No history";
        default: return "";
        }
    }
    function verdictText(d) {
        switch (d.state) {
        case "worth-it": return "One of the best prices in 2 years. This is the time to buy.";
        case "good-deal": return "Below the usual sale of " + d.typical + ".";
        case "no-rush": return "The usual sale is around " + d.typical + ".";
        case "wait": return "The 2-year low is " + d.lowest + ".";
        case "no-history": return "No 2-year history yet. No verdict for now.";
        case "free": return "Free to play.";
        case "coming-soon": return "Not released yet.";
        case "unavailable": case "no-price": return "No price data available.";
        default: return "Price data is still loading. Try again in a moment.";
        }
    }
    function fmtHours(h) {
        if (!h || h <= 0) return "--";
        var whole = Math.floor(h);
        return (whole > 0 ? whole : "") + (h - whole >= 0.5 ? "½" : "") + "h";
    }

    // ── Data ────────────────────────────────────────────────────────────────
    readonly property string helper: Qt.resolvedUrl("../code/steamaf.py").toString().replace("file://", "")

    property string queryText: ""
    property var results: []
    property bool loading: false
    property string errorText: ""
    property string lastQuery: ""
    property string searchCmd: ""

    property var detail: null          // {id, name} of the open game, plus data once loaded
    property bool detailLoading: false
    property string detailError: ""
    property string detailCmd: ""

    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'"; }

    function runSearch(text) {
        text = text.trim();
        if (text === lastQuery && !errorText) return;
        lastQuery = text;
        if (text.length < 2) {
            results = []; errorText = ""; loading = false; searchCmd = "";
            return;
        }
        // Timestamp suffix keeps every command unique so the engine never serves a cached result.
        searchCmd = "python3 " + q(helper) + " search " + q(currency) + " " + q(text) + " #" + Date.now();
        loading = true;
        errorText = "";
        exec.connectSource(searchCmd);
    }

    function openDetail(id, name) {
        detail = { id: id, name: name };
        detailError = "";
        detailLoading = true;
        detailCmd = "python3 " + q(helper) + " detail " + q(currency) + " " + q(id) + " " + q(name) + " #" + Date.now();
        exec.connectSource(detailCmd);
    }

    function closeDetail() {
        detail = null; detailLoading = false; detailError = ""; detailCmd = "";
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            exec.disconnectSource(source);
            var r = null;
            try { r = JSON.parse(data["stdout"]); }
            catch (e) { r = { ok: false, error: "Helper failed: " + String(data["stderr"] || "no output").slice(0, 100) }; }

            if (source === root.searchCmd) {
                root.searchCmd = "";
                root.loading = false;
                if (r.ok) root.results = r.results;
                else { root.errorText = r.error; root.results = []; }
            } else if (source === root.detailCmd) {
                root.detailCmd = "";
                root.detailLoading = false;
                if (r.ok) {
                    var d = r;
                    d.name = root.detail ? root.detail.name : "";
                    root.detail = d;
                } else {
                    root.detailError = r.error;
                }
            }
        }
    }

    // ── UI ──────────────────────────────────────────────────────────────────
    fullRepresentation: Item {
        id: container
        anchors.fill: parent

        readonly property int pad: 8
        readonly property int rowH: 58
        readonly property int rowGap: 6
        readonly property int maxRows: 10

        Rectangle {
            id: card
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.min(content.implicitHeight + 2 * container.pad, container.height)
            clip: true
            color: root.glassMode ? Qt.rgba(0.09, 0.10, 0.14, root.glassOpacity) : "#161820"
            radius: 16
            border.color: root.glassMode ? Qt.rgba(1, 1, 1, 0.22) : "#262a36"
            border.width: 1

            Behavior on height {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Column {
                id: content
                x: container.pad
                y: container.pad
                width: card.width - 2 * container.pad
                spacing: container.pad

                // ── Search bar ──
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 10
                    color: root.tileColor("#212532")
                    border.color: input.activeFocus ? "#53B7FF" : root.tileColor("#2c3242")
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 6
                        spacing: 8

                        Kirigami.Icon {
                            id: searchIcon
                            source: root.loading ? "view-refresh" : "search"
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            opacity: 0.7
                            RotationAnimation on rotation {
                                running: root.loading
                                from: 0; to: 360; duration: 900
                                loops: Animation.Infinite
                                onStopped: searchIcon.rotation = 0
                            }
                        }

                        TextInput {
                            id: input
                            Layout.fillWidth: true
                            color: "#ffffff"
                            selectionColor: "#53B7FF"
                            font.pixelSize: 13
                            clip: true
                            verticalAlignment: TextInput.AlignVCenter
                            onTextChanged: { root.queryText = text; debounce.restart(); }
                            onAccepted: { debounce.stop(); root.closeDetail(); root.runSearch(text); }
                            Keys.onEscapePressed: {
                                if (root.detail) root.closeDetail();
                                else text = "";
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !input.text
                                textFormat: Text.StyledText
                                text: "Search <b>steam<font color='#53B7FF'>AF</font></b>…"
                                color: "#6b7385"
                                font.pixelSize: 13
                            }
                        }

                        // Clear button: an × inside a filled circle
                        Rectangle {
                            visible: input.text.length > 0
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            radius: width / 2
                            color: clearArea.containsMouse ? "#cfd8dc" : "#6b7385"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Repeater {
                                model: [45, -45]
                                Rectangle {
                                    required property int modelData
                                    anchors.centerIn: parent
                                    width: 8; height: 1.6; radius: 0.8
                                    rotation: modelData
                                    color: "#161820"
                                    antialiasing: true
                                }
                            }
                            MouseArea {
                                id: clearArea
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { input.text = ""; root.closeDetail(); input.forceActiveFocus(); }
                            }
                        }

                        // Currency chip → opens the widget settings
                        Rectangle {
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: curText.implicitWidth + 14
                            radius: 6
                            color: curArea.containsMouse ? root.tileColor("#2f3647") : "transparent"
                            border.color: root.tileColor("#2c3242")
                            border.width: 1
                            Text {
                                id: curText
                                anchors.centerIn: parent
                                text: root.currency
                                color: "#90a4ae"
                                font.pixelSize: 10
                                font.bold: true
                            }
                            MouseArea {
                                id: curArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Plasmoid.internalAction("configure").trigger()
                            }
                        }
                    }

                    Timer {
                        id: debounce
                        interval: 500
                        onTriggered: { root.closeDetail(); root.runSearch(input.text); }
                    }
                }

                // ── Status line (list mode) ──
                Text {
                    readonly property bool shown: !root.detail && root.results.length === 0
                        && (root.loading || root.errorText.length > 0 || root.lastQuery.length >= 2)
                    visible: shown
                    width: parent.width
                    height: 28
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: root.errorText ? "#ff6b6b" : "#6b7385"
                    font.pixelSize: 12
                    text: root.loading ? "Searching…" : (root.errorText || "No games found")
                }

                // ── Results list ──
                ListView {
                    id: list
                    readonly property int shownRows: Math.min(root.results.length, container.maxRows)
                    visible: !root.detail && root.results.length > 0
                    width: parent.width
                    height: visible ? shownRows * container.rowH + Math.max(0, shownRows - 1) * container.rowGap : 0
                    model: root.results
                    spacing: container.rowGap
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    opacity: root.loading ? 0.5 : 1
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        width: ListView.view.width
                        height: container.rowH
                        radius: 10
                        color: rowArea.containsMouse ? (root.glassMode ? Qt.rgba(1, 1, 1, 0.14) : "#283041") : root.tileColor("#212532")

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openDetail(row.modelData.id, row.modelData.name)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Kirigami.ShadowedImage {
                                Layout.preferredWidth: 100
                                Layout.preferredHeight: 38
                                radius: 5
                                color: root.tileColor("#2a2f3d")
                                source: row.modelData.thumb
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.name
                                    color: "#ffffff"
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Text {
                                        text: row.modelData.price || "—"
                                        color: row.modelData.state ? root.verdictColor(row.modelData.state) : "#cfd8dc"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Rectangle {
                                        visible: row.modelData.discount > 0
                                        Layout.preferredHeight: 15
                                        Layout.preferredWidth: discText.implicitWidth + 8
                                        radius: 4
                                        color: Qt.rgba(0.20, 0.83, 0.60, 0.2)
                                        Text {
                                            id: discText
                                            anchors.centerIn: parent
                                            text: "-" + row.modelData.discount + "%"
                                            color: "#8bd0b7"
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                    VerdictBadge { verdict: row.modelData.state; small: true }
                                }
                            }
                        }
                    }
                }

                // ── Detail view ──
                Column {
                    id: detailView
                    visible: !!root.detail
                    width: parent.width
                    spacing: container.pad

                    // Title row with back button
                    RowLayout {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            radius: 13
                            color: backArea.containsMouse ? root.tileColor("#2f3647") : root.tileColor("#212532")
                            Text {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: -1
                                text: "‹"
                                color: "#cfd8dc"
                                font.pixelSize: 18
                                font.bold: true
                            }
                            MouseArea {
                                id: backArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.closeDetail()
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.detail ? root.detail.name : ""
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        VerdictBadge {
                            verdict: root.detail && !root.detailLoading ? (root.detail.state || "") : ""
                        }
                    }

                    Kirigami.ShadowedImage {
                        width: parent.width
                        height: Math.round(width * 215 / 460)
                        radius: 8
                        color: root.tileColor("#212532")
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        source: root.detail ? (root.detail.image
                            || "https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/" + root.detail.id + "/header.jpg") : ""
                    }

                    // Loading / error
                    Text {
                        visible: root.detailLoading || root.detailError.length > 0
                        width: parent.width
                        height: 40
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: root.detailError ? "#ff6b6b" : "#6b7385"
                        font.pixelSize: 12
                        text: root.detailError || "Checking prices…"
                    }

                    // Price block
                    Rectangle {
                        id: priceTile
                        readonly property bool ready: !!root.detail && !root.detailLoading && !root.detailError && root.detail.state !== undefined
                        readonly property color tone: ready ? root.verdictColor(root.detail.state) : "#cfd8dc"
                        visible: ready
                        width: parent.width
                        height: priceCol.implicitHeight + 20
                        radius: 10
                        color: root.tileColor("#212532")

                        Column {
                            id: priceCol
                            x: 10; y: 10
                            width: parent.width - 20
                            spacing: 8

                            RowLayout {
                                width: parent.width
                                spacing: 8
                                Text {
                                    text: priceTile.ready ? (root.detail.current || root.verdictLabel(root.detail.state) || "—") : ""
                                    color: priceTile.tone
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                                Rectangle {
                                    visible: priceTile.ready && root.detail.discount > 0
                                    Layout.preferredHeight: 18
                                    Layout.preferredWidth: dText.implicitWidth + 10
                                    radius: 5
                                    color: Qt.rgba(0.20, 0.83, 0.60, 0.2)
                                    Text {
                                        id: dText
                                        anchors.centerIn: parent
                                        text: priceTile.ready ? "-" + root.detail.discount + "%" : ""
                                        color: "#8bd0b7"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                Text {
                                    visible: priceTile.ready && root.detail.discount > 0 && !!root.detail.original
                                    text: priceTile.ready ? (root.detail.original || "") : ""
                                    color: "#6b7385"
                                    font.pixelSize: 11
                                    font.strikeout: true
                                }
                                Item { Layout.fillWidth: true }
                            }

                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                text: priceTile.ready ? root.verdictText(root.detail) : ""
                                color: "#cfd8dc"
                                font.pixelSize: 11
                            }

                            Text {
                                visible: priceTile.ready && !!root.detail.sale
                                text: priceTile.ready ? ("⏱ " + (root.detail.sale || "")) : ""
                                color: "#fbbf24"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            // 2-year low / usual sale
                            RowLayout {
                                visible: priceTile.ready && (!!root.detail.lowest || !!root.detail.typical)
                                width: parent.width
                                spacing: 6
                                Repeater {
                                    model: priceTile.ready ? [
                                        { label: "2-YEAR LOW", value: root.detail.lowest },
                                        { label: "USUAL SALE", value: root.detail.typical }
                                    ] : []
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 36
                                        radius: 7
                                        color: root.glassMode ? Qt.rgba(0, 0, 0, 0.22) : "#1a1d27"
                                        Column {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 9
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text { text: modelData.label; color: "#90a4ae"; font.pixelSize: 9; font.bold: true }
                                            Text { text: modelData.value || "—"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // HowLongToBeat
                    Rectangle {
                        visible: priceTile.ready && !!root.detail.hltb
                        width: parent.width
                        height: 62
                        radius: 10
                        color: root.tileColor("#212532")

                        Column {
                            x: 10; y: 8
                            width: parent.width - 20
                            spacing: 5
                            Text { text: "HOWLONGTOBEAT"; color: "#90a4ae"; font.pixelSize: 9; font.bold: true }
                            RowLayout {
                                width: parent.width
                                spacing: 6
                                Repeater {
                                    model: priceTile.ready && root.detail.hltb ? [
                                        { label: "Main", value: root.detail.hltb.main, accent: "#4a8fe7" },
                                        { label: "Main+", value: root.detail.hltb.plus, accent: "#a78bfa" },
                                        { label: "100%", value: root.detail.hltb.full, accent: "#f87171" }
                                    ] : []
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 28
                                        radius: 6
                                        color: root.glassMode ? Qt.rgba(0, 0, 0, 0.22) : "#1a1d27"
                                        Rectangle {
                                            width: 3; height: parent.height - 12; radius: 1.5
                                            anchors.left: parent.left
                                            anchors.leftMargin: 6
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: modelData.accent
                                        }
                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 14
                                            anchors.verticalCenter: parent.verticalCenter
                                            textFormat: Text.StyledText
                                            text: "<font color='#90a4ae'>" + modelData.label + "</font>  <b>" + root.fmtHours(modelData.value) + "</b>"
                                            color: "#ffffff"
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Links
                    RowLayout {
                        visible: !!root.detail
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: root.detail ? [
                                { label: "Open in Steam", url: "https://store.steampowered.com/app/" + root.detail.id },
                                { label: "Open steamAF", url: "https://steamaf.vercel.app/game/" + root.detail.id }
                            ] : []
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 8
                                color: linkArea.containsMouse ? root.tileColor("#2f3647") : root.tileColor("#212532")
                                border.color: root.tileColor("#2c3242")
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: "#cfd8dc"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                                MouseArea {
                                    id: linkArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally(modelData.url)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

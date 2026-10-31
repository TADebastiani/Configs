# StatusBar etapa 3 (popout de bluetooth) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Passar o mouse no ícone de bluetooth da barra abre um popout com os switches do adaptador (Ativado, Buscando) e a lista de todos os dispositivos, cada um com botão de link (parear/conectar/desconectar) e lixeira (esquecer, só pareados).

**Architecture:** Um `StyledSwitch` novo (só entrada, emite `toggled`) e um `BluetoothPopout` novo que lê e escreve direto em `Quickshell.Bluetooth` (adaptador e dispositivos), sem serviço. O `StatusIcons` hospeda o `HoverPopup` no glifo de bluetooth e estende o `openPopup` da etapa 2 com `"bluetooth"` e uma guarda `hasAdapter`.

**Tech Stack:** Quickshell 0.3.1 (QML, Qt 6), `Quickshell.Bluetooth`, Hyprland 0.56.

**Spec:** `docs/superpowers/specs/2026-09-21-statusbar-stage3-bluetooth-design.md` (continua as etapas 1 e 2, já implementadas e commitadas)

## Global Constraints

- Sem imports do Caelestia (`Caelestia`, `Caelestia.Config`, `Tokens`, `CUtils`). O popout do Caelestia é só referência de UX.
- Lista: **todos** os `Bluetooth.devices` (pareados ou só descobertos), ordenados por conectado, depois pareado, depois nome.
- Botão de link: não pareado → `pair()`; pareado e desconectado → `connected = true`; conectado → `connected = false`. Glifo `link` para parear/conectar e `linkOff` para desconectar.
- Lixeira: `forget()`, **sem confirmação**, só com `paired` (`paired` é `false` para dispositivos só descobertos; nunca `bonded`).
- Estado de carga (`Connecting`, `Disconnecting` ou `pairing`): o botão de link mostra o glifo de carregando girando e fica desabilitado. Na lógica, usar sempre o nome do membro do enum (`BluetoothDeviceState.Connecting`), nunca o número.
- Busca **manual**: o popout nunca liga nem desliga `discovering` sozinho.
- Adaptador em `Disabled`: o popout mostra só o switch **Ativado**. Em `Enabling`, `Disabling` e `Blocked`: o switch Ativado fica desabilitado (mostra o valor atual de `adapter.enabled`) e o resto também fica oculto. Contagem, switch Buscando e lista só aparecem com `state === Enabled`.
- Altura da lista limitada a `bluetoothPopoutMaxRows` (8) linhas, com rolagem por roda (`Flickable` + `Column` + `Repeater`, não `ListView`, para a altura ser exata na primeira medição do `HoverPopup`).
- `StyledSwitch.checked` é só entrada: o switch nunca atribui a si mesmo; o clique emite `toggled(!checked)` e o dono escreve na propriedade do adaptador (mesmo contrato do `StyledSlider`).
- O popout abre em hover real do ícone de bluetooth; `openPopup = "bluetooth"` só com adaptador presente; fecha pelo `dismissRequested` do `HoverPopup` (150 ms). Só um popup aberto por vez.
- Sem adaptador: sem ícone, sem popout, `openPopup` volta a `""` (guarda `hasAdapter`, no padrão do `hasSink`).
- Cores do `Theme`, raios de `Config.rounding`, espaçamentos de `Config.spacing`/`Config.padding`. Botões de 32 × 32 com `StateLayer` (`color: Theme.text`).
- Fora de escopo: agente de pareamento (PIN), `discoverable`, renomear, `trusted`/`blocked`, página de detalhes, busca automática, confirmação ao esquecer.
- **Sem commits e sem `git add`** durante a execução: o usuário commita tudo à mão no fim (memória `feedback-user-commits-manually`). Não adicionar `Co-Authored-By`. Ignorar os passos de commit de qualquer skill.
- **Nunca agir nos dispositivos reais do usuário:** nada de `bluetoothctl connect/disconnect/pair/remove/scan/power/trust/block`, nenhuma escrita em propriedade do adaptador ou de dispositivo, nenhuma chamada a `connect()`/`disconnect()`/`pair()`/`forget()` (nem em probes). `bluetoothctl devices`, `bluetoothctl show` e `bluetoothctl info <MAC>` são somente leitura e permitidos.

## Como verificar (vale para todas as tasks)

Não existem testes automatizados de QML. A verificação é: o shell recarrega sem erro/aviso novo no log, mais probes temporários com o valor calculado. **Não mova o mouse, não clique, não troque de workspace e não aja no bluetooth real** (o usuário testa hover/clique; memória `feedback-dont-drive-desktop`). Tudo que precisa de hover/clique reais vai para o usuário como checklist na Task 3.

Helper (rodar a partir de `/home/tiagod/Configs/quickshell/.config/quickshell`):

```bash
# recarrega (o watchFiles às vezes ignora edições; o touch garante) e mostra o log desde o último reload
touch shell.qml; sleep 4
qs log | awk '/Reloading configuration/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' | sed 's/\x1b\[[0-9;]*m//g'
```

O log já tem avisos de base que **não** são deste trabalho: os dois de `Connections at @services/Audio.qml[105:5]` (`Implicitly defined onFoo...` e `Cannot assign to non-existent property "onTargetChanged"`). Qualquer outra linha `WARN`/`ERROR` é nova. (Na primeira carga do shell aparecem também avisos de ícone vazio e de portal; eles não se repetem no reload.)

Se o log reclamar que um **tipo novo não existe** (`X is not a type`, `qmldir`), o `qmldir` virtual ficou em cache: o Quickshell precisa ser reiniciado. Peça ao usuário para reiniciar (`qs kill; quickshell -d`) em vez de reiniciar por conta própria.

O bluetooth chega 2–4 s depois do shell iniciar (medido na etapa 1): probes que leem `Bluetooth.*` usam `interval: 6000`.

Probes temporários levam o marcador `TEMP-PROBE-STAGE3` na linha do comentário e **têm que ser removidos** no fim da task que os cria. Confira com:

```bash
grep -rn "TEMP-PROBE-STAGE3\|probe3" /home/tiagod/Configs/quickshell/.config/quickshell --include='*.qml'
```

Saída esperada depois da remoção: vazia.

O repositório tem mudanças não commitadas que **não** são deste trabalho (`ARCHITECTURE.md`, outras pastas do dotfiles). Não use `git add`.

## File Structure

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `components/StyledSwitch.qml` | criar | switch: trilho, alça, estado desabilitado; emite `toggled` |
| `configs/IconsConfig.qml` | modificar | glifos de tipo de dispositivo, `link`, `linkOff`, `trash`, `loading` |
| `configs/BarSizes.qml` | modificar | `bluetoothPopoutWidth`, `bluetoothPopoutMaxRows` |
| `modules/bar/components/BluetoothPopout.qml` | criar | conteúdo do popup: switches, contagem, lista |
| `modules/bar/components/StatusIcons.qml` | modificar | `hasAdapter`, `HoverHandler` + `HoverPopup` no glifo de bluetooth |

---

### Task 1: `StyledSwitch`

**Files:**
- Create: `components/StyledSwitch.qml`
- Modify (temporário): `modules/bar/components/StatusIcons.qml` (probe, removido no fim da task)

**Interfaces:**
- Consumes: `Theme.active`, `Theme.surface2`, `Theme.text`, `StyledRect`, `Anim` (todos já existem).
- Produces (para a Task 2):
  - `StyledSwitch { property bool checked; signal toggled(bool checked) }`. O `enabled` do `Item` desabilita o switch (opacidade 0,5, sem clique).
  - Tamanho implícito 36 × 20.

- [ ] **Step 1: Guardar a linha de base do log**

```bash
cd /home/tiagod/Configs/quickshell/.config/quickshell
touch shell.qml; sleep 4
qs log | awk '/Reloading configuration/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' | sed 's/\x1b\[[0-9;]*m//g' | grep "WARN\|ERROR"
```

Expected: só os dois avisos de base de `Audio.qml[105:5]`. Se aparecer mais alguma linha, anotar no relatório: é a linha de base desta execução.

- [ ] **Step 2: Criar `components/StyledSwitch.qml`**

```qml
import QtQuick
import qs

// Toggle switch. `checked` is input only: a click emits `toggled` with the
// requested value and never assigns `checked`, so the owner's binding
// (e.g. to adapter.enabled) stays intact.
Item {
    id: root

    property bool checked

    signal toggled(bool checked)

    implicitWidth: 36
    implicitHeight: 20
    opacity: enabled ? 1 : 0.5

    StyledRect {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.active : Theme.surface2
    }

    StyledRect {
        id: thumb

        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 3 : 3
        width: 14
        height: 14
        radius: width / 2
        color: Theme.text

        Behavior on x {
            Anim {}
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: root.toggled(!root.checked)
    }
}
```

Conferência: com `width = 36`, a alça (14 px, margem 3) fica em `x = 3` desligado e `x = 36 - 14 - 3 = 19` ligado. `enabled: false` no `Item` desabilita também o `MouseArea` filho.

- [ ] **Step 3: Probe temporário no `StatusIcons.qml`**

Como filho direto do `StyledRect` raiz (por exemplo logo antes de `Row { id: row`). O caminho é relativo a `modules/bar/components/`:

```qml
    // TEMP-PROBE-STAGE3
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            const c = Qt.createComponent(Qt.resolvedUrl("../../../components/StyledSwitch.qml"));
            if (c.status !== Component.Ready) {
                console.log("[probe3] StyledSwitch FAILED: " + c.errorString());
                return;
            }
            const o = c.createObject(null, { checked: true });
            console.log("[probe3] StyledSwitch size=" + o.implicitWidth + "x" + o.implicitHeight + " checked=" + o.checked + " opacity=" + o.opacity);
            o.enabled = false;
            console.log("[probe3] StyledSwitch disabled opacity=" + o.opacity);
            o.destroy();
        }
    }
```

- [ ] **Step 4: Recarregar e conferir**

```bash
cd /home/tiagod/Configs/quickshell/.config/quickshell
touch shell.qml; sleep 6
qs log | awk '/Reloading configuration/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' | sed 's/\x1b\[[0-9;]*m//g' | grep -i "probe3\|WARN\|ERROR"
```

Expected:
- `[probe3] StyledSwitch size=36x20 checked=true opacity=1`
- `[probe3] StyledSwitch disabled opacity=0.5`
- Nenhum `FAILED`, nenhum `WARN`/`ERROR` além da linha de base do Step 1.

Se aparecer `FAILED: ... is not a type` ou erro de `Anim`/`StyledRect`, é o cache do `qmldir` virtual: pedir ao usuário para reiniciar o Quickshell.

- [ ] **Step 5: Remover o probe**

Apagar o bloco `TEMP-PROBE-STAGE3` do `StatusIcons.qml`. Conferir com o `grep` de "Como verificar" (saída vazia) e comparar `StatusIcons.qml` com o estado antes da task (sem diferença). Recarregar uma vez e confirmar que o log volta à linha de base.

---

### Task 2: Config e `BluetoothPopout`

**Files:**
- Modify: `configs/IconsConfig.qml` (depois de `bluetoothConnected`)
- Modify: `configs/BarSizes.qml` (depois de `audioPopoutWidth`)
- Create: `modules/bar/components/BluetoothPopout.qml`
- Modify (temporário): `modules/bar/components/StatusIcons.qml` (probe, removido no fim da task)

**Interfaces:**
- Consumes (Task 1): `StyledSwitch { checked; toggled(bool); enabled }`. E da etapa 1: `Config.icons.bluetooth`, `Bluetooth.defaultAdapter`, `Bluetooth.devices`.
- Produces (para a Task 3):
  - `BluetoothPopout` (sem propriedades obrigatórias; tem `implicitWidth`/`implicitHeight`, que o `HoverPopup` mede) e a função `deviceGlyph(icon: string): string`.
  - `Config.icons.btHeadset`, `btHeadphones`, `btSpeaker`, `btGamepad`, `btKeyboard`, `btMouse`, `btTablet`, `btPhone`, `btComputer`, `btPrinter`, `btCamera`, `link`, `linkOff`, `trash`, `loading`.
  - `Config.sizes.bar.bluetoothPopoutWidth: int` (320), `Config.sizes.bar.bluetoothPopoutMaxRows: int` (8).

- [ ] **Step 1: Glifos em `configs/IconsConfig.qml`**

Depois de `readonly property string bluetoothConnected: ...`, antes do `}` final:

```qml

    // Bluetooth popout: device type glyphs (BlueZ theme icon names map to
    // these in BluetoothPopout.deviceGlyph) and row actions
    readonly property string btHeadset: String.fromCodePoint(0xF02CE)
    readonly property string btHeadphones: String.fromCodePoint(0xF02CB)
    readonly property string btSpeaker: String.fromCodePoint(0xF04C3)
    readonly property string btGamepad: String.fromCodePoint(0xF0297)
    readonly property string btKeyboard: String.fromCodePoint(0xF030C)
    readonly property string btMouse: String.fromCodePoint(0xF037D)
    readonly property string btTablet: String.fromCodePoint(0xF04F6)
    readonly property string btPhone: String.fromCodePoint(0xF011C)
    readonly property string btComputer: String.fromCodePoint(0xF0322)
    readonly property string btPrinter: String.fromCodePoint(0xF042A)
    readonly property string btCamera: String.fromCodePoint(0xF0100)

    readonly property string link: String.fromCodePoint(0xF0337)
    readonly property string linkOff: String.fromCodePoint(0xF0338)
    readonly property string trash: String.fromCodePoint(0xF01B4)
    readonly property string loading: String.fromCodePoint(0xF0772)
```

- [ ] **Step 2: Tamanhos em `configs/BarSizes.qml`**

Depois de `readonly property int audioPopoutWidth: 280`:

```qml
    readonly property int bluetoothPopoutWidth: 320
    readonly property int bluetoothPopoutMaxRows: 8
```

- [ ] **Step 3: Criar `modules/bar/components/BluetoothPopout.qml`**

```qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.configs
import qs.components

// Content of the bluetooth popout: adapter switches, a device count and the
// list of every known device. It reads and writes Quickshell.Bluetooth
// directly; there is no service in between.
Item {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    // The rest of the popout is only shown once the adapter is fully on
    readonly property bool showDetails: adapter?.state === BluetoothAdapterState.Enabled
    // Not while the adapter is switching on/off or blocked
    readonly property bool switchable: adapter?.state === BluetoothAdapterState.Enabled || adapter?.state === BluetoothAdapterState.Disabled

    readonly property int deviceCount: Bluetooth.devices.values.length
    readonly property int connectedCount: [...Bluetooth.devices.values].filter(d => d.connected).length

    readonly property int rowHeight: 32
    readonly property int maxListHeight: Config.sizes.bar.bluetoothPopoutMaxRows * rowHeight + (Config.sizes.bar.bluetoothPopoutMaxRows - 1) * Config.spacing.extraSmall

    // BlueZ theme icon name -> glyph; anything unknown gets the generic one
    function deviceGlyph(icon: string): string {
        switch (icon) {
        case "audio-headset":
            return Config.icons.btHeadset;
        case "audio-headphones":
            return Config.icons.btHeadphones;
        case "audio-card":
            return Config.icons.btSpeaker;
        case "input-gaming":
            return Config.icons.btGamepad;
        case "input-keyboard":
            return Config.icons.btKeyboard;
        case "input-mouse":
            return Config.icons.btMouse;
        case "input-tablet":
            return Config.icons.btTablet;
        case "phone":
            return Config.icons.btPhone;
        case "computer":
            return Config.icons.btComputer;
        case "printer":
            return Config.icons.btPrinter;
        case "camera-photo":
        case "camera-video":
            return Config.icons.btCamera;
        default:
            return Config.icons.bluetooth;
        }
    }

    // Column is a positioner and rewrites its own implicit size, so the width
    // the HoverPopup measures lives on this wrapper
    implicitWidth: Config.sizes.bar.bluetoothPopoutWidth
    implicitHeight: column.implicitHeight

    Column {
        id: column

        width: parent.width
        spacing: Config.spacing.small

        SwitchRow {
            label: qsTr("Ativado")
            checked: root.adapter?.enabled ?? false
            switchEnabled: root.switchable
            onToggled: value => {
                if (root.adapter)
                    root.adapter.enabled = value;
            }
        }

        SwitchRow {
            visible: root.showDetails
            label: qsTr("Buscando")
            checked: root.adapter?.discovering ?? false
            onToggled: value => {
                if (root.adapter)
                    root.adapter.discovering = value;
            }
        }

        StyledText {
            visible: root.showDetails
            width: parent.width
            color: Theme.subtext0
            text: {
                const total = root.deviceCount;
                const connected = root.connectedCount;
                let s = total === 1 ? qsTr("%1 dispositivo").arg(total) : qsTr("%1 dispositivos").arg(total);
                if (connected > 0)
                    s += connected === 1 ? qsTr(" (%1 conectado)").arg(connected) : qsTr(" (%1 conectados)").arg(connected);
                return s;
            }
        }

        Flickable {
            id: flick

            visible: root.showDetails
            width: parent.width
            height: Math.min(list.implicitHeight, root.maxListHeight)
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: list

                width: flick.width
                spacing: Config.spacing.extraSmall

                Repeater {
                    // ScriptModel keeps each row's identity when the order changes
                    model: ScriptModel {
                        values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
                    }

                    DeviceRow {}
                }
            }
        }
    }

    component SwitchRow: RowLayout {
        id: switchRow

        required property string label
        property alias checked: sw.checked
        property alias switchEnabled: sw.enabled

        signal toggled(bool value)

        width: parent.width
        spacing: Config.spacing.medium

        StyledText {
            Layout.fillWidth: true
            text: switchRow.label
        }

        StyledSwitch {
            id: sw

            onToggled: v => switchRow.toggled(v)
        }
    }

    component ActionButton: StyledRect {
        id: btn

        required property string glyph
        // Shows the spinner instead of the glyph (and blocks clicks)
        property bool busy
        // Blocks clicks only, keeping the glyph
        property bool disabled

        signal clicked

        Layout.preferredWidth: root.rowHeight
        Layout.minimumWidth: root.rowHeight
        Layout.preferredHeight: root.rowHeight
        radius: Config.rounding.small

        StyledText {
            anchors.centerIn: parent
            visible: !btn.busy
            text: btn.glyph
            font.pixelSize: Config.font.size.large
        }

        // Only spins while shown, so the glyphs never keep a stale rotation
        StyledText {
            id: spinner

            anchors.centerIn: parent
            visible: btn.busy
            text: Config.icons.loading
            font.pixelSize: Config.font.size.large

            RotationAnimator on rotation {
                running: spinner.visible
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
        }

        StateLayer {
            // The popup background is surface0, the StateLayer default
            color: Theme.text
            disabled: btn.busy || btn.disabled
            onClicked: btn.clicked()
        }
    }

    component DeviceRow: RowLayout {
        id: dev

        required property BluetoothDevice modelData

        readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting || modelData.pairing

        // Unpaired: pair. Paired: toggle the connection.
        function toggleLink(): void {
            if (!modelData.paired)
                modelData.pair();
            else
                modelData.connected = !modelData.connected;
        }

        width: parent.width
        spacing: Config.spacing.small

        StyledText {
            Layout.preferredWidth: 24
            Layout.minimumWidth: 24
            horizontalAlignment: Text.AlignHCenter
            text: root.deviceGlyph(dev.modelData.icon)
            color: dev.modelData.connected ? Theme.active : dev.modelData.paired ? Theme.text : Theme.subtext0
            font.pixelSize: Config.font.size.large
        }

        StyledText {
            Layout.fillWidth: true
            text: dev.modelData.name
            color: dev.modelData.paired ? Theme.text : Theme.subtext0
            elide: Text.ElideRight
        }

        StyledText {
            visible: dev.modelData.batteryAvailable
            text: Math.round(dev.modelData.battery * 100) + "%"
            color: Theme.subtext0
        }

        // Trash goes left of the link button so the link column stays aligned
        // whether or not the device is paired
        ActionButton {
            visible: dev.modelData.paired
            glyph: Config.icons.trash
            // The whole row is inert while a connection or pairing is in flight
            disabled: dev.busy
            onClicked: dev.modelData.forget()
        }

        ActionButton {
            glyph: dev.modelData.connected ? Config.icons.linkOff : Config.icons.link
            busy: dev.busy
            onClicked: dev.toggleLink()
        }
    }
}
```

- [ ] **Step 4: Probe temporário no `StatusIcons.qml`**

O conteúdo do popup só é carregado no hover, então o log não mostraria nada por si só. O probe compila e instancia o `BluetoothPopout` fora da tela, confere os glifos e a tabela de `deviceGlyph` (com pass/fail) e loga a ordem real da lista. Ele **só lê**: não chama `connect`, `pair`, `forget` nem escreve em nenhuma propriedade. Como filho direto do `StyledRect` raiz:

```qml
    // TEMP-PROBE-STAGE3
    Timer {
        interval: 6000
        running: true
        onTriggered: {
            const c = Qt.createComponent(Qt.resolvedUrl("BluetoothPopout.qml"));
            if (c.status !== Component.Ready) {
                console.log("[probe3] BluetoothPopout FAILED: " + c.errorString());
                return;
            }
            const o = c.createObject(null);
            console.log("[probe3] BluetoothPopout size=" + o.implicitWidth + "x" + o.implicitHeight + " showDetails=" + o.showDetails + " devices=" + o.deviceCount + " connected=" + o.connectedCount);

            const expect = {
                "audio-headset": 0xF02CE, "audio-headphones": 0xF02CB, "audio-card": 0xF04C3,
                "input-gaming": 0xF0297, "input-keyboard": 0xF030C, "input-mouse": 0xF037D,
                "input-tablet": 0xF04F6, "phone": 0xF011C, "computer": 0xF0322, "printer": 0xF042A,
                "camera-photo": 0xF0100, "camera-video": 0xF0100, "something-else": 0xF00AF
            };
            let bad = 0;
            for (const k in expect) {
                const got = o.deviceGlyph(k).codePointAt(0);
                if (got !== expect[k]) {
                    bad++;
                    console.log("[probe3] MISMATCH " + k + " got " + got.toString(16));
                }
            }
            console.log("[probe3] deviceGlyph table checked, mismatches=" + bad);

            const want = { link: 0xF0337, linkOff: 0xF0338, trash: 0xF01B4, loading: 0xF0772 };
            for (const k in want)
                if (Config.icons[k].codePointAt(0) !== want[k])
                    console.log("[probe3] MISMATCH icon " + k);
            console.log("[probe3] bluetoothPopoutWidth=" + Config.sizes.bar.bluetoothPopoutWidth + " maxRows=" + Config.sizes.bar.bluetoothPopoutMaxRows);

            const order = [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name));
            console.log("[probe3] order: " + order.map(d => d.name + "(paired=" + d.paired + ",connected=" + d.connected + ",icon=" + d.icon + ")").join(" | "));
            o.destroy();
        }
    }
```

- [ ] **Step 5: Recarregar e conferir**

Antes, a leitura somente-leitura do estado real, para comparar:

```bash
bluetoothctl devices; for m in $(bluetoothctl devices | awk '{print $2}'); do bluetoothctl info $m | grep -E "Name|Paired|Connected|Icon"; done
cd /home/tiagod/Configs/quickshell/.config/quickshell
touch shell.qml; sleep 9
qs log | awk '/Reloading configuration/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' | sed 's/\x1b\[[0-9;]*m//g' | grep -i "probe3\|WARN\|ERROR"
```

Expected:
- `[probe3] BluetoothPopout size=320x<altura>` com `showDetails=true` (adaptador ligado) e `devices=<N>` igual ao número de linhas de `bluetoothctl devices`. A altura fica perto de `20 + 20 + 17 + (32·N + 4·(N−1)) + 24` (duas linhas de switch, a contagem, a lista e três espaçamentos de 8 px): para N = 3, algo perto de 185. Basta ser coerente com N (e ≤ o teto de 8 linhas).
- `[probe3] deviceGlyph table checked, mismatches=0` e nenhuma linha `MISMATCH`.
- `[probe3] bluetoothPopoutWidth=320 maxRows=8`.
- `[probe3] order:` com a ordem certa: conectados primeiro, depois pareados, depois o resto, e por nome dentro de cada grupo (por exemplo, com JBL e Xbox pareados e o Keychron não pareado: `JBL Charge 3`, `Xbox Wireless Controller`, `Keychron K3`, salvo se algum estiver conectado, caso em que ele sobe). Os `paired=`/`connected=` do probe batem com o `bluetoothctl info`.
- Nenhum `FAILED`, nenhum `WARN`/`ERROR` além da linha de base.

Se `showDetails=false` ou `devices=0`, o bluetooth pode ainda não ter chegado: repetir com `interval` maior antes de concluir que há bug. Se aparecer `FAILED: ... is not a type`, pedir ao usuário para reiniciar o Quickshell (cache do `qmldir`).

- [ ] **Step 6: Remover o probe**

Apagar o bloco `TEMP-PROBE-STAGE3` do `StatusIcons.qml`. Conferir com o `grep` de "Como verificar" (saída vazia) e que `StatusIcons.qml` ficou idêntico ao estado antes desta task. Recarregar uma vez e confirmar que o log volta à linha de base.

---

### Task 3: Ligar o popout ao ícone de bluetooth

**Files:**
- Modify: `modules/bar/components/StatusIcons.qml` (comentário e guarda na raiz; `DelegateChoice` de `bluetooth`)

**Interfaces:**
- Consumes: `HoverPopup` (etapa 1: `required property Item target`, `property bool targetHovered`, `property bool open`, `property Component content`, `signal dismissRequested`); `BluetoothPopout` (Task 2); `root.adapter` (já existe no `StatusIcons`).
- Produces: `StatusIcons.openPopup` aceita `"bluetooth"`; guarda `hasAdapter`. A etapa 4 (rede) usará o mesmo `openPopup` com `"network"`.

- [ ] **Step 1: Atualizar o comentário do `openPopup`**

De:

```qml
    // Which status popup is open, if any ("" or "audio"). Held here so that
    // only one is open at a time when more popouts exist.
    property string openPopup
```

Para:

```qml
    // Which status popup is open, if any ("", "audio" or "bluetooth"). Held
    // here so that only one is open at a time.
    property string openPopup
```

- [ ] **Step 2: Adicionar a guarda `hasAdapter`**

Logo depois de `readonly property bool btConnected: [...Bluetooth.devices.values].some(d => d.connected)`:

```qml

    // Same as hasSink: the bluetooth icon hides without an adapter, so its
    // popout must not stay "open" in the background
    readonly property bool hasAdapter: adapter !== null
    onHasAdapterChanged: {
        if (!hasAdapter && openPopup === "bluetooth")
            openPopup = "";
    }
```

- [ ] **Step 3: Trocar o `DelegateChoice` de `bluetooth`**

De:

```qml
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Glyph {
                        visible: root.adapter !== null
                        text: !root.btOn ? Config.icons.bluetoothOff : root.btConnected ? Config.icons.bluetoothConnected : Config.icons.bluetooth
                        color: root.btOn ? Theme.text : Theme.subtext0
                    }
                }
```

Para:

```qml
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Glyph {
                        id: bluetoothIcon

                        visible: root.adapter !== null
                        text: !root.btOn ? Config.icons.bluetoothOff : root.btConnected ? Config.icons.bluetoothConnected : Config.icons.bluetooth
                        color: root.btOn ? Theme.text : Theme.subtext0

                        // Glyph is a plain text item: it has no hover of its own
                        HoverHandler {
                            id: bluetoothHover

                            onHoveredChanged: {
                                if (hovered && root.adapter !== null)
                                    root.openPopup = "bluetooth";
                            }
                        }

                        HoverPopup {
                            target: bluetoothIcon
                            targetHovered: bluetoothHover.hovered
                            // Without an adapter there is nothing to show
                            open: root.openPopup === "bluetooth" && root.adapter !== null
                            onDismissRequested: {
                                if (root.openPopup === "bluetooth")
                                    root.openPopup = "";
                            }

                            content: Component {
                                BluetoothPopout {}
                            }
                        }
                    }
                }
```

`BluetoothPopout` está na mesma pasta que o `StatusIcons`, então não precisa de import (mesmo caso do `AudioPopout`). Nenhum outro delegate muda.

- [ ] **Step 4: Recarregar e conferir o log**

```bash
cd /home/tiagod/Configs/quickshell/.config/quickshell
touch shell.qml; sleep 6
qs log | awk '/Reloading configuration/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' | sed 's/\x1b\[[0-9;]*m//g' | grep "WARN\|ERROR"
grep -rn "TEMP-PROBE-STAGE3\|probe3" /home/tiagod/Configs/quickshell/.config/quickshell --include='*.qml'
```

Expected: só os avisos da linha de base; o `grep` de probes devolve vazio. O `HoverPopup` é instanciado no carregamento (a janela só mapeia com `open`), então erros de propriedade obrigatória ou de âncora apareceriam aqui. O conteúdo (`BluetoothPopout`) só carrega no hover e já foi validado na Task 2.

Se surgir erro de âncora ou de `required property`, comparar com o delegate de `audio` no mesmo arquivo (mesmo padrão).

- [ ] **Step 5: Checklist para o usuário (o hover e o clique reais não são verificados por mim)**

Passar ao usuário, dizendo explicitamente que **não foi verificado por mim**:

1. Passar o mouse no ícone de bluetooth: o popup sobe de trás da barra em ~400 ms, com os switches **Ativado** e **Buscando**, a contagem e a lista (JBL e Xbox pareados, mais o Keychron se o BlueZ ainda o listar).
2. Ir do ícone para dentro do popup: não fecha. Sair dos dois: fecha ~150 ms depois. Ir do ícone de áudio para o de bluetooth: o de áudio desce e o de bluetooth sobe.
3. Switch **Ativado**: ao desligar, o ícone da barra vira "desligado" e o popup passa a mostrar só esse switch; ao ligar, a lista volta.
4. Switch **Buscando**: aparecem dispositivos vizinhos (linhas em `subtext0`, sem lixeira). Confira se as linhas novas entram no meio da lista sem quebrar nada. Desligue a busca depois.
5. Botão de link no **JBL** (pareado): conectar mostra o glifo girando e depois o ícone da barra vira "conectado" e o JBL sobe para o topo; clicar de novo desconecta.
6. Parear um dispositivo novo (use um "Just Works", como uma caixa de som): o primeiro clique em link pareia (aparece a lixeira), o segundo conecta. Dispositivos que pedem PIN vão falhar em silêncio, é a limitação conhecida.
7. Lixeira: **é imediata e sem confirmação.** Teste só em um dispositivo que dê para parear de novo sem dor (o JBL, não o controle do Xbox, que exige reparear com o botão físico).
8. Com mais de 8 dispositivos (com a busca ligada num lugar movimentado), a lista rola com a roda e o popup para de crescer.
9. O popup não fecha durante o clique nos botões e switches, e o popout de áudio e o menu do tray continuam funcionando como antes.

- [ ] **Step 6: Relatório final (sem commit)**

Listar os arquivos alterados e criados, sem `git add` nem commit:

```
components/StyledSwitch.qml                     (novo)
configs/IconsConfig.qml
configs/BarSizes.qml
modules/bar/components/BluetoothPopout.qml      (novo)
modules/bar/components/StatusIcons.qml
docs/superpowers/specs/2026-09-21-statusbar-stage3-bluetooth-design.md
docs/superpowers/plans/2026-09-21-statusbar-stage3-bluetooth.md
```

Oferecer ao usuário, para ele rodar se quiser, sem `Co-Authored-By`, a partir de `~/Configs`:

```bash
git add quickshell/.config/quickshell/{components/StyledSwitch.qml,configs/IconsConfig.qml,configs/BarSizes.qml,modules/bar/components/BluetoothPopout.qml,modules/bar/components/StatusIcons.qml,docs/superpowers/specs/2026-09-21-statusbar-stage3-bluetooth-design.md,docs/superpowers/plans/2026-09-21-statusbar-stage3-bluetooth.md}
git commit -m "add bluetooth popout to status icons"
```

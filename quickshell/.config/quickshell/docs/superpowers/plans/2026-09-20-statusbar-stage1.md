# StatusBar etapa 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar na barra inferior um bloco de ícones de status ao vivo (áudio, microfone, rede, bluetooth, layout de teclado) e extrair o popup do `TrayItem` para um `HoverPopup` reutilizável.

**Architecture:** Glifos Nerd Font (Material Design) ficam em `Config.icons`; serviços singleton (`Audio`, `Network`, `Keyboard`) expõem o glifo/texto já calculado; `StatusIcons` é um `StyledRect` com uma `Row` de `StyledText`, montada por um `DelegateChooser` sobre `Config.bar.statusIcons`. O `HoverPopup` é um `PopupWindow` com o slide/settle/hover-close do `TrayItem` atual, e o dono decide quando abrir.

**Tech Stack:** Quickshell 0.3.1 (QML, Qt 6), `Quickshell.Networking`, `Quickshell.Bluetooth`, `Quickshell.Services.Pipewire`, `Quickshell.Hyprland`, `Quickshell.Io`, Hyprland 0.56.

**Spec:** `docs/superpowers/specs/2026-09-20-statusbar-design.md`

## Global Constraints

- Sem imports do Caelestia (`Caelestia`, `Caelestia.Config`, `Tokens`, `CUtils`).
- Ícones: glifos Nerd Font, família `Config.font.family` (`NotoSans Nerd Font Propo`), desenhados com `StyledText`, tamanho `Config.font.size.large` (20 px). Sem componente de ícone nem fonte novos. O tray continua com Papirus.
- Cor: `Theme.text`; estados apagados (mudo, sem conexão, bluetooth desligado) usam `Theme.subtext0`.
- Layout de teclado: `StyledText` com `Config.font.pixel` (`BigBlueTerm437 Nerd Font`) e `Config.font.pixelSize` (`12`), cor `Theme.text`.
- Contêiner: `Theme.surface1`, `Config.rounding.large`, padding `Config.padding.extraSmall`.
- Item sem fonte de dados fica `visible: false` (microfone sem entrada padrão, bluetooth sem adaptador, layout antes da primeira leitura).
- Cabo tem prioridade sobre Wi-Fi.
- Nenhuma ausência (NetworkManager parado, sem adaptador BT, `hyprctl` falhando) pode gerar erro ou aviso novo no `qs log`.
- Na lógica, usar sempre o nome do membro do enum (`DeviceType.Wired`), nunca o número.
- A etapa 1 **não** abre popout nos itens de status. Fora de escopo: bateria, Caps/Num Lock, popouts, ícone por dispositivo BT, ações de clique/scroll.
- O `HoverPopup` deve preservar o comportamento do `TrayItem` atual: ancoragem por `anchor.window` com `rect` calculado em `onAnchoring` (nunca `anchor.item`), janela desmapeada até o tamanho ficar 50 ms estável (`settle`), slide de 400 ms (`emphasizedDecel` na entrada, `emphasizedAccel` na saída), fechamento por hover com `Timer` de 150 ms, fundo `Theme.surface0`, `Config.rounding.small`, padding `Config.padding.medium` (horizontal) e `Config.padding.large` (vertical).

## Como verificar (vale para todas as tasks)

Não existem testes automatizados de QML. A verificação é: o shell recarrega sem erro/aviso novo no log, mais logs temporários com o valor calculado. **Não mova o mouse, não clique e não troque de workspace no desktop do usuário** (ele testa hover/click; ver memória `feedback-dont-drive-desktop`). Tudo que precisa de hover/clique reais vai para o usuário como checklist.

Helper (rodar a partir de `/home/tiagod/Configs/quickshell/.config/quickshell`):

```bash
# recarrega (o watchFiles às vezes ignora edições; o touch garante) e mostra o log desde o último reload
touch shell.qml; sleep 2
qs log | awk '/Reloading configuration/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}'
```

Se o log reclamar que um **tipo novo não existe** (`X is not a type`, `qmldir`), o `qmldir` virtual ficou em cache: o Quickshell precisa ser reiniciado (ele é iniciado pelo `hl.exec_cmd("quickshell")` do Hyprland). Peça ao usuário para reiniciar (`qs kill; quickshell -d`) em vez de reiniciar por conta própria.

O repositório tem muitas mudanças não commitadas que **não** são deste trabalho (kitty, nvim, i3, tmux…). Em todo commit, use `git add` com caminhos explícitos, nunca `git add -A`/`-u`.

## File Structure

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `configs/FontConfig.qml` | modificar | `pixel` (família) e `pixelSize` (12) |
| `configs/IconsConfig.qml` | criar | glifos Nerd Font como propriedades `string` |
| `Config.qml` | modificar | expõe `icons` tipado |
| `configs/Entry.qml` | modificar | `enabled` deixa de ser `readonly` (para poder desligar um item da lista) |
| `configs/BarConfig.qml` | modificar | entrada `statusIcons` em `entries` e lista `statusIcons` |
| `components/HoverPopup.qml` | criar | popup com slide/settle/hover-close extraído do `TrayItem` |
| `modules/bar/components/TrayItem.qml` | modificar | passa a usar `HoverPopup` |
| `services/Audio.qml` | modificar | `volumeIcon`, `micIcon`, `hasSource` |
| `services/Network.qml` | criar | `icon` a partir de `Quickshell.Networking` |
| `services/Keyboard.qml` | criar | `layout` (texto curto) via `hyprctl` + evento `activelayout` |
| `modules/bar/components/StatusIcons.qml` | criar | contêiner + `DelegateChooser` |
| `modules/bar/Bar.qml` | modificar | `DelegateChoice` para `statusIcons` |

---

### Task 1: Config — fonte pixel, glifos e lista de itens

Nada aparece na barra ainda; a task só deixa a configuração pronta e verificada.

**Files:**
- Modify: `configs/FontConfig.qml`
- Create: `configs/IconsConfig.qml`
- Modify: `Config.qml`
- Modify: `configs/Entry.qml`
- Modify: `configs/BarConfig.qml`

**Interfaces:**
- Consumes: nada.
- Produces (usados pelas tasks 3 e 4):
  - `Config.font.pixel: string`, `Config.font.pixelSize: int`
  - `Config.icons.<nome>: string` — `volumeOff`, `volumeLow`, `volumeMedium`, `volumeHigh`, `micOff`, `mic`, `ethernet`, `wifi4`, `wifi3`, `wifi2`, `wifi1`, `wifi0`, `wifiOff`, `bluetoothOff`, `bluetooth`, `bluetoothConnected`
  - `Config.bar.statusIcons: list<Entry>` com `entryId` `audio`, `microphone`, `network`, `bluetooth`, `kbLayout`, nessa ordem
  - `Entry.enabled` gravável

- [ ] **Step 1: Adicionar `pixel` e `pixelSize` em `configs/FontConfig.qml`**

```qml
import QtQuick

QtObject {
    readonly property string family: "NotoSans Nerd Font Propo"
    readonly property string mono: "MesloLGS Nerd Font"
    // Bitmap-style font used by the keyboard layout label; crisp at its base size (12 px)
    readonly property string pixel: "BigBlueTerm437 Nerd Font"
    readonly property int pixelSize: 12

    readonly property FontSizes size: FontSizes {}
}
```

- [ ] **Step 2: Criar `configs/IconsConfig.qml`**

```qml
import QtQuick

// Nerd Font (Material Design) glyphs used by the status icons.
// Swap any code point to change an icon; codes come from glyphnames.json.
QtObject {
    readonly property string volumeOff: String.fromCodePoint(0xF0581)
    readonly property string volumeLow: String.fromCodePoint(0xF057F)
    readonly property string volumeMedium: String.fromCodePoint(0xF0580)
    readonly property string volumeHigh: String.fromCodePoint(0xF057E)

    readonly property string micOff: String.fromCodePoint(0xF036D)
    readonly property string mic: String.fromCodePoint(0xF036C)

    readonly property string ethernet: String.fromCodePoint(0xF0200)
    readonly property string wifi4: String.fromCodePoint(0xF0928)
    readonly property string wifi3: String.fromCodePoint(0xF0925)
    readonly property string wifi2: String.fromCodePoint(0xF0922)
    readonly property string wifi1: String.fromCodePoint(0xF091F)
    readonly property string wifi0: String.fromCodePoint(0xF092F)
    readonly property string wifiOff: String.fromCodePoint(0xF092D)

    readonly property string bluetoothOff: String.fromCodePoint(0xF00B2)
    readonly property string bluetooth: String.fromCodePoint(0xF00AF)
    readonly property string bluetoothConnected: String.fromCodePoint(0xF00B1)
}
```

- [ ] **Step 3: Expor em `Config.qml`**

Adicionar dentro do `Singleton`, depois da linha `font`:

```qml
    readonly property IconsConfig icons: IconsConfig {}
```

- [ ] **Step 4: Tornar `Entry.enabled` gravável em `configs/Entry.qml`**

Sem isso, `Entry { entryId: "audio"; enabled: false }` é erro (propriedade `readonly`) e a lista não teria como desligar um item.

```qml
import QtQuick

QtObject {
    required property string entryId;
    readonly property string id: entryId;
    property bool enabled: true
}
```

- [ ] **Step 5: `entries` e `statusIcons` em `configs/BarConfig.qml`**

Inserir a entrada `statusIcons` entre `tray` e `clock` e a nova lista antes de `workspaces`:

```qml
        Entry {
            entryId: "tray"
        },
        Entry {
            entryId: "statusIcons"
        },
        Entry {
            entryId: "clock"
        }
    ]

    // Items of the status block, in bar order
    readonly property list<Entry> statusIcons: [
        Entry {
            entryId: "audio"
        },
        Entry {
            entryId: "microphone"
        },
        Entry {
            entryId: "network"
        },
        Entry {
            entryId: "bluetooth"
        },
        Entry {
            entryId: "kbLayout"
        }
    ]

    readonly property WorkspacesConfig workspaces: WorkspacesConfig {}
```

(`Bar.qml` ainda não tem `DelegateChoice` para `statusIcons`, então a entrada nova é ignorada até a Task 4.)

- [ ] **Step 6: Verificar com um log temporário**

Adicionar temporariamente em `Config.qml`, dentro do `Singleton`:

```qml
    Component.onCompleted: console.log("CFGCHECK", Config.icons.volumeOff.codePointAt(0).toString(16), Config.bar.statusIcons.length, Config.font.pixelSize, Config.font.pixel)
```

Rodar o helper de reload. Expected no log: `CFGCHECK f0581 5 12 BigBlueTerm437 Nerd Font`, e nenhum `ERROR`/`WARN` novo além dos já existentes (`Could not load icon ""` e o aviso do portal `qt.qpa.services` são anteriores a este trabalho).

Se aparecer `IconsConfig is not a type`, ver a seção "Como verificar" (reinício do Quickshell).

- [ ] **Step 7: Remover o log temporário e commitar**

Remover a linha `Component.onCompleted` de `Config.qml`, recarregar e confirmar que `CFGCHECK` sumiu.

```bash
git add configs/FontConfig.qml configs/IconsConfig.qml Config.qml configs/Entry.qml configs/BarConfig.qml
git commit -m "Add status icon glyphs, pixel font and statusIcons config"
```

---

### Task 2: Extrair `HoverPopup` e migrar o `TrayItem`

Único risco real de regressão do trabalho: o tray tem que se comportar exatamente como antes.

**Files:**
- Create: `components/HoverPopup.qml`
- Modify: `modules/bar/components/TrayItem.qml` (reescrita completa)

**Interfaces:**
- Consumes: `Config.anim.emphasizedDecel/emphasizedAccel`, `Config.padding.*`, `Config.rounding.small`, `Theme.surface0`, `Anim`, `StyledRect`.
- Produces (usado por `TrayItem` aqui e pelos popouts das etapas 2–4):

```qml
HoverPopup {
    required property Item target      // âncora: popup centrado acima dele
    property bool targetHovered        // o dono liga ao hover do próprio item
    property bool open                 // o dono decide abrir/fechar
    property Component content         // criado a cada abertura
    signal dismissRequested()          // hover saiu do item e do popup (após 150 ms)
}
```

- [ ] **Step 1: Criar `components/HoverPopup.qml`**

O corpo é o `PopupWindow` do `TrayItem` atual, com `root.*` trocado por propriedades do próprio componente e o `closeTimer` movido para dentro.

```qml
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.configs
import qs.components

// Popup that rises out from behind the bar, centered above `target`.
// The owner decides when it opens (`open`); this keeps "only one popup at a
// time" a decision of whoever holds several of them. `dismissRequested` fires
// when neither the target nor the popup is under the pointer anymore.
PopupWindow {
    id: popup

    required property Item target
    property bool targetHovered
    property bool open
    property Component content

    signal dismissRequested

    readonly property bool wantOpen: open && !!content

    // The content is built while the window is still unmapped, and the window
    // is only mapped once its size stopped changing. Otherwise it would show
    // up small and then reshape itself while the slide-in already runs.
    // Stays mapped while the slide-out runs.
    property bool ready

    visible: (wantOpen && ready) || slideOut.running
    color: "transparent"
    implicitWidth: background.implicitWidth
    implicitHeight: background.implicitHeight

    // Centered above the target, resting on top of the bar window
    anchor {
        window: popup.target.QsWindow.window
        edges: Edges.Top
        gravity: Edges.Top

        // The target has no scene position yet when the popup is created
        onAnchoring: {
            const p = popup.target.mapToItem(null, 0, 0);
            popup.anchor.rect = Qt.rect(p.x, 0, popup.target.width, 1);
        }
    }

    // The popup lives in another window, so leaving the target doesn't mean the
    // pointer left the popup. Only dismiss if neither is hovered after a grace period.
    onTargetHoveredChanged: {
        if (targetHovered)
            closeTimer.stop();
        else
            closeTimer.restart();
    }

    Timer {
        id: closeTimer

        interval: 150
        onTriggered: {
            if (popup.open && !popup.targetHovered && !popupHover.hovered)
                popup.dismissRequested();
        }
    }

    // The window ends where the bar starts, so clipping here makes the popup
    // look like it rises out from behind the bar
    Item {
        id: slide

        // 1 = fully below the window edge (hidden), 0 = final position
        property real hidden: 1
        property int duration: 400

        anchors.fill: parent
        clip: true

        Anim {
            id: slideIn

            target: slide
            property: "hidden"
            to: 0
            type: Anim.Emphasized
            duration: slide.duration
            // Anim.Emphasized's own curve reaches 1 at 25% of the time
            easing.bezierCurve: Config.anim.emphasizedDecel
        }

        Anim {
            id: slideOut

            target: slide
            property: "hidden"
            to: 1
            type: Anim.Emphasized
            duration: slide.duration
            easing.bezierCurve: Config.anim.emphasizedAccel
        }

        StyledRect {
            id: background

            width: parent.width
            height: parent.height
            y: slide.hidden * height
            implicitWidth: contentLoader.implicitWidth + Config.padding.medium * 2
            implicitHeight: contentLoader.implicitHeight + Config.padding.large * 2
            color: Theme.surface0
            radius: Config.rounding.small

            HoverHandler {
                id: popupHover

                onHoveredChanged: {
                    if (hovered)
                        closeTimer.stop();
                    else
                        closeTimer.restart();
                }
            }

            // Recreated on each open so nothing survives a reopen
            Loader {
                id: contentLoader

                active: popup.wantOpen || popup.visible
                anchors.centerIn: parent
                sourceComponent: popup.content
            }
        }
    }

    Timer {
        id: settle

        interval: 50
        onTriggered: {
            popup.ready = true;
            slideIn.restart();
        }
    }

    Connections {
        target: background

        function onImplicitWidthChanged(): void {
            if (popup.wantOpen && !popup.ready)
                settle.restart();
        }

        function onImplicitHeightChanged(): void {
            if (popup.wantOpen && !popup.ready)
                settle.restart();
        }
    }

    // Both animations start from wherever the popup currently is, so a
    // hover during the slide-out reverses it instead of jumping
    onWantOpenChanged: {
        if (wantOpen) {
            slideOut.stop();
            if (visible)
                slideIn.restart();
            else
                settle.restart();
        } else {
            settle.stop();
            if (visible) {
                slideIn.stop();
                slideOut.restart();
            }
        }
    }

    onVisibleChanged: {
        if (!visible) {
            slideIn.stop();
            slideOut.stop();
            slide.hidden = 1;
            ready = false;
        }
    }
}
```

Diferenças deliberadas em relação ao `TrayItem` antigo: o `closeTimer` só dispara `dismissRequested` se `open` (evita sinal sem popup aberto), e `content` é um `Component` genérico no lugar do `TrayMenu`.

- [ ] **Step 2: Reescrever `modules/bar/components/TrayItem.qml`**

Substituir o arquivo inteiro. Os sinais `menuRequested`/`menuDismissed` e a propriedade `menuOpen` continuam iguais, então `Tray.qml` não muda.

```qml
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs
import qs.configs
import qs.components

MouseArea {
    id: root

    required property SystemTrayItem modelData
    property bool menuOpen

    signal menuRequested
    signal menuDismissed

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: 20 //config
    implicitHeight: 20

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else
            modelData.secondaryActivate();
    }

    onEntered: menuRequested()

    IconImage {
        anchors.fill: parent
        source: Quickshell.iconPath(root.modelData.icon)
    }

    HoverPopup {
        target: root
        targetHovered: root.containsMouse
        open: root.menuOpen && !!root.modelData.menu
        onDismissRequested: root.menuDismissed()

        content: Component {
            TrayMenu {
                trayItem: root.modelData.menu // qmllint disable unresolved-type
                onCloseRequested: root.menuDismissed()
            }
        }
    }
}
```

- [ ] **Step 3: Recarregar e ler o log**

Rodar o helper de reload. Expected: nenhum `ERROR`/`WARN` novo. Erros prováveis e o que significam:
- `HoverPopup is not a type` → cache do `qmldir` virtual; pedir reinício ao usuário (ver "Como verificar").
- `Cannot read property 'window' of undefined` / `QsWindow` → o `target` chegou sem janela; conferir que `HoverPopup` é filho do `MouseArea` e que `import Quickshell` está no arquivo.
- `Invalid write to global property "rect"` → alguém escreveu `rect =` sem o prefixo `popup.anchor.`.

- [ ] **Step 4: Pedir a regressão do tray ao usuário**

Não simular hover. Enviar este checklist (sem mexer no mouse do usuário):

1. Passar o mouse num ícone do tray com menu (ex.: steam): o menu sobe de trás da barra em ~400 ms (`emphasizedDecel`), sem aparecer antes como retângulo pequeno.
2. Tirar o mouse do ícone e do menu: fecha após ~150 ms descendo (`emphasizedAccel`).
3. Sair e voltar com o mouse durante a descida: reverte de onde estava, sem pulo.
4. Ir do ícone para dentro do menu sem soltar o hover: não fecha.
5. Passar de um ícone do tray para outro: só um menu aberto por vez.
6. Clicar num item do menu: aciona e fecha; submenu abre e "Voltar" funciona.

- [ ] **Step 5: Commit (depois de o usuário confirmar o tray)**

```bash
git add components/HoverPopup.qml modules/bar/components/TrayItem.qml
git commit -m "Extract HoverPopup from TrayItem"
```

---

### Task 3: Serviços — `Audio`, `Network`, `Keyboard`

Ainda sem UI: cada serviço é verificado por log temporário.

**Files:**
- Modify: `services/Audio.qml`
- Create: `services/Network.qml`
- Create: `services/Keyboard.qml`

**Interfaces:**
- Consumes: `Config.icons.*` (Task 1).
- Produces (usados pela Task 4):
  - `Audio.volumeIcon: string`, `Audio.micIcon: string`, `Audio.hasSource: bool` (além de `Audio.muted`, `Audio.sourceMuted`, que já existem)
  - `Network.icon: string`, `Network.connected: bool`
  - `Keyboard.layout: string` (`""` até a primeira leitura)

- [ ] **Step 1: Propriedades de ícone em `services/Audio.qml`**

Adicionar `import qs` junto dos imports (o serviço passa a ler `Config`):

```qml
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs
```

Adicionar, depois de `sourceVolume`:

```qml
    readonly property bool hasSource: source !== null

    // Volume thresholds live here only. The percentage is rounded so that
    // 0.33 (which may come as 0.3300001) still counts as 33 %.
    readonly property string volumeIcon: {
        const pct = Math.round(volume * 100);
        if (muted || pct <= 0)
            return Config.icons.volumeOff;
        if (pct <= 33)
            return Config.icons.volumeLow;
        if (pct <= 66)
            return Config.icons.volumeMedium;
        return Config.icons.volumeHigh;
    }

    readonly property string micIcon: sourceMuted ? Config.icons.micOff : Config.icons.mic
```

- [ ] **Step 2: Criar `services/Network.qml`**

`Networking.devices` vem vazio por 2–4 s após o start (aceito na v1: mostra "desconectado" e corrige). Os `[...x.values]` copiam a lista para um array JS comum, que aceita `find`.

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import qs

// Network state for the status icon. Wired wins over Wi-Fi.
Singleton {
    id: root

    readonly property var devices: [...Networking.devices.values]

    readonly property var wired: devices.find(d => d.type === DeviceType.Wired && d.connected && d.hasLink) ?? null
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var wifiNetwork: wifi ? ([...wifi.networks.values].find(n => n.connected) ?? null) : null

    // 0..1
    readonly property real strength: wifiNetwork?.signalStrength ?? 0
    readonly property bool connected: wired !== null || wifi !== null

    readonly property string icon: {
        if (wired)
            return Config.icons.ethernet;
        if (!wifi)
            return Config.icons.wifiOff;
        if (strength >= 0.8)
            return Config.icons.wifi4;
        if (strength >= 0.6)
            return Config.icons.wifi3;
        if (strength >= 0.4)
            return Config.icons.wifi2;
        if (strength >= 0.2)
            return Config.icons.wifi1;
        return Config.icons.wifi0;
    }
}
```

- [ ] **Step 3: Criar `services/Keyboard.qml`**

Leitura inicial por `hyprctl -j devices` (teclado com `main: true`, campo `active_keymap`) e atualização pelo evento `activelayout` (`activelayout>>teclado,Nome do layout`; o nome do layout pode conter vírgulas, então só a primeira vírgula separa). Qualquer saída inesperada mantém o valor anterior, sem log.

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // Short code of the active layout ("US"); empty until the first read
    property string layout: ""

    // "English (US, intl., with dead keys)" -> "US": the first item inside the
    // parentheses. Enough for a single layout; revisit if another name format shows up.
    function shortName(name: string): string {
        const m = /\(([^,)]+)/.exec(name);
        return m ? m[1].trim() : "";
    }

    function apply(name: string): void {
        const code = shortName(name);
        if (code !== "")
            layout = code;
    }

    Process {
        running: true
        command: ["hyprctl", "-j", "devices"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kb = JSON.parse(text).keyboards.find(k => k.main);
                    if (kb)
                        root.apply(kb.active_keymap);
                } catch (e) {
                    // keep the previous value
                }
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name !== "activelayout")
                return;
            const comma = event.data.indexOf(",");
            if (comma >= 0)
                root.apply(event.data.slice(comma + 1));
        }
    }
}
```

- [ ] **Step 4: Verificar com logs temporários**

Um singleton só é instanciado quando algo o referencia. Para forçar, adicionar temporariamente em `shell.qml`, dentro do `ShellRoot` (ele já importa `qs.services`):

```qml
    Component.onCompleted: console.log("SVCCHECK audio", Audio.volumeIcon.codePointAt(0).toString(16), Audio.micIcon.codePointAt(0).toString(16), Audio.hasSource, "| net", Network.icon.codePointAt(0).toString(16), Network.connected, "| kb", Keyboard.layout)
```

Como `Network`/`Keyboard` levam alguns segundos para ter dados, adicionar também, nos serviços, um log de mudança (temporário):

- `Network.qml`: `onIconChanged: console.log("NETCHECK", icon.codePointAt(0).toString(16), strength)`
- `Keyboard.qml`: `onLayoutChanged: console.log("KBCHECK", layout)`

Rodar o helper de reload e esperar ~5 s. Expected:
- `NETCHECK` para o glifo do estado real (cabo conectado: `f0200`; só Wi-Fi: um dos `f0928`/`f0925`/`f0922`/`f091f`/`f092f`; nada: `f092d`).
- `KBCHECK US` (com o layout atual `English (US, intl., with dead keys)`).
- `SVCCHECK` com o glifo de volume coerente com `wpctl get-volume @DEFAULT_AUDIO_SINK@` (somente leitura) e `hasSource true` se há microfone.
- Nenhum `ERROR`/`WARN` novo. Em especial nada de `Cannot read property 'connected' of undefined` no `Network` (os `?.` e `?? null` cobrem lista vazia) nem de `hyprctl`.

Checagem read-only adicional para comparar (não altera nada):

```bash
wpctl get-volume @DEFAULT_AUDIO_SINK@; wpctl get-volume @DEFAULT_AUDIO_SOURCE@
nmcli -t -f DEVICE,TYPE,STATE device
hyprctl -j devices | python3 -c "import sys,json; print([k['active_keymap'] for k in json.load(sys.stdin)['keyboards'] if k['main']])"
```

- [ ] **Step 5: Remover todos os logs temporários e commitar**

Remover: o `Component.onCompleted` de `shell.qml`, `onIconChanged` em `Network.qml`, `onLayoutChanged` em `Keyboard.qml`. Recarregar e confirmar que `SVCCHECK`, `NETCHECK` e `KBCHECK` sumiram e que o log continua limpo. `git diff shell.qml` deve estar vazio (o arquivo já estava limpo antes).

```bash
git add services/Audio.qml services/Network.qml services/Keyboard.qml
git commit -m "Add Network and Keyboard services and Audio icons"
```

---

### Task 4: `StatusIcons` e a entrada na barra

**Files:**
- Create: `modules/bar/components/StatusIcons.qml`
- Modify: `modules/bar/Bar.qml`

**Interfaces:**
- Consumes: `Config.bar.statusIcons` (list<Entry>, `id` por item), `Config.icons`, `Config.font.pixel/pixelSize/size.large`, `Audio.volumeIcon/muted/micIcon/sourceMuted/hasSource`, `Network.icon/connected`, `Keyboard.layout`, `Bluetooth.defaultAdapter`, `Bluetooth.devices`.
- Produces: tipo `StatusIcons` (sem propriedades públicas) e a entrada `statusIcons` na barra.

- [ ] **Step 1: Criar `modules/bar/components/StatusIcons.qml`**

Notas de implementação:
- `Audio` existe em `qs.components` (widget antigo, `components/Audio.qml`) e em `qs.services` (singleton). Importar `qs.services` **por último**, como o `osd/Wrapper.qml` já faz, para o singleton prevalecer.
- Cada delegate do `DelegateChooser` declara `required property var modelData` e `index`, como o `EntryWrapper` da `Bar.qml`.
- Bluetooth lê `Quickshell.Bluetooth` direto: "com dispositivo conectado" é `devices.some(d => d.connected)`; a mera existência de dispositivos não conta (a lista inclui os não pareados).

```qml
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.configs
import qs.components
import qs.services

// Status icons block: audio, microphone, network, bluetooth, keyboard layout.
// Order and visibility come from Config.bar.statusIcons.
StyledRect {
    id: root

    readonly property int padding: Config.padding.extraSmall

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property bool btConnected: [...Bluetooth.devices.values].some(d => d.connected)

    implicitHeight: Config.sizes.bar.innerHeight - Config.spacing.small
    implicitWidth: row.implicitWidth + padding * 2

    color: Theme.surface1
    radius: Config.rounding.large

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Config.spacing.small

        Repeater {
            model: Config.bar.statusIcons.filter(e => e.enabled)

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "audio"
                    delegate: Glyph {
                        text: Audio.volumeIcon
                        color: Audio.muted ? Theme.subtext0 : Theme.text
                    }
                }

                DelegateChoice {
                    roleValue: "microphone"
                    delegate: Glyph {
                        visible: Audio.hasSource
                        text: Audio.micIcon
                        color: Audio.sourceMuted ? Theme.subtext0 : Theme.text
                    }
                }

                DelegateChoice {
                    roleValue: "network"
                    delegate: Glyph {
                        text: Network.icon
                        color: Network.connected ? Theme.text : Theme.subtext0
                    }
                }

                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: Glyph {
                        visible: root.adapter !== null
                        text: !root.btOn ? Config.icons.bluetoothOff : root.btConnected ? Config.icons.bluetoothConnected : Config.icons.bluetooth
                        color: root.btOn ? Theme.text : Theme.subtext0
                    }
                }

                DelegateChoice {
                    roleValue: "kbLayout"
                    delegate: Glyph {
                        visible: Keyboard.layout !== ""
                        text: Keyboard.layout
                        font.family: Config.font.pixel
                        font.pixelSize: Config.font.pixelSize
                    }
                }
            }
        }
    }

    component Glyph: StyledText {
        required property var modelData
        required property int index

        anchors.verticalCenter: parent?.verticalCenter
        font.pixelSize: Config.font.size.large
    }
}
```

- [ ] **Step 2: Adicionar o `DelegateChoice` em `modules/bar/Bar.qml`**

Inserir depois do bloco `tray` (mesmo padrão):

```qml
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: EntryWrapper {
                    StatusIcons {
                        objectName: "taskbarStatusIcons"
                    }
                }
            }
```

`Bar.qml` já tem `import "components"`, então `StatusIcons` resolve sem import novo.

- [ ] **Step 3: Recarregar e ler o log**

Rodar o helper de reload. Expected: nenhum `ERROR`/`WARN` novo. O bloco aparece entre o tray e o relógio. Erros prováveis:
- `StatusIcons is not a type` → cache do `qmldir` virtual; pedir reinício ao usuário.
- `Cannot assign to non-existent property "anchors"` no `Glyph` → o delegate ficou fora de um `Item` pai; `anchors.verticalCenter: parent?.verticalCenter` só vale dentro da `Row`.
- `Audio` resolvendo para o widget antigo (`Audio.volumeIcon` "is not a property"/`unresolved`) → conferir que `import qs.services` é o **último** import.

Se algum glifo aparecer como quadrado/vazio, o ponto é a fonte (`Config.font.family`) ou o código em `IconsConfig.qml`; conferir com `fc-list : family | grep "NotoSans Nerd Font Propo"`.

- [ ] **Step 4: Verificação visual pelo usuário**

Screenshot do desktop do usuário não é permitido sem pedir. Enviar este checklist; os comandos são todos do usuário (eu não altero áudio, rede nem bluetooth):

1. O bloco aparece entre o tray e o relógio, com o mesmo estilo do tray, na ordem áudio, microfone, rede, bluetooth, layout.
2. Tamanho dos glifos: `Config.font.size.large` (20 px) é a proposta; se algum parecer pequeno/grande, ajustar em `StatusIcons.qml` (`Glyph`).
3. Áudio: `wpctl set-volume @DEFAULT_AUDIO_SINK@ 20%` → glifo baixo; `50%` → médio; `90%` → alto; `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` → `volume_off` em `subtext0`.
4. Microfone: `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` alterna `microphone`/`microphone_off`.
5. Bluetooth: `bluetoothctl power off` → `bluetooth_off` em `subtext0`; `power on` → `bluetooth`; ao conectar um dispositivo → `bluetooth_connect`.
6. Rede: desconectar o Wi-Fi (`nmcli radio wifi off` e `on`) → `wifi_strength_off` e volta; cabo conectado mostra `ethernet`.
7. Layout: mostra `US` em 12 px na fonte pixel; trocar o layout (se houver mais de um) atualiza na hora.
8. Tray continua funcionando (regressão da Task 2).

- [ ] **Step 5: Commit**

```bash
git add modules/bar/components/StatusIcons.qml modules/bar/Bar.qml
git commit -m "Add StatusIcons block to the bar"
```

- [ ] **Step 6: Atualizar `ARCHITECTURE.md` (só se relevante)**

`ARCHITECTURE.md` já descreve `components/`, `services/` e `configs/`; se a lista de exemplos ficou desatualizada com `HoverPopup`, `Network`, `Keyboard` e `IconsConfig`, acrescentar uma linha por arquivo. `ARCHITECTURE.md` tem mudanças não commitadas de outra sessão: editar por cima e commitar só com o `git add ARCHITECTURE.md` se o usuário concordar em incluí-las; caso contrário, pular este passo.

---

## Self-Review (feita contra a spec)

**Cobertura da spec**

| Requisito da spec | Onde |
|---|---|
| `Config.bar.entries` ganha `statusIcons` entre `tray` e `clock` | Task 1, Step 5 |
| `Config.bar.statusIcons` (`list<Entry>`, `enabled`, ordem) | Task 1, Steps 4–5 |
| `Config.font.pixel` / `pixelSize` | Task 1, Step 1 |
| `Config.icons` com todos os glifos da tabela | Task 1, Steps 2–3 |
| `HoverPopup` com o contrato e o comportamento preservado | Task 2 |
| `TrayItem` só com `MouseArea`, ícone e `HoverPopup` | Task 2, Step 2 |
| `Audio.volumeIcon`/`micIcon`, limiares em um só lugar | Task 3, Step 1 |
| `Network.icon`, cabo antes de Wi-Fi, `signalStrength` | Task 3, Step 2 |
| `Keyboard.layout` via `hyprctl -j devices` + `activelayout` | Task 3, Step 3 |
| Bluetooth direto no componente, `devices.some(d => d.connected)` | Task 4, Step 1 |
| Itens sem fonte de dados somem | Task 4, Step 1 (`visible:`) |
| Sem erro no log com serviços ausentes | Tasks 3 e 4 (`?.`, `?? null`, `try/catch`) |
| Cor `subtext0` em estados apagados | Task 4, Step 1 |
| `DelegateChoice statusIcons` no `Bar` | Task 4, Step 2 |
| Regressão do tray | Task 2, Step 4 |
| Tamanho do glifo (ponto a confirmar) | Task 4, Step 4, item 2 |

**Desvios em relação à spec (registrados):**
- `Entry.enabled` passa a ser `property` (não `readonly`) — a spec diz que cada item "tem `enabled`", mas o tipo atual não permitia defini-lo por instância.
- `HoverPopup.closeTimer` só dispara com `open` verdadeiro.
- `Audio.hasSource` é uma propriedade nova (a spec só pede "sem entrada padrão → some"; a propriedade é o meio de expressar isso).
- Nomes das propriedades de `Config.icons` (`volumeOff`, `wifi4`, `bluetoothConnected`…) são definidos aqui; a spec só dá os glifos.

**Consistência de tipos:** `Config.icons.*` (Task 1) ↔ usados em `Audio`/`Network`/`StatusIcons` com os mesmos nomes; `Audio.hasSource`, `Network.connected`, `Keyboard.layout` definidos na Task 3 e consumidos na Task 4 com os mesmos nomes; `entryId` `audio|microphone|network|bluetooth|kbLayout` da Task 1 batem com os `roleValue` da Task 4.

**Pontos incertos para checar ao executar (não há como validar sem rodar):** (1) `popup.target.QsWindow.window` com `target` como propriedade (original usava um id); se falhar, o log mostra erro em `anchor.window`. (2) Se `Audio` resolver para o widget antigo, ver a nota de import da Task 4. (3) Largura desigual entre glifos `Propo` no `Row`; ajustar com largura fixa por `Glyph` se incomodar.

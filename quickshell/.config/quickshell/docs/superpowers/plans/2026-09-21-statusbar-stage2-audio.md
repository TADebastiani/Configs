# StatusBar etapa 2 (popout de áudio) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Passar o mouse no ícone de áudio da barra abre um popout com volume e mudo da saída e da entrada (microfone), reusando o `HoverPopup` da etapa 1.

**Architecture:** O `Audio` (singleton) ganha os setters de volume/mudo e os nomes dos dispositivos. Um `StyledSlider` novo emite `moved(real)` sem escrever no áudio; o `AudioPopout` liga slider e botão de mudo aos setters do `Audio`. O `StatusIcons` guarda qual popup está aberto (`openPopup`) e hospeda o `HoverPopup` no glifo de áudio, no padrão do `Tray.menuItem`.

**Tech Stack:** Quickshell 0.3.1 (QML, Qt 6), `Quickshell.Services.Pipewire`, Hyprland 0.56.

**Spec:** `docs/superpowers/specs/2026-09-21-statusbar-stage2-audio-design.md` (continua `2026-09-20-statusbar-design.md`, etapa 1, já implementada)

## Global Constraints

- Sem imports do Caelestia (`Caelestia`, `Caelestia.Config`, `Tokens`, `CUtils`).
- **Sem escolha de dispositivo** nesta etapa. O nome do dispositivo é só texto informativo.
- Slider de 0 a 100 %. Se o volume real estiver acima, o slider aparece cheio e a porcentagem mostra o valor real.
- Um único popout, no ícone de áudio, com duas linhas: saída (só com `Audio.sink`) e entrada (só com `Audio.hasSource`). Sem `Audio.sink`, o ícone de áudio não abre popout.
- Cada linha: botão de mudo (glifo `Audio.volumeIcon` / `Audio.micIcon`), slider, porcentagem `Math.round(volume * 100)`, e o nome do dispositivo abaixo em `Theme.subtext0`.
- O popout abre em hover real do ícone de áudio e fecha pelo `dismissRequested` do `HoverPopup` (150 ms depois de o mouse sair do ícone e do popup).
- Mutar o microfone pelo popout faz o ícone dele sumir da barra (regra da etapa 1) e **não** fecha o popout (o alvo é o ícone de áudio, que nunca some).
- `StyledSlider.value` é só entrada: o slider nunca atribui a si mesmo; o arraste emite `moved`. Atribuir imperativamente quebraria o binding com `Audio.volume`.
- Escritas no áudio ficam no serviço `Audio`, não nos componentes.
- `Audio.refreshNodes()` **não** é tocado (o `Connections` em `Pipewire.nodes` que nunca dispara fica como está; só importaria numa lista de dispositivos).
- Cores do `Theme`, raios de `Config.rounding`, espaçamentos de `Config.spacing`/`Config.padding`. Fora de escopo: scroll, volume acima de 100 %, volume por aplicativo, escolha de dispositivo.
- **Sem commits e sem `git add`** durante a execução: o usuário commita tudo à mão no fim (memória `feedback-user-commits-manually`). Não adicionar `Co-Authored-By`. Ignorar os passos de commit de qualquer skill.
- **Armadilha de nome:** existem `components/Audio.qml` e `services/Audio.qml`. Todo arquivo que usa `Audio` importa `qs.components` **antes** de `qs.services` (o último import vence, e o singleton é o de `services`). Não inverta a ordem.

## Como verificar (vale para todas as tasks)

Não existem testes automatizados de QML. A verificação é: o shell recarrega sem erro/aviso novo no log, mais probes temporários com o valor calculado. **Não mova o mouse, não clique, não troque de workspace e não escreva no áudio real** (nada de `wpctl set-*`, `pactl set-*`; o usuário testa hover/clique, memória `feedback-dont-drive-desktop`). `wpctl get-volume` (somente leitura) é permitido. Tudo que precisa de hover/clique reais vai para o usuário como checklist na Task 3.

Helper (rodar a partir de `/home/tiagod/Configs/quickshell/.config/quickshell`):

```bash
# recarrega (o watchFiles às vezes ignora edições; o touch garante) e mostra o log desde o último reload
touch shell.qml; sleep 4
qs log | awk '/Reloading configuration/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}'
```

O log já tem avisos de base que **não** são deste trabalho: `Cannot assign to non-existent property "onTargetChanged"` (em `services/Audio.qml`, linha ~80) e `qt.dbus.integration` / `qt.qpa.services` (portal). Qualquer outra linha `WARN`/`ERROR` é nova.

Se o log reclamar que um **tipo novo não existe** (`X is not a type`, `qmldir`), o `qmldir` virtual ficou em cache: o Quickshell precisa ser reiniciado. Peça ao usuário para reiniciar (`qs kill; quickshell -d`) em vez de reiniciar por conta própria.

Probes temporários levam o marcador `TEMP-PROBE-STAGE2` na linha do comentário e **têm que ser removidos** no fim da task que os cria. Confira com:

```bash
grep -rn "TEMP-PROBE-STAGE2\|probe2" /home/tiagod/Configs/quickshell/.config/quickshell --include='*.qml'
```

Saída esperada depois da remoção: vazia.

O repositório tem muitas mudanças não commitadas que **não** são deste trabalho (kitty, nvim, i3, tmux…). Não use `git add`.

## File Structure

| Arquivo | Ação | Responsabilidade |
|---|---|---|
| `configs/BarSizes.qml` | modificar | `audioPopoutWidth` |
| `services/Audio.qml` | modificar | `sinkName`, `sourceName`, setters de volume e mudo |
| `components/StyledSlider.qml` | criar | trilho, preenchimento e alça; emite `moved(real)` |
| `modules/bar/components/AudioPopout.qml` | criar | conteúdo do popup: linha de saída e de entrada |
| `modules/bar/components/StatusIcons.qml` | modificar | `openPopup`, hover no glifo de áudio, `HoverPopup` com `AudioPopout` |

---

### Task 1: Serviço `Audio` (nomes e setters) e largura do popout

**Files:**
- Modify: `services/Audio.qml` (após a linha `readonly property bool hasSource: source !== null`, linha 28)
- Modify: `configs/BarSizes.qml`
- Modify (temporário): `modules/bar/components/StatusIcons.qml` (probe, removido no fim da task)

**Interfaces:**
- Consumes: `Audio.sink`, `Audio.source`, `Audio.hasSource`, `Audio.volume`, `Audio.muted`, `Audio.sourceVolume`, `Audio.sourceMuted` (já existem, etapa 1).
- Produces (para a Task 2 e a Task 3):
  - `Audio.sinkName: string`, `Audio.sourceName: string` (`description || name || qsTr("Dispositivo desconhecido")`, ao vivo)
  - `Audio.setVolume(value: real): void`, `Audio.setMuted(muted: bool): void`
  - `Audio.setSourceVolume(value: real): void`, `Audio.setSourceMuted(muted: bool): void`
  - `Config.sizes.bar.audioPopoutWidth: int` (280)

- [ ] **Step 1: Guardar a linha de base do log**

Rodar o helper e guardar a saída, para distinguir o que é novo:

```bash
cd /home/tiagod/Configs/quickshell/.config/quickshell
touch shell.qml; sleep 4
qs log | awk '/Reloading configuration/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' > /tmp/claude-1000/-home-tiagod-Configs-quickshell--config-quickshell/00c84675-60c5-4474-adb6-bb57aa763566/scratchpad/baseline.log
grep -c "WARN\|ERROR" /tmp/claude-1000/-home-tiagod-Configs-quickshell--config-quickshell/00c84675-60c5-4474-adb6-bb57aa763566/scratchpad/baseline.log
```

Expected: só os avisos de base descritos em "Como verificar" (o número exato varia).

- [ ] **Step 2: Adicionar a largura em `configs/BarSizes.qml`**

Depois de `trayMenuHeight`:

```qml
    readonly property int trayMenuHeight: 300
    readonly property int audioPopoutWidth: 280
```

- [ ] **Step 3: Adicionar nomes e setters em `services/Audio.qml`**

Logo depois de `readonly property bool hasSource: source !== null`:

```qml
    readonly property string sinkName: sink?.description || sink?.name || qsTr("Dispositivo desconhecido")
    readonly property string sourceName: source?.description || source?.name || qsTr("Dispositivo desconhecido")

    // The volume is written as given: callers (the slider) already clamp it.
    // `audio` is null until the node is bound, hence the checks.
    function setVolume(value: real): void {
        if (sink?.audio)
            sink.audio.volume = value;
    }

    function setMuted(muted: bool): void {
        if (sink?.audio)
            sink.audio.muted = muted;
    }

    function setSourceVolume(value: real): void {
        if (source?.audio)
            source.audio.volume = value;
    }

    function setSourceMuted(muted: bool): void {
        if (source?.audio)
            source.audio.muted = muted;
    }
```

- [ ] **Step 4: Probe temporário no `StatusIcons.qml`**

Como filho direto do `StyledRect` raiz (por exemplo logo antes de `Row { id: row`):

```qml
    // TEMP-PROBE-STAGE2
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            console.log("[probe2] sink=" + Audio.sinkName + " | source=" + Audio.sourceName + " | hasSource=" + Audio.hasSource);
            // Writes the current value back: exercises the setters without changing anything
            Audio.setVolume(Audio.volume);
            Audio.setMuted(Audio.muted);
            Audio.setSourceVolume(Audio.sourceVolume);
            Audio.setSourceMuted(Audio.sourceMuted);
            console.log("[probe2] after no-op writes: vol=" + Audio.volume + " muted=" + Audio.muted + " srcVol=" + Audio.sourceVolume + " srcMuted=" + Audio.sourceMuted);
        }
    }
```

- [ ] **Step 5: Recarregar e conferir**

Antes e depois, leitura somente-leitura do estado real:

```bash
wpctl get-volume @DEFAULT_AUDIO_SINK@; wpctl get-volume @DEFAULT_AUDIO_SOURCE@
cd /home/tiagod/Configs/quickshell/.config/quickshell
touch shell.qml; sleep 6
qs log | awk '/Reloading configuration/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' | grep -i "probe2\|WARN\|ERROR"
wpctl get-volume @DEFAULT_AUDIO_SINK@; wpctl get-volume @DEFAULT_AUDIO_SOURCE@
```

Expected:
- `[probe2] sink=<nome do dispositivo de saída> | source=<nome da entrada> | hasSource=true` (nomes reais, não vazios e não "Dispositivo desconhecido").
- `[probe2] after no-op writes:` com os mesmos valores de `wpctl get-volume` (volume em fração, ex.: `0.45` = 45 %; `muted=true/false` igual ao `[MUTED]` do wpctl).
- As duas leituras de `wpctl` idênticas antes e depois.
- Nenhum `WARN`/`ERROR` além da linha de base.

Se o nome vier vazio ou "Dispositivo desconhecido" com o dispositivo existindo, o `PwObjectTracker` ainda não vinculou o nó: repetir com `interval` maior antes de concluir que há bug.

- [ ] **Step 6: Remover o probe**

Apagar o bloco `TEMP-PROBE-STAGE2` do `StatusIcons.qml`. Conferir:

```bash
grep -rn "TEMP-PROBE-STAGE2\|probe2" /home/tiagod/Configs/quickshell/.config/quickshell --include='*.qml'
```

Expected: vazia. Recarregar uma vez e confirmar que o log volta à linha de base.

---

### Task 2: `StyledSlider` e `AudioPopout`

**Files:**
- Create: `components/StyledSlider.qml`
- Create: `modules/bar/components/AudioPopout.qml`
- Modify (temporário): `modules/bar/components/StatusIcons.qml` (probe, removido no fim da task)

**Interfaces:**
- Consumes (Task 1): `Audio.sinkName`, `Audio.sourceName`, `Audio.setVolume`, `Audio.setMuted`, `Audio.setSourceVolume`, `Audio.setSourceMuted`, `Config.sizes.bar.audioPopoutWidth`; e da etapa 1: `Audio.sink`, `Audio.hasSource`, `Audio.volume`, `Audio.muted`, `Audio.volumeIcon`, `Audio.sourceVolume`, `Audio.sourceMuted`, `Audio.micIcon`.
- Produces (para a Task 3):
  - `StyledSlider { property real value; property real maxValue: 1; signal moved(real value); function valueAt(x: real): real }`
  - `AudioPopout` (sem propriedades obrigatórias; tem `implicitWidth`/`implicitHeight`, que o `HoverPopup` mede)

- [ ] **Step 1: Criar `components/StyledSlider.qml`**

```qml
import QtQuick
import qs

// Horizontal slider. `value` is input only: dragging emits `moved` and never
// assigns `value`, so the owner's binding (e.g. to Audio.volume) stays intact.
Item {
    id: root

    property real value
    property real maxValue: 1

    // Handle position along the track, 0..1. Clamped so a value above maxValue
    // (e.g. a 120 % volume) draws a full slider.
    readonly property real ratio: maxValue > 0 ? Math.max(0, Math.min(value / maxValue, 1)) : 0

    signal moved(real value)

    // The handle center travels from handle.width / 2 to width - handle.width / 2
    function valueAt(x: real): real {
        const span = width - handle.width;
        if (span <= 0)
            return 0;
        return Math.max(0, Math.min((x - handle.width / 2) / span, 1)) * maxValue;
    }

    implicitWidth: 200
    implicitHeight: 24

    StyledRect {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: height / 2
        color: Theme.surface2

        StyledRect {
            width: handle.x + handle.width / 2
            height: parent.height
            radius: parent.radius
            color: Theme.active
        }
    }

    StyledRect {
        id: handle

        anchors.verticalCenter: parent.verticalCenter
        x: root.ratio * (root.width - width)
        width: 14
        height: 14
        radius: width / 2
        color: Theme.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onPressed: event => root.moved(root.valueAt(event.x))
        onPositionChanged: event => {
            if (pressed)
                root.moved(root.valueAt(event.x));
        }
    }
}
```

Conferência da matemática (`width = 200`, `handle.width = 14`, `maxValue = 1`): `valueAt(7) = 0`, `valueAt(100) = 0.5`, `valueAt(193) = 1`; fora do trilho (`x = -30` ou `x = 400`) cai em 0 e 1 pelo clamp, então arrastar além das pontas não passa de 0–100 %.

- [ ] **Step 2: Criar `modules/bar/components/AudioPopout.qml`**

```qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.configs
import qs.components
// Must come after qs.components: `Audio` has to resolve to the singleton in
// services, not to components/Audio.qml
import qs.services

// Content of the audio popout: output row, then input row. Each row hides
// itself when its device is missing.
Item {
    id: root

    // Column is a positioner and rewrites its own implicit size, so the width
    // the HoverPopup measures lives on this wrapper
    implicitWidth: Config.sizes.bar.audioPopoutWidth
    implicitHeight: column.implicitHeight

    Column {
        id: column

        width: parent.width
        spacing: Config.spacing.medium

        AudioRow {
            visible: Audio.sink !== null
            icon: Audio.volumeIcon
            muted: Audio.muted
            volume: Audio.volume
            deviceName: Audio.sinkName
            onMuteToggled: Audio.setMuted(!Audio.muted)
            onVolumeMoved: v => Audio.setVolume(v)
        }

        AudioRow {
            visible: Audio.hasSource
            icon: Audio.micIcon
            muted: Audio.sourceMuted
            volume: Audio.sourceVolume
            deviceName: Audio.sourceName
            onMuteToggled: Audio.setSourceMuted(!Audio.sourceMuted)
            onVolumeMoved: v => Audio.setSourceVolume(v)
        }
    }

    component AudioRow: Column {
        id: row

        required property string icon
        required property bool muted
        required property real volume
        required property string deviceName

        signal muteToggled
        signal volumeMoved(real value)

        width: parent.width
        spacing: Config.spacing.extraSmall

        RowLayout {
            width: parent.width
            spacing: Config.spacing.small

            StyledRect {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Config.rounding.small

                StyledText {
                    anchors.centerIn: parent
                    text: row.icon
                    color: row.muted ? Theme.subtext0 : Theme.text
                    font.pixelSize: Config.font.size.large
                }

                StateLayer {
                    // The popup background is surface0, the StateLayer default
                    color: Theme.text
                    onClicked: row.muteToggled()
                }
            }

            StyledSlider {
                Layout.fillWidth: true
                value: row.volume
                onMoved: v => row.volumeMoved(v)
            }

            StyledText {
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                text: Math.round(row.volume * 100) + "%"
            }
        }

        StyledText {
            width: parent.width
            text: row.deviceName
            color: Theme.subtext0
            elide: Text.ElideRight
        }
    }
}
```

- [ ] **Step 3: Probe temporário no `StatusIcons.qml`**

O conteúdo do popup só é carregado no hover, então o log não mostraria nada por si só. O probe compila e instancia o `AudioPopout` fora da tela (sem janela, sem hover). Como filho direto do `StyledRect` raiz:

```qml
    // TEMP-PROBE-STAGE2
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            const c = Qt.createComponent(Qt.resolvedUrl("AudioPopout.qml"));
            if (c.status !== Component.Ready) {
                console.log("[probe2] AudioPopout FAILED: " + c.errorString());
                return;
            }
            const o = c.createObject(null);
            console.log("[probe2] AudioPopout size=" + o.implicitWidth + "x" + o.implicitHeight);
            o.destroy();
        }
    }
```

- [ ] **Step 4: Recarregar e conferir**

```bash
cd /home/tiagod/Configs/quickshell/.config/quickshell
touch shell.qml; sleep 6
qs log | awk '/Reloading configuration/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' | grep -i "probe2\|WARN\|ERROR"
```

Expected:
- `[probe2] AudioPopout size=280x<altura>` com altura maior que 0. Com saída e entrada presentes, algo perto de 118 (`(32 + 4 + ~17) * 2 + 12`); com só uma linha, algo perto de 53. O valor exato depende da fonte, então basta ser coerente com o número de linhas.
- Nenhum `FAILED`, nenhum `WARN`/`ERROR` além da linha de base do arquivo `baseline.log`.

Se aparecer `FAILED: ... X is not a type`, é o cache do `qmldir` virtual: pedir ao usuário para reiniciar o Quickshell (ver "Como verificar"). Se aparecer erro em `Audio.<algo>`, conferir a ordem dos imports (armadilha de nome nas restrições globais).

- [ ] **Step 5: Remover o probe**

Apagar o bloco `TEMP-PROBE-STAGE2` do `StatusIcons.qml`. Conferir com o `grep` de "Como verificar" (saída vazia) e recarregar uma vez para confirmar que o log volta à linha de base.

---

### Task 3: Ligar o popout ao ícone de áudio

**Files:**
- Modify: `modules/bar/components/StatusIcons.qml` (propriedades da raiz; `DelegateChoice` de `audio`)

**Interfaces:**
- Consumes: `HoverPopup` (etapa 1: `required property Item target`, `property bool targetHovered`, `property bool open`, `property Component content`, `signal dismissRequested`); `AudioPopout` (Task 2); `Audio.sink`, `Audio.volumeIcon`, `Audio.muted`.
- Produces: `StatusIcons.openPopup: string` (`""` ou `"audio"`); as etapas 3 e 4 (bluetooth e rede) usarão o mesmo `openPopup` com outros valores.

- [ ] **Step 1: Adicionar `openPopup` na raiz**

Depois de `readonly property int startPadding: Config.padding.extraSmall`:

```qml
    // Which status popup is open, if any ("" or "audio"). Held here so that
    // only one is open at a time when more popouts exist.
    property string openPopup
```

- [ ] **Step 2: Trocar o `DelegateChoice` de `audio`**

De:

```qml
                DelegateChoice {
                    roleValue: "audio"
                    delegate: Glyph {
                        text: Audio.volumeIcon
                        color: Audio.muted ? Theme.subtext0 : Theme.text
                    }
                }
```

Para:

```qml
                DelegateChoice {
                    roleValue: "audio"
                    delegate: Glyph {
                        id: audioIcon

                        text: Audio.volumeIcon
                        color: Audio.muted ? Theme.subtext0 : Theme.text

                        // Glyph is a plain text item: it has no hover of its own
                        HoverHandler {
                            id: audioHover

                            onHoveredChanged: {
                                if (hovered)
                                    root.openPopup = "audio";
                            }
                        }

                        HoverPopup {
                            target: audioIcon
                            targetHovered: audioHover.hovered
                            // Without an output there is nothing to show
                            open: root.openPopup === "audio" && Audio.sink !== null
                            onDismissRequested: {
                                if (root.openPopup === "audio")
                                    root.openPopup = "";
                            }

                            content: Component {
                                AudioPopout {}
                            }
                        }
                    }
                }
```

`AudioPopout` está na mesma pasta que o `StatusIcons`, então não precisa de import (mesmo caso do `TrayMenu` no `TrayItem`).

- [ ] **Step 3: Recarregar e conferir o log**

```bash
cd /home/tiagod/Configs/quickshell/.config/quickshell
touch shell.qml; sleep 6
qs log | awk '/Reloading configuration/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' | grep -i "WARN\|ERROR"
grep -rn "TEMP-PROBE-STAGE2\|probe2" /home/tiagod/Configs/quickshell/.config/quickshell --include='*.qml'
```

Expected: só os avisos da linha de base; o `grep` de probes devolve vazio. O `HoverPopup` é instanciado no carregamento (a janela só mapeia com `open`), então erros de propriedade obrigatória ou de âncora apareceriam aqui. O conteúdo (`AudioPopout`) só carrega no hover e já foi validado na Task 2.

Se surgir erro `Cannot anchor to an item...` ou de `required property`, comparar com o `TrayItem.qml` (mesmo padrão de `HoverPopup` dentro do delegate).

- [ ] **Step 4: Checklist para o usuário (o hover e o clique reais não são verificados por mim)**

Passar ao usuário, dizendo explicitamente que **não foi verificado por mim**:

1. Passar o mouse no ícone de áudio: o popup sobe de trás da barra em ~400 ms, com a linha de saída e a de entrada (a entrada padrão do usuário é uma placa-mãe muda, então a linha do microfone aparece com o glifo de mudo).
2. Ir do ícone para dentro do popup: não fecha. Sair dos dois: fecha ~150 ms depois.
3. Arrastar o slider da saída muda o volume (conferir com `wpctl get-volume @DEFAULT_AUDIO_SINK@` e pelo glifo da barra, que troca em 33/66 %). Clicar no trilho salta para o ponto. Arrastar além das pontas trava em 0 e 100 %.
4. Botão de mudo da saída: o glifo do popup e o da barra vão para "mudo"/cinza; clicar de novo desfaz.
5. Microfone: desmutar pelo popup faz o ícone do microfone aparecer na barra; mutar de novo faz o ícone sumir **sem o popup fechar**.
6. Sair do popup e voltar durante a descida: o slide reverte sem pulo.
7. Passar o mouse nos outros ícones (rede, bluetooth, teclado) com o popout aberto: ele fecha após ~150 ms e nenhum deles abre popout.
8. Volume acima de 100 % (rodar `wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.2` e depois voltar): o slider aparece cheio e o texto mostra `120%`.
9. O tray continua funcionando (menu do steam abre e fecha como antes): o `HoverPopup` é o mesmo componente.

- [ ] **Step 5: Relatório final (sem commit)**

Listar os arquivos alterados e criados, sem `git add` nem commit:

```
configs/BarSizes.qml
services/Audio.qml
components/StyledSlider.qml                  (novo)
modules/bar/components/AudioPopout.qml       (novo)
modules/bar/components/StatusIcons.qml
docs/superpowers/specs/2026-09-21-statusbar-stage2-audio-design.md
docs/superpowers/plans/2026-09-21-statusbar-stage2-audio.md
```

Oferecer ao usuário, para ele rodar se quiser, sem `Co-Authored-By`, a partir de `~/Configs`:

```bash
git add quickshell/.config/quickshell/{configs/BarSizes.qml,services/Audio.qml,components/StyledSlider.qml,modules/bar/components/AudioPopout.qml,modules/bar/components/StatusIcons.qml,docs/superpowers/specs/2026-09-21-statusbar-stage2-audio-design.md,docs/superpowers/plans/2026-09-21-statusbar-stage2-audio.md}
git commit -m "add audio popout to status icons"
```

Avisar que o `StatusIcons.qml` e o `Audio.qml` também carregam as mudanças não commitadas da etapa 1; se ele quiser separar, `git add -p`.

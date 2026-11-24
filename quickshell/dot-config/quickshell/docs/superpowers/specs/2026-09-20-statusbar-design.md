# StatusBar (ícones de status na barra) — design

Data: 2026-09-20 · Escopo deste documento: **etapa 1** (ícones ao vivo + `HoverPopup`
reutilizável). As etapas 2–4 (popouts) só estão esboçadas, cada uma terá seu
próprio design/plano.

## Objetivo

Exibir na barra inferior um bloco de ícones de status (áudio, microfone, rede,
bluetooth, layout de teclado), seguindo o modelo do `StatusIcons` do Caelestia,
mas mantendo a simplicidade do projeto: sem imports do Caelestia, sem serviços
grandes (o Caelestia usa um `Nmcli` próprio), sem camada `Icons` separada.

## Decisões já tomadas

| Tema | Decisão |
|---|---|
| Ícones | **Glifos Nerd Font (Material Design)** numa família `Propo`, a mesma `Config.font.family` (`NotoSans Nerd Font Propo`), desenhados com `StyledText`. Recoloríveis com o `Theme`; sem componente nem fonte novos. O tray continua com Papirus. Decidido após comparar Papirus e Nerd Font numa janela de teste. |
| Itens da v1 | áudio (volume), microfone, rede (Wi-Fi/cabo), bluetooth, layout de teclado. Bateria fora (a máquina é desktop). Caps/Num Lock fica para depois (sem evento no Hyprland, exigiria polling). |
| Interação | Popouts no hover, como o Caelestia, **decompostos em etapas** (ver Roteiro). A etapa 1 não abre popout nos itens de status. |
| Reuso do popup | Extrair `components/HoverPopup.qml` do `TrayItem`; tray e itens de status passam a usá-lo. |
| Fonte do layout | `BigBlueTerm437 Nerd Font` (a `Plus` não mostrou diferença), em **12 px** (a base da fonte; 24 px também fica nítido). Novos `Config.font.pixel` (família) e `Config.font.pixelSize` (12). |

## Escopo e decomposição

Popouts no hover são subsistemas independentes, então o trabalho é dividido:

1. **Etapa 1 (este documento):** `StatusIcons` na barra + `HoverPopup` extraído.
2. Etapa 2: popout de áudio.
3. Etapa 3: popout de bluetooth.
4. Etapa 4: popout de rede.

## Arquitetura

### Onde entra na barra

- `Config.bar.entries` ganha a entrada `statusIcons`, entre `tray` e `clock`.
- `Bar.qml` ganha `DelegateChoice { roleValue: "statusIcons" ... }` (mesmo
  padrão de `workspaces`, `tray`, `clock`).
- `Config.bar.statusIcons` é uma `list<Entry>` (mesmo tipo `Entry` das entradas
  da barra) com `audio`, `microphone`, `network`, `bluetooth`, `kbLayout`.
  Cada um tem `enabled`, e a ordem da lista é a ordem na barra.

### Visual

Contêiner igual ao do `Tray`: `Theme.surface1`, `Config.rounding.large`,
padding `Config.padding.extraSmall`, com uma `Row` de itens. Cada ícone é um
`StyledText` com o glifo (`Config.font.family`, `Config.font.size.large`,
20 px, o mesmo espaço dos ícones do tray). Cor `Theme.text`; estados
"apagados" (mudo, sem conexão, bluetooth desligado) usam `Theme.subtext0`.
O layout de teclado é `StyledText` com `Config.font.pixel` e
`Config.font.pixelSize` (12 px), cor `Theme.text`.

### Arquivos

Novos:

```
components/HoverPopup.qml              # extraído do TrayItem
modules/bar/components/StatusIcons.qml # contêiner + DelegateChooser
services/Network.qml                   # sobre Quickshell.Networking
services/Keyboard.qml                  # layout ativo do Hyprland
configs/IconsConfig.qml                # glifos dos ícones (Config.icons)
```

Alterados: `TrayItem.qml` (usa `HoverPopup`), `Bar.qml`, `configs/BarConfig.qml`
(`entries` e `statusIcons`), `configs/FontConfig.qml` (`pixel` e `pixelSize`), `Config.qml` (`icons`),
`services/Audio.qml` (propriedades de ícone).

## `HoverPopup`

Extrai do `TrayItem` o `PopupWindow` com slide, espera de tamanho e fechamento
por hover. O **dono** decide quando abrir; isso preserva a regra "só um popup
aberto por vez" (hoje feita pelo `Tray.menuItem`).

```qml
// components/HoverPopup.qml
required property Item target       // âncora: popup centrado acima dele
property bool targetHovered         // o dono liga ao hover do próprio item
property bool open                  // o dono decide abrir/fechar
property Component content          // criado a cada abertura
signal dismissRequested()           // hover saiu do item e do popup (após 150 ms)
```

Comportamento que **deve ser preservado** do `TrayItem` atual:

- Ancoragem pela janela da barra (`anchor.window`), com `rect` em coordenadas
  da janela calculado em `onAnchoring` (`Qt.rect(p.x, 0, width, 1)`,
  `edges/gravity: Edges.Top`). `anchor.item` **não** serve: ele ignora o offset.
- O conteúdo é criado com a janela **desmapeada**; a janela só é mapeada
  quando o tamanho ficou 50 ms sem mudar (`settle`), e então roda o slide.
  Evita o retângulo pequeno que se remodela antes da animação.
- Slide de entrada e saída: `hidden` de 1 a 0, `clip: true`, 400 ms
  (`slide.duration`), entrada com `emphasizedDecel` e saída com
  `emphasizedAccel`. Durante a saída a janela continua mapeada; se o hover
  voltar, as animações partem da posição atual (sem pulo).
- Fechamento: `Timer` de 150 ms que só dispara `dismissRequested` se nem o
  alvo nem o popup estão sob o mouse.
- Visual: fundo `Theme.surface0`, `Config.rounding.small`, padding
  `Config.padding.medium` (horizontal) e `Config.padding.large` (vertical).

O `TrayItem` passa a ter só o `MouseArea`, o ícone e:

```qml
HoverPopup {
    target: root
    targetHovered: root.containsMouse
    open: root.menuOpen
    onDismissRequested: root.menuDismissed()
    content: Component { TrayMenu { trayItem: root.modelData.menu; onCloseRequested: root.menuDismissed() } }
}
```

Os itens de status usarão o mesmo contrato, com o `StatusIcons` guardando qual
está aberto. Na etapa 1 eles não abrem popup.

## Estados dos ícones

Glifos Material Design do Nerd Font (códigos da lista oficial `glyphnames.json`).
Ficam em `Config.icons` como propriedades `string`
(`String.fromCodePoint(0x...)`), para você trocar qualquer um ao seu gosto.

| Item | Estado | Glifo | Código |
|---|---|---|---|
| áudio | mudo, ou volume 0 | `md-volume_off` | U+F0581 |
| | ≤ 33 % | `md-volume_low` | U+F057F |
| | ≤ 66 % | `md-volume_medium` | U+F0580 |
| | acima (inclui > 100 %) | `md-volume_high` | U+F057E |
| microfone | mudo | `md-microphone_off` | U+F036D |
| | ligado | `md-microphone` | U+F036C |
| rede | cabo conectado e com link | `md-ethernet` | U+F0200 |
| | Wi-Fi, `signalStrength` (0–1) ≥ 0,8 | `md-wifi_strength_4` | U+F0928 |
| | ≥ 0,6 | `md-wifi_strength_3` | U+F0925 |
| | ≥ 0,4 | `md-wifi_strength_2` | U+F0922 |
| | ≥ 0,2 | `md-wifi_strength_1` | U+F091F |
| | < 0,2 | `md-wifi_strength_outline` | U+F092F |
| | nada conectado | `md-wifi_strength_off` | U+F092D |
| bluetooth | sem adaptador ou desligado | `md-bluetooth_off` | U+F00B2 |
| | ligado, sem dispositivo | `md-bluetooth` | U+F00AF |
| | ligado, com dispositivo conectado | `md-bluetooth_connect` | U+F00B1 |
| layout | texto curto do layout ativo (ex.: `US`) | — | — |

O Material Design não tem níveis de microfone nem "acima de 100 %", então o
microfone tem só dois estados e o excesso de volume usa o glifo de volume alto.

Regras:

- Cabo tem prioridade sobre Wi-Fi.
- Item sem fonte de dados fica `visible: false`: microfone sem entrada padrão,
  bluetooth sem adaptador, layout antes da primeira leitura.
- Cor: `Theme.text` normalmente; `Theme.subtext0` quando mudo, sem conexão ou
  bluetooth desligado.
- Sem ícone por dispositivo Bluetooth conectado (fica para o popout da etapa 3).
- Os limiares de 33/66 % ficam num só lugar (serviço `Audio`).

## Serviços

- `services/Audio.qml` (existe): ganha `volumeIcon` e `micIcon` (somente
  leitura, glifos de `Config.icons`), a partir de `volume`, `muted` e
  `sourceMuted`.
- `services/Network.qml` (novo): sobre `Quickshell.Networking`; expõe `icon` (glifo de `Config.icons`).
  Escolhe o dispositivo conectado (cabo antes de Wi-Fi) e, no Wi-Fi, a rede
  conectada e sua `signalStrength`.
- `services/Keyboard.qml` (novo): leitura inicial via `hyprctl -j devices`
  (`Quickshell.Io`, teclado com `main: true`, campo `active_keymap`) e
  atualização pelo evento `activelayout` de `Hyprland.rawEvent`. Expõe
  `layout` (texto curto). O código curto é o que está no primeiro parêntese
  antes da vírgula (`English (US, intl., ...)` → `US`); com um único layout
  isso basta, e é o ponto a revisar se surgir outro formato de nome.
- Bluetooth: usa `Quickshell.Bluetooth` direto no componente
  (`Bluetooth.defaultAdapter.enabled`, `devices[].connected`).

## Falhas e ausências

Nenhuma delas deve gerar erro no log:

- NetworkManager parado: `Networking.devices` vazio → ícone "desconectado".
- Sem adaptador Bluetooth ou sem entrada de áudio padrão: o item some.
- `hyprctl` falha ou saída inesperada: `Keyboard` mantém o valor anterior, e o
  item some se ainda não houve leitura.

## Testes

Não há testes automatizados de QML. Verificação:

- Por mim: recarregar e ler o `qs log` (sem erro/aviso novo); logs temporários
  com o glifo calculado, removidos depois.
- Por você (eu passo os comandos; não altero áudio nem rede): `wpctl` para
  volume/mudo, `bluetoothctl power on/off`, desconectar o Wi-Fi.
- Regressão do tray (único risco real do refactor): abrir o menu do steam e
  conferir slide de 400 ms, fechamento por hover, reversão se o mouse voltar
  durante a descida, e ausência do retângulo pequeno antes do slide.

## Ordem de implementação (etapa 1)

Cada passo deixa o shell funcionando.

1. `Config.font.pixel` e a lista `Config.bar.statusIcons`.
2. Extrair `HoverPopup`, migrar o `TrayItem` (você confere o tray).
3. Serviços: propriedades de ícone no `Audio`; `Network` e `Keyboard` novos.
4. `StatusIcons` e a entrada `statusIcons` no `Bar`.

## Roteiro das etapas seguintes

- Etapa 2, áudio: sliders de volume (saída e entrada), mudo, escolha do
  dispositivo padrão.
- Etapa 3, bluetooth: ligar/desligar adaptador, lista de dispositivos,
  conectar/desconectar.
- Etapa 4, rede: lista de redes Wi-Fi e conexão; redes com senha exigem um
  diálogo de senha (a parte mais trabalhosa).

## Confirmado por medição

Medido com uma instância separada e sem janela do Quickshell 0.3.1 (não há
documentação sobre isso), lendo `Quickshell.Networking` e `Quickshell.Bluetooth`:

- `WifiNetwork.signalStrength` é um `number` de **0 a 1** (medido 0,81 com o
  `nmcli` oscilando entre 79 e 94 na mesma rede). Os limiares da tabela usam
  essa escala.
- Enums de rede: `DeviceType.Wifi = 1`, `DeviceType.Wired = 2`;
  `ConnectionState.Connecting = 1`, `Connected = 2`, `Disconnected = 4`.
- Enums de bluetooth: `BluetoothAdapterState.Disabled = 0`, `Enabled = 1`;
  `BluetoothDeviceState.Disconnected = 0`, `Connected = 1`. Usar sempre o nome
  do membro na lógica, nunca o número.
- Dispositivos Bluetooth (medido com um JBL conectado): `connected` e
  `state` (`Connected`) refletem a conexão real, e `paired` é `false` para
  dispositivos apenas descobertos. `Bluetooth.devices` **inclui** os não
  pareados, então "com dispositivo conectado" é `devices.some(d => d.connected)`,
  nunca a mera existência de dispositivos. O campo `icon` já vem como nome de
  ícone de tema (`audio-card`, `input-gaming`, `input-keyboard`), útil para o
  popout da etapa 3; `battery` não está disponível nesses dispositivos.
- `Networking.devices` traz o cabo (`enp37s0`, `WiredDevice` com `hasLink` e
  `linkSpeed`) e o Wi-Fi (`wlan0`, com `networks` e `connected`). A rede
  conectada é a que tem `WifiNetwork.connected`.

**Inicialização assíncrona:** logo após o shell iniciar, `Networking.devices`
vem vazio, `wifiEnabled` é `false` e `Bluetooth.adapters` vem vazio; os dados
aparecem uns 2–4 s depois. Consequências de projeto: o ícone de rede mostra
"desconectado" nesses primeiros segundos e depois corrige, e o item Bluetooth
só aparece quando o adaptador chega (coerente com a regra de esconder item sem
fonte de dados). Isso é aceito na v1.

## Decidido após a janela de teste

- Ícones: glifos Nerd Font `Propo` no lugar da Papirus.
- Fonte do layout: `BigBlueTerm437 Nerd Font`; base de 12 px (12 e 24 px ficam
  nítidos); `Plus` e `437` sem diferença perceptível.
- Cor dos estados apagados (mudo, sem conexão, bluetooth desligado):
  `Theme.subtext0`.

## Pontos a confirmar na implementação

- Tamanho dos glifos: proposto `Config.font.size.large` (20 px), igual ao dos
  ícones do tray; ajustar se algum glifo parecer pequeno ou grande.

## Fora de escopo

Bateria, Caps/Num Lock, popouts (etapas 2–4), ícone por dispositivo Bluetooth
na barra, ações por clique/scroll.

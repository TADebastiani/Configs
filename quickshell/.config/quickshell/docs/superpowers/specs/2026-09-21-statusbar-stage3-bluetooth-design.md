# StatusBar etapa 3 — popout de bluetooth

Data: 2026-09-21 · Continua `2026-09-20-statusbar-design.md` (etapa 1) e
`2026-09-21-statusbar-stage2-audio-design.md` (etapa 2), ambas implementadas.
Escopo: popout de hover no ícone de bluetooth, com switches do adaptador e a
lista completa de dispositivos (pareados ou só descobertos). Rede (etapa 4)
fica de fora.

## Objetivo

Passar o mouse no ícone de bluetooth da barra abre um popout, no estilo do
popout de bluetooth do Caelestia, para ligar/desligar o adaptador, ligar/desligar
a busca, e conectar, desconectar, parear ou esquecer dispositivos. Reusa o
`HoverPopup` e o `openPopup` do `StatusIcons`.

## Decisões

| Tema | Decisão |
|---|---|
| Âncora | Popout no ícone de bluetooth. `StatusIcons.openPopup` passa a aceitar `"bluetooth"` (além de `"audio"`); abrir um fecha o outro. |
| Topo | Dois switches: **Ativado** (`adapter.enabled`) e **Buscando** (`adapter.discovering`), e a linha de contagem "N dispositivo(s) (M conectado(s))". |
| Lista | **Todos** os `Bluetooth.devices`, pareados ou só descobertos, ordenados por conectado, depois pareado, depois nome. |
| Linha | Glifo por tipo (`device.icon`), nome, bateria (só se disponível), lixeira (só se pareado) e botão de link. |
| Botão de link | Não pareado: `pair()`. Pareado e desconectado: `connected = true`. Conectado: `connected = false`. Glifo "link" para parear/conectar, "link_off" para desconectar. |
| Lixeira | `forget()`, **sem confirmação** (como no Caelestia). Só aparece quando `paired`. |
| Estado de carga | `Connecting`, `Disconnecting` ou `pairing`: o botão de link mostra um glifo de carregando girando e a linha fica desabilitada. |
| Busca | **Manual**, como no Caelestia. O popout nunca liga nem desliga a busca sozinho. |
| Altura | Limitada a 8 linhas (`bluetoothPopoutMaxRows`), com rolagem por roda dentro do popout. Abaixo de 8 linhas o popout tem a altura do conteúdo. |
| Pareamento | Em dois cliques: `pair()` só pareia; depois o mesmo botão passa a conectar. Escolhido no lugar de `connected = true` em não pareados, porque não é garantido que o BlueZ pareie sozinho nesse caso. |
| Escritas | Os componentes escrevem direto nas propriedades e métodos de `Quickshell.Bluetooth` (adaptador e dispositivo); não há serviço novo, como já é o caso do ícone de bluetooth na etapa 1. |

## Comportamento

- O popout abre em hover real do ícone de bluetooth (`HoverHandler`, mesmo
  padrão do áudio) e fecha pelo `dismissRequested` do `HoverPopup` (150 ms
  depois de o mouse sair do ícone e do popup). `openPopup = "bluetooth"` só é
  atribuído com adaptador presente.
- O ícone de bluetooth já some sem adaptador (etapa 1). Como o alvo do popup
  some junto, o `StatusIcons` ganha uma guarda `hasAdapter`
  (`Bluetooth.defaultAdapter !== null`), no padrão do `hasSink`: sem adaptador,
  se `openPopup === "bluetooth"` ele volta a `""`.
- Adaptador desligado (`state === Disabled`): o popout mostra só o switch
  **Ativado**. A contagem, o switch **Buscando** e a lista ficam ocultos.
- `Enabling`, `Disabling` e `Blocked`: o switch **Ativado** fica desabilitado
  (não aceita clique) e mostra o valor atual de `adapter.enabled`.
- Mover o mouse do ícone de áudio para o de bluetooth troca o popup: o de
  áudio desce e o de bluetooth sobe (só um `openPopup` por vez).
- Trocas de estado do dispositivo (conectar, desconectar) vêm de
  `connected`/`state`/`paired`/`pairing`, por binding; a lista não precisa de
  refresh manual.

## Linha de dispositivo

Layout da direita para a esquerda, para o botão de link ficar sempre na mesma
coluna, com ou sem lixeira: `[glifo][nome ...][bateria][lixeira][link]`.

- Glifo de tipo, pelo nome de ícone de tema do BlueZ (`device.icon`), com o
  glifo genérico de bluetooth para qualquer nome desconhecido:

| `device.icon` | Glifo | Código |
|---|---|---|
| `audio-headset` | `md-headset` | U+F02CE |
| `audio-headphones` | `md-headphones` | U+F02CB |
| `audio-card` | `md-speaker` | U+F04C3 |
| `input-gaming` | `md-gamepad_variant` | U+F0297 |
| `input-keyboard` | `md-keyboard` | U+F030C |
| `input-mouse` | `md-mouse` | U+F037D |
| `input-tablet` | `md-tablet` | U+F04F6 |
| `phone` | `md-cellphone` | U+F011C |
| `computer` | `md-laptop` | U+F0322 |
| `printer` | `md-printer` | U+F042A |
| `camera-photo`, `camera-video` | `md-camera` | U+F0100 |
| qualquer outro | `md-bluetooth` | U+F00AF (já existe: `Config.icons.bluetooth`) |

- Nome: `device.name` (o alias; o BlueZ cai para o endereço quando o
  dispositivo não tem nome), com `elide: Text.ElideRight`.
- Bateria: só quando `device.batteryAvailable`, como texto `Math.round(battery * 100) + "%"`
  em `Theme.subtext0` (medido na etapa 1: os dispositivos do usuário não
  expõem bateria, então normalmente não aparece).
- Lixeira: glifo `md-delete` (U+F01B4), visível só com `device.paired`
  (medido na etapa 1: `paired` é `false` para dispositivos só descobertos).
- Link: `md-link` (U+F0337) e `md-link_off` (U+F0338). Em carga, `md-loading`
  (U+F0772) girando, no lugar do glifo, e `StateLayer` desabilitado.
- Botões de 32 × 32 com `StateLayer` (`color: Theme.text`, como no áudio) e
  `Config.rounding.small`.
- Cores: glifos em `Theme.text`; conectado usa `Theme.active` no glifo de
  tipo para se destacar; o resto em `Theme.subtext0` quando o dispositivo não
  está pareado.

## Ordenação e lista

```qml
model: ScriptModel {
    values: [...Bluetooth.devices.values].sort((a, b) =>
        (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
}
```

O `ScriptModel` mantém a identidade das linhas ao reordenar, então uma linha
que só muda de posição não é recriada.

A lista é uma `Flickable` (rolagem por roda) com uma `Column` e um `Repeater`
sobre o `ScriptModel`. `Column` e `Repeater` (e não `ListView`) porque a
altura precisa ser exata na primeira medição do `HoverPopup`: com poucas
linhas, o `implicitHeight` da `Column` é o real, e a `Flickable` limita a
`bluetoothPopoutMaxRows` linhas (`32 * 8 + espaçamentos`).

## Arquivos

Novos:

```
components/StyledSwitch.qml                   # switch: trilho, alça, estado desabilitado
modules/bar/components/BluetoothPopout.qml    # conteúdo do popup
```

Alterados:

- `modules/bar/components/StatusIcons.qml`: guarda `hasAdapter`; o delegate de
  bluetooth ganha `HoverHandler` e `HoverPopup` com `BluetoothPopout`.
- `configs/IconsConfig.qml`: glifos de tipo de dispositivo (`btHeadset`,
  `btHeadphones`, `btSpeaker`, `btGamepad`, `btKeyboard`, `btMouse`,
  `btTablet`, `btPhone`, `btComputer`, `btPrinter`, `btCamera`), `link`,
  `linkOff`, `trash` e `loading`.
- `configs/BarSizes.qml`: `bluetoothPopoutWidth` (320) e
  `bluetoothPopoutMaxRows` (8).

O mapa `device.icon` → glifo mora em uma função do `BluetoothPopout`
(`deviceGlyph(icon: string): string`), não em `Config`, porque é lógica de
apresentação, não dado de configuração.

### `StyledSwitch`

```qml
property bool checked          // só entrada, ligado pelo dono
signal toggled(bool checked)   // pede o novo valor (!checked); nunca escreve
```

Igual ao `StyledSlider`: `checked` não é atribuído pelo switch (evita quebrar
o binding com `adapter.enabled`). O clique emite `toggled(!checked)` e o dono
escreve na propriedade do adaptador. `enabled: false` reduz a opacidade e
ignora cliques. A alça desliza com `Anim` (`Behavior on x`). Cores: ligado em
`Theme.active`, desligado em `Theme.surface2`, alça em `Theme.text`.

### `BluetoothPopout`

`Item` de raiz com `implicitWidth: Config.sizes.bar.bluetoothPopoutWidth` e
`implicitHeight` da coluna (mesma razão do `AudioPopout`: `Column` reescreve o
próprio tamanho implícito e o `HoverPopup` mede o item carregado). Não tem
propriedades obrigatórias.

## Falhas e ausências

Nenhuma delas deve gerar erro no log:

- Sem adaptador: sem ícone, sem popout, `openPopup` volta a `""`.
- Bluetooth só chega 2–4 s depois do shell (medido na etapa 1); até lá o
  ícone e o popout não existem, e isso é aceito.
- Dispositivo que some da lista no meio da interação (a busca o descarta):
  a linha some, sem erro; como o `ScriptModel` remove a linha, um clique em
  andamento nela é perdido.
- Dispositivo que não aceita pareamento (`pair()` falha): ver Limitações.

## Limitações conhecidas

- **Sem agente de pareamento.** O Quickshell não expõe um agente do BlueZ, então
  dispositivos que pedem PIN ou confirmação não pareiam: a linha volta a "não
  pareado" sem mensagem de erro. Dispositivos "Just Works" (a maioria de
  caixas de som e fones) funcionam.
- Com a busca ligada, dispositivos novos entram no meio da lista (a ordem é
  por nome; não há RSSI), então a linha sob o mouse pode mudar de posição.
- O rect de ancoragem do popup é calculado quando ele abre. Se o ícone de
  bluetooth se deslocar com o popup aberto (o ícone do microfone, que vem
  depois dele, aparecer ou sumir, ou o texto do layout de teclado mudar de
  largura), o popup pode ficar um pouco fora de centro até a próxima abertura.
  O ícone de áudio não sofre disso por ser o último da fila.
- `forget()` é imediato e não pede confirmação.

## Verificação

Não há testes automatizados de QML.

- Por mim: recarregar e ler o `qs log` (sem erro/aviso novo). Um probe
  temporário (removido depois) instancia o `BluetoothPopout` fora da tela e
  loga o tamanho, e outro loga a ordem da lista com os dispositivos reais
  (nome e `paired`/`connected`), sem conectar, parear, esquecer nem ligar a
  busca. **Não uso** `bluetoothctl connect/pair/remove/scan/power` nem
  escrevo em nenhuma propriedade do adaptador ou dos dispositivos.
- Por você (eu passo o que ficou sem verificar): abrir/fechar no hover; troca
  do popup de áudio para o de bluetooth; switch Ativado (o ícone da barra muda
  para "desligado" e a lista some); switch Buscando (aparecem dispositivos
  vizinhos); conectar e desconectar o JBL (estado de carga girando, ícone da
  barra vira "conectado"); parear um dispositivo novo (só um "Just Works"); a
  lixeira em um dispositivo que dê para parear de novo depois, porque é
  imediata; rolagem por roda com mais de 8 linhas; o popout não fechar durante
  o clique dos botões.
- Sem commits. No fim, listo os arquivos e ofereço `git add` e a mensagem.

## Fora de escopo

Agente de pareamento (PIN, confirmação), visível/descobrível (`discoverable`),
renomear, confiar/bloquear (`trusted`/`blocked`), página de detalhes do
dispositivo, bateria além do texto, busca automática ao abrir o popup,
confirmação ao esquecer.

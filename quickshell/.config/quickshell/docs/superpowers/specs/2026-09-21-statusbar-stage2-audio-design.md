# StatusBar etapa 2 — popout de áudio

Data: 2026-09-21 · Continua `2026-09-20-statusbar-design.md` (etapa 1, já
implementada). Escopo: popout de hover no ícone de áudio, com saída e entrada
(microfone) juntas. Bluetooth (etapa 3) e rede (etapa 4) ficam de fora.

## Objetivo

Passar o mouse no ícone de áudio da barra abre um popout com o controle de
volume e mudo da saída e da entrada, reusando o `HoverPopup` da etapa 1.

## Decisões

| Tema | Decisão |
|---|---|
| Âncora | Um único popout, no ícone de áudio. O ícone do microfone na barra continua só indicando "entrada ao vivo", sem popout próprio. |
| Conteúdo | Duas linhas (saída e entrada), cada uma com botão de mudo, slider, porcentagem e o nome do dispositivo atual (texto). |
| Dispositivo padrão | **Sem escolha de dispositivo** nesta etapa. O nome do dispositivo é só informativo. |
| Limite do slider | 0 a 100 %. O PipeWire aceita mais, mas o slider não ultrapassa 100 %. Se o volume já estiver acima, o slider aparece cheio e a porcentagem mostra o valor real. |
| Dono do estado | `StatusIcons` guarda qual popout está aberto (`openPopup: string`, `""` ou `"audio"`), no padrão do `Tray.menuItem`. |
| Escritas no áudio | Ficam no serviço `Audio`, não nos componentes. |

## Comportamento

- O popout abre em `onEntered` do ícone de áudio (hover real), então o
  `closeTimer` do `HoverPopup` arma normalmente. Não há o caso de abrir sem
  nada sob o mouse, que o `closeTimer` (só arma em mudança de hover) não cobre.
- Fecha pelo `dismissRequested` do `HoverPopup`: 150 ms depois de o mouse sair
  do ícone e do popup.
- Linha de saída: só existe com `Audio.sink`. Sem sink, o ícone de áudio não
  abre popout.
- Linha de entrada: só existe com `Audio.hasSource`.
- Mutar o microfone pelo popout faz o ícone dele sumir da barra (regra da
  etapa 1: oculto quando mudo). O popout **não** fecha por isso, porque o alvo
  é o ícone de áudio, que nunca some.
- Botão de mudo: mostra `Audio.volumeIcon` (saída) e `Audio.micIcon` (entrada),
  então o glifo de mudo vem dos estados já existentes. Clique alterna o mudo.
- Slider: arraste e clique no trilho ajustam o volume. Sem scroll (fora de
  escopo).

## Arquivos

Novos:

```
components/StyledSlider.qml                # trilho, preenchimento e alça
modules/bar/components/AudioPopout.qml     # conteúdo do popup
```

Alterados:

- `services/Audio.qml`: ganha `setVolume(real)`, `setMuted(bool)`,
  `setSourceVolume(real)`, `setSourceMuted(bool)`, e `sinkName`/`sourceName`
  (`description || name`, ao vivo). O `refreshNodes()` **não** é tocado: só
  serviria a uma lista de dispositivos, que esta etapa não tem.
- `modules/bar/components/StatusIcons.qml`: `property string openPopup`,
  `HoverHandler` no glifo de áudio (o `Glyph` é um `StyledText`, sem hover
  próprio) e `HoverPopup` com `AudioPopout` como conteúdo.
- `configs/BarSizes.qml`: largura do popout.

### `StyledSlider`

```qml
property real value            // 0..1, ligado pelo dono
property real maxValue: 1
signal moved(real value)       // emitido ao arrastar/clicar; nunca escreve no áudio
```

`value` é só entrada: o slider **não** atribui a si mesmo. Atribuir
imperativamente quebraria o binding com `Audio.volume`. O arraste emite
`moved`, o `AudioPopout` chama `Audio.setVolume`, e o binding devolve o novo
valor. Cores do `Theme`, raios de `Config.rounding`, animações com `Anim`.

### `AudioPopout`

Coluna com no máximo duas linhas. Cada linha: botão de mudo (glifo, com
`StateLayer` para o feedback de hover), `StyledSlider`, porcentagem
(`Math.round(volume * 100)`), e o nome do dispositivo abaixo, em `subtext0`.
A linha some quando sua fonte não existe (`Audio.sink` / `Audio.hasSource`).

## Falhas e ausências

Nenhuma deve gerar erro no log:

- Sem sink: sem popout. Sem source: só a linha de saída.
- Nó do PipeWire ainda não vinculado: `sink.audio` é `null`, então os
  setters checam `sink?.audio` antes de escrever. O `PwObjectTracker` do
  `Audio` já cobre `sink` e `source`.
- Dispositivo sem `description`: cai para `name`, e depois para
  `qsTr("Dispositivo desconhecido")`, como o `Audio` já faz.

## Verificação

Não há testes automatizados de QML.

- Por mim: recarregar e ler o `qs log` (sem erro/aviso novo). Não altero
  volume, mudo nem mouse, e não uso `wpctl` para escrever.
- Por você (eu passo o que ficou sem verificar): abrir/fechar o popout no
  hover; ida do ícone para o popup sem fechar; arraste e clique do slider;
  mudo da saída e da entrada; o ícone do microfone sumir/voltar ao mutar sem
  o popout fechar; reversão do slide se o mouse voltar durante a descida.
- Sem commits. No fim, listo os arquivos e ofereço `git add` e a mensagem.

## Fora de escopo

Escolha de dispositivo padrão, volumes por aplicativo (`streams`), scroll no
ícone ou no slider, volume acima de 100 %, e o conserto do `refreshNodes()`
(o `Connections` em `Pipewire.nodes` que nunca dispara), que só importa
quando houver lista de dispositivos.

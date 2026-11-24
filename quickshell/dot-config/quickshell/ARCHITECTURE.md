# Estrutura de arquivos e imports — Quickshell

Notas sobre como esse config (Quickshell 0.3.2, Hyprland com config em Lua) é
organizado e como evitar imports relativos tipo `import "../../services"`.

## Como o Quickshell resolve imports

- O Quickshell **gera um `qmldir` virtual automaticamente** para cada
  diretório da config, olhando os arquivos que começam com letra maiúscula
  (`[A-Z]*.qml`). Cada subpasta vira um módulo `qs.<pasta>`:
  - `components/` → `import qs.components`
  - `services/` → `import qs.services`
  - `modules/drawers/` → `import qs.modules.drawers`
  - a raiz da config inteira → `import qs`
- **Não escrever `qmldir` à mão:** um `qmldir` manual desativa a auto-geração
  daquele diretório.

Com isso o import deixa de depender da profundidade do diretório. Em vez de
`import "../../services"`, qualquer arquivo em qualquer nível faz:

```qml
import qs                  // raiz (Theme.qml, Config.qml)
import qs.components       // components/
import qs.services         // services/
import qs.modules.drawers  // modules/drawers/
```

### Restrição

Nada de imports do plugin C++ do Caelestia (`Caelestia`, `Caelestia.Config`,
`Tokens`, `CUtils`). O Caelestia serve só de referência visual; o que for
necessário é replicado em QML.

## Singletons

Arquivos com `pragma Singleton` no topo (`Theme.qml`, `Config.qml` e os de
`services/`) são instância única global: basta o import, sem instanciar, e usar
direto, como em `Theme.surface0`.

Um singleton só é criado quando alguém o referencia. Um `IpcHandler` dentro dele
só responde depois disso, então algum componente carregado na inicialização
precisa usá-lo (por exemplo, `Osd.qml` usa `Brightness`).

## Config tipado (`Config.qml` + `configs/`)

O LSP (qmlls/qmllint) só enxerga membros de tipos **declarados**. Isto NÃO
funciona (`Member "thickness" not found on type "QObject"`):

```qml
readonly property QtObject border: QtObject { readonly property int thickness: 10 }
```

Cada seção do config vira um arquivo em `configs/` (tipo `QtObject`, sem
`pragma Singleton`) e o `Config.qml` só a expõe por propriedade **tipada**:

```qml
import qs.configs
Singleton {
    readonly property BorderConfig border: BorderConfig {}
}
```

- Seção aninhada (ex.: `sizes.bar`) também é um tipo próprio (`BarSizes`).
- Curvas de easing são `list<real>`; use
  `easing.type: Easing.BezierSpline` + `easing.bezierCurve: Config.anim.standard`.
  (Um `{ type: ...; bezierCurve: ... }` em binding NÃO é objeto, é um bloco.)
- Arquivos novos costumam entrar só com a recarga. Se o Quickshell em execução
  reclamar de `qmldir`, reinicie: o `qmldir` virtual pode ficar em cache no
  processo.

## Convenção de pastas

- `components/` — widgets visuais reutilizáveis (têm UI).
- `services/` — singletons **sem UI** que expõem estado e ações do sistema,
  com `pragma Singleton`.
- `modules/` — seções grandes/compostas do shell, cada uma na sua subpasta.
- `configs/` — seções tipadas do `Config.qml`.

```
.config/quickshell/
├── shell.qml                  # entrada: instancia os módulos
├── Theme.qml                  # cores
├── Config.qml                 # expõe as seções de configs/
├── configs/                   # import qs.configs
├── components/                # import qs.components
│   ├── containers/            # StyledWindow
│   ├── HoverPopup.qml
│   ├── StateLayer.qml
│   ├── Styled*.qml            # Rect, Text, Slider, Switch, ClippingRect
│   ├── Anim.qml, CAnim.qml
│   └── ScreenState.qml
├── services/                  # import qs.services
│   ├── Audio.qml              # Pipewire: saída, microfone, volume, mudo
│   ├── Brightness.qml         # brilho físico do monitor, por DDC/CI
│   ├── Keyboard.qml           # layout do teclado
│   ├── Network.qml            # rede, ações de Wi-Fi e estado da janela de senha
│   ├── Screens.qml
│   ├── Session.qml            # estado e ações do menu de sessão
│   ├── ShellState.qml
│   └── Time.qml
└── modules/                   # import qs.modules.*
    ├── bar/
    │   ├── Bar.qml
    │   └── components/        # status icons, popouts, tray, relógio, workspaces/
    ├── drawers/               # Drawers.qml, ContentWindow.qml
    ├── network/               # PasswordDialog.qml
    ├── osd/                   # Osd.qml: volume e brilho
    └── session/               # SessionMenu.qml
```

## Comandos IPC

Os atalhos ficam em `~/Configs/hyprland/.config/hypr/hyprland.lua`. A lista
atual sai de `qs ipc show`.

| Comando | Efeito | Atalho |
|---|---|---|
| `qs ipc call session toggle` | Abre ou fecha o menu de sessão | `SUPER + SHIFT + ESC` |
| `qs ipc call osd volume` | Mostra o OSD de volume (não muda o volume) | Teclas de volume e mudo, depois do `wpctl` |
| `qs ipc call brightness up` | Sobe 5% e mostra o OSD | `XF86MonBrightnessUp` |
| `qs ipc call brightness down` | Desce 5% e mostra o OSD | `XF86MonBrightnessDown` |

O OSD de volume abre só pelas teclas, não pelo slider do popout de áudio. Por
isso ele é chamado por IPC em vez de observar `Audio.volume`.

## Dependências externas

- **`ddcutil`** — brilho, em `services/Brightness.qml`. O pacote já carrega o
  `i2c-dev` no boot e libera o acesso sem `sudo`. Cada chamada leva de 70 a
  180 ms e elas não podem se sobrepor; por isso há um único processo de escrita,
  que sempre envia o valor mais recente.
- **NetworkManager** — Wi-Fi, por `Quickshell.Networking`. Mesmo com senha
  errada, `connectWithPsk` em uma rede nova deixa um perfil salvo; a janela de
  senha o apaga ao cancelar.

## Padrões do projeto

### `HoverPopup`

- Quem usa decide quando abrir, pela propriedade `open`. Em `StatusIcons.qml`,
  `openPopup` garante um popup aberto por vez.
- `dismissRequested` dispara quando nem o ícone nem o popup estão sob o ponteiro.
- **Limpar `openPopup` quando os dados somem.** O `closeTimer` só arma quando o
  hover muda e só fecha se `open` for verdadeiro. Um popup "aberto" sem dados
  ficaria pendente e apareceria sozinho quando os dados voltassem. Os guardas
  `hasSink`, `hasAdapter` e `canOpenNetwork` fazem isso.
- O conteúdo fica em um `Loader`, recriado a cada abertura: nada sobrevive entre
  aberturas, e `Component.onCompleted`/`onDestruction` acompanham o popup.
- Em conteúdo com `Column`, dê `implicitWidth` a um `Item` em volta: o `Column`
  reescreve o próprio tamanho implícito.
- O popup não recebe teclado de forma testada. Entrada de texto vai em uma janela
  própria com `WlrKeyboardFocus.Exclusive`, como `SessionMenu` e `PasswordDialog`.

### Conteúdo compilado sob demanda

O conteúdo do popout só é compilado quando ele abre, então **um erro ali não
aparece ao recarregar o shell**. Para validar sem abrir, use uma sonda temporária:

```qml
const c = Qt.createComponent(Qt.resolvedUrl("modules/bar/components/NetworkPopout.qml"));
console.warn(c.status, c.errorString());
```

### Como verificar

- Depois de editar, ler o log com `timeout 8 qs log`. Se a recarga não ocorrer,
  usar `touch` no arquivo.
- Depois de editar `hyprland.lua`, rodar `hyprctl reload` e `hyprctl configerrors`.

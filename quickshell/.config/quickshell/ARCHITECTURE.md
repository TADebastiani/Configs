# Estrutura de arquivos e imports — Quickshell

Notas sobre como organizar esse config (Quickshell 0.3.1) e evitar imports
relativos tipo `import "../../services"`.

## Como o Quickshell resolve imports

- O Quickshell **gera um `qmldir` virtual automaticamente** para cada
  diretório da config, olhando os arquivos que começam com letra maiúscula
  (`[A-Z]*.qml`). Cada subpasta vira um módulo `qs.<pasta>`:
  - `components/` → `import qs.components`
  - `services/` → `import qs.services`
  - `modules/drawers/` → `import qs.modules.drawers`
  - a raiz da config inteira → `import qs`
- **Se existir um `qmldir` manual num diretório, isso desativa a
  auto-geração daquele diretório.** Foi exatamente o motivo do erro que eu
  tomei: os `qmldir` declaravam `module MyShell.Components` /
  `module MyShell.Services`, o que não bate com o esquema `qs.*` esperado —
  o resolvedor de módulos não acha `MyShell.Services` em lugar nenhum do
  import path.
- **Solução: não escrever `qmldir` à mão.** Apagar os existentes
  (`components/qmldir`, `services/qmldir`) e deixar o Quickshell gerar
  sozinho.

Com isso o import deixa de depender da profundidade do diretório. Em vez de
`import "../../services"`, qualquer arquivo em qualquer nível faz:

```qml
import qs                  // raiz (Theme.qml, etc.)
import qs.components       // components/
import qs.services         // services/
import qs.modules.drawers  // modules/drawers/
```

## Singletons

`Theme.qml` hoje é acessado via `import ".."` relativo. Adicionando
`//@ pragma Singleton` no topo dele, vira instância única global — daí
basta `import qs` (sem instanciar `Theme {}`) em qualquer arquivo e usar
`Theme.corDeFundo` direto, igual já é feito com `Quickshell` nativo.

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
- Adicionou arquivo/propriedade e o Quickshell em execução reclama de `qmldir`?
  Reinicie o quickshell: o `qmldir` virtual fica em cache no processo.

## Convenção de pastas sugerida

- `components/` — widgets visuais reutilizáveis (têm UI).
- `services/` — singletons **sem UI** que expõem estado do sistema
  (Pipewire, Hyprland, rede, etc.), com `pragma Singleton`.
- `modules/` — seções grandes/compostas do shell (ex.: `Drawers`,
  notificações), cada uma podendo ter sua própria subpasta.

```
.config/quickshell/
├── shell.qml
├── Theme.qml              # pragma Singleton → import qs
├── Bar.qml
├── components/            # import qs.components
│   ├── Audio.qml
│   ├── Clock.qml
│   └── Workspaces.qml
├── services/               # import qs.services
│   └── Audio.qml           # wrap do Pipewire.defaultAudioSink, sink/vol/muted
└── modules/                # import qs.modules.*
    └── drawers/
        └── Drawers.qml
```

## Limpeza pendente no config atual

- [ ] Apagar `components/qmldir` e `services/qmldir`.
- [ ] `Workspaces.qml` na raiz está vazio (0 linhas) — sobra da migração
      pra `components/`. Apagar.
- [ ] `Volume.qml` na raiz (94 linhas) parece a versão antiga de
      `components/Audio.qml` (218 linhas, mais evoluído). Conferir e
      apagar se confirmado.
- [ ] `services/Clock.qml` é puramente visual (`Text` + `Timer`) — mover
      para `components/`, já que `services/` deveria ser só lógica sem UI.
- [ ] Adicionar `//@ pragma Singleton` em `Theme.qml`.
- [ ] Trocar os imports relativos (`import ".."`, `import "components"`,
      `import MyShell.Services`) por `import qs` / `import qs.components`
      / `import qs.services` nos arquivos existentes (`Bar.qml`,
      `components/Audio.qml`, `services/Clock.qml`).

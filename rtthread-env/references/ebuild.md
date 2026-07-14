# EBuild Templates

## Basic Project

Use this template for an EBuild-style `stm32f407-rt-spark` hello project.

```text
stm32f407-rt-spark-hello/
├── .config
├── Kconfig
├── SConstruct
├── SConscript
├── proj_config.py
├── applications/
│   ├── SConscript
│   └── main.c
└── board/
    ├── SConscript
    └── linker_scripts/
        └── link.lds
```

`SConstruct`:

```python
from SCons.Script import Environment, Export, SConscript
from ebuild import PrepareBuilding, DoBuilding
import proj_config

env = Environment()
PrepareBuilding(env, proj_config=proj_config)
Export('env')

objs = SConscript('SConscript')
DoBuilding(env, 'rtthread.elf', objs)
```

`proj_config.py`:

```python
import os

PROJECT_NAME = 'stm32f407-rt-spark-hello'
TARGET_NAME = 'rtthread.elf'
CONFIG_HEADER = 'proj_config.h'

TOOLCHAIN_CONFIG = {
    'CC_PREFIX': 'arm-none-eabi-',
    'EXEC_PATH': os.getenv('RTT_EXEC_PATH', ''),
    'MCU_SERIES': {
        'CONFIG_SOC_STM32F407': {
            'cpu': 'cortex-m4',
            'fpu': 'fpv4-sp-d16',
            'float_abi': 'hard',
            'link_script': 'board/linker_scripts/link.lds',
        },
    },
    'BUILD': 'debug',
}

POST_ACTION = '$OBJCOPY -O binary $TARGET build/rtthread.bin'
```

`Kconfig`:

```text
mainmenu "RT-Thread stm32f407-rt-spark hello"

config SOC_STM32F407
    bool
    default y

config APP_HELLO
    bool "Enable hello application"
    default y

source "$PKGS_DIR/Kconfig"
```

Root `SConscript` using bridge:

```python
from SCons.Script import Import

Import('env')

groups = env.Bridge()
Return('groups')
```

`env.Bridge()` scans immediate child directories such as `applications/` and
`board/`, executes their `SConscript` files, and merges returned groups. Use
explicit `SConscript('path/SConscript')` calls only when the root must include a
fixed subset or a specific order.

`applications/main.c`:

```c
#include <rtthread.h>

int main(void)
{
    rt_kprintf("hello rt-thread env ebuild\n");
    return 0;
}
```

`applications/SConscript`:

```python
from SCons.Script import Import, Split

Import('env')

cwd = env.GetCurrentDir()

src = Split("""
main.c
""")

CPPPATH = [cwd + '/include']

group = env.DefineGroup(
    'applications',
    src,
    depend=['APP_HELLO'],
    CPPPATH=CPPPATH,
)

Return('group')
```

`board/SConscript`:

```python
from SCons.Script import Glob, Import

Import('env')

cwd = env.GetCurrentDir()

src = Glob('*.c')

CPPPATH = [cwd + '/include']

group = env.DefineGroup(
    'board',
    src,
    depend=['SOC_STM32F407'],
    CPPPATH=CPPPATH,
)

Return('group')
```

Reuse startup files, board init, drivers, and linker script from the existing
`stm32f407-rt-spark` BSP before adapting the build entry points.

Build:

```sh
scons --menuconfig
scons --pyconfig-silent
scons -c
scons
scons --target=vscode
```

## SConscript Style

When a `SConscript` selects source files, use `Glob` for a pattern and `Split`
for an explicit, multiline list. Select exactly one initial form for a source
list. Add individual files incrementally with `src += [...]`; do not replace
an existing source list merely to add a file.

```python
from SCons.Script import Glob, Import, Split

Import('env')

cwd = env.GetCurrentDir()

# Use this form when the component compiles every matching file.
src = Glob('*.c')
src += Glob('*.cpp')
src += Glob('*.S')
```

```python
from SCons.Script import Import, Split

Import('env')

cwd = env.GetCurrentDir()

# Use this form when the source set must be a deliberate whitelist.
src = Split("""
xx.c
nn/mm.c
""")

src += ['yy.c']
env.SrcRemove(src, 'xx.c')

CPPPATH = [cwd + '/include']
CPPPATH += [cwd + '/xx/include']
```

Use `Glob` for an ordinary directory whose matching files all belong to the
component. Use `Split` for startup files, protocol stacks, generated vendor
sources, or any component where the file set and order must be explicit. Do
not add a file explicitly when it is already selected by the same `Glob`.

Use `/` in `SConscript` relative paths on both Linux and Windows. Prefer the
simple `cwd + '/subdir'` form above for include directories and source paths;
do not introduce `os.path.join` solely to build these paths. Keep `os.path`
only where filesystem inspection or other path operations actually require it.

EBuild injects `DefineGroup`, `BuildPackage`, `Bridge`, `GetCurrentDir`, and
`SrcRemove` onto `env`, so EBuild scripts call them as `env.DefineGroup(...)`,
`env.BuildPackage(...)`, `env.Bridge()`, `env.GetCurrentDir()`, and
`env.SrcRemove(...)`. `Glob` and `Split` are SCons functions imported directly
as shown above.

### Configuration, Scope, and Ownership

Keep a feature's source files, private include directories, and private defines
in the same configuration branch. A `depend` list is an AND condition in both
RT-Thread and EBuild: `depend=['CONFIG_A', 'CONFIG_B']` requires both options.
For an OR condition, use an explicit `if` expression.

```python
from SCons.Script import Glob, Import

Import('env')

cwd = env.GetCurrentDir()
src = Glob('src/common/*.c')

CPPPATH = [cwd + '/include']
LOCAL_CPPPATH = [cwd + '/src/include']
LOCAL_CPPDEFINES = ['COMPONENT_INTERNAL']

if env.GetDepend('CONFIG_TLS'):
    src += ['src/tls.c']
    LOCAL_CPPPATH += [cwd + '/src/tls/include']
    LOCAL_CPPDEFINES += ['COMPONENT_USING_TLS']

if env.GetDepend('CONFIG_IPV6'):
    src += ['src/ipv6.c']
    LOCAL_CPPPATH += [cwd + '/src/ipv6/include']
    LOCAL_CPPDEFINES += ['COMPONENT_USING_IPV6']

group = env.DefineGroup(
    'component',
    src,
    depend=['CONFIG_COMPONENT'],
    CPPPATH=CPPPATH,
    LOCAL_CPPPATH=LOCAL_CPPPATH,
    LOCAL_CPPDEFINES=LOCAL_CPPDEFINES,
)
Return('group')
```

Use `CPPPATH` and `CPPDEFINES` for public interfaces required outside the
component. Use `LOCAL_CPPPATH`, `LOCAL_CPPDEFINES`, and `LOCAL_CFLAGS` for
private headers, defines, and compiler options so they stay on the component's
cloned build environment. Do not mutate the shared SCons environment from a
component script.

Each source file has exactly one owning leaf `SConscript` and one group. A
directory with `package.json` uses `env.BuildPackage(...)`; do not also register
the same sources with `env.DefineGroup(...)`.

For the RT-Thread source tree and conventional BSP `SConscript` files, import
the build helpers with `from building import *` and call the helpers directly:

```python
from building import *

cwd = GetCurrentDir()
src = Glob('*.c')
src += ['yy.c']
SrcRemove(src, 'xx.c')

CPPPATH = [cwd + '/include']
CPPPATH += [cwd + '/xx/include']

group = DefineGroup('component', src, depend=['RT_USING_COMPONENT'],
                    CPPPATH=CPPPATH)
Return('group')
```

Do not change these RT-Thread direct calls to `env.Method(...)`; the standard
RT-Thread `building` interface exports them as module-level functions.

## Component Script

Prefer `DefineGroup` for local components.

```text
components/foo/
├── Kconfig
├── SConscript
├── include/
│   └── foo.h
└── src/
    └── foo.c
```

`components/foo/Kconfig`:

```text
config COMPONENT_USING_FOO
    bool "Enable foo component"
    default n
```

`components/foo/SConscript`:

```python
from SCons.Script import Glob, Import

Import('env')

cwd = env.GetCurrentDir()

src = Glob('src/*.c')

CPPPATH = [cwd + '/include']

group = env.DefineGroup(
    'foo',
    src,
    depend=['COMPONENT_USING_FOO'],
    CPPPATH=CPPPATH,
    CPPDEFINES=['FOO_USING_EBUILD'],
)

Return('group')
```

Use `BuildPackage` when the component owns a `package.json`:

```python
from SCons.Script import Import

Import('env')

group = env.BuildPackage('.')
Return('group')
```

`package.json`:

```json
{
  "type": "rt-thread-component",
  "name": "foo",
  "dependencies": ["COMPONENT_USING_FOO"],
  "defines": ["FOO_USING_EBUILD"],
  "sources": [
    {
      "dependencies": [],
      "includes": ["include"],
      "files": ["src/*.c"]
    }
  ]
}
```

## Cascaded SConscript

Use `env.Bridge()` for cascaded subdirectories. It scans only immediate child
directories that contain `SConscript`, in sorted directory-name order, and
merges their returned groups.

```text
components/
├── SConscript
├── drivers/
│   ├── SConscript
│   └── uart_ext/
│       └── SConscript
└── middleware/
    ├── SConscript
    └── foo/
        └── SConscript
```

`components/SConscript` and intermediate directory `SConscript` files:

```python
from SCons.Script import Import

Import('env')

groups = env.Bridge()
Return('groups')
```

Leaf directories use `DefineGroup` or `BuildPackage` and return `group`.
The project root `SConscript` can also use bridge to connect all immediate
subdirectory `SConscript` files. When the parent needs a fixed order, must
exclude a child directory, or needs to make the selected children obvious, use
explicit `SConscript('path/SConscript')` calls instead of `env.Bridge()`:

```python
from SCons.Script import Import, SConscript

Import('env')

groups = []
groups += SConscript('drivers/SConscript')
groups += SConscript('middleware/SConscript')
Return('groups')
```

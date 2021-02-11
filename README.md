# Abt

Abt makes re-occuring tasks easily accessible from the terminal:
- Moving asana tasks around
- Tracking work/meetings in harvest
- Consistently naming branches

## How does abt work?

Abt uses a hybrid approach between having small scripts each doing one thing:
- `start-asana --project-gid xxxx --task-gid yyyy`
- `start-harvest --project-id aaaa --task-id bbbb`

And having a single highly advanced script that does everything:
- `start xxxx/yyyy aaaa/bbbb`

Abt looks like one script, but works like a bunch of light independent scripts:
- `abt start asana:xxxx/yyyy harvest:aaaa/bbbb`

## Usage
`abt <command> [<scheme-argument>] [<options> --] [<scheme-argument>] ...`

Definitions:
- `<command>`: Name of command to execute, e.g. `start`, `finalize` etc.
- `<scheme-argument>`: A URI-like identifier, `scheme:path`, pointing to a project/task etc. within a system.
- `<options>`: Optional flags for the command and scheme argument

Getting started:
- `abt init asana harvest`: Setup asana and harvest project git repo in working dir
- `abt pick harvest`: Pick harvest tasks, for most projects this will stay the same
- `abt pick asana | abt start harvest`: Pick asana task and start working
- `abt stop harvest`: Stop time tracker
- `abt start asana harvest`: Continue working, e.g. after a break
- `abt finalize asana`: Finalize the selected asana task

Tracking meetings (without changing the config):
- `abt pick asana -d | abt track harvest`: Track on asana meeting task
- `abt pick harvest -d | abt track harvest -c "Name of meeting"`: Track on separate harvest-task

Command output can be piped, e.g.:
- `abt tasks asana | grep -i <name of task>`
- `abt tasks asana | grep -i <name of task> | abt start`

Sharing configuration:
- `abt share asana harvest | tr "\n" " "`: Print current configuration
- `abt share asana harvest | tr "\n" " " | pbcopy`: Copy configuration (mac only)
- `abt start <shared configuration>`: Start a shared configuration

Flags:
- `abt start harvest -c "comment"`: Add command flags after <scheme>:<path>
- `abt start harvest -c "comment" -- asana`: Use -- to mark the end of a flag list if it's to be followed by a <scheme-argument>
- `abt pick harvest | abt start -c "comment"`: Flags placed directly after a command applies to piped in <scheme-argument>

## Available commands:
Some commands have `[options]`. Run such a command with `--help` flag to view supported flags, e.g: `abt track harvest -h`

### Asana
| Command | Description |
| :------ | :---------- |
| `abt add asana[:<project-gid>]`                                | Create a new task for the current/specified Asana project |
| `abt branch-name asana[:<project-gid>/<task-gid>]`             | Suggest a git branch name for the current/specified task. |
| `abt clear asana`                                              | Clear asana configuration |
| `abt current asana[:<project-gid>[/<task-gid>]]`               | Get or set project and or task for current git repository |
| `abt finalize asana[:<project-gid>/<task-gid>]`                | Move current/specified task to section (column) for finalized tasks |
| `abt harvest-time-entry-data asana[:<project-gid>/<task-gid>]` | Print Harvest time entry data for Asana task as json. Used by harvest start script. |
| `abt init asana`                                               | Pick Asana project for current git repository |
| `abt pick asana[:<project-gid>]`                               | Pick task for current git repository |
| `abt projects asana`                                           | List all available projects - useful for piping into grep etc. |
| `abt share asana[:<project-gid>[/<task-gid>]]`                 | Print project/task config string |
| `abt start asana[:<project-gid>/<task-gid>]`                   | Move current or specified task to WIP section (column) and assign it to you |
| `abt tasks asana`                                              | List available tasks on project - useful for piping into grep etc. |

### Devops
| Command | Description |
| :------ | :---------- |
| `abt boards devops`                                                                                 | List all boards - useful for piping into grep etc |
| `abt branch-name devops[:<organization-name>/<project-name>/<board-id>/<work-item-id>]`             | Suggest a git branch name for the current/specified work-item. |
| `abt clear devops`                                                                                  | Clear DevOps configuration |
| `abt current devops[:<organization-name>/<project-name>/<board-id>[/<work-item-id>]]`               | Get or set DevOps configuration for current git repository |
| `abt harvest-time-entry-data devops[:<organization-name>/<project-name>/<board-id>/<work-item-id>]` | Print Harvest time entry data for DevOps work item as json. Used by harvest start script. |
| `abt init devops`                                                                                   | Pick DevOps board for current git repository |
| `abt pick devops[:<organization-name>/<project-name>/<board-id>]`                                   | Pick work item for current git repository |
| `abt share devops[:<organization-name>/<project-name>/<board-id>[/<work-item-id>]]`                 | Print DevOps config string |
| `abt work-items devops`                                                                             | List all work items on board - useful for piping into grep etc. |

### Git
| Command | Description |
| :------ | :---------- |
| `abt branch git <scheme>[:<path>]` | Switch branch. Uses a compatible scheme to generate the branch-name: E.g. `abt branch git asana` |

### Harvest
| Command | Description |
| :------ | :---------- |
| `abt clear harvest`                                    | Clear harvest configuration |
| `abt current harvest[:<project-id>[/<task-id>]]`       | Get or set project and or task for current git repository |
| `abt init harvest`                                     | Pick Harvest project for current git repository |
| `abt pick harvest[:<project-id>]`                      | Pick task for current git repository |
| `abt projects harvest`                                 | List all available projects - useful for piping into grep etc. |
| `abt share harvest[:<project-id>[/<task-id>]]`         | Print project/task config string |
| `abt start harvest[:<project-id>/<task-id>] [options]` | Alias for: `abt track harvest`. Meant to used in combination with other scheme arguments, e.g. `abt start harvest asana` |
| `abt stop harvest`                                     | Stop running harvest tracker |
| `abt tasks harvest`                                    | List available tasks on project - useful for piping into grep etc. |
| `abt track harvest[:<project-id>/<task-id>] [options]` | Start tracker for current or specified task. Add a relevant scheme argument to link the time entry, e.g. `abt track harvest asana` |

#### This readme was generated with `abt readme > README.md`

# Abt

Abt makes re-occuring tasks easily accessible from the terminal:
- Moving asana tasks around
- Tracking work/meetings in harvest
- Consistently naming branches

## How does abt work?

Abt is a hybrid of having small scripts each doing one thing:
- `start-asana --project-gid xxxx --task-gid yyyy`
- `start-harvest --project-id aaaa --task-id bbbb`

And having a single highly advanced script that does everything with a single command:
- `start xxxx/yyyy aaaa/bbbb`

Abt looks like one command, but works like a bunch of light scripts:
- `abt start asana:xxxx/yyyy harvest:aaaa/bbbb`

## Usage
`abt <command> [<ARI>] [<options> --] [<ARI>] ...`

Definitions:
- `<command>`: Name of command to execute, e.g. `start`, `finalize` etc.
- `<ARI>`: A URI-like resource identifier with a scheme and an optional path in the format: `<scheme>[:<path>]`. E.g., `harvest:11111111/22222222`
- `<options>`: Optional flags for the command and ARI

Getting started:
- `abt init asana harvest`: Setup asana and harvest project for local git repo
- `abt pick harvest`: Pick harvest task. This will likely stay the same throughout the project
- `abt pick asana | abt start harvest`: Pick asana task and start tracking time
- `abt stop harvest`: Stop time tracker
- `abt start asana harvest`: Continue working, e.g., after a break
- `abt finalize asana`: Finalize the selected asana task

Tracking meetings (without switching current task setting):
- `abt pick asana -d | abt track harvest`: Track on asana meeting task
- `abt pick harvest -d | abt track harvest -c "Name of meeting"`: Track on separate harvest-task

Many commands output ARIs that can be piped into other commands:
- `abt tasks asana | grep -i <name of task>`
- `abt tasks asana | grep -i <name of task> | abt start`

Sharing ARIs:
- `abt share asana harvest | tr "\n" " "`: Print current asana and harvest ARIs on a single line
- `abt share asana harvest | tr "\n" " " | pbcopy`: Copy ARIs to clipboard (mac only)
- `abt start <ARIs from coworker>`: Work on a task your coworker shared with you
- `abt current <ARIs from coworker> | abt start`: Set task as current, then start it

Flags:
- `abt start harvest -c "comment"`: Add command flags after ARIs
- `abt start harvest -c "comment" -- asana`: Use -- to end a list of flags, so that it can be followed by another ARI
- `abt pick harvest | abt start -c "comment"`: Flags placed directly after a command applies to the piped in ARI

## Commands:

Some commands have `[options]`. Run such a command with `--help` flag to view supported flags, e.g: `abt track harvest -h`

### Global
| Command | Description |
| :------ | :---------- |
| `abt commands` | List all abt commands |
| `abt examples` | Print command examples |
| `abt help`     | Print abt usage text |
| `abt readme`   | Print markdown readme |
| `abt share`    | Prints all project configuration as a single line of ARIs |
| `abt version`  | Print abt version |

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
| `abt share asana[:<project-gid>[/<task-gid>]]`                 | Print project/task ARI |
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
| `abt share devops[:<organization-name>/<project-name>/<board-id>[/<work-item-id>]]`                 | Print DevOps ARI |
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
| `abt share harvest[:<project-id>[/<task-id>]]`         | Print project/task ARI |
| `abt start harvest[:<project-id>/<task-id>] [options]` | Alias for: `abt track harvest`. Meant to used in combination with other ARIs, e.g. `abt start harvest asana` |
| `abt stop harvest`                                     | Stop running harvest tracker |
| `abt tasks harvest`                                    | List available tasks on project - useful for piping into grep etc. |
| `abt track harvest[:<project-id>/<task-id>] [options]` | Start tracker for current or specified task. Add a relevant ARI to link the time entry, e.g. `abt track harvest asana` |

#### This readme was generated with `abt readme > README.md`

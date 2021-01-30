# Abt
This readme was generated with `abt help-md > README.md`

## Usage
`abt <command> [<provider[:<arguments>]>...]`

Getting started:
- `abt init asana harvest`: Setup asana and harvest project git repo in working dir
- `abt pick harvest`: Pick harvest tasks, for most projects this will stay the same
- `abt pick asana | abt start harvest`: Pick asana task and start working
- `abt stop harvest`: Stop time tracker
- `abt start asana harvest`: Continue working, e.g. after a break
- `abt finalize asana`: Finalize the selected asana task

Tracking meetings (without changing the config):
- `abt tasks asana | grep -i standup | abt track harvest`: Track on asana meeting task without changing any configuration
- `abt tasks harvest | grep -i comment | abt track harvest`: Track on harvest "Comment"-task (will prompt for a comment)

Command output can be piped, e.g.:
- `abt tasks asana | grep -i <name of task>`
- `abt tasks asana | grep -i <name of task> | abt start`

Sharing configuration:
- `abt share asana harvest | tr "\n" " "`: Print current configuration
- `abt share asana harvest | tr "\n" " " | pbcopy`: Copy configuration (mac only)
- `abt start <shared configuration>`: Start a shared configuration

## Available commands:
### Asana
| Command | Description |
| :------ | :---------- |
| `clear asana`                                              | Clear project/task for current git repository |
| `clear-global asana`                                       | Clear all global configuration |
| `current asana[:<project-gid>[/<task-gid>]]`               | Get or set project and or task for current git repository |
| `finalize asana[:<project-gid>/<task-gid>]`                | Move current/specified task to section (column) for finalized tasks |
| `harvest-time-entry-data asana[:<project-gid>/<task-gid>]` | Print Harvest time entry data for Asana task as json. Used by harvest start script. |
| `init asana`                                               | Pick Asana project for current git repository |
| `pick asana[:<project-gid>]`                               | Pick task for current git repository |
| `projects asana`                                           | List all available projects - useful for piping into grep etc. |
| `share asana[:<project-gid>[/<task-gid>]]`                 | Print project/task config string |
| `start asana[:<project-gid>/<task-gid>]`                   | Set current task and move it to a section (column) of your choice |
| `tasks asana`                                              | List available tasks on project - useful for piping into grep etc. |

### Devops
| Command | Description |
| :------ | :---------- |
| `boards devops`                                                                                 | List all boards - useful for piping into grep etc |
| `clear devops`                                                                                  | Clear DevOps config for current git repository |
| `clear-global devops`                                                                           | Clear all global configuration |
| `current devops[:<organization-name>/<project-name>/<board-id>[/<work-item-id>]]`               | Get or set DevOps configuration for current git repository |
| `harvest-time-entry-data devops[:<organization-name>/<project-name>/<board-id>/<work-item-id>]` | Print Harvest time entry data for DevOps work item as json. Used by harvest start script. |
| `init devops`                                                                                   | Pick DevOps board for current git repository |
| `pick devops[:<organization-name>/<project-name>/<board-id>]`                                   | Pick work item for current git repository |
| `share devops[:<organization-name>/<project-name>/<board-id>[/<work-item-id>]]`                 | Print DevOps config string |
| `work-items devops`                                                                             | List all work items on board - useful for piping into grep etc. |

### Harvest
| Command | Description |
| :------ | :---------- |
| `clear harvest`                              | Clear project/task for current git repository |
| `clear-global harvest`                       | Clear all global configuration |
| `current harvest[:<project-id>[/<task-id>]]` | Get or set project and or task for current git repository |
| `init harvest`                               | Pick Harvest project for current git repository |
| `pick harvest[:<project-id>]`                | Pick task for current git repository |
| `projects harvest`                           | List all available projects - useful for piping into grep etc. |
| `share harvest[:<project-id>[/<task-id>]]`   | Print project/task config string |
| `start harvest[:<project-id>/<task-id>]`     | As track, but also lets the user override the current task and triggers `start` commands for other providers  |
| `stop harvest`                               | Stop running harvest tracker |
| `tasks harvest`                              | List available tasks on project - useful for piping into grep etc. |
| `track harvest[:<project-id>/<task-id>]`     | Start tracker for current or specified task. Add a relevant provider to link the time entry: E.g. `abt start harvest asana` |

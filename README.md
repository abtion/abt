# Abt
This readme was generated with `abt help-md > README.md`

## Usage
`abt <command> [<provider:arguments>...]`

Multiple providers and arguments can be passed, e.g.:
- `abt init asana harvest`
- `abt pick-task asana harvest`
- `abt start asana harvest`
- `abt clear asana harvest`

Command output can be piped, e.g.:
- `abt tasks asana | grep -i <name of task>`
- `abt tasks asana | grep -i <name of task> | abt start`

## Available commands:
### Asana
| Command | Description |
| :------ | :---------- |
| `clear asana                                             ` | Clear project/task for current git repository |
| `clear-global asana                                      ` | Clear all global configuration |
| `current asana[:<project-gid>[/<task-gid>]]              ` | Get or set project and or task for current git repository |
| `harvest-time-entry-data asana[:<project-gid>/<task-gid>]` | Print Harvest time entry data for Asana task as json. Used by harvest start script. |
| `init asana                                              ` | Pick Asana project for current git repository |
| `move asana[:<project-gid>/<task-gid>]                   ` | Move current or specified task to another section (column) |
| `pick-task asana[:<project-gid>]                         ` | Pick task for current git repository |
| `projects asana                                          ` | List all available projects - E.g. for grepping and selecting `| grep -i <name> | abt current` |
| `start asana[:<project-id>/<task-id>]                    ` | Set current task and move it to a section (column) of your choice |
| `tasks asana                                             ` | List available tasks on project - E.g. for grepping and selecting `| grep -i <name> | abt current` |

### Harvest
| Command | Description |
| :------ | :---------- |
| `clear harvest                             ` | Clear project/task for current git repository |
| `clear-global harvest                      ` | Clear all global configuration |
| `current harvest[:<project-id>[/<task-id>]]` | Get or set project and or task for current git repository |
| `init harvest                              ` | Pick Harvest project for current git repository |
| `pick-task harvest[:<project-id>]          ` | Pick task for current git repository |
| `projects harvest                          ` | List all available projects - E.g. for grepping and selecting `| grep -i <name> | abt current` |
| `start harvest[:<project-id>/<task-id>]    ` | Start tracker for current or specified task. Add a relevant provider to link the time entry: E.g. `abt start harvest asana` |
| `stop harvest                              ` | Stop running harvest tracker |
| `tasks harvest                             ` | List available tasks on project - E.g. for grepping and selecting `| grep -i <name> | abt current` |

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
| `start harvest[:<project-id>/<task-id>]`     | Start tracker for current or specified task. Add a relevant provider to link the time entry: E.g. `abt start harvest asana` |
| `stop harvest`                               | Stop running harvest tracker |
| `tasks harvest`                              | List available tasks on project - useful for piping into grep etc. |

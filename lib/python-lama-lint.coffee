# I've commented this to be newb friendly (ie me).
{BufferedProcess} = require 'atom'
{CompositeDisposable} = require 'atom'
path = require 'path'

# Name for debug.
moduleName = 'python-lama-lint'
status = {}
subs = null
lints = []
currentEditorPath = null

# Package API function.
# Called when the package is being loaded, used to setup anything.
activate = (state) ->
  # The layout may be edited before it is consumed.
  initStatusBarLayout()
  # Get the path for the active pane and then sub the event for it changing.
  activePane = atom.workspace.getActiveTextEditor()
  if activePane then currentEditorPath = activePane.getPath()
  subs = new CompositeDisposable
  subs.add atom.workspace.onDidChangeActivePaneItem updateContext
  console.log 'activated: ' + moduleName # For debug.

# Package API function.
# Called when the package is deactivated, use for disposing.
deactivate = ->
  status.bar?.destroy()
  status.bar = null
  subs.dispose()
  console.log 'deactivated: ' + moduleName # For debug.

initStatusBarLayout = ->
    status.ele = document.createElement('span')
    status.errors = document.createElement('span')
    status.warnings = document.createElement('span')
    status.infos = document.createElement('span')
    status.ele.appendChild status.errors
    status.ele.appendChild status.warnings
    status.ele.appendChild status.infos

# Updates the status bar element
setStatus = (errors, warnings, infos) ->
  status.errors.textContent = 'E: ' + errors
  status.warnings.textContent = ' W: ' + warnings
  status.infos.textContent = ' I: ' + infos
  # Text and the numbers above 0 are both give colour.
  # These are basic atom styles from the styleguide.
  status.errors.className = if errors then 'text-error' else 'text-subtle'
  status.warnings.className = if warnings then 'text-warning' else 'text-subtle'
  status.infos.className = if infos then 'text-info' else 'text-subtle'

# Clears all status text.
clearStatus = ->
  status.errors.textContent = ''
  status.warnings.textContent = ''
  status.infos.textContent = ''

# Checks if editor has been linted and updates the status bar.
update = ->
  i = (lints.map (x) -> x.path).indexOf currentEditorPath
  if i isnt -1
    x = lints[i]
    setStatus x.errors, x.warnings, x.infos
  else
    # Current editor is either not linted or not an editor.
    clearStatus()

# Trigger status bar update when the pane view changes.
updateContext = (textEditor) ->
  if typeof textEditor.getPath is 'function'
    currentEditorPath = textEditor.getPath()
  else
    currentEditorPath = ''
  update()

# Add editor if it is new.
addEditorPath = (filePath) ->
  i = (lints.map (x) -> x.path).indexOf filePath
  if i is -1
    x =
      path: filePath
      errors: '?'
      warnings: '?'
      infos: '?'
    lints.push x

# Changes the internal tracking of EWI for each pane.
# TextEditor may have been destroyed during linting so path must be used.
changeEwi = (filePath, errors, warnings, infos) ->
  # Path may have been removed if the editor was destory (not implemented).
  i = (lints.map (x) -> x.path).indexOf filePath
  if i isnt -1
    x = lints[i]
    x.errors = errors
    x.warnings = warnings
    x.infos = infos

# Converts line of LamaLint output into Linter package message.
processline = (line, filepath)->
  codeindex = line.indexOf(': ')
  if codeindex == -1
    # This line does not make sense so skip it.
    if line isnt '' then console.log('bad line:' + line)
    return undefined
  codeletter = line.charAt(codeindex + 2)
  if codeletter == 'E'
    msgcode = 'Error'
  else if codeletter == 'W'
    msgcode = 'Warning'
  else
    msgcode = "Info"
  firstcolon = line.indexOf(':')
  secondcolon = line.indexOf(':', firstcolon + 1)
  lineno = parseInt(line.substring(firstcolon + 1, secondcolon), 10) - 1
  msgrange = [[lineno, 0],[lineno, 1]]
  msgtext = line.substring(codeindex + 2)
  return lintEntry =
    type: msgcode,
    text: msgtext,
    range:msgrange,
    filePath: filepath

# Creates a promise to lint file.
lintFile = (filePath) ->
  # The executor function returns quickly, the resolve method is captured in
  #  in the ansyc buffered process exit function.
  lintExecutor = (resolve, reject) ->
    ret = []
    filedir = path.dirname filePath
    lamapath = 'pylama'
    proc = new BufferedProcess(
      command: lamapath
      args: [filePath]
      options:
        cwd: filedir
      stdout: (data) ->
        ret.push(data)
      exit: (code) ->
        lintdata = ret.join('')
        lintlines = lintdata.split('\n')
        results = []
        infos = 0
        warnings = 0
        errors = 0
        for line in lintlines
          res = processline line, filePath
          if typeof res isnt 'undefined'
            results.push res
            switch res.type
              when 'Error' then errors++
              when 'Warning' then warnings++
              when 'Info' then infos++
        # changeEwi and update are separate because the pane may have changed.
        changeEwi(filePath, errors, warnings, infos)
        update()
        resolve(results)
    )
  return new Promise (lintExecutor)

# Linter API function.
# Provides a the config and a function for performing the linting.
provideLinter = ->
  provider =
    # Short name saves screen space.
    name: 'P',
    grammarScopes: ['source.python'],
    scope: 'file',
    lintOnFly: false,
    lint: (textEditor) ->
      filePath = textEditor.getPath()
      addEditorPath filePath
      console.log('Linting:' + filePath) # For debug.
      lintFile filePath

# Status bar API function
consumeStatusBar = (statusBar) ->
  status.bar = statusBar.addLeftTile(item: status.ele, priority: 100)

# Rant:
# CoffeeScript lacks function declarations so we can't enjoy function hoisting.

# Export essential functions.
module.exports.activate = activate
module.exports.deactivate = deactivate
module.exports.provideLinter = provideLinter
module.exports.consumeStatusBar = consumeStatusBar

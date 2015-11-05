PythonLamaLintView = require './python-lama-lint-view'
{CompositeDisposable} = require 'atom'

module.exports = PythonLamaLint =
  pythonLamaLintView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @pythonLamaLintView = new PythonLamaLintView(state.pythonLamaLintViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @pythonLamaLintView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'python-lama-lint:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @pythonLamaLintView.destroy()

  serialize: ->
    pythonLamaLintViewState: @pythonLamaLintView.serialize()

  toggle: ->
    console.log 'PythonLamaLint was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

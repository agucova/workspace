[
  # Toggle terminal
  {
    key     = "ctrl+`";
    command = "workbench.action.terminal.toggleTerminal";
    when    = "terminal.active";
  }
  {
    key     = "ctrl+`";
    command = "workbench.action.terminal.toggleTerminal";
  }

  # Send Ctrl-C inside terminal
  {
    key     = "ctrl+c";
    command = "workbench.action.terminal.sendSequence";
    when    = "terminalFocus";
    args    = { text = "\\u0003"; };
  }
  {
    key     = "ctrl+v";
    command = "workbench.action.terminal.paste";
    when    = "terminalFocus";
  }

  # mac-style word navigation
  {
    key     = "alt+left";
    command = "workbench.action.terminal.sendSequence";
    when    = "terminalFocus";
    args    = { text = "\\u001b[1;5D"; };
  }
  {
    key     = "alt+right";
    command = "workbench.action.terminal.sendSequence";
    when    = "terminalFocus";
    args    = { text = "\\u001b[1;5C"; };
  }

  # mac-style delete word
  {
    key     = "alt+backspace";
    command = "deleteWordLeft";
    when    = "textInputFocus && !editorReadonly";
  }
]

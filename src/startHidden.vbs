Dim shell, command, file, scriptDir
scriptdir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
file = " -File """ & scriptdir & "\autoMeteredConnection.ps1"""
command = "powershell.exe -NoLogo -ExecutionPolicy bypass -NonInteractive" & file
'Wscript.Echo command
Set shell = CreateObject("WScript.Shell")
shell.Run command,0
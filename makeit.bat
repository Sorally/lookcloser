@echo off

if exist regme.obj del regme.obj
if exist regme.exe del regme.exe

\MASM32\BIN\Rc.exe /v rsrc.rc
\MASM32\BIN\Cvtres.exe /machine:ix86 rsrc.res

\masm32\bin\ml /c /coff /nologo regme.asm
\masm32\bin\Link /SUBSYSTEM:WINDOWS /MERGE:.rdata=.text regme.obj rsrc.obj > nul

copy regme.exe C:\Users\sora\Desktop\



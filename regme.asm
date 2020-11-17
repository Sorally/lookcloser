; #########################################################################

  .386
  .model flat, stdcall
  option casemap :none   ; case sensitive

; #########################################################################

  include \masm32\include\windows.inc
  include \masm32\include\user32.inc
  include \masm32\include\kernel32.inc
  include \masm32\include\masm32.inc
  include \masm32\include\Shlwapi.inc

  includelib \masm32\lib\Shlwapi.lib
  includelib \masm32\lib\user32.lib
  includelib \masm32\lib\kernel32.lib
  includelib \masm32\lib\masm32.lib

; #########################################################################

  ID_EDIT1   equ 101
  ID_EDIT2   equ 102
  ID_BUTTON1 equ 201

  ;=================
  ; Local prototypes
  ;=================
  WndProc     PROTO :DWORD,:DWORD,:DWORD,:DWORD
  checklic    PROTO
;  hotpatch    PROTO :DWORD
;  hehehe      PROTO



.data
  szDisplayName          db "Reg Me!",0
  hInstance              dd 0
  hEdit1                 dd 0
  hEdit2                 dd 0
  counter                dd 7
  pa                     dd 0
  eml                    db 64 dup (0)
  lic                    db 64 dup (0)
  txt1                   db "Please enter a valid email address.",0
  txt2                   db "Please enter a valid license key.",0
  txt3                   db "Thank you for supporting our software!",0
  txt4                   db "0123456789ABCDEF",0
  user32                 db "user32.dll",0
  SetProcessDPIAware     db "SetProcessDPIAware",0
  dlgname                db "DLGWIN",0
  hndl                   dd 0
  dwWritten              dd 0
  lpflOldProtect         dd 0

.code

start:

; #########################################################################

  invoke GetModuleHandle, NULL
  mov hInstance, eax

  invoke LoadLibrary,offset user32
  push eax
  invoke GetProcAddress, eax, offset SetProcessDPIAware
  call eax
  pop eax
  invoke FreeLibrary,eax

  ; -------------------------------------------
  ; Call the dialog box stored in resource file
  ; -------------------------------------------
  invoke DialogBoxParam,hInstance,ADDR dlgname,0,ADDR WndProc,0
  
  invoke ExitProcess,eax

; #########################################################################

WndProc proc hWin :DWORD, uMsg :DWORD, wParam :DWORD, lParam :DWORD

      .if uMsg == WM_INITDIALOG
        invoke SendMessage,hWin,WM_SETTEXT,0,ADDR szDisplayName
        ;invoke hotpatch, addr szDisplayName
        jmp hotpatch
        invoke GetDlgItem,hWin,ID_EDIT1
        mov hEdit1, eax
        invoke GetDlgItem, hWin, ID_EDIT2
        mov hEdit2, eax
      .elseif uMsg == WM_CLOSE
        invoke EndDialog,hWin,0
      .elseif uMsg == WM_COMMAND
        .if wParam == ID_BUTTON1
            invoke checklic
        .endif
      .endif

    xor eax, eax
    ret

WndProc endp

; #########################################################################
checklic proc


  local len1:byte
  local len2:byte
  
  invoke SendMessage, hEdit1, WM_GETTEXT, 64, addr eml
  mov len1, al
  invoke SendMessage, hEdit2, WM_GETTEXT, 64, addr lic
  mov len2, al

  cmp len1, 5
  jb bademail
  cmp len2, 8
  jne badserial

  ; search for '@' char
  lea eax, eml
  inc eax
  invoke StrRChr, eax, 0, 40h
  cmp eax, 0
  je  bademail

  ; search for '.' char
  inc eax
  invoke StrRChr, eax, 0, 2Eh
  cmp eax, 0
  je  bademail

  mov eax, dword ptr[eml]
  xor eax, 12345678h
  xor ebx, ebx                                          ; 52553719
  xor ecx, ecx
  mov counter, 7
  lea esi, lic
  add esi, counter
looop:
  mov bl, al
  and bl, 0Fh
  mov bl, byte ptr[txt4 + ebx]
  mov cl, byte ptr[esi]
  cmp bl, cl
  jne badserial
  shr eax, 4
  dec esi
  dec counter
  cmp counter, 0
  jge looop

  invoke MessageBox, 0, addr txt3, addr szDisplayName, 0
  ret

bademail:
  invoke MessageBox, 0, addr txt1, addr szDisplayName, 0
  ret

badserial:
  invoke MessageBox, 0, addr txt2, addr szDisplayName, 0
  ret

  
checklic endp

; #########################################################################



hotpatch:
  mov ebx, 401023h
  inc ebx
  mov ebx, dword ptr[ebx]
  mov pa, ebx
  sub ebx, 7
  invoke VirtualProtect, ebx, 7, PAGE_EXECUTE_READWRITE, addr lpflOldProtect
  mov eax, dword ptr[pa]
  mov word ptr[eax], 0f9ebh ; jump 5 bytes back
  sub eax, 5
  mov byte ptr[eax], 0e9h
  mov ebx, blackmagicfuckery
  sub ebx, eax
  sub ebx, 5
  inc eax
  mov dword ptr[eax], ebx
  mov edi, [hotpatch]
  invoke VirtualProtect, edi, 100, PAGE_EXECUTE_READWRITE, addr lpflOldProtect
  xor eax,eax
  mov ecx, 15h
  rep stosd
  mov ebx, 4010a8h
  jmp ebx

blackmagicfuckery:
  cmp counter, 0
  jne checkifbadboy
  cmp byte ptr[lic], 52h
  jne endfuckery
  add dword ptr[esp + 8], 22h ; make into goodboy!
  jmp endfuckery

checkifbadboy:
  cmp counter, -1
  jne endfuckery
  sub dword ptr[esp + 8], 22h ; make into badboy!

endfuckery:
  mov eax, pa
  add eax, 2
  jmp eax

end start


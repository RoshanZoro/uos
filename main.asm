; Target: x64 EFI executable (PE32+ format)
; Assembler: NASM

; -----------------------------------------------------------------------------
; Data Section: Define the string
; -----------------------------------------------------------------------------
section .data
    ; The UEFI Print function expects a UTF-16LE (wide character) string.
    ; Each character is 2 bytes, and the string must be null-terminated.
    msg db 'H', 0, 'e', 0, 'l', 0, 'l', 0, 'o', 0, ',', 0, ' ', 0
    db 'W', 0, 'o', 0, 'r', 0, 'l', 0, 'd', 0, '!', 0, 0, 0
    msg_len equ $ - msg

; -----------------------------------------------------------------------------
; Code Section
; -----------------------------------------------------------------------------
section .text
    ; The standard entry point for an EFI application
    global EfiMain

; EFI Entry Point:
; In x64 calling convention:
; RCX = EFI_HANDLE ImageHandle (This image's handle)
; RDX = EFI_SYSTEM_TABLE* SystemTable (Pointer to the firmware's system table)
EfiMain:
    ; Prologue: Standard function setup (optional for this simple program, but good practice)
    push rbp
    mov rbp, rsp
    
    ; ---------------------------------------------------------------------
    ; 1. Get the pointer to the SimpleTextOutputProtocol (Console Output)
    ; ---------------------------------------------------------------------
    ; The pointer to the ConsoleOut struct is the 7th entry (index 6) in the SystemTable.
    ; Offset of ConsoleOut pointer in EFI_SYSTEM_TABLE is 0x58 (88 decimal).
    ; SystemTable* is in RDX.
    mov rax, [rdx + 0x58] ; RAX = SystemTable->ConsoleOut*

    ; ---------------------------------------------------------------------
    ; 2. Call ConsoleOut->OutputString (the 'Print' function)
    ; ---------------------------------------------------------------------
    ; The OutputString function pointer is the 2nd entry (index 1) in the ConsoleOut VTBL.
    ; Offset of OutputString pointer in SimpleTextOutputProtocol VTBL is 0x8 (8 decimal).
    
    ; Get the ConsoleOut VTBL pointer (first 8 bytes of the ConsoleOut struct)
    mov r8, [rax]          ; R8 = ConsoleOut->VTBL* (Virtual Table)
    
    ; Get the OutputString function pointer
    mov r10, [r8 + 0x8]    ; R10 = ConsoleOut->OutputString function address

    ; Set up the arguments for the OutputString function call (x64 calling convention):
    ; RCX = EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL* (The 'this' pointer, in RAX from step 1)
    ; RDX = CHAR16* String (The string address)
    mov rcx, rax           ; First argument: ConsoleOut struct pointer (from step 1)
    lea rdx, [rel msg]     ; Second argument: Address of our UTF-16 string

    ; Alignment: Stack must be 16-byte aligned before a call.
    sub rsp, 8             ; Adjust stack for alignment (since we only pushed RBP)

    ; Call the print function
    call r10

    ; Clean up stack after alignment
    add rsp, 8

    ; ---------------------------------------------------------------------
    ; 3. Exit the application
    ; ---------------------------------------------------------------------
    ; EFI_SUCCESS is zero. The Exit function is the 5th entry (index 4) in the BootServices VTBL.
    ; We don't need to explicitly call Exit for a simple app, as the firmware returns control to
    ; the shell/boot manager when EfiMain returns, but for completeness:
    
    ; Restore RBP and return (EfiMain should return EFI_STATUS)
    xor eax, eax           ; Set return value to 0 (EFI_SUCCESS)
    mov rsp, rbp
    pop rbp
    ret
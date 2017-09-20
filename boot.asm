	%define BASE 0x7C00
	%define DEST 0x0600
	%define PARTITION_TABLE 0x01AE

	org BASE	
	bits 16				;16-bit real mode

	cli				;clear interrupts

;========== Prepare registers ==========

	xor ax, ax
	mov es, ax
	mov ds, ax

;========== Prepare stack ==========

	mov ax, 0x7E00			;setting stack segment pointer
	mov ss, ax

	mov sp, 0x2000			;setting stack pointer (making 8k stack)

;========== Copy yourself by adress 0000:0600 ==========

	mov si, BASE			;setting eds = 0000:07C0

	mov di, DEST			;setting edi = 0000:0600

	mov cx, 0x0200			;cx = amount of words to copy

	rep movsb				;[DS:SI] => [ES:DI]; SI += 2; DI += 2;


	jmp skip + DEST			;jumping to new position

	skip: equ ($ - $$)		;where we have jumped

;========== Print welcoming strings ==========

	mov ax, first_msg_ID
	call print


;========== Check partition table ==========
	mov si, PARTITION_TABLE
	add si, DEST
	mov bh, 0x80
	mov cl, -1				;cl - number of checked sector


;========== Check if here any active sector ==========
partitions_check:
	cmp cl, 3				;if 4 sectors have checked we finish cycle
	je partition_select

	add si, 0x0010			;0x0010 - distanse between sectors in table			
	inc cl

	mov bl, [es:si]			;take 1-st byte from partition entry
	cmp bl, bh				;check if entry is active

	jne partitions_check		;entry isn't entry
	
	call partitions_process		;entry is active

	jmp partitions_check


;========== Print information about active entry ==========
partitions_process:
	mov ax, boot_part_msg_ID
	call print

	mov di, part_num_ID			;detect number of entry and print
	add [ds:di], cl
	mov ax, part_num_ID
	call print
	sub [ds:di], cl				;return to initial value

	mov di, boot_flags_ID		;put flag that this entry is active
	mov ch, 0
	add di, cx
	mov byte[ds:di], 1

	ret

;========== Let user choose entry ==========
partition_select:
	mov ax, select_part_msg_ID
	call print

choise:	
	mov di, boot_flags_ID
	mov si, PARTITION_TABLE
	add si, DEST

	mov ah, 0
	int 0x16			;get keystroke
					;AH = 00h
					;
					;Return:
					;AH = BIOS scan code
					;AL = ASCII character

p0:					;check if 1st entry have chosen
	cmp al, 48
	jne p1
	add si, 0x0010
	jmp disk

p1:					;check if 2nd entry have chosen
	cmp al, 49
	jne p2
	add si, 0x0020
	jmp disk

p2:					;check if 3rd entry have chosen
	cmp al, 50
	jne p3
	add si, 0x0030
	jmp disk

p3:					;check if 4th entry have chosen
	add si, 0x0040
	cmp al, 51
	je disk

;========== Print that user made wrong entry ==========
wrong_choise:
	mov ax, wrong_input_msg_ID
	call print
	jmp choise

;========== Check that chosen entry is entry and try to load vbr ==========
disk:	
	mov ah, 0
	sub al, 48				;48 = code of '0', so al will have
							;value in range 0..3
	add di, ax
	cmp byte [ds:di], 0		;check if flag is set on
	je wrong_choise			;entry isn't active
	
	mov ah, 41h				;Check Extensions Present
	mov bx, 55AAh			;AH = 41h
	int 0x13				;BX = 55AAh
							;DL = drive (80h-FFh)
							;
							;Return:
							;CF set on error (extensions not supported)
							;AH = 01h (invalid function)
							;CF clear if successful
							;BX = AA55h if installed
							;CX = API subset support bitmap
							;...
	
	jc  ext_not_present_error
	cmp  bx, 0xAA55

	je   read_boot_sect

;========== Print that extensions isn't present ==========
ext_not_present_error:
	mov ax, ext_not_pres_msg_ID
	call print
	int 18h

;========== Read vbr and jump to copied code ==========
read_boot_sect:
	mov ah, 42h
	mov di, DAP_structure_ID
	add di, 8
	add si, 8
	mov ebx, [ds:si]
	mov [ds:di], ebx
	mov si, DAP_structure_ID
	int 13h
	
	jc  ext_not_present_error

	jmp 0x0000:0x7C00

	sti
	hlt

;========== Print string ==========
print:
	push si
	mov si, ax
	mov ah, 0x0E
.loop:
	lodsb
	or al, al
	jz print_end
	int 0x10
	jmp .loop
print_end:
	pop si
	ret



first_msg		db "#### Zem4ik's bootloader #####", 0x0D, 0x0A, 0
boot_part_msg		db 'Find bootable partitions:', 0x0D, 0x0A, 0
select_part_msg 	db 'Select part to boot from (press 0 ... 3)', 0x0D, 0x0A, 0
wrong_input_msg		db 'Wrong choise. Try again', 0x0D, 0x0A, 0
ext_not_pres_msg	db 'Disk read error occured', 0x0D, 0x0A, 0
part_num		db '0', 0x0D, 0x0A, 0
boot_flags		times 4 db 0
DAP_structure		db 0x10, 0x00, 0x01, 0x00, 0x00, 0x7C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

first_msg_ID		equ first_msg - BASE + DEST
boot_part_msg_ID	equ boot_part_msg - BASE + DEST
select_part_msg_ID	equ select_part_msg - BASE + DEST
wrong_input_msg_ID	equ wrong_input_msg - BASE + DEST
ext_not_pres_msg_ID	equ ext_not_pres_msg - BASE + DEST
part_num_ID		equ part_num - BASE + DEST
boot_flags_ID		equ boot_flags - BASE + DEST
DAP_structure_ID	equ DAP_structure - BASE + DEST
	
	times 446 -($-$$) db 0

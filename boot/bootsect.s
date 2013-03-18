	.code16
# rewrite with AT&T syntax by falcon <wuzhangjin@gmail.com> at 081012
#
# SYS_SIZE is the number of clicks (16 bytes) to be loaded.
# 0x3000 is 0x30000 bytes = 196kB, more than enough for current
# versions of linux
#
	.equ SYSSIZE, 0x3000
#
#	bootsect.s		(C) 1991 Linus Torvalds
#
# bootsect.s is loaded at 0x7c00 by the bios-startup routines, and moves
# iself out of the way to address 0x90000, and jumps there.
#
# It then loads 'setup' directly after itself (0x90200), and the system
# at 0x10000, using BIOS interrupts. 
#
# NOTE! currently system is at most 8*65536 bytes long. This should be no
# problem, even in the future. I want to keep it simple. This 512 kB
# kernel size should be enough, especially as this doesn't contain the
# buffer cache as in minix
#
# The loader has been made as simple as possible, and continuos
# read errors will result in a unbreakable loop. Reboot by hand. It
# loads pretty fast by getting whole sectors at a time whenever possible.

	.global _start, begtext, begdata, begbss, endtext, enddata, endbss
	.text
	begtext:
	.data
	begdata:
	.bss
	begbss:
	.text

	.equ SETUPLEN, 4		# nr of setup-sectors
	.equ BOOTSEG, 0x07c0		# original address of boot-sector
	.equ INITSEG, 0x9000		# we move boot here - out of the way
	.equ SETUPSEG, 0x9020		# setup starts here
	.equ SYSSEG, 0x1000		# system loaded at 0x10000 (65536).
	.equ ENDSEG, SYSSEG + SYSSIZE	# where to stop loading

# ROOT_DEV:	0x000 - same type of floppy as boot.
#		0x301 - first partition on first drive etc
	.equ ROOT_DEV, 0x301       # �o��N��nŪ�����Ӹ˸m�A0x301�OŪ��/dev/hda1�A�]�i�H������L�˸m
	ljmp    $BOOTSEG, $_start  # �o��@�ӬOCS(BOOTSEG), �@�ӬOEIP(_start)
_start:
	#���U�ӴN�O��ۤv���ʨ� 0x9000����m�A����n���ʡA�O�]��setup.S�N�Ѽƪ�O�s�쨺�̦ӹw�d�Ŷ�
	mov	$BOOTSEG, %ax          # ��0x07C0 �]�� ds, ��0x9000�]�� es, ���Ucopy ���ɭԡA�|�Ψ췽�a�}���զX�O ds:si, �������ؼЦa�}�� es:di
	mov	%ax, %ds
	mov	$INITSEG, %ax
	mov	%ax, %es
	mov	$256, %cx              # cx register�q�`���ӷ�counter, �]�N�Ofor loop���� i
	sub	%si, %si               # sub �O�Ȧs���۴�A�o�̪��N��P xor %si, %si, �]�N�Osi�۴�A�M��0
	sub	%di, %di
	rep	                       # rep��repeat���O�A�L�|�ھ�CX�ȡA��@repeat������
	movsw                      # movw AT&T �y�k �O���t�ާ@�ƪ��A�q [ds:si]->[es:si], Intel�y�k�n���O movsw, �]�N�Ocopy data�q 0x7C0��0x9000�A�۸���MOVSB�AMOVSW�O�HWORD�����
	ljmp	$INITSEG, $go      # ����  INITSEG:go  �B�A�]�N�O������ۤv����0x9000���~�A�]��ثe����B�A�q0x7Cxx����0x90XX����A����۰��U�h

go:	mov	%cs, %ax               # copy������A��ds, es, ss ���]�� cs ( 0x9000) 
	mov	%ax, %ds
	mov	%ax, %es
# put stack at 0x9ff00.
	mov	%ax, %ss
	mov	$0xFF00, %sp		# arbitrary value >>512

# load the setup-sectors directly after the bootblock.
# Note that 'es' is already set up.
# �ǳ�Ū��sec 2 �X�ӡA����sec 2 �O��m setup.S �� code
# �ϥ�int 13�ɡA��m data���a��O�H ES:BX �ӥN��
load_setup:
	mov	$0x0000, %dx		# drive 0, head 0
	mov	$0x0002, %cx		# sector 2, track 0         # �� sec 2 Ū�X��(chs mode �O�Hsec 1 �@���}�l)
	mov	$0x0200, %bx		# address = 512, in INITSEG # address = ES*0x10 + BX, ES:BX ���V��service�n�s��b��,�Ѧ��i���o��O�n��dataŪ�X�ө��0x90200����m
	.equ    AX, 0x0200+SETUPLEN                         # �o�䪺�Ȭ�0x0204, AH�O0x02�� service (��data���ram), AL ��Ū�X�� sector
	mov     $AX, %ax		# service 2, nr of sectors
	int	$0x13			    # read it                   # INT 13H/AH=02H�GŪ���ϰ�
	jnc	ok_load_setup		# ok - continue
	
	#�Ureset disk cmd ����A�b����̫e���A�ݰ_�ӨS���h���AŪ�즨�\����A�_�h�N�O���`��
	mov	$0x0000, %dx
	mov	$0x0000, %ax		# reset the diskette
	int	$0x13
	jmp	load_setup

ok_load_setup:

# Get disk drive parameters, specifically nr of sectors/track

	mov	$0x00, %dl          # DL= drive No, int 13, AH=8 = get param
	mov	$0x0800, %ax		# AH=8 is get drive parameters
	int	$0x13
	mov	$0x00, %ch
	#seg cs
	mov	%cx, %cs:sectors+0  # %cs means sectors is in %cs , # ��CX�����e(�]�N�Ocy�P sec per track)�s�bcs:sectors+0 ���Asector ���@��m�A�b�̤U�����w�q
	mov	$INITSEG, %ax       # INITSEG���Ȭ�0x9000
	mov	%ax, %es

# Print some inane message
	# �ϥ�int10, AH=3 ��Ū�� cursor��m��A�A�H�ثe��m�g�J,(CX�BDX)�׹ϧΧ��ЦC(X)�B��(Y)
	mov	$0x03, %ah		# read cursor pos
	xor	%bh, %bh        # BH�M��0
	int	$0x10           # AH=03H/INT 10H �A(CX�BDX)�׹ϧΧ��ЦC(X)�B��(Y)
	
	mov	$24, %cx
	mov	$0x0007, %bx		# page 0, attribute 7 (normal)
	#lea	msg1, %bp
	mov     $msg1, %bp      # ES:BP = Offset of string, ���load system..
	mov	$0x1301, %ax		# write string, move cursor  # AH=13:�bTeletype�Ҧ��U��ܦr�Ŧ�, AL�׹�����
	int	$0x10

# ok, we've written the message, now
# we want to load the system (at 0x10000)

	mov	$SYSSEG, %ax    # SYSSEG=0x1000,  system loaded at 0x10000 (65536)64k.
	mov	%ax, %es		# segment of 0x010000
	call	read_it     # read_it �b�U��
	call	kill_motor

# After that we check which root-device to use. If the device is
# defined (#= 0), nothing is done and the given device is used.
# Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
# on the number of sectors that the BIOS reports currently.

	#seg cs
	mov	%cs:root_dev+0, %ax  # root_dev �ϥ�code ���覡 hard code, �w�]�Ȭ� 0x301
	cmp	$0, %ax              # �ˬd�Ӫ��O�_�� 0   
	jne	root_defined         # jne (jump not equal) 	������h�ಾ 	�ˬd zf=0
	#seg cs
	mov	%cs:sectors+0, %bx
	mov	$0x0208, %ax		# /dev/ps0 - 1.2Mb
	cmp	$15, %bx
	je	root_defined
	mov	$0x021c, %ax		# /dev/PS0 - 1.44Mb
	cmp	$18, %bx
	je	root_defined
undef_root:
	jmp undef_root
root_defined:
	#seg cs
	mov	%ax, %cs:root_dev+0

# after that (everyting loaded), we jump to
# the setup-routine loaded directly after
# the bootblock:

	ljmp	$SETUPSEG, $0  # ����0x90200�A����setup.S

# This routine loads the system at address 0x10000, making sure
# no 64kB boundaries are crossed. We try to load it as fast as
# possible, loading whole tracks whenever we can.
#
# in:	es - starting address segment (normally 0x1000)
#
sread:	.word 1+ SETUPLEN	# sectors read of current track
head:	.word 0			# current head
track:	.word 0			# current track

read_it:
	mov	%es, %ax            # es�w�g�Q�]�w�� 0x1000
	test	$0x0fff, %ax    # ���� es �O�_�� 0x1000
die:	jne 	die			# es must be at 64kB boundary
	xor 	%bx, %bx		# bx is starting address within segment
rp_read:
	mov 	%es, %ax
 	cmp 	$ENDSEG, %ax	# have we loaded all yet? # sys_start = 0x1000, sts_end = 0x3000 �A�ҥH�j�p��100��sector?
	jb	ok1_read
	ret
ok1_read:
	#seg cs
	mov	%cs:sectors+0, %ax   # Ū�����e�� secPerTrack
	sub	sread, %ax           # sread = sread - ax 
	mov	%ax, %cx
	shl	$9, %cx
	add	%bx, %cx
	jnc 	ok2_read
	je 	ok2_read
	xor 	%ax, %ax
	sub 	%bx, %ax
	shr 	$9, %ax
ok2_read:
	call 	read_track
	mov 	%ax, %cx
	add 	sread, %ax
	#seg cs
	cmp 	%cs:sectors+0, %ax
	jne 	ok3_read
	mov 	$1, %ax
	sub 	head, %ax
	jne 	ok4_read
	incw    track 
ok4_read:
	mov	%ax, head
	xor	%ax, %ax
ok3_read:
	mov	%ax, sread
	shl	$9, %cx
	add	%cx, %bx
	jnc	rp_read
	mov	%es, %ax
	add	$0x1000, %ax
	mov	%ax, %es
	xor	%bx, %bx
	jmp	rp_read

read_track:
	push	%ax
	push	%bx
	push	%cx
	push	%dx
	mov	track, %dx
	mov	sread, %cx
	inc	%cx
	mov	%dl, %ch
	mov	head, %dx
	mov	%dl, %dh
	mov	$0, %dl
	and	$0x0100, %dx
	mov	$2, %ah
	int	$0x13
	jc	bad_rt
	pop	%dx
	pop	%cx
	pop	%bx
	pop	%ax
	ret
bad_rt:	mov	$0, %ax
	mov	$0, %dx
	int	$0x13
	pop	%dx
	pop	%cx
	pop	%bx
	pop	%ax
	jmp	read_track

#/*
# * This procedure turns off the floppy drive motor, so
# * that we enter the kernel in a known state, and
# * don't have to worry about it later.
# */
kill_motor:
	push	%dx
	mov	$0x3f2, %dx
	mov	$0, %al
	outsb
	pop	%dx
	ret

sectors:
	.word 0

msg1:
	.byte 13,10
	.ascii "Loading system ..."
	.byte 13,10,13,10

	.org 508
root_dev:
	.word ROOT_DEV
boot_flag:
	.word 0xAA55
	
	.text
	endtext:
	.data
	enddata:
	.bss
	endbss:

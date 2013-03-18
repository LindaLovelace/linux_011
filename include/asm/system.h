#define move_to_user_mode() \
__asm__ ("movl %%esp,%%eax\n\t" \
	"pushl $0x17\n\t" \
	"pushl %%eax\n\t" \
	"pushfl\n\t" \
	"pushl $0x0f\n\t" \
	"pushl $1f\n\t" \
	"iret\n" \
	"1:\tmovl $0x17,%%eax\n\t" \
	"movw %%ax,%%ds\n\t" \
	"movw %%ax,%%es\n\t" \
	"movw %%ax,%%fs\n\t" \
	"movw %%ax,%%gs" \
	:::"ax")

#define sti() __asm__ ("sti"::)
#define cli() __asm__ ("cli"::)
#define nop() __asm__ ("nop"::)

#define iret() __asm__ ("iret"::)

/* �Ҧ��� set_xx_gate���O�H�o�Ӭ���¦, �ӳo�ؼg�k�OGCC���OASM���g�k,�ѥ����k��
  _set_gate�Ω�]�m���_�V�q��A�Y�Ninterrupt[]�Midt_table�pô�b�@�_
  gate_addr�b����m�]�m���y�z��(�Oidt�����쪺�s����ramaddr)
  type ���y�z������(14,15)
  dpl�S�v�ūH��(�YDPTR����DPL)(0~3)
  addr���_�β��`�B�z�L�{�a�}
  ���N%%dx���C16�첾�J%%ax���C16��(�`�N%%dx�P%%edx���ϧO�^//���N%%dx���C16�첾�J%%ax���C16��(�`�N%%dx�P%%edx���ϧO�^
  ���ۧ�Ĥ@�ӿ�J�ߧY��(0x8000+(dpl<<13)+(type<<8)�ˤJ%%edx(�]�N�O%dx)���C16��C( type��0x100,0x200 ~ 0xE00, 0xF00)
   �M��A�Q��move long,��ax�Pdx���O����gateaddr�Pgateaddr+4 */

/* "i" �ߧY��, "o" �ާ@�Ƭ����s�ܶq�A���O��M�}�覡�O�����q�����A */
/* �H�Ud����,�]��param 0,1,2�O�]�t�basm code�̭�,�ҥH�u���n��input���O d �P a�A�]�N�O�� addr���edx, ��0x00080000���eax */
#define _set_gate(gate_addr,type,dpl,addr) \
__asm__ ("movw %%dx,%%ax\n\t" \
	"movw %0,%%dx\n\t" \
	"movl %%eax,%1\n\t" \
	"movl %%edx,%2" \
	: \
	: "i" ((short) (0x8000+(dpl<<13)+(type<<8))), \
	"o" (*((char *) (gate_addr))), \
	"o" (*(4+(char *) (gate_addr))), \
	"d" ((char *) (addr)),"a" (0x00080000))

/*
 * �p0�����_��asm�p�U�A�|���]input(0x52f~541)�A�A�Ӱ���asm(0x546~54f)
	set_trap_gate(0,&divide_error);
 52f:	b9 00 00 00 00       	mov    $0x0,%ecx       // ecx�ΨӦs��gate_addr
 534:	b8 00 00 00 00       	mov    $0x0,%eax
 539:	8d 58 04             	lea    0x4(%eax),%ebx  // ebx�ΨӦs��gate_addr+4
 53c:	ba 00 00 00 00       	mov    $0x0,%edx       // ��addr ���edx
 541:	b8 00 00 08 00       	mov    $0x80000,%eax   // �o�ӴN�O "a"(0x80000)
 //====================== �H�U������ ================================
 546:	66 89 d0             	mov    %dx,%ax
 549:	66 ba 00 8f          	mov    $0x8F00,%dx  // �p�G�Oset_trap_gate�A�ѩ�type=15(0x0f), dpl=0�A�ҥH��X�ӬO0x8f00
 54d:	89 01                	mov    %eax,(%ecx)  // ��eax���ȡA����gate_addr(�Yidt table)���O�����m
 54f:	89 13                	mov    %edx,(%ebx)
*/

#define set_intr_gate(n,addr) \
	_set_gate(&idt[n],14,0,addr) /* �ھڽs��,��idt�����쪺�s����ram addr�ǵ�set_gate */

#define set_trap_gate(n,addr) \
	_set_gate(&idt[n],15,0,addr)

#define set_system_gate(n,addr) \
	_set_gate(&idt[n],15,3,addr)

#define _set_seg_desc(gate_addr,type,dpl,base,limit) {\
	*(gate_addr) = ((base) & 0xff000000) | \
		(((base) & 0x00ff0000)>>16) | \
		((limit) & 0xf0000) | \
		((dpl)<<13) | \
		(0x00408000) | \
		((type)<<8); \
	*((gate_addr)+1) = (((base) & 0x0000ffff)<<16) | \
		((limit) & 0x0ffff); }

#define _set_tssldt_desc(n,addr,type) \
__asm__ ("movw $104,%1\n\t" \
	"movw %%ax,%2\n\t" \
	"rorl $16,%%eax\n\t" \
	"movb %%al,%3\n\t" \
	"movb $" type ",%4\n\t" \
	"movb $0x00,%5\n\t" \
	"movb %%ah,%6\n\t" \
	"rorl $16,%%eax" \
	::"a" (addr), "m" (*(n)), "m" (*(n+2)), "m" (*(n+4)), \
	 "m" (*(n+5)), "m" (*(n+6)), "m" (*(n+7)) \
	)

#define set_tss_desc(n,addr) _set_tssldt_desc(((char *) (n)),((int)(addr)),"0x89")
#define set_ldt_desc(n,addr) _set_tssldt_desc(((char *) (n)),((int)(addr)),"0x82")


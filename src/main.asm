.data
    title: .asciiz "\n= MIPS VENDING MACHINE =\n"
    menu: .asciiz "\nEscolha um produto:\n1 - Agua\n2 - Refrigerante\n3 - Suco\n4 - Chocolate\n5 - Salgadinho\n0 - Sair\nOpcao: "
    selected: .asciiz "\nProduto selecionado!\n"
    invalid: .asciiz "\nOpcao invalida. Tente novamente.\n"
    goodbye: .asciiz "\nObrigado por utilizar a maquina!\n"
    sem_estoque: .asciiz "\nProduto esgotado!\n"
    
    # Vetor de estoque: 5 produtos, inicializados com 3 unidades cada
    estoque: .word 3, 3, 3, 3, 3 

.text
.globl main

main:
    jal show_menu

    li $v0, 5
    syscall

    move $a0, $v0

    jal handle_choice

    beq $v0, $zero, exit_program

    j main

show_menu:
    li $v0, 4
    la $a0, title
    syscall

    li $v0, 4
    la $a0, menu
    syscall

    jr $ra

handle_choice:
    beq $a0, $zero, choice_exit

    # Verifica se a opcao e valida (1 a 5)
    blt $a0, 1, choice_invalid
    bgt $a0, 5, choice_invalid

    # Calcula o endereco do produto no vetor: (opcao - 1) * 4
    sub $t0, $a0, 1
    mul $t0, $t0, 4
    la $t1, estoque
    add $t1, $t1, $t0       # $t1 = endereco de estoque[opcao - 1]
    
    lw $t2, 0($t1)          # Carrega a quantidade em estoque
    beq $t2, $zero, choice_empty # Se for 0, vai para sem estoque

    # Decrementa o estoque e salva de volta no vetor
    sub $t2, $t2, 1
    sw $t2, 0($t1)

    li $v0, 4
    la $a0, selected
    syscall

    li $v0, 1
    jr $ra

choice_empty:
    li $v0, 4
    la $a0, sem_estoque
    syscall

    li $v0, 1
    jr $ra

choice_invalid:
    li $v0, 4
    la $a0, invalid
    syscall

    li $v0, 1
    jr $ra

choice_exit:
    li $v0, 4
    la $a0, goodbye
    syscall

    move $v0, $zero
    jr $ra

exit_program:
    li $v0, 10
    syscall

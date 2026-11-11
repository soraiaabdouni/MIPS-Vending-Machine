.data
    title: .asciiz "\n= MIPS VENDING MACHINE =\n"
    menu: .asciiz "\nEscolha um produto:\n1 - Agua\n2 - Refrigerante\n3 - Suco\n4 - Chocolate\n5 - Salgadinho\n0 - Sair\nOpcao: "
    selected: .asciiz "\nProduto selecionado!\n"
    invalid: .asciiz "\nOpcao invalida. Tente novamente.\n"
    goodbye: .asciiz "\nObrigado por utilizar a maquina!\n"

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

    blt $a0, 1, choice_invalid
    bgt $a0, 5, choice_invalid

    li $v0, 4
    la $a0, selected
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

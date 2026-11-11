# =============================================================================
# SmartVend MIPS - Maquina de vendas em Assembly MIPS (MARS)
# Arquivo principal: src/main.asm
#
# Convencoes usadas em todos os procedimentos:
#   - Argumentos em $a0-$a3, retorno em $v0.
#   - $t0-$t9 sao temporarios: podem ser destruidos por qualquer chamada.
#   - $s0-$s7 sao preservados: quem usa um $s salva o valor antigo na pilha
#     e restaura antes de retornar.
#   - Procedimentos que chamam outros procedimentos (nao-folha) salvam $ra
#     na pilha, porque o jal interno sobrescreve o endereco de retorno.
# =============================================================================

.eqv NUM_PRODUTOS 5

.data
    title:       .asciiz "\n= MIPS VENDING MACHINE =\n"
    menu:        .asciiz "\nEscolha um produto:\n1 - Agua\n2 - Refrigerante\n3 - Suco\n4 - Chocolate\n5 - Salgadinho\n0 - Sair\nOpcao: "
    selected:    .asciiz "\nProduto selecionado!\n"
    invalid:     .asciiz "\nOpcao invalida. Tente novamente.\n"
    goodbye:     .asciiz "\nObrigado por utilizar a maquina!\n"
    sem_estoque: .asciiz "\nProduto esgotado!\n"

    .align 2
    # Vetor de estoque: 5 produtos, inicializados com 3 unidades cada
    # Endereco do elemento i: estoque + i * 4  (cada .word ocupa 4 bytes)
    estoque: .word 3, 3, 3, 3, 3

.text
.globl main

# -----------------------------------------------------------------------------
# main - laco principal: mostra o menu, le a opcao e a processa.
#        Encerra quando handle_choice retorna 0.
# -----------------------------------------------------------------------------
main:
    jal  show_menu

    li   $v0, 5                 # le inteiro (opcao do usuario)
    syscall

    move $a0, $v0               # a0 = opcao
    jal  handle_choice

    beq  $v0, $zero, exit_program   # v0 == 0 -> usuario pediu para sair
    j    main

exit_program:
    li   $v0, 10                # encerra o programa
    syscall

# -----------------------------------------------------------------------------
# show_menu - imprime o titulo e o menu de produtos.
# Argumentos: nenhum
# Retorno:    nenhum
# Pilha:      nao usa (procedimento folha)
# -----------------------------------------------------------------------------
show_menu:
    li   $v0, 4
    la   $a0, title
    syscall

    li   $v0, 4
    la   $a0, menu
    syscall

    jr   $ra

# -----------------------------------------------------------------------------
# handle_choice - valida a opcao, verifica o estoque e registra a escolha.
# Argumentos: $a0 = opcao digitada (0 = sair, 1..NUM_PRODUTOS = produto)
# Retorno:    $v0 = 0 para encerrar o programa, 1 para continuar
# Pilha:      nao usa (procedimento folha, so usa temporarios)
# -----------------------------------------------------------------------------
handle_choice:
    beq  $a0, $zero, choice_exit

    # opcao valida apenas entre 1 e NUM_PRODUTOS
    blt  $a0, 1, choice_invalid
    bgt  $a0, NUM_PRODUTOS, choice_invalid

    addi $t0, $a0, -1           # t0 = indice = opcao - 1
    sll  $t0, $t0, 2            # t0 = indice * 4 (deslocamento em bytes)
    la   $t1, estoque
    add  $t1, $t1, $t0          # t1 = &estoque[indice]
    lw   $t2, 0($t1)            # t2 = quantidade em estoque
    beq  $t2, $zero, choice_empty   # estoque zerado -> esgotado

    addi $t2, $t2, -1           # decrementa e grava de volta no vetor
    sw   $t2, 0($t1)

    li   $v0, 4
    la   $a0, selected
    syscall
    li   $v0, 1
    j    choice_return

choice_empty:
    li   $v0, 4
    la   $a0, sem_estoque
    syscall
    li   $v0, 1
    j    choice_return

choice_invalid:
    li   $v0, 4
    la   $a0, invalid
    syscall
    li   $v0, 1
    j    choice_return

choice_exit:
    li   $v0, 4
    la   $a0, goodbye
    syscall
    move $v0, $zero

choice_return:
    jr   $ra

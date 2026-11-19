# Bandejao Express - Maquina de vendas em Assembly MIPS (MARS)
# Arquivo principal: src/main.asm
#
# Registradores utilizados:
#   $a0-$a1 = argumentos para procedimentos
#   $v0     = codigo de syscall ou numero retornado pelo procedimento
#   $v1     = saldo atualizado retornado por handle_choice
#   $t0-$t9 = temporarios
#   $s0     = saldo de tickets do usuario
#   $ra     = endereco de retorno dos procedimentos

.eqv NUM_PRODUTOS 5

.data
    # Mensagens exibidas durante a execucao do programa.
    titulo:          .asciiz "\n===== BANDEJAO EXPRESS =====\n"
    prompt_tickets:  .asciiz "\nQuantos tickets do RU voce possui? "
    menu:            .asciiz "\n1 - Suco Sabor 'Cor' - 1 ticket\n2 - Salgado de Estufa de Ontem - 3 tickets\n3 - Bife de Sola de Sapato - 5 tickets\n4 - Salada com 'Proteina Extra' Surpresa - 2 tickets\n5 - Frango Desossado - 10 tickets (ESGOTADO)\n0 - Sair\nOpcao: "

    opcao_invalida:  .asciiz "\nCodigo nao existe no cardapio!\n"
    sem_estoque:     .asciiz "\nAcabou as 11h02! Este item esta esgotado.\n"
    sem_tickets:     .asciiz "\nSem tickets, va pedir emprestado!\n"

    entrega1:        .asciiz "\nEntregue: Suco Sabor 'Cor'. Parece suco, pelo menos!\n"
    entrega2:        .asciiz "\nEntregue: Salgado de Estufa de Ontem. Crocante onde der!\n"
    entrega3:        .asciiz "\nEntregue: Bife de Sola de Sapato. Mango na nota do cardapio!\n"
    entrega4:        .asciiz "\nEntregue: Salada com 'Proteina Extra' Surpresa. Boa sorte!\n"
    entrega5:        .asciiz "\nEntregue: Frango Desossado. Ate acharam as sementes!\n"

    troco_final:     .asciiz "\nTroco final: "
    unidade_troco:   .asciiz " balas de canela\n"
    saldo_atual:     .asciiz "\nTickets restantes: "
    obrigado:        .asciiz "\nObrigado por comer no Bandejao Express!\n"

    .align 2
    # Catálogo: as posições correspondem aos códigos 1 a 5.
    preco:   .word 1, 3, 5, 2, 10
    estoque: .word 5, 3, 2, 4, 0

.text
.globl main

# main:
#   $s0 = saldo de tickets
#   $a0 = opcao digitada
#   $v1 = novo saldo devolvido por handle_choice
main:
    # Apresenta a máquina e recebe os tickets iniciais.
    li   $v0, 4
    la   $a0, titulo
    syscall

    li   $v0, 4
    la   $a0, prompt_tickets
    syscall

    li   $v0, 5                 # ler quantidade inicial de tickets
    syscall
    move $s0, $v0               # s0 = saldo inicial

main_loop:
    # Repete o menu até o usuário digitar 0.
    li   $v0, 4
    la   $a0, menu
    syscall

    li   $v0, 5                 # ler codigo do item
    syscall
    move $a0, $v0               # a0 = opcao
    move $a1, $s0               # a1 = saldo atual
    jal  handle_choice

    move $s0, $v1               # atualizar saldo
    beq  $v0, $zero, exit_program

    li   $v0, 4
    la   $a0, saldo_atual
    syscall
    li   $v0, 1
    move $a0, $s0
    syscall

    j    main_loop

# handle_choice:
#   $a0 = opcao digitada (1..5 ou 0)
#   $a1 = saldo atual
#   $v0 = 0 para sair, 1 para continuar
#   $v1 = saldo atualizado
handle_choice:
    # Primeiro verifica a opção digitada pelo usuário.
    beq  $a0, $zero, choice_exit

    blt  $a0, 1, choice_invalid
    bgt  $a0, NUM_PRODUTOS, choice_invalid

    # Localiza o preço e o estoque usando o índice do produto.
    addi $t0, $a0, -1           # t0 = indice = opcao - 1
    sll  $t0, $t0, 2            # t0 = deslocamento em bytes

    la   $t1, estoque
    add  $t1, $t1, $t0          # t1 = endereco do estoque do item
    lw   $t2, 0($t1)            # t2 = estoque atual
    blez $t2, choice_empty

    la   $t3, preco
    add  $t3, $t3, $t0          # t3 = endereco do preco do item
    lw   $t4, 0($t3)            # t4 = preco em tickets

    # Impede a compra quando o saldo não cobre o preço.
    blt  $a1, $t4, choice_no_tickets

    # Compra realizada: desconta tickets e atualiza o estoque.
    sub  $v1, $a1, $t4          # descontar tickets
    addi $t2, $t2, -1           # decrementar estoque
    sw   $t2, 0($t1)

    beq  $a0, 1, delivery1
    beq  $a0, 2, delivery2
    beq  $a0, 3, delivery3
    beq  $a0, 4, delivery4
    j    delivery5

delivery1:
    li   $v0, 4
    la   $a0, entrega1
    syscall
    li   $v0, 1
    j    choice_continue

delivery2:
    li   $v0, 4
    la   $a0, entrega2
    syscall
    li   $v0, 1
    j    choice_continue

delivery3:
    li   $v0, 4
    la   $a0, entrega3
    syscall
    li   $v0, 1
    j    choice_continue

delivery4:
    li   $v0, 4
    la   $a0, entrega4
    syscall
    li   $v0, 1
    j    choice_continue

delivery5:
    li   $v0, 4
    la   $a0, entrega5
    syscall
    li   $v0, 1
    j    choice_continue

choice_empty:
    li   $v0, 4
    la   $a0, sem_estoque
    syscall
    move $v1, $a1
    li   $v0, 1
    jr   $ra

choice_no_tickets:
    li   $v0, 4
    la   $a0, sem_tickets
    syscall
    move $v1, $a1
    li   $v0, 1
    jr   $ra

choice_invalid:
    li   $v0, 4
    la   $a0, opcao_invalida
    syscall
    move $v1, $a1
    li   $v0, 1
    jr   $ra

choice_continue:
    li   $v0, 1
    jr   $ra

choice_exit:
    move $v1, $a1
    li   $v0, 0
    jr   $ra

exit_program:
    li   $v0, 4
    la   $a0, troco_final
    syscall

    li   $v0, 1
    move $a0, $s0
    syscall

    li   $v0, 4
    la   $a0, unidade_troco
    syscall

    li   $v0, 4
    la   $a0, obrigado
    syscall

    li   $v0, 10                # encerrar programa
    syscall

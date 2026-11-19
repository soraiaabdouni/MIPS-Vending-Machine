# =============================================================================
# Bandejao Express - Maquina de vendas em Assembly MIPS (MARS)
# Arquivo principal: src/main.asm
#
# Como funciona:
#   1. O usuario informa quantos tickets do RU possui (saldo).
#   2. O menu e montado a partir dos vetores (nome, preco e estoque).
#   3. A cada compra, o saldo e o estoque diminuem.
#   4. Ao digitar 0, o programa mostra o troco e encerra.
#
# Registradores:
#   $a0-$a1 = argumentos enviados aos procedimentos
#   $v0     = codigo da syscall / valor de retorno principal
#   $v1     = segundo valor de retorno (novo saldo, em handle_choice)
#   $t0-$t9 = temporarios (podem ser apagados por qualquer chamada)
#   $s0     = saldo de tickets do usuario (vive durante todo o programa)
#   $s1     = novo saldo dentro de handle_choice (salvo na pilha)
#   $ra     = endereco de retorno (para onde voltar apos um jal)
#   $sp     = topo da pilha
#
# Procedimentos: read_int, show_menu, handle_choice, deliver
# =============================================================================

.eqv NUM_PRODUTOS 5

.data
    # ---------------- Mensagens fixas ----------------
    titulo:          .asciiz "\n===== BANDEJAO EXPRESS =====\n"
    prompt_tickets:  .asciiz "\nQuantos tickets do RU voce possui? "
    tickets_invalid: .asciiz "\nDigite um numero inteiro, 0 ou maior!\n"
    cardapio:        .asciiz "\n---------- CARDAPIO ----------\n"
    sep_traco:       .asciiz " - "
    txt_ticket:      .asciiz " ticket"
    txt_plural:      .asciiz "s"
    txt_restam:      .asciiz " (restam "
    txt_fecha:       .asciiz ")\n"
    txt_esgotado:    .asciiz " (ESGOTADO)\n"
    rodape:          .asciiz "0 - Sair\nOpcao: "

    opcao_invalida:  .asciiz "\nCodigo nao existe no cardapio!\n"
    sem_estoque:     .asciiz "\nAcabou as 11h02! Este item esta esgotado.\n"
    sem_tickets:     .asciiz "\nSem tickets, va pedir emprestado!\n"

    troco_final:     .asciiz "\nTroco final: "
    unidade_troco:   .asciiz " balas de canela\n"
    saldo_atual:     .asciiz "Tickets restantes: "
    obrigado:        .asciiz "\nObrigado por comer no Bandejao Express!\n"

    # ---------------- Nomes dos produtos ----------------
    nome1: .asciiz "Suco Sabor 'Cor'"
    nome2: .asciiz "Salgado de Estufa de Ontem"
    nome3: .asciiz "Bife de Sola de Sapato"
    nome4: .asciiz "Salada com 'Proteina Extra' Surpresa"
    nome5: .asciiz "Frango Desossado"

    # ---------------- Mensagens de entrega ----------------
    entrega1: .asciiz "\nEntregue: Suco Sabor 'Cor'. Parece suco, pelo menos!\n"
    entrega2: .asciiz "\nEntregue: Salgado de Estufa de Ontem. Crocante onde der!\n"
    entrega3: .asciiz "\nEntregue: Bife de Sola de Sapato. Mango na nota do cardapio!\n"
    entrega4: .asciiz "\nEntregue: Salada com 'Proteina Extra' Surpresa. Boa sorte!\n"
    entrega5: .asciiz "\nEntregue: Frango Desossado. Ate acharam as sementes!\n"

    # Espaco para guardar o texto digitado pelo usuario (read_int)
    buffer: .space 16

    # ---------------- Vetores do catalogo ----------------
    # Todos os vetores tem 5 posicoes e usam o mesmo indice:
    #   indice 0 = produto 1, indice 1 = produto 2, ... indice 4 = produto 5
    # Cada .word ocupa 4 bytes, entao o elemento i fica em: base + i * 4
    .align 2
    nomes:    .word nome1, nome2, nome3, nome4, nome5            # enderecos dos nomes
    entregas: .word entrega1, entrega2, entrega3, entrega4, entrega5  # enderecos das mensagens
    preco:    .word 1, 3, 5, 2, 10     # preco de cada item, em tickets
    estoque:  .word 5, 3, 2, 4, 1      # unidades disponiveis (Frango: so 1!)

.text
.globl main

# =============================================================================
# main - ponto de partida do programa.
#   Le o saldo inicial, depois repete: mostra menu -> le opcao -> processa.
#   O saldo fica em $s0 durante todo o programa.
# =============================================================================
main:
    li   $v0, 4
    la   $a0, titulo
    syscall

# Pede o saldo ate o usuario digitar um numero valido (0 ou maior)
ask_tickets:
    li   $v0, 4
    la   $a0, prompt_tickets
    syscall

    jal  read_int               # v0 = numero digitado, ou -1 se invalido
    bgez $v0, tickets_ok        # numero >= 0 -> aceito

    li   $v0, 4                 # caso contrario, avisa e pergunta de novo
    la   $a0, tickets_invalid
    syscall
    j    ask_tickets

tickets_ok:
    move $s0, $v0               # s0 = saldo inicial

main_loop:
    jal  show_menu              # monta o cardapio a partir dos vetores

    jal  read_int               # v0 = opcao digitada (-1 se invalida)
    move $a0, $v0               # a0 = opcao      (1o argumento)
    move $a1, $s0               # a1 = saldo atual (2o argumento)
    jal  handle_choice          # retorna v0 = continuar? e v1 = novo saldo

    move $s0, $v1               # guarda o novo saldo
    beq  $v0, $zero, exit_program   # v0 = 0 -> usuario escolheu sair

    # Mostra o saldo apos cada operacao
    li   $v0, 4
    la   $a0, saldo_atual
    syscall
    li   $v0, 1
    move $a0, $s0
    syscall

    j    main_loop

# Encerramento: o que sobrou de tickets vira "troco"
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

    li   $v0, 10                # encerra o programa
    syscall

# =============================================================================
# read_int - le uma linha de texto e converte para numero inteiro.
#   Usamos texto (syscall 8) em vez de syscall 5 porque a syscall 5 trava
#   o MARS se o usuario digitar letras.
# Argumentos: nenhum
# Retorno:    $v0 = numero lido (>= 0), ou -1 se tiver letra, sinal ou vazio
# Pilha:      nao usa (procedimento folha: nao chama ninguem)
# =============================================================================
read_int:
    li   $v0, 8                 # syscall 8 = ler string
    la   $a0, buffer            # onde guardar o texto
    li   $a1, 16                # tamanho maximo
    syscall

    la   $t0, buffer            # t0 = ponteiro para o caractere atual
    li   $t1, 0                 # t1 = numero sendo montado
    li   $t2, 0                 # t2 = quantos digitos ja lemos

ri_loop:
    lb   $t3, 0($t0)            # t3 = caractere atual (1 byte)
    beq  $t3, 10, ri_end        # '\n' (Enter) -> fim do numero
    beq  $t3, $zero, ri_end     # fim da string -> fim do numero

    blt  $t3, '0', ri_invalid   # nao e digito -> invalido
    bgt  $t3, '9', ri_invalid

    addi $t3, $t3, -48          # converte caractere em valor ('7' -> 7)
    mul  $t1, $t1, 10           # numero = numero * 10 + digito
    add  $t1, $t1, $t3

    addi $t2, $t2, 1
    bgt  $t2, 6, ri_invalid     # mais de 6 digitos -> invalido (evita estouro)
    addi $t0, $t0, 1            # avanca para o proximo caractere
    j    ri_loop

ri_end:
    beq  $t2, $zero, ri_invalid # nenhum digito (so Enter) -> invalido
    move $v0, $t1
    jr   $ra

ri_invalid:
    li   $v0, -1
    jr   $ra

# =============================================================================
# show_menu - imprime o cardapio percorrendo os vetores nomes, preco e estoque.
#   Como o menu le os vetores toda vez, preco e estoque aparecem sempre
#   atualizados (e "ESGOTADO" surge sozinho quando o estoque chega a 0).
# Argumentos: nenhum
# Retorno:    nenhum
# Pilha:      nao usa (procedimento folha: so faz syscalls)
# =============================================================================
show_menu:
    li   $v0, 4
    la   $a0, cardapio
    syscall

    li   $t0, 0                 # t0 = i (indice do produto), comeca em 0

sm_loop:
    bge  $t0, NUM_PRODUTOS, sm_end   # percorreu os 5 produtos -> sai do laco
    sll  $t1, $t0, 2            # t1 = i * 4 (deslocamento em bytes)

    # "N - "  (numero da opcao = i + 1)
    li   $v0, 1
    addi $a0, $t0, 1
    syscall
    li   $v0, 4
    la   $a0, sep_traco
    syscall

    # nome: nomes[i] guarda um endereco; a syscall 4 imprime o texto dele
    lw   $a0, nomes($t1)
    li   $v0, 4
    syscall
    li   $v0, 4
    la   $a0, sep_traco
    syscall

    # preco: "X ticket" + "s" se o preco for maior que 1
    lw   $t2, preco($t1)        # t2 = preco[i]
    li   $v0, 1
    move $a0, $t2
    syscall
    li   $v0, 4
    la   $a0, txt_ticket
    syscall
    ble  $t2, 1, sm_estoque     # preco 1 -> singular, pula o "s"
    li   $v0, 4
    la   $a0, txt_plural
    syscall

sm_estoque:
    # estoque: "(restam N)" ou "(ESGOTADO)"
    lw   $t3, estoque($t1)      # t3 = estoque[i]
    beq  $t3, $zero, sm_esgotado
    li   $v0, 4
    la   $a0, txt_restam
    syscall
    li   $v0, 1
    move $a0, $t3
    syscall
    li   $v0, 4
    la   $a0, txt_fecha
    syscall
    j    sm_next

sm_esgotado:
    li   $v0, 4
    la   $a0, txt_esgotado
    syscall

sm_next:
    addi $t0, $t0, 1            # i++
    j    sm_loop

sm_end:
    li   $v0, 4
    la   $a0, rodape
    syscall
    jr   $ra

# =============================================================================
# handle_choice - valida a opcao e, se possivel, realiza a compra.
#   Ordem das verificacoes: sair? -> codigo existe? -> tem estoque? -> saldo basta?
# Argumentos: $a0 = opcao digitada, $a1 = saldo atual
# Retorno:    $v0 = 0 para sair, 1 para continuar
#             $v1 = saldo depois da operacao
# Pilha:      salva $ra, porque chama deliver (o jal sobrescreve $ra)
#             salva $s1, porque usa $s1 para guardar o novo saldo durante
#             a chamada de deliver (e $s1 precisa ser devolvido intacto)
# =============================================================================
handle_choice:
    addi $sp, $sp, -8           # abre espaco para 2 palavras na pilha
    sw   $ra, 4($sp)            # guarda o endereco de retorno
    sw   $s1, 0($sp)            # guarda o valor antigo de $s1

    move $s1, $a1               # por padrao, o saldo nao muda

    beq  $a0, $zero, hc_exit    # 0 -> sair

    blt  $a0, 1, hc_invalid     # fora de 1..5 (ou -1 de read_int) -> invalido
    bgt  $a0, NUM_PRODUTOS, hc_invalid

    # Calcula a posicao do produto nos vetores
    addi $t0, $a0, -1           # t0 = indice = opcao - 1
    sll  $t1, $t0, 2            # t1 = indice * 4

    lw   $t2, estoque($t1)      # t2 = estoque do item
    blez $t2, hc_empty          # sem estoque -> esgotado

    lw   $t3, preco($t1)        # t3 = preco do item
    blt  $a1, $t3, hc_no_tickets    # saldo < preco -> nao pode comprar

    # Compra aprovada: atualiza saldo e estoque
    sub  $s1, $a1, $t3          # novo saldo = saldo - preco
    addi $t2, $t2, -1           # estoque - 1
    sw   $t2, estoque($t1)      # grava o novo estoque no vetor

    move $a0, $t0               # a0 = indice do produto
    jal  deliver                # imprime a mensagem de entrega
    # (aqui $t0-$t3 podem ter mudado, mas $s1 continua com o novo saldo)

    li   $v0, 1                 # continuar
    j    hc_return

hc_empty:
    li   $v0, 4
    la   $a0, sem_estoque
    syscall
    li   $v0, 1
    j    hc_return

hc_no_tickets:
    li   $v0, 4
    la   $a0, sem_tickets
    syscall
    li   $v0, 1
    j    hc_return

hc_invalid:
    li   $v0, 4
    la   $a0, opcao_invalida
    syscall
    li   $v0, 1
    j    hc_return

hc_exit:
    li   $v0, 0                 # sair

# Ponto unico de saida: devolve o saldo e restaura a pilha
hc_return:
    move $v1, $s1               # v1 = saldo final da operacao
    lw   $s1, 0($sp)            # restaura $s1 de quem chamou
    lw   $ra, 4($sp)            # restaura o endereco de retorno
    addi $sp, $sp, 8            # fecha o espaco da pilha
    jr   $ra

# =============================================================================
# deliver - imprime a mensagem de entrega do produto.
#   Em vez de 5 blocos repetidos, busca o endereco da mensagem no vetor
#   entregas (mesma ideia do vetor nomes).
# Argumentos: $a0 = indice do produto (0 a 4)
# Retorno:    nenhum
# Pilha:      nao usa (procedimento folha)
# =============================================================================
deliver:
    sll  $t0, $a0, 2            # t0 = indice * 4
    lw   $a0, entregas($t0)     # a0 = endereco da mensagem
    li   $v0, 4
    syscall
    jr   $ra

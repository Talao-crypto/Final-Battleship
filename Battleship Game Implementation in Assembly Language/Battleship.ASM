title INPUT DO USUÁRIO --> BATALHA NAVAL
; ************************************************
; **************** Battle Ship *******************
; ************************************************
; Desenvolvedores  // 2 semestre 2024
; ************************************************
; Tales Martins                 
; Lucas Kitsuta Sabino          
; Daniel Picconi Alquete        
; ************************************************
; Versão 1.0.0
; ************************************************
; ********* Data da versão- 14/11/2025 ***********
; ************************************************
; Descrição
; O famoso jogo de barquinhos e explosões agora em
; assembly x86 do DOS.
;************************************************
.MODEL SMALL
.STACK 100H

;****************************************************************
;Macro Para Armazenar os Registradores
PUSH_4 MACRO R1,R2,R3,R4
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
ENDM
;Desempilhar os Registradores
POP_4 MACRO R1,R2,R3,R4
    POP R4
    POP R3
    POP R2
    POP R1
ENDM

;MACRO PARA PULAR LINHA
PULAR_LINHA MACRO
    PUSH AX
    PUSH DX
    
    MOV AH, 2
    MOV DL, 10
    INT 21H
    MOV DL, 13
    INT 21H

    POP DX
    POP AX
ENDM

;ESSE MACRO COLOCA A POSIÇÃO DA FILEIRA EM BX E DA COLUNA EM SI (UTILIZA AS COORDENADAS DO ÚLTIMO TIRO)
CARREGAR_TABULEIRO MACRO MAPA
    MOV BX, MAPA
    ADD BX, COORDENADA_FILEIRA
    MOV SI, COORDENADA_COLUNA
ENDM

;MACRO PARA DAR 5 ESPAÇOS (AJUDOU PARA FAZER A MONTAGEM DA TELA)
ESPACO MACRO
    LOCAL FOR
    MOV AH, 2
    MOV CX, 5
    MOV DL, 20H
    FOR:
        INT 21H
        LOOP FOR
ENDM

;MACRO PARA LIMPAR TELA
LIMPAR_TELA MACRO
    PUSH_4 AX, BX, CX, DX
    MOV AH, 06h
    MOV AL, 0
    MOV BH, 07h
    MOV CX, 0
    MOV DX, 184FH
    INT 10H
    POP_4 AX, BX, CX, DX
ENDM
;****************************************************************

.DATA
    ;****************************************************************
    ; Declaração de todas as mensagens do jogo
    MSG_ENTRADA             DB "WELCOME TO BATTLESHIP! PRESS ANY BUTTON TO CONTINUE ",0
    MSG_REGRA               DB 10, 13, "BEM VINDO AO SIMULADOR DE BATALHA NAVAL", 10, "PARA JOGAR, BASTA DIGITAR AS COORDENADAS DO TABULEIRO (0 A 9)", 10, "O JOGO SERA ENCERRADO APOS TODOS OS BARCOS SEJAM DERRUBADOS OU AO DIGITAR '*'.$"
    MSG_TIRO_FILEIRA        DB 10, 13, "DIGITE O INDICE DA FILEIRA: $"
    MSG_TIRO_COLUNA         DB 10, 13, "DIGITE O INDICE DA COLUNA: $"
    MSG_ENTRADA_ERRADA      DB 10, 13, "CARACTERE INVALIDO$"
    MSG_TIRO_REPETIDO       DB 10, 13, "VOCE JA ATIROU NESSA POSIÇAO, DIGITE NOVAMENTE$"

    MSG_FIM                 DB 10, 13, "!!OBRIGADO POR JOGAR!!$"
    MSG_VITORIA             DB 10, 13, "PARABENS, VOCE DERRUBOU TODOS OS BARCOS INIMIGOS$"

    MSG_NUM_TIROS           DB 10, 13, "NUMERO DE TIROS: $"
    MSG_NUM_ERROS           DB 10, 13, "NUMERO DE ERROS: $"

    ACERTO_ENCOURACADO      DB 10, 13, "PARABENS, VOCE DERRUBOU UM ENCOURACADO$"
    ACERTO_FRAGATA          DB 10, 13, "PARABENS, VOCE DERRUBOU UMA FRAGATA$"
    ACERTO_SUB              DB 10, 13, "PARABENS, VOCE DERRUBOU UM SUBMARINO$"
    ACERTO_HIDRO            DB 10, 13, "PARABENS, VOCE DERRUBOU UM HIDROAVIAO$"
    ACERTO_AGUA             DB 10, 13, "VOCE NAO ACERTOU NENHUM BARCO$"
    ACERTOU_ALGO            DB 10, 13, "ATENCAO, VOCE ACERTOU ALGO$"
    

    ;**************************************************************************************************************
    ;DECLARAÇÃO DAS VARIAVEIS
    
    LISTA_MENSAGENS         DW 6 DUP(0)             ;UM VETOR QUE SERÁ UTILIZADO PARA ARMAZENAR O ENDEREÇO DAS MENSAGENS DE CADA TIPO DE INTERAÇÃO (USA OS MESMOS INDICES QUE O VETOR 'LISTA_INDICES')
    COORDENADA_COLUNA       DW 0                    ;CONTÉM A ÚLTIMA COORDENADA DIGITADA REFERENTE À COLUNA
    COORDENADA_FILEIRA      DW 0                    ;CONTÉM A ÚLTIMA COORDENADA DIGITADA REFERENTE À FILEIRA
    GABARITO_SELECIONADO    DW 0                    ;CONTÉM O ENDEREÇO DO GABARITO ESCOLHIDO
    NUM_MENSAGEM            DB 0                    ;GUARDA ÍNDICE DO BARCO QUE FOI DERRUBADO
    PONTUACAO               DB 0                    ;MANTÉM CONTA DE QUANTOS BARCOS O USUÁRIO DERRUBOU
    NUM_TIROS               DB 0                    ;NÚMERO DE TIROS DADOS PELO USUÁRIO
    NUM_ERROS               DB 0                    ;NÚMERO DE TIROS DO USUÁRIO QUE ACERTARAM A ÁGUA

    LISTA_INDICES           DB 7 DUP(0)               ;CRIA A LISTA DE ÍNDICES QUE REALIZA A CONTAGEM DE QUANTOS ACERTOS O USUÁRIO REALIZOU EM CADA CATEGORIA
    TABULEIRO               DB 10 DUP(10 DUP(7Eh))    ;CRIA UM TABULEIRO 10x10 EM QUE TODOS OS NÚMEROS ESTÃO ZERADOS 
    ;CADA GABARITO CONTÉM NÚMEROS DE 0 A 6, EM QUE CADA NÚMERO REPRESENTA UMA EMBARCAÇÃO (AGUA É REPRESENTADA POR 0) NO VETOR LISTA_INDICES
    ;ENCOURAÇADO    --> 1
    ;FRAGATA        --> 2
    ;SUBMARINO1     --> 3
    ;SUBMARINO2     --> 4
    ;HIDROAVIÃO1    --> 5
    ;HIDROAVIÃO2    --> 6
    ; ****************************************************************
    ; Declaração dos 6 gabaritos numerados de 0 a 5
    GABARITO_0  DB 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 1, 0, 0, 0, 0, 0, 5, 5, 5, 0
                DB 1, 0, 0, 0, 0, 0, 0, 5, 0, 0
                DB 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 4, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 4, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 6, 0, 0, 0, 0, 0, 0, 3
                DB 0, 6, 6, 6, 0, 0, 0, 0, 0, 3
                DB 0, 0, 0, 0, 0, 2, 2, 2, 0, 0
    ;PRIMEIRO GABARITO
    GABARITO_1  DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 4, 4, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 3, 3
                DB 0, 0, 2, 2, 2, 0, 0, 0, 0, 0
                DB 5, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 5, 5, 0, 0, 1, 1, 1, 1, 0, 0
                DB 5, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 6, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 6, 6
                DB 0, 0, 0, 0, 0, 0, 0, 0, 6, 0
    ;SEGUNDO GABARITO
    GABARITO_2  DB 0, 0, 0, 4, 4, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 3, 3, 0, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 5, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 5, 5, 0, 0, 0, 0, 0
                DB 0, 0, 0, 5, 0, 0, 6, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 6, 6, 0, 0
                DB 0, 0, 0, 0, 0, 0, 6, 0, 0, 0
                DB 2, 2, 2, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 1, 1, 1, 1

    ;TERCEIRO GABARITO
    GABARITO_3  DB 0, 0, 0, 0, 0, 0, 6, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 6, 6, 0, 0
                DB 0, 0, 0, 0, 0, 0, 6, 0, 0, 0
                DB 0, 0, 5, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 5, 5, 0, 2, 2, 2, 0, 0
                DB 0, 0, 5, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 4, 4
                DB 0, 3, 0, 1, 1, 1, 1, 0, 0, 0
                DB 0, 3, 0, 0, 0, 0, 0, 0, 0, 0
    
    ;QUARTO GABARITO
    GABARITO_4  DB 0, 0, 0, 0, 0, 0, 0, 0, 5, 0
                DB 0, 0, 4, 4, 0, 0, 0, 0, 5, 5
                DB 0, 0, 0, 0, 0, 0, 0, 0, 5, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 1, 1, 1, 1
                DB 6, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 6, 6, 0, 2, 2, 2, 0, 0, 0, 0
                DB 6, 0, 0, 0, 0, 0, 0, 0, 3, 3

    ;QUINTO GABARITO
    GABARITO_5  DB 2, 2, 2, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 3, 3, 0, 0, 0
                DB 0, 4, 4, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 1, 1, 1, 1
                DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 6, 6, 6, 0
                DB 0, 0, 5, 0, 0, 0, 0, 6, 0, 0
                DB 0, 5, 5, 5, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.CODE
MAIN PROC
    ;Inializa o segmento de dados
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX

    CALL SORTEIA_GABARTIO                   ;REALIZA A SELEÇÃO ENTRE OS 6 GABARITOS
    CALL INICIALIZA_LISTA_MSG               ;CARREGA OS ENDEREÇOS DAS MENSAGENS DE INTERAÇÃO COM O TABULEIRO NO VETOR
    CALL IMPRIMIR_BOAS_VINDAS               ;PAGINA DE BOAS-VINDAS
    LIMPAR_TELA
    JOGO:
        CALL IMPRIMIR_TABULEIRO
        CALL TIRO                           ;RECEBE COORDENADAS DO USUÁRIO
        CALL COMPARAR_TIRO                  ;MARCA ESSAS COORDENADAS NO TABULEIRO
        
        CMP PONTUACAO, 6                    ;CADA PONTO SE REFERE A UM BARCO DERRUBADO
        JE VENCEU_JOGO                      ;SE O USUÁRIO DERRUBOU OS 6 BARCOS, ENCERRAR O JOGO COM MENSAGEM DE VITORIA
        JG DESISTIU                         ;CASO O USUÁRIO DIGITE '*', A PONTUAÇÃO SERÁ ALTERADA PARA ENCERRAR O LOOP
        
        LIMPAR_TELA
        CALL FEEDBACK_TIRO                  ;IMPRIME A MENSAGEM DE ACORDO COM A INTERAÇÃAO FEITA
        JMP JOGO

    VENCEU_JOGO:
        CALL VITORIA
        JMP FIM
    DESISTIU:
        CALL ENCERRAR
    FIM:
        MOV AH, 4CH
        INT 21H
MAIN ENDP


    ;**********************************************************************************
    ;FUNÇÃO RESPONSAVEL PARA LIMPAR A TELA E IMPRIMIR A MENSAGEM DE BOAS VINDAS
IMPRIMIR_BOAS_VINDAS PROC
    ; Limpar a tela
    MOV AH, 6
    MOV AL, 0            ; Número de linhas para rolar (0 = limpa toda a tela)
    MOV BH, 07H          ; Atributo de cor (branco sobre preto)
    MOV CX, 0000H        ; Posição inicial (linha superior, coluna esquerda)
    MOV DX, 184FH        ; Posição final (linha inferior, coluna direita)
    INT 10H              ; Chama o interruptor para limpar a tela

    ; Posiciona o cursor na linha 5, coluna 10 para a mensagem
    MOV AH, 2            ; Função para mover o cursor
    MOV BH, 0            ; Número da página (0)
    MOV DH, 5            ; Linha (y)
    MOV DL, 10           ; Coluna (x)
    INT 10H              ; Chama o interruptor para mover o cursor

    ; Exibe a mensagem de boas-vindas
    LEA SI, MSG_ENTRADA
    CALL PrintString

    ret
IMPRIMIR_BOAS_VINDAS ENDP

;****************************************************************
;Procedimento para imprimir a mensagem de entrada
PrintString PROC
    NEXT_CHAR:
        LODSB                  ; Carrega o próximo byte de DS:SI em AL
        CMP AL, 0              ; Verifica se é o fim da string (terminador 0)
        JE DONE                ; Se for o fim, sai da função
        MOV AH, 0Eh            ; Função para exibir caractere
        MOV BH, 0              ; Página 0
        INT 10H                ; Exibe o caractere em AL
        JMP NEXT_CHAR          ; Continua com o próximo caractere
    DONE:
        mov ah,1
        int 21h
        RET
PrintString ENDP


;*******************************************************************************
;SELECIONA UM DOS 6 GABARITOS PARA SEREM UTILIZADOS NA PARTI
SORTEIA_GABARTIO PROC
    PUSH_4 AX, BX, DX, DI
    MOV AH, 2CH                                     ;COLOCA HORA DO RELÓGIO EM DX
    INT 21h

    AND DX, 0FH                                     ;PRESERVA OS 4 BITS MENOS SIGNIFICATIVO DO NÚMERO COLETADO (NÚMERO DE 0-15)
    CMP DL, 10                                      ;SE DL > 10, SUBTRAIR 10 E UTILIZAR ESSE NÚMERO
    JLE DIVIDE                                      ;SE DL <= 10, DIVIDIR POR 2 E UTILIZAR ESSE NÚMERO

    SUB DL, 10                                      ;FUNÇÃO RESPONSÁVEL PELA ALETORIEDADE
    JMP CASO_0
    DIVIDE:
        ;DEFINIE DIVIDENDO
        MOV AX, DX                                  ;DIVIDENDO (AX)
        MOV BL, 2                                   ;DEFINE DIVISOR (BL)
        ;DIVISAO
        DIV BL                                      ;AX / BL --> QUOCIENTE EM AL, RESTO EM AH

    CASO_0:
        CMP AL, 0
        JG CASO_1
        LEA DI, GABARITO_0
        JMP SELECIONADO
    CASO_1:
        CMP AL, 1
        JG CASO_2
        LEA DI, GABARITO_1
        JMP SELECIONADO
    CASO_2:
        CMP AL, 2
        JG CASO_3
        LEA DI, GABARITO_2
        JMP SELECIONADO
    CASO_3:
        CMP AL, 3
        JG CASO_4
        LEA DI, GABARITO_3
        JMP SELECIONADO
    CASO_4:
        CMP AL, 4
        JG CASO_5
        LEA DI, GABARITO_4
        JMP SELECIONADO
    CASO_5:
        LEA DI, GABARITO_5

    SELECIONADO:
        MOV GABARITO_SELECIONADO, DI                ;PEGA O GABARITO ALEATORIO E MOVE PARA A VARIAVEL GABARITO_SELECIONADO
    POP_4 AX, BX, DX, DI
    RET
SORTEIA_GABARTIO ENDP


;*********************************************************************************
;PROCEDIMENTO QUE INICIALIZA A LISTA DE MENSAGENS
INICIALIZA_LISTA_MSG PROC
    PUSH AX
    LEA DI, LISTA_MENSAGENS         ;ARMAZENA O ENDEREÇO DA LISTA DE MENSAGENS
    CLD
    
    LEA AX, ACERTO_AGUA             ;RECEBE O ENDEREÇO DA MENSAGEM EM AX
    STOSW                           ;PEGA O ENDEREÇO CONTIDO EM AX E O ARMAZENA NA POSIÇÃO DE MEMORIA GUARDADA EM DI 
    LEA AX, ACERTO_ENCOURACADO
    STOSW
    LEA AX, ACERTO_FRAGATA
    STOSW
    LEA AX, ACERTO_SUB
    STOSW
    LEA AX, ACERTO_HIDRO
    STOSW
    LEA AX, ACERTOU_ALGO
    STOSW


    POP AX
    RET
INICIALIZA_LISTA_MSG ENDP


;************************************************************************************
;PROCEDIMENTO QUE IMPRIME O TABULEIRO ATUALIZADO
IMPRIMIR_TABULEIRO PROC
    PUSH_4 AX, BX, CX, DX
    PULAR_LINHA
    ESPACO
    MOV AH, 2
    MOV DX, 3020H
    MOV CX, 10
    IMPRIMIR_NUMEROS:
        INT 21H
        INT 21H                     ;IMPRIME 3 ESPAÇOS
        INT 21H
        XCHG DL, DH                 ;TROCA ENTRE IMPRIMIR ESPAÇO E IMPRIMIR NÚMERO
        INT 21H                     ;IMPRIME UM NÚMERO
        INC DL                      ;INCREMENTA O NÚMERO
        XCHG DL, DH
        LOOP IMPRIMIR_NUMEROS

    PULAR_LINHA
    ESPACO
    MOV CX, 39
    MOV AH, 2
    INT 21H
    INT 21H
    MOV DL, '-'
    IMPRIMIR_LINHA:
        INT 21H
        LOOP IMPRIMIR_LINHA

    XOR SI, SI
    MOV DI, 10
    MOV CX, 10
    MOV DX, 3020H
    TABELA:
        XCHG CX, DI
        PULAR_LINHA
        ESPACO
        XCHG DL, DH
        INT 21H
        INC DL
        XCHG DL, DH                                     ;DH VAI CONTER O NÚMERO DA FILEIRA
        MOV BL, '|'                                     ;BL VAI ARMAZENAR A BARRA
        XCHG BL, DL
        INT 21H
        XCHG BL, DL
        INT 21H
        MOV CX, 10
        IMPRIMIR_FILEIRA:
            MOV BH, TABULEIRO[SI]                       ;FOI UTILIZADA INDEXAÇÃO COMO VETOR AO INVÉS DE MATRIZ PELA FALTA DE REGISTRADORES DISPONÍVEIS
            INC SI
            XCHG BH, DL
            INT 21H
            XCHG BH, DL
            INT 21H
            INT 21H
            INT 21H
            LOOP IMPRIMIR_FILEIRA
            XCHG DI, CX
        LOOP TABELA
    POP_4 AX, BX, CX, DX
    RET
IMPRIMIR_TABULEIRO ENDP


;************************************************************************************************
;PROCEDIMENTO RESPONSAVEL POR IMPRIMIR O GABARITO SELECIONADO NO INICIO DO CÓDIGO 
IMPRIMIR_GABARITO PROC
    PUSH_4 AX, BX, CX, DX
    PULAR_LINHA
    ESPACO
    MOV AH, 2
    MOV DX, 3020H
    MOV CX, 10
    GABARITO_NUMS:
        INT 21H
        INT 21H
        INT 21H
        XCHG DL, DH
        INT 21H
        INC DL
        XCHG DL, DH
        LOOP GABARITO_NUMS

    PULAR_LINHA
    ESPACO
    MOV CX, 39
    MOV AH, 2
    MOV DL, 20H
    INT 21H
    INT 21H
    MOV DL, '-'
    GABARITO_LINHA:
        INT 21H
        LOOP GABARITO_LINHA

    MOV SI, GABARITO_SELECIONADO                ;VARIAVEL QUE ARMAZENOU O GABARITO SELECIONADO
    MOV DI, 10
    MOV CX, 10
    MOV DX, 3020H
    TABELA_GABARITO:
        XCHG CX, DI
        PULAR_LINHA
        ESPACO
        XCHG DL, DH
        INT 21H
        INC DL
        XCHG DL, DH                                     ;DH VAI CONTER O NÚMERO DA FILEIRA
        MOV BL, '|'                                     ;BL VAI ARMAZENAR A BARRA
        XCHG BL, DL
        INT 21H
        XCHG BL, DL
        INT 21H
        MOV CX, 10
        GABARITO_FILEIRA:
            MOV BH, [SI]                       ;FOI UTILIZADA INDEXAÇÃO COMO VETOR AO INVÉS DE MATRIZ PELA FALTA DE REGISTRADORES DISPONÍVEIS
            INC SI
            XCHG BH, DL
            INT 21H
            XCHG BH, DL
            INT 21H
            INT 21H
            INT 21H
            LOOP GABARITO_FILEIRA
            XCHG DI, CX
        LOOP TABELA_GABARITO
    POP_4 AX, BX, CX, DX
    RET
IMPRIMIR_GABARITO ENDP


;******************************************************************************************************
;RECEBE O INPUT DE FILEIRA E COLUNA DO USUÁRIO
TIRO PROC
    PUSH_4 AX, BX, SI, DX
    ;receber coordenada coluna
    JMP ENTRADA_COLUNA
    ENTRADA_ERRADA_C:                           ;CASO O CARACTERE DIGITADO FOR INVÁLIDO, VOLTAR E PEDIR PARA DIGITAR NOVAMENTE
        MOV AH,9
        LEA DX, MSG_ENTRADA_ERRADA              ;IMPRIME MENSAGEM DE CARACTERE INVÁLIDO
        INT 21H
    ENTRADA_COLUNA:
        MOV AH, 9
        LEA DX, MSG_TIRO_COLUNA                 ;IMPRIME MENSAGEM PEDINDO ENTRADA DO USUÁRIO
        INT 21H

        MOV AH, 1                               ;RECEBE CARACTERE EM AL
        INT 21H

        CMP AL, '*'                             ;CARACTER PARA ENCERRAR O PROGRAMA
        JE FECHAR_PROGRAMA

        CMP AL, '0'
        JL ENTRADA_ERRADA_C
        CMP AL, '9'
        JG ENTRADA_ERRADA_C                     ;RECEBE NOVAMENTE SE O CARACTERE FOR INVÁLIDO

        AND AX, 000Fh                           ;CONVERTE PARA NÚMERO
        MOV COORDENADA_COLUNA, AX               ;GUARDA NA MEMÓRIA O A COORDENADA DIGITADA
    ;receber coordenada fileira
    JMP ENTRADA_FILEIRA
    ENTRADA_ERRADA_F:                           ;CASO O CARACTERE DIGITADO FOR INVÁLIDO, VOLTAR E PEDIR PARA DIGITAR NOVAMENTE
        MOV AH,9
        LEA DX, MSG_ENTRADA_ERRADA              ;IMPRIME MENSAGEM DE CARACTERE INVÁLIDO
        INT 21H                                 ;RECEBE NOVAMENTE UM CARACTERE
    ENTRADA_FILEIRA:
        MOV AH, 9                               ;IMPRIME MENSAGEM PEDINDO UMA ENTRADA DO USUÁRIO
        LEA DX, MSG_TIRO_FILEIRA
        INT 21H
        MOV AH, 1                               ;RECEBE CARACTERE EM AL
        INT 21H

        CMP AL, '*'
        JE FECHAR_PROGRAMA
        
        CMP AL, '0'                             ;CONFERE SE O NÚMERO É VÁLIDO
        JL ENTRADA_ERRADA_F
        CMP AL, '9'
        JG ENTRADA_ERRADA_F                     ;RECEBE NOVAMENTE SE O CARACTERE FOR INVÁLIDO
        
        AND AX, 000Fh                           ;CONVERTE PARA NÚMERO
        MOV BL, 10
        MUL BL                                  ;CONVERTE PARA ÍNDICE NA TABELA
        MOV COORDENADA_FILEIRA, AX              ;GUARDA NA MEMÓRIA A COORDENADA DIGITADA

    ; CONFERE SE O TIRO É VÁLIDO
    LEA AX, TABULEIRO
    CARREGAR_TABULEIRO AX

    MOV AL, [BX][SI]                            ;PEGA O ELEMENTO NA COORDENADA DIGITADA PELO USUÁRIO NO GABARITO E COLOCA EM AX
    
    CMP AL, 7Eh                                 ;SE ELEMENTO MARCADO, O USUÁRIO JÁ ATIROU NESSA POSIÇÃO
    JZ TIRO_VALIDO                              ;SE O TIRO FOR VÁLIDO, SAIR DO PROCEDIMENTO
    
    MOV AH, 9
    LEA DX, MSG_TIRO_REPETIDO                   ;SE O TIRO FOR REPETIDO, IMPRIMIR MENSAGEM E RECOMEÇAR PROCEDIMENTO
    INT 21H
    
    JMP ENTRADA_COLUNA                          ;VOLTA AO COMEÇO
    FECHAR_PROGRAMA:
        MOV PONTUACAO, 15                       ;SE USUÁRIO DIGITOU '*', REVELA GABARITO E ENCERRA PROGRAMA
        JMP FIM_PROGRAMA
    TIRO_VALIDO:
        ADD NUM_TIROS, 1                        ;CONTADOR DE QUANTOS TIROS O USUÁRIO FEZ
    FIM_PROGRAMA:
    POP_4 AX, BX, SI, DX
    RET
TIRO ENDP

;*****************************************************************************************************
;PROCEDIMENTO QUE COMPARA A POSIÇÃO DIGITADA PELO USUÁRIO COM O GABARITO
COMPARAR_TIRO PROC
    PUSH_4 AX, BX, CX, DX
    CMP PONTUACAO, 6
    JL CONTINUAR_COMPARACAO
    JMP SAIR_COMPARACAO                         ;SE SINAL DE SAIR DO PROGRAMA, SAIR DO PROCEDIMENTO

    CONTINUAR_COMPARACAO:
    CARREGAR_TABULEIRO GABARITO_SELECIONADO     ;POSICIONA AS COORDENADAS NO GABARITO ESCOLHIDO
    MOV BL, [BX][SI]                            ;PEGA O ÍNDICE QUE ESTÁ NA COORDENADA ESCOLHIDA PELO USUÁRIO
    
    MOV AH, 9                                   ;PREPARA PARA IMPRIMIR MENSAGEM
    AND BX, 00FFh                               ;LIMPA O BH

    CMP BL, 0                                   ;CONFERE SE ACERTOU ÁGUA (0=ÁGUA)
    JNZ SALTO_AGUA
    JMP AGUA
    
    SALTO_AGUA:
    CMP BL, 1                                   ;CONFERE SE ACERTOU ENCOURAÇADO (1=ENCOURAÇADO)
    JNZ SALTO_ENCOURACADO
    JMP ENCOURACADO

    SALTO_ENCOURACADO:
    CMP BL, 2                                   ;CONFERE SE ACERTOU FRAGATA (2=FRAGATA)
    JNZ SALTO_FRAGATA
    JMP FRAGATA

    SALTO_FRAGATA:
    CMP BL, 3                                   ;CONFERE SE ACERTOU SUBMARINO1 (3=SUBMARINO1)
    JE SUBMARINO1

    CMP BL, 4                                   ;CONFERE SE ACERTOU SUBMARINO2 (4=SUBMARINO2)
    JE SUBMARINO2

    CMP BL, 5                                   ;CONFERE SE ACERTOU HIDROAVIÃO1 (5=HIDROAVIÃO1)
    JE HIDROAVIAO1


    ;*******************************************************************************************************************************
    ;CONFERIR SE QUANTAS VEZES ACERTOU A NAVEGAÇÃO, PARA IMPRIMIR QUANDO DERRUBAR POR COMPLETO A EMBARCAÇÃO

    HIDROAVIAO2:                                ;SE NÃO ACERTOU NENHUM DOS ANTERIORES, LOGO ACERTOU HIDROAVIÃO2
        ADD LISTA_INDICES[BX], 1                ;ADICIONA 1 À LISTA DE ÍNDICES NO ESPAÇO DESSA EMBARCAÇÃO (ÍNDICE --> 6)
        MOV CL, LISTA_INDICES[BX]
        MOV NUM_MENSAGEM, 10
        CMP CL, 4                               ;CONFERE SE DERRUBOU ESSA EMBARCAÇÃO
        JE DERRUBOU_HIDRO
        JMP SAIR_COMPARACAO
        
    HIDROAVIAO1:
        ADD LISTA_INDICES[BX], 1                ;ADICIONA 1 À LISTA DE ÍNDICES NO ESPAÇO DESSA EMBARCAÇÃO (ÍNDICE --> 5)
        MOV CL, LISTA_INDICES[BX]
        MOV NUM_MENSAGEM, 10                    ;MENSAGEM DE QUE ATINGIU
        CMP CL, 4                               ;CONFERE SE DERRUBOU ESSA EMBARCAÇÃO
        JE DERRUBOU_HIDRO                       ;MENSAGEM DE QUANDO DERRUBA A NAVEGAÇÃO
        JMP SAIR_COMPARACAO
        DERRUBOU_HIDRO:                         ;SE DERRUBOU UM HIDROAVIÃO, IMPRIMIR MENSAGEM
            MOV NUM_MENSAGEM, 8
            ADD PONTUACAO, 1
            JMP SAIR_COMPARACAO

    SUBMARINO2:
        ADD LISTA_INDICES[BX], 1                ;ADICIONA 1 À LISTA DE ÍNDICES NO ESPAÇO DESSA EMBARCAÇÃO (ÍNDICE --> 4)
        MOV CL, LISTA_INDICES[BX]
        MOV NUM_MENSAGEM, 10
        CMP CL, 2                               ;CONFERE SE DERRUBOU ESSA EMBARCAÇÃO
        JE DERRUBOU_SUB
        JMP SAIR_COMPARACAO

    SUBMARINO1:
        ADD LISTA_INDICES[BX], 1                ;ADICIONA 1 À LISTA DE ÍNDICES NO ESPAÇO DESSA EMBARCAÇÃO (ÍNDICE --> 3)
        MOV CL, LISTA_INDICES[BX]
        MOV NUM_MENSAGEM, 10
        CMP CL, 2                               ;CONFERE SE DERRUBOU ESSA EMBARCAÇÃO
        JNE SAIR_COMPARACAO
        DERRUBOU_SUB:                           ;SE DERRUBOU UM SUBMARINO, IMPRIMIR MENSAGEM
            MOV NUM_MENSAGEM, 6
            ADD PONTUACAO, 1
            JMP SAIR_COMPARACAO

    FRAGATA:
        ADD LISTA_INDICES[BX], 1                ;ADICIONA 1 À LISTA DE ÍNDICES NO ESPAÇO DESSA EMBARCAÇÃO (ÍNDICE --> 2)
        MOV CL, LISTA_INDICES[BX]
        MOV NUM_MENSAGEM, 10
        CMP CL, 3                               ;CONFERE SE DERRUBOU ESSA EMBARCAÇÃO
        JNE SAIR_COMPARACAO
        DERRUBOU_FRAGATA:                       ;SE DERRUBOU UMA FRAGATA, IMPRIMIR MENSAGEM
            MOV NUM_MENSAGEM, 4
            ADD PONTUACAO, 1
            JMP SAIR_COMPARACAO

    ENCOURACADO:
        ADD LISTA_INDICES[BX], 1                ;ADICIONA 1 À LISTA DE ÍNDICES NO ESPAÇO DESSA EMBARCAÇÃO (ÍNDICE --> 1)
        MOV CL, LISTA_INDICES[BX]
        MOV NUM_MENSAGEM, 10
        CMP CL, 4                               ;CONFERE SE DERRUBOU ESSA EMBARCAÇÃO
        JNE SAIR_COMPARACAO
        DERRUBOU_ENCOURACADO:                   ;SE DERRUBOU UM ENCOURAÇADO, IMPRIMIR MENSAGEM
            MOV NUM_MENSAGEM, 2
            ADD PONTUACAO, 1
            JMP SAIR_COMPARACAO
    AGUA:
        ADD LISTA_INDICES[BX], 1
        MOV NUM_MENSAGEM, 0
        ADD NUM_ERROS, 1
        JMP SAIR_COMPARACAO
    SAIR_COMPARACAO:

    CARREGAR_TABULEIRO GABARITO_SELECIONADO     ;POSIÇÃO NO TABULEIRO DO JOGADOR
    MOV DL, [BX][SI]                            ;CONFERE SE AQUELA COORDENADA POSSUI UM BARCO OU NÃO NO GABARITO

    LEA AX, TABULEIRO
    CARREGAR_TABULEIRO AX                       ;TROCA PARA O ENDEREÇO DO USUÁRIO
    CMP DL, 0                                   ;COMPARA ELEMENTO ENTRE O GABARITO E O TABULEIRO
    JE MARCAR_ERRO
    MARCAR_ACERTO:
        MOV BYTE PTR [BX][SI], 4                ;ALTERA VALOR NO TABULEIRO DO USUÁRIO (1 -->  BARCO) (SINAL DE OUROS PARA EMBARCAÇÃO)
        JMP FIM_COMPARACAO

    MARCAR_ERRO:
        MOV BYTE PTR [BX][SI], 1                ;ALTERA VALOR NO TABULEIRO DO USUÁRIO (2 -->  ÁGUA) (SINAL PARA A ÁGUA)

    FIM_COMPARACAO:
    POP_4 AX, BX, CX, DX
    RET
COMPARAR_TIRO ENDP

;***************************************************************************
;IMPRIME MENSAGEM AVISANDO QUE UM BARCO FOI DERRUBADO
FEEDBACK_TIRO PROC
    PUSH_4 AX, BX, CX, DX
    XOR BH, BH
    MOV BL, NUM_MENSAGEM                    ;IMPRIME A MENSAGEM BASEADO NO ÍNDICE ARMAZENADO EM 'NUM_MENSAGEM'
    MOV AH, 9
    MOV DX, LISTA_MENSAGENS[BX]
    INT 21H
    PULAR_LINHA

    POP_4 AX, BX, CX, DX
    RET
FEEDBACK_TIRO ENDP

;*****************************************************************************
;PROCEDIMENTO QUE IMPRIME UMA MENSAGEM DE PARABÉNS
VITORIA PROC
    PUSH AX
    PUSH DX
    LIMPAR_TELA
    CALL IMPRIMIR_TABULEIRO

    MOV AH, 9
    LEA DX, MSG_VITORIA
    INT 21H
    CALL IMPRIMIR_ESTATISTICAS

    POP DX
    POP AX
    RET
VITORIA ENDP


;********************************************************************************
;PROCEDIMENTO QUE ENCERRA O PROGRAMA E MOSTRA O TABULEIRO PARA O USUÁRIO
ENCERRAR PROC
    PUSH AX
    PUSH DX
    LIMPAR_TELA
    CALL IMPRIMIR_GABARITO

    MOV AH, 9
    LEA DX, MSG_FIM
    INT 21H
    CALL IMPRIMIR_ESTATISTICAS

    POP DX
    POP AX
    RET
ENCERRAR ENDP

        ;****************************************************************
        ;PARA IMPRIMIR O NUMERO DE TIROS E O NUMERO DE ERROS
SAIDADECIMAL PROC
    PUSH_4 AX, BX, CX, DX

    MOV DI, 10
    XOR CX, CX
    XOR AH, AH                                  ;LIMPA AX, POIS CONTÉM 'LIXO'
    XOR DX, DX                                  ;tira o lixo de dx
    OUTPUTDECIMAL:
        DIV DI                                  ;DX:AX / DI    --> QUOCIENTE VAI PARA AX E RESTO VAI PARA DX
        PUSH DX                                 ;COLOCA RESTO NA PILHA
        XOR DX, DX                              ;LIMPA DX PARA A PRÓXIMA MULTIPLICAÇÃO
        INC CX                                  ;MANTÉM CONTA DO NUMERO DE CARACTERES PARA O PROXIMO LOOP
        OR AX, AX                               ;SE QUOCIENTE = 0, SAIR DO LOOP
        JNZ OUTPUTDECIMAL
    
    MOV AH, 2
    IMPRIMIRDECIMAL:
        POP DX                                  ;SESEMPILHA NÚMEROS E OS IMPRIME
        OR DL, 30H
        INT 21H
        LOOP IMPRIMIRDECIMAL

    POP_4 AX, BX, CX, DX
    RET
SAIDADECIMAL ENDP

;IMPRIME MENSAGENS DE NUMERO DE TIROS E NUMERO DE ERROS
IMPRIMIR_ESTATISTICAS PROC
    PUSH AX
    MOV AH, 9
    LEA DX, MSG_NUM_TIROS
    INT 21H
    MOV AL, NUM_TIROS                           ;IMPRIME NÚMERO
    CALL SAIDADECIMAL

    MOV AH, 9
    LEA DX, MSG_NUM_ERROS                       ;IMPRIME MENSAGEM
    INT 21H
    MOV AL, NUM_ERROS                           ;IMPRIME NUMERO
    CALL SAIDADECIMAL
    POP AX
    RET
IMPRIMIR_ESTATISTICAS ENDP
END MAIN
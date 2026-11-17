/*
 * microc.flex
 *
 * Esqueleto do analisador lexico (scanner) para a linguagem Micro C.
 * Disciplina: Compiladores I - FACOM
 *
 * Este arquivo NAO esta completo. Partes do reconhecimento de tokens
 * foram implementadas apenas como EXEMPLO, para orienta-lo(a) sobre o
 * padrao a seguir. As demais estao marcadas com "TODO(aluno)" e devem
 * ser completadas por voce.
 *
 * Compilacao:
 *      flex microc.flex
 *      gcc lex.yy.c -o lexer
 *
 * Uso:
 *      ./lexer test.mc
 */

%option prefix="microc_yy" noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---------------------------------------------------------------------
 * 1. VOCABULARIO DE TOKENS (equivalente a tokens.h)
 * ------------------------------------------------------------------- */

#include "tokens.h"

/* Nomes dos tokens, usados apenas pelo main() de teste abaixo para
 * imprimir o tipo de cada token de forma legivel. Mantenha esta lista
 * na MESMA ORDEM do enum TokenType. */
static const char *nome_token[] = {
    "UNDEF", "ID", "END_OF_FILE",
    "INTEGERCONST", "CHARCONST", "STRINGCONST",
    "PLUS", "MINUS", "MUL", "DIV", "MOD",
    "EQ", "NEQ", "LT", "GT", "LEQ", "GEQ", "AND", "OR", "NOT",
    "ASSIGN", "SEMICOLON", "COMMA", "LPAREN", "RPAREN",
    "LBRACE", "RBRACE", "LBRACKET", "RBRACKET",
    "MAIN", "IF", "ELSE", "FOR", "RETURN", "INT", "CHAR", "PRINT"
};

YYSTYPE microc_yylval;

/* Linha atual do arquivo-fonte sendo processado. Deve ser incrementada
 * toda vez que uma quebra de linha for consumida pelo scanner (seja em
 * codigo "normal", dentro de comentarios ou dentro de strings). */
int linha_atual = 1;
int linha_token = 1;

static int pode_unario = 1;

/* Funcao auxiliar para preencher microc_yylval.symbol com uma copia do
 * texto reconhecido (yytext). Sinta-se livre para usar/adaptar. */
static void guarda_lexema(void) {
    microc_yylval.symbol = strdup(yytext);
}

static char *converte_escapes(const char *texto, size_t inicio, size_t fim) {
    size_t i, j = 0;
    char *saida = malloc(fim - inicio + 1);
    if (!saida) {
        fprintf(stderr, "Erro: memoria insuficiente\n");
        exit(1);
    }

    for (i = inicio; i < fim; ++i) {
        if (texto[i] == '\\' && i + 1 < fim) {
            ++i;
            switch (texto[i]) {
                case 'n': saida[j++] = '\n'; break;
                case 't': saida[j++] = '\t'; break;
                case '\\': saida[j++] = '\\'; break;
                case '"': saida[j++] = '"'; break;
                case '0': saida[j++] = '\0'; break;
                default:  saida[j++] = texto[i]; break;
            }
        } else {
            saida[j++] = texto[i];
        }
    }
    saida[j] = '\0';
    return saida;
}

void microc_liberar_symbol(void)
{
    free(microc_yylval.symbol);
    microc_yylval.symbol = NULL;
}


#define YY_USER_ACTION linha_token = linha_atual;
%}

/* -----------------------------------------------------------------------
 * 2. SECAO DE DEFINICOES
 * ------------------------------------------------------------------- */

DIGIT       [0-9]
LETRA       [a-zA-Z_]
ALFANUM     [a-zA-Z0-9_]

%x COMMENT

%%


 /* -----------------------------------------------------------------------
  * 3. SECAO DE REGRAS
  * --------------------------------------------------------------------- */

 /* --- Fim de arquivo -----------------------------------------------------
  * Tratada explicitamente (em vez de depender do retorno automatico 0
  * do flex), pois o token UNDEF tambem vale 0 no enum TokenType -- se
  * dependessemos do comportamento padrao, um erro lexico seria
  * confundido com o fim do arquivo pelo main() de teste abaixo. */
<<EOF>>             { return END_OF_FILE; }

 /* --- Espacos em branco e quebras de linha ---------------------------- */
\n                  { linha_atual++; }
[ \t\r]+            { /* ignora espacos em branco */ }

 /* --- Comentarios ------------------------------------------------------
  * Estes ja estao implementados como exemplo de uso de estados (%x) e
  * de tratamento de erro via EOF dentro de um estado especial. */
"//".*              { /* comentario de linha: ignora ate o fim da linha */ }

"/*"                { BEGIN(COMMENT); }
<COMMENT>"*/"       { BEGIN(INITIAL); }
<COMMENT>\n         { linha_atual++; }
<COMMENT><<EOF>>    {
                        microc_yylval.error_msg = "EOF em comentario";
                        return UNDEF;
                    }
<COMMENT>.          { /* consome qualquer outro caractere dentro do comentario */ }

 /* Fechamento de comentario sem abertura correspondente. */
"*/"                {
                        microc_yylval.error_msg = "Comentario nao iniciado";
                        return UNDEF;
                    }

 /* --- Palavras reservadas e identificadores ----------------------------
  * TODO(aluno): atualmente TODA sequencia de letras/underscore e
  * devolvida como ID. Voce deve comparar o lexema reconhecido com cada
  * palavra reservada da linguagem (main, if, else, for, return, int,
  * char, print) e devolver o token especifico quando houver
  * correspondencia. Use strcmp(), conforme discutido em aula, ou uma
  * tabela hash caso queira ir alem do exigido. Nao esqueca de chamar
  * guarda_lexema() (ou equivalente) quando o token for de fato ID. */
{LETRA}{ALFANUM}*   {
                        if (strcmp(yytext, "main") == 0) {
                            pode_unario = 1;
                            return MAIN;
                        }

                        if (strcmp(yytext, "if") == 0) {
                            pode_unario = 1;
                            return IF;
                        }

                        if (strcmp(yytext, "else") == 0) {
                            pode_unario = 1;
                            return ELSE;
                        }

                        if (strcmp(yytext, "for") == 0) {
                            pode_unario = 1;
                            return FOR;
                        }

                        if (strcmp(yytext, "return") == 0) {
                            pode_unario = 1;
                            return RETURN;
                        }

                        if (strcmp(yytext, "int") == 0) {
                            pode_unario = 1;
                            return INT;
                        }

                        if (strcmp(yytext, "char") == 0) {
                            pode_unario = 1;
                            return CHAR;
                        }

                        if (strcmp(yytext, "print") == 0) {
                            pode_unario = 1;
                            return PRINT;
                        }

                        guarda_lexema();
                        pode_unario = 0;
                        return ID;
                    }

 /* --- Constantes inteiras -----------------------------------------------
  * TODO(aluno): o padrao formal para um inteiro em Micro C e um ou mais
  * digitos, opcionalmente precedidos de um sinal de menos (numeros
  * negativos). A regra abaixo trata apenas inteiros sem sinal; use a
  * tecnica de lookahead discutida em aula (veja o operador MINUS mais
  * abaixo) para decidir quando um '-' faz parte do numero e quando ele
  * e, na verdade, o operador de subtracao. */
{DIGIT}+            {
                        guarda_lexema();
                        pode_unario = 0;
                        return INTEGERCONST;
                    }

"-"{DIGIT}+          {
                        if (pode_unario) {
                            guarda_lexema();
                            pode_unario = 0;
                            return INTEGERCONST;
                        }
                        
                        yyless(1);
                        pode_unario = 1;
                        return MINUS;
                    }

 /* --- Constantes de caractere --------------------------------------------
  * TODO(aluno): reconhecer o padrao 'x' (aspas simples, um caractere,
  * aspas simples) e devolver CHARCONST. Trate tambem o caso de erro em
  * que as aspas simples nao sao fechadas corretamente (token UNDEF). */

'([^'\\\n\0]|\\[nt\\"0])' {
    microc_yylval.symbol = converte_escapes(yytext, 1, yyleng - 1);
    pode_unario = 0;
    return CHARCONST;
}

''                  {
    microc_yylval.error_msg = "Char nao pode ser vazio";
    return UNDEF;
}
'\\[^nt\\"0]'        {
    microc_yylval.error_msg = "Sequencia de escape invalida em char";
    return UNDEF;
}
'[^']*\0[^']*'       {
    microc_yylval.error_msg = "Char contem caractere nulo";
    return UNDEF;
}
'[^'\\\n]{2,}'      {
    microc_yylval.error_msg = "Char nao pode conter mais de um caractere";
    return UNDEF;
}
'[^'\n]*\n          {
    microc_yylval.error_msg = "Char nao terminado";
    linha_atual++;
    return UNDEF;
}

 /* --- Constantes de string -------------------------------------------
  * TODO(aluno): reconhecer o padrao "[^"\n]*" (uma ou mais aspas
  * duplas delimitando o conteudo da string) e devolver STRINGCONST.
  * Voce deve tratar os seguintes erros (veja o enunciado, Secao 4.1):
  *   - EOF antes do fechamento da string ("EOF em string")
  *   - quebra de linha nao escapada dentro da string
  *     ("String nao terminada")
  *   - caractere nulo dentro da string
  *     ("String contem caractere nulo")
  * Alem disso, converta as sequencias de escape (\n, \t, \\, \", \0)
  * para os caracteres correspondentes antes de armazenar o lexema. */

\"([^\"\\\n\0]|\\[nt\\"0])*\" {
    microc_yylval.symbol = converte_escapes(yytext, 1, yyleng - 1);
    pode_unario = 0;
    return STRINGCONST;
}

\"\"                  {
    microc_yylval.error_msg = "String nao pode ser vazia";
    return UNDEF;
}

\"[^\"\n]*\n          {
    microc_yylval.error_msg = "String nao terminada";
    linha_atual++;
    return UNDEF;
}
\"[^\"\n]*\0[^\"\n]*\" {
    microc_yylval.error_msg = "String contem caractere nulo";
    return UNDEF;
}
\"[^\"\\\n]*\\[^nt\\"0][^\"\\\n]*\" {
    microc_yylval.error_msg = "Sequencia de escape invalida";
    return UNDEF;
}
\"[^\"\n]*\"         {
    microc_yylval.error_msg = "String contem escape invalido";
    return UNDEF;
}

 /* --- Operadores relacionais e logicos ---------------------------------
  * O caso de '=' esta implementado como EXEMPLO do uso de lookahead
  * (yytext mostra o que foi casado; voce pode usar input()/unput() ou,
  * de forma mais simples em flex, escrever as duas alternativas como
  * regras separadas, deixando o proprio flex escolher o casamento mais
  * longo -- veja a explicacao na Secao 2 do enunciado). */
"=="                { pode_unario = 1; return EQ; }
"="                 { pode_unario = 1; return ASSIGN; }

 /* TODO(aluno): complete os demais operadores que compartilham prefixo,
  * seguindo o mesmo padrao do exemplo acima:
  *   !=  e  !      ->  NEQ, NOT
  *   <=  e  <      ->  LEQ, LT
  *   >=  e  >      ->  GEQ, GT
  *   &&             ->  AND
  *   ||             ->  OR
  */

"!="                { pode_unario = 1; return NEQ; }
"!"                 { pode_unario = 1; return NOT; }
"<="                { pode_unario = 1; return LEQ; }
"<"                 { pode_unario = 1; return LT; }
">="                { pode_unario = 1; return GEQ; }
">"                 { pode_unario = 1; return GT; }
"&&"                { pode_unario = 1; return AND; }
"||"                { pode_unario = 1; return OR; }

 /* --- Operadores aritmeticos e simbolos de pontuacao (ja prontos) ------ */
"+"                 { return PLUS; }
"-"                 { return MINUS; }
"*"                 { return MUL; }
"/"                 { return DIV; }
"%"                 { return MOD; }
";"                 { return SEMICOLON; }
","                 { return COMMA; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }
"{"                 { return LBRACE; }
"}"                 { return RBRACE; }
"["                 { return LBRACKET; }
"]"                 { return RBRACKET; }

 /* --- Caractere invalido -------------------------------------------------
  * Casa com qualquer caractere que nao tenha correspondido a nenhuma
  * regra anterior. Deve ser SEMPRE a ultima regra do arquivo. */
.                   {
                        microc_yylval.error_msg = yytext;
                        return UNDEF;
                    }


                    
%%
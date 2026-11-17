
#include <stdarg.h>
#include <stdio.h>
#include "ll1.h"
#include "util.h"


static void reportar(const Gramatica *g, int nt, const Expr *e, int eh_aviso,
                     const Bitset *comum, const char *fmt, ...)
{
    va_list ap;

    fprintf(stderr, "%s:%d:%d: %s: conflito LL(1) em %s: ",
            g->arquivo, e->linha, e->coluna,
            eh_aviso ? "aviso" : "erro", g->nts[nt].nome);

    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);

    if (comum != NULL) {
        fprintf(stderr, " ");
        gram_imprimir_conjunto(stderr, g, comum);
    }

    fputc('\n', stderr);
}


static int verificar_expr(const Gramatica *g, int nt, const Expr *e)
{
    int erros;
    int i;
    int j;
    int anulaveis;
    Bitset comum;

    erros = 0;

    switch (e->tipo) {
    case E_ALT:
       
        anulaveis = 0;

        for (i = 0; i < e->nfilhos; i++) {
            if (e->filhos[i]->anulavel) {
                anulaveis++;
            }

            for (j = i + 1; j < e->nfilhos; j++) {
                bitset_iniciar(&comum, g->nterms);
                bitset_intersecao(&comum,
                                  &e->filhos[i]->first,
                                  &e->filhos[j]->first);

                if (!bitset_vazio(&comum)) {
                    reportar(g, nt, e, 0, &comum,
                             "alternativas %d e %d comecam com",
                             i + 1, j + 1);
                    erros++;
                }

                bitset_liberar(&comum);
            }
        }

       
        if (anulaveis > 1) {
            reportar(g, nt, e, 0, NULL,
                     "mais de uma alternativa e anulavel");
            erros++;
        }

       
        for (i = 0; i < e->nfilhos; i++) {
            if (e->filhos[i]->anulavel) {
                for (j = 0; j < e->nfilhos; j++) {
                    if (i != j) {
                        bitset_iniciar(&comum, g->nterms);
                        bitset_intersecao(
                            &comum,
                            &e->filhos[i]->follow,
                            &e->filhos[j]->first
                        );

                        if (!bitset_vazio(&comum)) {
                            reportar(g, nt, e, 0, &comum,
                                     "FOLLOW da alternativa %d conflita "
                                     "com FIRST da alternativa %d",
                                     i + 1, j + 1);
                            erros++;
                        }

                        bitset_liberar(&comum);
                    }
                }
            }
        }

        break;

    case E_OPC:
    case E_REP:
        if (e->nfilhos > 0) {
            
            if (e->filhos[0]->anulavel) {
                if (e->tipo == E_OPC) {
                    reportar(g, nt, e, 0, NULL,
                             "conteudo de opcional e anulavel");
                } else {
                    reportar(g, nt, e, 0, NULL,
                             "conteudo de repeticao e anulavel");
                }

                erros++;
            }

          
            bitset_iniciar(&comum, g->nterms);
            bitset_intersecao(&comum,
                              &e->filhos[0]->first,
                              &e->follow);

            if (!bitset_vazio(&comum)) {
                if (e->tipo == E_OPC) {
                    reportar(g, nt, e, 1, &comum,
                             "FIRST e FOLLOW de [ ] se intersectam "
                             "(resolvido de forma gulosa) em");
                } else {
                    reportar(g, nt, e, 1, &comum,
                             "FIRST e FOLLOW de { } se intersectam "
                             "(resolvido de forma gulosa) em");
                }
            }

            bitset_liberar(&comum);
        }

        break;

    case E_SEQ:
        break;

    case E_TERM:
    case E_NAOTERM:
    case E_VAZIO:
        break;
    }

   
    for (i = 0; i < e->nfilhos; i++) {
        erros += verificar_expr(g, nt, e->filhos[i]);
    }

    return erros;
}


int ll1_verificar(const Gramatica *g)
{
    int erros;
    int i;

    erros = 0;

    for (i = 0; i < g->nnts; i++) {
        erros += verificar_expr(g, i, g->nts[i].regra);
    }

    return erros;
}

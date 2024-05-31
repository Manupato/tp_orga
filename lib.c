#include "lib.h"

funcCmp_t *getCompareFunction(type_t t)
{
    switch (t)
    {
    case TypeInt:
        return (funcCmp_t *)&intCmp;
        break;
    case TypeString:
        return (funcCmp_t *)&strCmp;
        break;
    case TypeCard:
        return (funcCmp_t *)&cardCmp;
        break;
    default:
        break;
    }
    return 0;
}
funcClone_t *getCloneFunction(type_t t)
{
    switch (t)
    {
    case TypeInt:
        return (funcClone_t *)&intClone;
        break;
    case TypeString:
        return (funcClone_t *)&strClone;
        break;
    case TypeCard:
        return (funcClone_t *)&cardClone;
        break;
    default:
        break;
    }
    return 0;
}
funcDelete_t *getDeleteFunction(type_t t)
{
    switch (t)
    {
    case TypeInt:
        return (funcDelete_t *)&intDelete;
        break;
    case TypeString:
        return (funcDelete_t *)&strDelete;
        break;
    case TypeCard:
        return (funcDelete_t *)&cardDelete;
        break;
    default:
        break;
    }
    return 0;
}
funcPrint_t *getPrintFunction(type_t t)
{
    switch (t)
    {
    case TypeInt:
        return (funcPrint_t *)&intPrint;
        break;
    case TypeString:
        return (funcPrint_t *)&strPrint;
        break;
    case TypeCard:
        return (funcPrint_t *)&cardPrint;
        break;
    default:
        break;
    }
    return 0;
}

/** Int **/

int32_t intCmp(int32_t *a, int32_t *b) {

    if (*a > *b)
        return -1;
    else if (*a < *b)
        return 1;
    else
        return 0;
}

void intDelete(int32_t* a) {
    free(a);
}

void intPrint(int32_t *a, FILE *pFile)
{
    fprintf(pFile, "%d", *a);
}

int32_t* intClone(int32_t* a) {    
    int32_t* clone = (int32_t*)malloc(sizeof(int32_t));

    if (clone == NULL || a == NULL)
        return NULL;

    *clone = *a;
    
    return clone;
}

/** Lista **/

list_t *listNew(type_t t)
{
    list_t *new_list = (list_t*)malloc(sizeof(list_t));

    new_list->type = t;
    new_list->size = 0;
    new_list->first = NULL;
    new_list->last = NULL;

    return new_list;
}

uint8_t listGetSize(list_t *l)
{
    return l->size;
}

void* listGet(list_t* l, uint8_t i) {

    if (l == NULL) {

        return NULL;
    }

    if (i >= l->size) {

        return NULL;
    }

    listElem_t* elem = l->first;
    for (uint8_t j = 0; j < i; j++)
        elem = elem->next;
    
    return elem->data;
}

void listAddFirst(list_t *l, void *data)
{
    listElem_t *new_elem = (listElem_t *)malloc(sizeof(listElem_t));
    funcClone_t* funcClone = (funcClone_t*) getCloneFunction(l->type);
    void* newData = funcClone(data);

    new_elem->data = newData;
    new_elem->next = l->first;
    new_elem->prev = NULL;

    if (l->last != NULL) {
        l->first->prev = new_elem;
    } else {
        l->last = new_elem;
    }

    l->first = new_elem;
    l->size++;
}

void listAddLast(list_t *l, void *data)
{
    listElem_t* oldLast = l->last;

    listElem_t* newLast = (listElem_t*) malloc(sizeof(listElem_t));
    funcClone_t* funcClone = (funcClone_t*) getCloneFunction(l->type);
    void* newData = funcClone(data);

    newLast->data = newData;
    newLast->next = NULL;
    newLast->prev = oldLast;

    if (oldLast) {

        oldLast->next = newLast;
    } else {

        l->first = newLast;
    }

    l->size++;
    l->last = newLast;
}

list_t* listClone(list_t* l){
    funcClone_t* cloneFunction = getCloneFunction(l->type);

    if (cloneFunction == NULL)
        return NULL;

    list_t* newList = listNew(l->type);

    newList->type = l->type;
    newList->size = 0;
    newList->first = NULL;
    newList->last = NULL;

    uint8_t size = l->size;
    for(uint8_t i = 0; i < size; i++){
        listAddLast(newList, listGet(l, i));
    }

    return newList;
}

void *listRemove(list_t *l, uint8_t i)
{
    if (i >= l->size) {
        // Manejo de error en caso de índice fuera de rango
        return NULL;
    }

    listElem_t *current = l->first;
    for (uint8_t j = 0; j < i; j++) {
        current = current->next;
    }

    void *data = current->data;

    if (current->prev != NULL) {
        current->prev->next = current->next;
    } else {
        l->first = current->next;
    }

    if (current->next != NULL) {
        current->next->prev = current->prev;
    } else {
        l->last = current->prev;
    }

    free(current);
    l->size--;

    return data;
}

void listSwap(list_t *l, uint8_t i, uint8_t j)
{
    uint8_t size = l->size;

    if (i < size && j < size) {

        listElem_t* first = l->first;
        listElem_t* last = l->first;

        for (uint8_t m = 0; m < i; m++) {

            first = first->next;
        }

        for (uint8_t n = 0; n < j; n++) {

            last = last->next;
        }

        void* firstData = first->data;
        first->data = last->data;
        last->data = firstData;
    }
}

void listDelete(list_t* l){

    if(l == NULL)
        return;

    funcDelete_t* deleteFunction = getDeleteFunction(l->type);
    listElem_t* current = l->first;

    uint8_t size = l->size;

    for(uint8_t i = 0; i < size; i++) {

        deleteFunction(listRemove(l, 0));
    }

    free(l);
}

void listPrint(list_t *l, FILE *pFile)
{
    funcPrint_t* funcionPrint = getPrintFunction(l->type);

    fputc('[', pFile);
    uint8_t _size = l->size;

    for (uint8_t i = 0; i < _size; i++) {

        funcionPrint(listGet(l, i), pFile);

        if (_size > 0 && i < _size - 1) {

            fputc(',', pFile);
        }
    }

    fputc(']', pFile);
}

/** Game **/

game_t *gameNew(void *cardDeck, funcGet_t *funcGet, funcRemove_t *funcRemove, funcSize_t *funcSize, funcPrint_t *funcPrint, funcDelete_t *funcDelete)
{
    game_t *game = (game_t *)malloc(sizeof(game_t));
    game->cardDeck = cardDeck;
    game->funcGet = funcGet;
    game->funcRemove = funcRemove;
    game->funcSize = funcSize;
    game->funcPrint = funcPrint;
    game->funcDelete = funcDelete;
    return game;
}
int gamePlayStep(game_t *g)
{
    int applied = 0;
    uint8_t i = 0;
    while (applied == 0 && i + 2 < g->funcSize(g->cardDeck))
    {
        card_t *a = g->funcGet(g->cardDeck, i);
        card_t *b = g->funcGet(g->cardDeck, i + 1);
        card_t *c = g->funcGet(g->cardDeck, i + 2);
        if (strCmp(cardGetSuit(a), cardGetSuit(c)) == 0 || intCmp(cardGetNumber(a), cardGetNumber(c)) == 0)
        {
            card_t *removed = g->funcRemove(g->cardDeck, i);
            cardAddStacked(b, removed);
            cardDelete(removed);
            applied = 1;
        }
        i++;
    }
    return applied;
}
uint8_t gameGetCardDeckSize(game_t *g)
{
    return g->funcSize(g->cardDeck);
}
void gameDelete(game_t *g)
{
    g->funcDelete(g->cardDeck);
    free(g);
}
void gamePrint(game_t *g, FILE *pFile)
{
    g->funcPrint(g->cardDeck, pFile);
}
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>

static void handleOpt(char ch);
static void prompt(void);
static void showHelp(void);

static void handleOpt(char ch) {
    switch (ch) {
        case 'x':
        case 'X':
            exit(0);
            break;

        default:
            printf("\nUnrecognized option\n");
            break;
    }
}

static void prompt(void) {
    showHelp();

    printf("\nSelect an option:\n");
    handleOpt(cgetc());
}

static void showHelp(void) {
    printf("\nFloating Point Demonstration Program\n\n");

    printf("X - Exit\n");
}

void main()
{
    clrscr();

    while (1) {
        prompt();
    }
}
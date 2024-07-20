/*---------------------------------------------------------------------------------


     snes pad demo
    -- alekmaul


---------------------------------------------------------------------------------*/
#include <snes.h>

extern char snesfont, snespal;
unsigned short padCurrent;

//---------------------------------------------------------------------------------
int main(void)
{
    // Initialize SNES
    consoleInit();

    // Initialize text console with our font
    consoleSetTextVramBGAdr(0x6800);
    consoleSetTextVramAdr(0x3000);
    consoleSetTextOffset(0x0100);
    consoleInitText(0, 16 * 2, &snesfont, &snespal);

    // Draw a wonderful text :P
    consoleDrawText(12, 1, "PAD TEST");
    consoleDrawText(6, 5, "USE PAD TO SEE VALUE");

    // Init background
    bgSetGfxPtr(0, 0x2000);
    bgSetMapPtr(0, 0x6800, SC_32x32);

    // Now Put in 16 color mode
    setMode(BG_MODE1, 0);
    bgSetDisable(1);
    bgSetDisable(2);

    // Wait for nothing :P
    setScreenOn();

    while (1)
    {
        // Get current #0 pad
        padCurrent = padsDown(0);

        // Update display with current pad
        switch (padCurrent) {
        case KEY_A:
            consoleDrawText(9, 10, "A PRESSED P1");
            break;
        case KEY_B:
            consoleDrawText(9, 10, "B PRESSED P1");
            break;
        case KEY_SELECT:
            consoleDrawText(9, 10, "SELECT PRESSED P1");
            break;
        case KEY_START:
            consoleDrawText(9, 10, "START PRESSED P1");
            break;
        case KEY_RIGHT:
            consoleDrawText(9, 10, "RIGHT PRESSED P1");
            break;
        case KEY_LEFT:
            consoleDrawText(9, 10, "LEFT PRESSED P1");
            break;
        case KEY_DOWN:
            consoleDrawText(9, 10, "DOWN PRESSED P1");
            break;
        case KEY_UP:
            consoleDrawText(9, 10, "UP PRESSED P1");
            break;
        case KEY_R:
            consoleDrawText(9, 10, "R PRESSED P1");
            break;
        case KEY_L:
            consoleDrawText(9, 10, "L PRESSED P1");
            break;
        case KEY_X:
            consoleDrawText(9, 10, "X PRESSED P1");
            break;
        case KEY_Y:
            consoleDrawText(9, 10, "Y PRESSED P1");
            break;
        default:
            consoleDrawText(9, 10, "                         ");
            break;
        }

        // Get current #1 pad
        padCurrent = padsDown(1);

        // Update display with current pad
        switch (padCurrent) {
        case KEY_A:
            consoleDrawText(9, 14, "A PRESSED P2");
            break;
        case KEY_B:
            consoleDrawText(9, 14, "B PRESSED P2");
            break;
        case KEY_SELECT:
            consoleDrawText(9, 14, "SELECT PRESSED P2");
            break;
        case KEY_START:
            consoleDrawText(9, 14, "START PRESSED P2");
            break;
        case KEY_RIGHT:
            consoleDrawText(9, 14, "RIGHT PRESSED P2");
            break;
        case KEY_LEFT:
            consoleDrawText(9, 14, "LEFT PRESSED P2");
            break;
        case KEY_DOWN:
            consoleDrawText(9, 14, "DOWN PRESSED P2");
            break;
        case KEY_UP:
            consoleDrawText(9, 14, "UP PRESSED P2");
            break;
        case KEY_R:
            consoleDrawText(9, 14, "R PRESSED P2");
            break;
        case KEY_L:
            consoleDrawText(9, 14, "L PRESSED P2");
            break;
        case KEY_X:
            consoleDrawText(9, 14, "X PRESSED P2");
            break;
        case KEY_Y:
            consoleDrawText(9, 14, "Y PRESSED P2");
            break;
        default:
            consoleDrawText(9, 14, "                         ");
            break;
        }

        WaitForVBlank();
    }
    return 0;
}
#include <windows.h>
#include <iostream>

int main() {
    HWND hDesktop = GetDesktopWindow();

    if (hDesktop) {
        std::cout << "HWND of Desktop: " << hDesktop << std::endl;
    } else {
        std::cerr << "Failed to get Desktop HWND" << std::endl;
    }

    return 0;
}
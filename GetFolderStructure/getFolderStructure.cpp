#include <iostream>
#include <filesystem>
#include <string>

namespace fs = std::filesystem;

void printDirJSON(const fs::path& path, int depth, int maxDepth) {
    if (depth > maxDepth) return;

    std::cout << "{\n";

    bool firstEntry = true;
    for (const auto& entry : fs::directory_iterator(path)) {
        if (!firstEntry) std::cout << ",\n";
        firstEntry = false;

        // Key: file/folder name
        std::cout << std::string((depth + 1) * 2, ' ') << "\"" 
                  << entry.path().filename().string() << "\": ";

        if (fs::is_directory(entry.status())) {
            // Recurse into directory
            printDirJSON(entry.path(), depth + 1, maxDepth);
        } else {
            // File: just output null
            std::cout << "null";
        }
    }

    std::cout << "\n" << std::string(depth * 2, ' ') << "}";
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " <directory> <max_depth>\n";
        return 1;
    }

    fs::path startPath = argv[1];
    int maxDepth = std::stoi(argv[2]);

    if (!fs::exists(startPath) || !fs::is_directory(startPath)) {
        std::cerr << "Error: Path does not exist or is not a directory\n";
        return 1;
    }

    printDirJSON(startPath, 0, maxDepth);
    std::cout << "\n"; // End with newline
    return 0;
}

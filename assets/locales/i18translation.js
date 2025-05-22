import fs from "fs";
import path from "path";
import https from "https";
import { fileURLToPath } from "url";
import { promisify } from "util";

// Get current file directory with ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Language options as provided
const LANGUAGE_OPTIONS = {
  en: {
    name: "English",
    nativeName: "English",
    direction: "ltr",
  },
  fr: {
    name: "French",
    nativeName: "Français",
    direction: "ltr",
  },
  de: {
    name: "German",
    nativeName: "Deutsch",
    direction: "ltr",
  },
  es: {
    name: "Spanish",
    nativeName: "Español",
    direction: "ltr",
  },
  nl: {
    name: "Dutch",
    nativeName: "Nederlands",
    direction: "ltr",
  },
  pt: {
    name: "Portuguese",
    nativeName: "Português",
    direction: "ltr",
  },
  ar: {
    name: "Arabic",
    nativeName: "العربية",
    direction: "rtl", // Corrected for Arabic
  },
  hi: {
    name: "Hindi",
    nativeName: "हिन्दी",
    direction: "ltr",
  },
  vi: {
    name: "Vietnamese",
    nativeName: "Tiếng Việt",
    direction: "ltr",
  },
};

// Promisify fs functions
const readdir = promisify(fs.readdir);
const readFile = promisify(fs.readFile);
const writeFile = promisify(fs.writeFile);
const mkdir = promisify(fs.mkdir);
const stat = promisify(fs.stat);

// Rate limiting to avoid hitting API limits
const DELAY_BETWEEN_REQUESTS = 500; // ms

// Utility function to pause execution
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Translate text using MyMemory free translation API
 * @param {string} text - Text to translate
 * @param {string} targetLang - Target language code
 * @returns {Promise<string>} - Translated text
 */
async function translateText(text, targetLang) {
  // Skip translation for empty strings, code, or very technical content
  if (
    !text.trim() ||
    text.includes("import ") ||
    text.includes("require(") ||
    text.includes("function(") ||
    text.startsWith("//") ||
    text.includes("{") ||
    text.includes("<") ||
    text.includes("${")
  ) {
    return text;
  }

  // Prepare the API URL (MyMemory Translation API)
  const encodedText = encodeURIComponent(text);
  const url = `https://api.mymemory.translated.net/get?q=${encodedText}&langpair=en|${targetLang}`;

  return new Promise((resolve, reject) => {
    https
      .get(url, (res) => {
        let data = "";

        res.on("data", (chunk) => {
          data += chunk;
        });

        res.on("end", () => {
          try {
            const response = JSON.parse(data);

            if (response.responseStatus === 200 && response.responseData) {
              resolve(response.responseData.translatedText);
            } else {
              console.warn(
                `Warning: Translation issue for "${text}" - using original text`
              );
              resolve(text);
            }
          } catch (error) {
            console.error("Error parsing translation response:", error);
            resolve(text); // Return original on error
          }
        });
      })
      .on("error", (error) => {
        console.error("Translation request error:", error);
        resolve(text); // Return original on error
      });
  });
}

/**
 * Process a JS/JSX file for translation
 */
async function processJSFile(filePath, targetLanguage) {
  try {
    const content = await readFile(filePath, "utf8");

    // Use regex to find translation strings
    // This targets string literals that are likely to be UI text
    const translationRegex = /(["'])(?:(?=(\\?))\2.)*?\1/g;

    let translatedContent = content;
    const matches = content.match(translationRegex);

    if (matches) {
      for (const match of matches) {
        // Extract string without quotes
        const text = match.slice(1, -1);

        // Skip translation for non-UI strings
        if (
          text.length < 2 ||
          text.includes("${") ||
          text.includes("/") ||
          text.includes(".") ||
          text.includes("import") ||
          !text.match(/[a-zA-Z]/)
        ) {
          continue;
        }

        // Add delay to avoid hitting API limits
        await sleep(DELAY_BETWEEN_REQUESTS);

        const translated = await translateText(text, targetLanguage);

        // Replace in the content (preserving quotes)
        translatedContent = translatedContent.replace(
          new RegExp(match.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "g"),
          match[0] + translated + match[0]
        );
      }
    }

    return translatedContent;
  } catch (error) {
    console.error(`Error processing file ${filePath}:`, error);
    return null;
  }
}

/**
 * Process a JSON file for translation
 */
async function processJSONFile(filePath, targetLanguage) {
  try {
    const content = await readFile(filePath, "utf8");
    const json = JSON.parse(content);

    const translatedJson = await translateJSONObject(json, targetLanguage);

    return JSON.stringify(translatedJson, null, 2);
  } catch (error) {
    console.error(`Error processing JSON file ${filePath}:`, error);
    return null;
  }
}

/**
 * Translate a JSON object recursively
 */
async function translateJSONObject(obj, targetLanguage) {
  const result = {};

  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === "string") {
      // Add delay to avoid hitting API limits
      await sleep(DELAY_BETWEEN_REQUESTS);
      result[key] = await translateText(value, targetLanguage);
    } else if (Array.isArray(value)) {
      result[key] = await Promise.all(
        value.map(async (item) => {
          if (typeof item === "string") {
            // Add delay to avoid hitting API limits
            await sleep(DELAY_BETWEEN_REQUESTS);
            return await translateText(item, targetLanguage);
          } else if (typeof item === "object" && item !== null) {
            return await translateJSONObject(item, targetLanguage);
          }
          return item;
        })
      );
    } else if (typeof value === "object" && value !== null) {
      result[key] = await translateJSONObject(value, targetLanguage);
    } else {
      result[key] = value;
    }
  }

  return result;
}

/**
 * Process a directory recursively for translation
 */
async function processDirectory(dir, targetLanguage) {
  try {
    const files = await readdir(dir);
    const cwd = process.cwd();

    for (const file of files) {
      const sourcePath = path.join(dir, file);
      const sourceStats = await stat(sourcePath);

      if (sourceStats.isDirectory()) {
        // Recursively process subdirectories
        await processDirectory(sourcePath, targetLanguage);
      } else {
        const relativePath = path.relative(path.join(cwd, "en"), sourcePath);
        const targetPath = path.join(cwd, targetLanguage, relativePath);
        const targetDir = path.dirname(targetPath);

        // Create target directory if it doesn't exist
        await mkdir(targetDir, { recursive: true });

        let translatedContent;
        const ext = path.extname(file).toLowerCase();

        // First check if the target file already exists
        let targetExists = false;
        try {
          await stat(targetPath);
          targetExists = true;
          console.log(`File already exists: ${targetPath}`);
        } catch {
          // File doesn't exist, will be created
        }

        if (ext === ".json") {
          if (!targetExists) {
            translatedContent = await processJSONFile(
              sourcePath,
              targetLanguage
            );
          }
        } else if ([".js", ".jsx", ".ts", ".tsx"].includes(ext)) {
          if (!targetExists) {
            translatedContent = await processJSFile(sourcePath, targetLanguage);
          }
        } else {
          // For other file types, just copy the file if it doesn't exist
          if (!targetExists) {
            const content = await readFile(sourcePath);
            await writeFile(targetPath, content);
            console.log(`Copied file: ${targetPath}`);
          }
          continue;
        }

        if (translatedContent && !targetExists) {
          await writeFile(targetPath, translatedContent);
          console.log(`Created translated file: ${targetPath}`);
        }
      }
    }
  } catch (error) {
    console.error(`Error processing directory: ${error}`);
  }
}

/**
 * Check if a directory exists
 */
async function directoryExists(dirPath) {
  try {
    const stats = await stat(dirPath);
    return stats.isDirectory();
  } catch {
    return false;
  }
}

// Main function
async function main() {
  // Use process.cwd() to get current working directory
  const cwd = process.cwd();
  const sourceDir = path.join(cwd, "en");

  // Check if the source directory exists
  if (!(await directoryExists(sourceDir))) {
    console.error(`Error: Source directory '${sourceDir}' does not exist!`);
    console.log(
      "Make sure you run this script from the parent folder containing all language directories."
    );
    return;
  }

  console.log("Starting translation process...");
  console.log(`Source directory: ${sourceDir}`);

  // Process each target language
  for (const [lang, langInfo] of Object.entries(LANGUAGE_OPTIONS)) {
    if (lang === "en") continue; // Skip English source

    console.log(`\nProcessing language: ${langInfo.name} (${lang})`);

    // Create language directory if it doesn't exist
    const langDir = path.join(cwd, lang);
    if (!(await directoryExists(langDir))) {
      await mkdir(langDir, { recursive: true });
      console.log(`Created language directory: ${langDir}`);
    }

    // Process all files for this language
    await processDirectory(sourceDir, lang);

    console.log(`Completed processing for ${langInfo.name}`);
  }

  console.log("\nTranslation process completed!");
  console.log(
    "Note: MyMemory Translation API has a limit of 1000 words/day for free usage."
  );
}

// Run the script
main().catch((err) => console.error("Error running script:", err));

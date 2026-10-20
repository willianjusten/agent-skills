// Quality rules for repos that lint with ESLint. Keep the framework's own config (for
// example eslint-config-next) first in the array and add these blocks after it.
import boundaries from "eslint-plugin-boundaries";
import sonarjs from "eslint-plugin-sonarjs";
import tseslint from "typescript-eslint";

export default tseslint.config(
  // <framework config here>
  ...tseslint.configs.strictTypeChecked,
  {
    languageOptions: { parserOptions: { projectService: true, tsconfigRootDir: import.meta.dirname } },
  },
  {
    // Plain JavaScript has no types to check.
    files: ["**/*.{js,mjs,cjs}"],
    extends: [tseslint.configs.disableTypeChecked],
  },
  {
    plugins: { sonarjs, boundaries },
    settings: {
      "boundaries/elements": [
        { type: "<module from docs/architecture.md>", pattern: "<folder that holds it, e.g. src/ui>" },
      ],
      "import/resolver": { node: { extensions: [".ts", ".tsx", ".js", ".jsx"] } },
    },
    rules: {
      // Warnings, not errors: scripts/ratchet.mjs counts them and fails when the count grows.
      "sonarjs/cognitive-complexity": ["warn", 15],
      "max-params": ["warn", { max: 3 }],

      "no-restricted-imports": [
        "error",
        { patterns: [{ group: ["<database client package>"], message: "Only the data layer talks to the database." }] },
      ],
      "boundaries/dependencies": [
        "error",
        {
          default: "disallow",
          policies: [
            {
              from: { element: { type: "<module>" } },
              allow: { to: { element: { types: { anyOf: ["<module it may import>"] } } } },
            },
          ],
        },
      ],
    },
  },
  {
    files: ["<data layer folder>/**"],
    rules: { "no-restricted-imports": "off" },
  },
);

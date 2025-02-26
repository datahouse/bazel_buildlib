"""Base tsconfig"""

tsconfig_base = {
    "compilerOptions": {
        "composite": True,
        "emitDecoratorMetadata": True,
        "esModuleInterop": True,
        "experimentalDecorators": True,
        "forceConsistentCasingInFileNames": True,
        "isolatedModules": True,
        "jsx": "react-jsx",
        "lib": ["es2022"],
        # Module and module resolution:
        # We want to transpile to ESM and have strict module resolution (node16).
        # TSC does not allow us to specify `module` explicitly (i.e. es2022)
        # while having `moduleResolution` set to `node16`.
        # Therefore, we use package_json to force `"type": "module"` in
        # `package.json` which configures both Node.js and TSC to emit ESM.
        #
        # Also see https://www.typescriptlang.org/docs/handbook/modules/reference.html#node16-nodenext
        "module": "node16",
        "moduleResolution": "node16",
        "rootDir": ".",
        "rootDirs": [".", "bazel-bin"],
        "skipLibCheck": True,
        "sourceMap": True,
        "strict": True,
        "target": "es2018",
    },
}
